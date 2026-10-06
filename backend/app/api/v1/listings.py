import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.models.listing import Listing, ListingImage, ListingStatus, Platform
from app.models.review import Review
from app.models.user import User, UserRole
from app.schemas.listing import ListingCreate, ListingOut, ListingPage, ListingUpdate
from app.services.commission import ensure_default_settings

router = APIRouter(prefix="/listings", tags=["listings"])

ALLOWED_IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp"}
MAX_IMAGE_BYTES = 5 * 1024 * 1024


def _seller_payload(db: Session, seller_id: uuid.UUID) -> dict | None:
    seller = db.get(User, seller_id)
    if seller is None:
        return None
    stats = (
        db.query(func.count(Review.id), func.avg(Review.rating))
        .filter(Review.reviewee_id == seller_id)
        .one()
    )
    count = int(stats[0] or 0)
    avg = float(stats[1]) if stats[1] is not None else None
    return {
        "id": seller.id,
        "username": seller.username,
        "full_name": seller.full_name,
        "avg_rating": round(avg, 2) if avg is not None else None,
        "reviews_count": count,
    }


def _listing_out(db: Session, listing: Listing) -> ListingOut:
    payload = {
        "id": listing.id,
        "seller_id": listing.seller_id,
        "title": listing.title,
        "description": listing.description,
        "price_xof": listing.price_xof,
        "platform": listing.platform,
        "team_strength": listing.team_strength,
        "account_level": listing.account_level,
        "status": listing.status,
        "images": [
            {"id": image.id, "url": image.url, "position": image.position}
            for image in listing.images
        ],
        "seller": _seller_payload(db, listing.seller_id),
        "created_at": listing.created_at,
        "updated_at": listing.updated_at,
    }
    return ListingOut(**payload)


def _get_owned_listing(db: Session, listing_id: uuid.UUID, user: User) -> Listing:
    listing = db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Annonce introuvable")
    if user.role is not UserRole.admin and listing.seller_id != user.id:
        raise HTTPException(status_code=403, detail="Vous n'êtes pas le propriétaire de cette annonce")
    return listing


@router.get("", response_model=ListingPage)
def list_listings(
    db: Session = Depends(get_db),
    q: str | None = None,
    platform: Platform | None = None,
    min_price: int | None = Query(default=None, ge=0),
    max_price: int | None = Query(default=None, ge=0),
    team_strength: int | None = Query(default=None, ge=0),
    status_filter: ListingStatus | None = Query(default=None, alias="status"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=50),
):
    query = db.query(Listing)
    if status_filter is not None:
        query = query.filter(Listing.status == status_filter)
    else:
        query = query.filter(Listing.status == ListingStatus.active)
    if q:
        pattern = f"%{q}%"
        query = query.filter(or_(Listing.title.ilike(pattern), Listing.description.ilike(pattern)))
    if platform is not None:
        query = query.filter(Listing.platform == platform)
    if min_price is not None:
        query = query.filter(Listing.price_xof >= min_price)
    if max_price is not None:
        query = query.filter(Listing.price_xof <= max_price)
    if team_strength is not None:
        query = query.filter(Listing.team_strength == team_strength)

    total = query.count()
    items = (
        query.order_by(Listing.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    return ListingPage(
        items=[_listing_out(db, item) for item in items],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/mine", response_model=ListingPage)
def my_listings(
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.seller, UserRole.admin)),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=50),
):
    query = db.query(Listing).filter(Listing.seller_id == user.id)
    total = query.count()
    items = (
        query.order_by(Listing.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    return ListingPage(
        items=[_listing_out(db, item) for item in items],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{listing_id}", response_model=ListingOut)
def get_listing(listing_id: uuid.UUID, db: Session = Depends(get_db)):
    listing = db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Annonce introuvable")
    return _listing_out(db, listing)


@router.post("", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
def create_listing(
    payload: ListingCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.seller, UserRole.admin)),
):
    ensure_default_settings(db)
    listing = Listing(
        seller_id=user.id,
        title=payload.title,
        description=payload.description,
        price_xof=payload.price_xof,
        platform=payload.platform,
        team_strength=payload.team_strength,
        account_level=payload.account_level,
        status=payload.status,
    )
    db.add(listing)
    db.flush()
    for index, url in enumerate(payload.image_urls):
        db.add(ListingImage(listing_id=listing.id, url=url, position=index))
    db.commit()
    db.refresh(listing)
    return _listing_out(db, listing)


@router.patch("/{listing_id}", response_model=ListingOut)
def update_listing(
    listing_id: uuid.UUID,
    payload: ListingUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    listing = _get_owned_listing(db, listing_id, user)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(listing, field, value)
    db.commit()
    db.refresh(listing)
    return _listing_out(db, listing)


@router.delete("/{listing_id}", response_model=ListingOut)
def archive_listing(
    listing_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    listing = _get_owned_listing(db, listing_id, user)
    listing.status = ListingStatus.archived
    db.commit()
    db.refresh(listing)
    return _listing_out(db, listing)


@router.post("/{listing_id}/images", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
async def upload_listing_image(
    listing_id: uuid.UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    listing = _get_owned_listing(db, listing_id, user)
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in ALLOWED_IMAGE_EXT:
        raise HTTPException(status_code=400, detail="Format d'image non supporté")
    content = await file.read()
    if len(content) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Image trop lourde (max 5 Mo)")

    upload_root = Path(settings.upload_dir)
    target_dir = upload_root / str(listing.id)
    target_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4().hex}{suffix}"
    (target_dir / filename).write_bytes(content)
    url = f"/uploads/{listing.id}/{filename}"

    position = len(listing.images)
    db.add(ListingImage(listing_id=listing.id, url=url, position=position))
    db.commit()
    db.refresh(listing)
    return _listing_out(db, listing)


@router.get("/{listing_id}/images", response_model=list[dict])
def list_listing_images(listing_id: uuid.UUID, db: Session = Depends(get_db)):
    listing = db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Annonce introuvable")
    return [{"id": img.id, "url": img.url, "position": img.position} for img in listing.images]
