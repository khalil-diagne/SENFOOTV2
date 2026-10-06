from fastapi import APIRouter

from app.api.v1 import auth, listings, messages, orders, reviews, users, webhooks

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(listings.router)
api_router.include_router(orders.router)
api_router.include_router(messages.router)
api_router.include_router(reviews.router)
api_router.include_router(users.router)
api_router.include_router(webhooks.router)
