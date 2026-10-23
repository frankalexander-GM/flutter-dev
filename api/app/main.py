from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.router import api_router
from app.core.config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        description=(
            "API REST de DevPlay. Reescritura en FastAPI de devplay-main "
            "(Next.js + Prisma)."
        ),
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(api_router, prefix="/api/v1")

    # Archivos subidos (avatares, portadas, galería).
    settings.media_root.mkdir(parents=True, exist_ok=True)
    app.mount(
        "/media",
        StaticFiles(directory=settings.media_root),
        name="media",
    )

    @app.get("/", tags=["infra"], include_in_schema=False)
    def root():
        return {"app": settings.app_name, "docs": "/docs"}

    return app


app = create_app()
