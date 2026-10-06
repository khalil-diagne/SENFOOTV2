import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.config import settings
from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.user import User, UserRole


def main() -> None:
    email = os.getenv("ADMIN_EMAIL", "admin@efoot.sn")
    username = os.getenv("ADMIN_USERNAME", "admin")
    password = os.getenv("ADMIN_PASSWORD", "ChangeMeAdmin123!")
    full_name = os.getenv("ADMIN_FULL_NAME", "Administrateur EFoot")

    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == email).first()
        if existing is not None:
            print(f"Admin déjà présent : {email}")
            return
        user = User(
            email=email,
            username=username,
            full_name=full_name,
            hashed_password=hash_password(password),
            role=UserRole.admin,
            is_verified_seller=True,
        )
        db.add(user)
        db.commit()
        print(f"Admin créé : {email} (username={username})")
        print("Changez le mot de passe par défaut en production.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
