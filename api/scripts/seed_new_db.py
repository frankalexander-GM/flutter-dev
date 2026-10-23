"""Script para inicializar y poblar una nueva base de datos para DevPlay."""
import os
import shutil
import json
from datetime import datetime, UTC
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import all models to ensure metadata is complete
from app.models import Base, User, Post, Comment, Like, Bookmark, Poll, PollOption, Beta, StoreItem
from app.core.security import hash_password

DB_PATH = "devplay.db"
BACKUP_PATH = "devplay_backup.db"

def main():
    if os.path.exists(DB_PATH):
        print(f"Haciendo backup de la base de datos anterior en {BACKUP_PATH}...")
        try:
            shutil.copy2(DB_PATH, BACKUP_PATH)
        except Exception as e:
            print(f"Nota: No se pudo hacer backup: {e}")

    engine = create_engine(f"sqlite:///{DB_PATH}", echo=False)
    print("Creando todas las tablas en la nueva base de datos...")
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    print("Tablas creadas exitosamente.")

    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        print("Insertando usuarios iniciales...")
        # Usuario Principal
        frank = User(
            id="u_frank_001",
            email="frank@devplay.com",
            username="frank",
            password_hash=hash_password("password123"),
            full_name="Frank Alexander",
            bio="Desarrollador de videojuegos y creador en DevPlay 🎮",
            role="ADMIN",
            dev_coins=1500,
            location="Colombia",
            tags=json.dumps(["GameDev", "Flutter", "FastAPI"]),
        )
        # Usuario Demo
        pixel_dev = User(
            id="u_pixel_002",
            email="pixel@devplay.com",
            username="pixel_coder",
            password_hash=hash_password("password123"),
            full_name="Pixel Coder",
            bio="Pixel artist y amante de los juegos retro 🕹️",
            role="USER",
            dev_coins=800,
            tags=json.dumps(["PixelArt", "IndieGame", "Retro"]),
        )
        session.add_all([frank, pixel_dev])
        session.flush()

        print("Insertando posts de prueba...")
        # Post 1: Mensaje de bienvenida
        post1 = Post(
            id="p_001",
            author_id=frank.id,
            type="POST",
            content="¡Bienvenidos a DevPlay! 🚀 Nueva versión conectada a Flutter Web y backend FastAPI. ¿Qué les parece el nuevo diseño?",
            media_urls=json.dumps([]),
        )
        # Post 2: Beta de videojuego
        post2 = Post(
            id="p_002",
            author_id=pixel_dev.id,
            type="BETA",
            content="Acabo de publicar la primera versión beta de 'Planet Hop'. ¡Pruébenla y me cuentan!",
            media_urls=json.dumps([]),
        )
        session.add_all([post1, post2])
        session.flush()

        # Beta asociada a post2
        beta1 = Beta(
            id="b_001",
            post_id=post2.id,
            title="Planet Hop 🪐",
            description="Juego de plataformas arcade espacial donde saltas entre órbitas gravitacionales.",
            download_type="web",
            external_url="https://devplay.app/games/planet-hop",
            beta_status="open_beta",
            genre="Arcade / Plataformas",
            version="0.2.1",
            platforms=json.dumps(["Web", "Android", "PC"]),
            tags=json.dumps(["Espacio", "Arcade", "Indie"]),
            install_instructions="Juega directamente en el navegador.",
        )
        session.add(beta1)

        # Post 3: Encuesta
        post3 = Post(
            id="p_003",
            author_id=frank.id,
            type="POLL",
            content="¿Cuál es tu motor o framework favorito para desarrollar?",
            media_urls=json.dumps([]),
        )
        session.add(post3)
        session.flush()

        poll1 = Poll(
            id="poll_001",
            post_id=post3.id,
            question="¿Cuál es tu motor o framework favorito para desarrollar?",
            allow_multiple=False,
        )
        session.add(poll1)
        session.flush()

        opt1 = PollOption(id="opt_1", poll_id=poll1.id, text="Flutter / Flame", position=0, vote_count=12)
        opt2 = PollOption(id="opt_2", poll_id=poll1.id, text="Godot Engine", position=1, vote_count=25)
        opt3 = PollOption(id="opt_3", poll_id=poll1.id, text="Unity", position=2, vote_count=18)
        opt4 = PollOption(id="opt_4", poll_id=poll1.id, text="Unreal Engine", position=3, vote_count=9)
        session.add_all([opt1, opt2, opt3, opt4])

        print("Insertando comentarios y likes...")
        com1 = Comment(
            id="c_001",
            post_id=post1.id,
            user_id=pixel_dev.id,
            content="¡Quedó brutal la interfaz y la integración con Flutter! 🔥",
        )
        like1 = Like(
            id="l_001",
            post_id=post1.id,
            user_id=pixel_dev.id,
        )
        session.add_all([com1, like1])

        print("Insertando artículos de la tienda (StoreItems)...")
        store_items = [
            StoreItem(
                id="item_001",
                name="Insignia Retro Arcade",
                description="Muestra tu pasión por los clásicos con una insignia brillante en tu perfil.",
                price=150,
                category="BADGE",
                icon="Gamepad2",
            ),
            StoreItem(
                id="item_002",
                name="Borde Neón Cyberpunk",
                description="Efecto de resplandor neón animado para tu avatar.",
                price=300,
                category="AVATAR_FRAME",
                icon="Sparkles",
            ),
            StoreItem(
                id="item_003",
                name="Multiplicador DevCoins x2 (7 días)",
                description="Duplica los DevCoins obtenidos al publicar e interactuar durante una semana.",
                price=500,
                category="BOOST",
                icon="Zap",
                duration=7,
            ),
        ]
        session.add_all(store_items)

        session.commit()
        print("¡Base de datos nueva creada y poblada exitosamente!")
    except Exception as e:
        session.rollback()
        print(f"Error poblando base de datos: {e}")
        raise
    finally:
        session.close()

if __name__ == "__main__":
    main()
