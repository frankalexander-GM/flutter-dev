"""Reconstruye devplay.db con un set de datos completo y VALIDO.

Uso (desde devplay-api):
    .venv\\Scripts\\python.exe scripts\\seed_devplay.py

- Hace backup de devplay.db -> devplay_backup.db
- Recrea el esquema y siembra usuarios, posts, betas, encuestas, likes,
  comentarios, follows y tienda.
- Respeta los enums del backend (downloadType DIRECT/LINK, categorias de
  tienda powerup/avatar/premium/bundle).
"""
from __future__ import annotations

import json
import shutil
import sys
from datetime import datetime, timedelta, UTC
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.security import hash_password  # noqa: E402
from app.models import (  # noqa: E402
    Base,
    Beta,
    Bookmark,
    Comment,
    Follow,
    Like,
    Poll,
    PollOption,
    Post,
    StoreItem,
    User,
)

DB_PATH = Path(__file__).resolve().parents[1] / "devplay.db"
BACKUP_PATH = DB_PATH.with_name("devplay_backup.db")

MEDIA = "http://127.0.0.1:8000/media"


def m(url: str) -> str:
    return json.dumps([{"url": f"{MEDIA}/{url}", "kind": "image"}])


def arr(values: list[str]) -> str:
    return json.dumps(values, ensure_ascii=False)


NOW = datetime.now(UTC).replace(tzinfo=None, microsecond=0)
def ago(hours: float) -> datetime:
    return NOW - timedelta(hours=hours)


USERS = [
    dict(
        id="u_frank", email="frank@devplay.com", username="frank",
        full_name="Frank Alexander", avatar=f"{MEDIA}/avatars/frank.png",
        bio="GameDev y creador en DevPlay. Prototipos rápidos y noches de Godot.",
        location="Colombia", role="ADMIN", dev_coins=1500,
        tags=arr(["GameDev", "Prototipos", "Godot"]), profession="Desarrollador de juegos",
    ),
    dict(
        id="u_pixel", email="pixel@devplay.com", username="pixel_coder",
        full_name="Pixel Coder", avatar=f"{MEDIA}/avatars/pixel_coder.png",
        bio="Pixel art y juegos retro. 1 bit, 0 dramas.", location="Medellín",
        dev_coins=820, tags=arr(["PixelArt", "Retro", "IndieGame"]), profession="Pixel artist",
    ),
    dict(
        id="u_luna", email="luna@devplay.com", username="luna_dev",
        full_name="Luna Ríos", avatar=f"{MEDIA}/avatars/luna_dev.png",
        bio="Narrativa interactiva y prototipos en Godot. Historias que se juegan.",
        location="Bogotá", dev_coins=640, tags=arr(["Godot", "Narrativa", "UX"]),
        profession="Diseñadora narrativa",
    ),
    dict(
        id="u_neko", email="neko@devplay.com", username="neko_studio",
        full_name="Neko Studio", avatar=f"{MEDIA}/avatars/neko_studio.png",
        bio="Estudio indie de tres personas. Unity y mucho café.", location="Lima",
        dev_coins=430, tags=arr(["Unity", "3D", "Indie"]), profession="Estudio indie",
    ),
    dict(
        id="u_maria", email="maria@devplay.com", username="byte_maria",
        full_name="María Byte", avatar=f"{MEDIA}/avatars/byte_maria.png",
        bio="Juegos que caben en el bolsillo. Móvil primero.", location="CDMX",
        dev_coins=980, tags=arr(["Mobile", "Puzzle", "Indie"]), profession="Dev móvil",
    ),
    dict(
        id="u_dark", email="syntax@devplay.com", username="dark_syntax",
        full_name="Syntax", avatar=f"{MEDIA}/avatars/dark_syntax.png",
        bio="Shaders, post-proceso y luces que duelen.", location="Buenos Aires",
        dev_coins=310, tags=arr(["Shaders", "VFX", "Vulkan"]), profession="Technical artist",
    ),
    dict(
        id="u_sara", email="sara@devplay.com", username="sara_ui",
        full_name="Sara UI", avatar=f"{MEDIA}/avatars/sara_ui.png",
        bio="Interfaces para juegos. Menos HUD, más juego.", location="Santiago",
        dev_coins=530, tags=arr(["UI", "GameDesign", "Figma"]), profession="Diseñadora UI",
    ),
    dict(
        id="u_retro", email="juan@devplay.com", username="retro_juan",
        full_name="Juan Retro", avatar=f"{MEDIA}/avatars/retro_juan.png",
        bio="Arcade de los 90. CRT o nada.", location="Madrid",
        dev_coins=260, tags=arr(["Arcade", "CRT", "Hardware"]), profession="Coleccionista",
    ),
]

# ------------------------------------------------------------------ Betas
# (slug, titulo, genero, version, estado, plataformas, tags, descripcion,
#  horas, descargas, autor, downloadType)
BETAS = [
    dict(
        slug="neon_drift", title="Neon Drift", genre="Racing arcade", version="0.4.2",
        status="open_beta", platforms=["Web", "Android"], tags=["Carreras", "Neón", "Arcade"],
        desc="Corre por autopistas imposibles a 300 km/h. Drift, boost y un synthwave que "
             "no te deja parar. Buscamos testers para el modo contrarreloj.",
        hours=3, downloads=1240, author="u_dark", dtype="LINK",
        extra="Controles: WASD o gamepad. Mejor en Chrome de escritorio.",
    ),
    dict(
        slug="astral_garden", title="Astral Garden", genre="Puzles / Relax", version="0.3.0",
        status="open_beta", platforms=["Web", "iOS"], tags=["Puzles", "Cozy", "Zen"],
        desc="Haz crecer constelaciones plantando semillas de luz. Un puzle tranquilo de "
             "20 minutos por sesión, sin anuncios ni cronómetros.",
        hours=9, downloads=860, author="u_luna", dtype="LINK",
        extra="Guarda partida en local. Probad el modo libre.",
    ),
    dict(
        slug="planeta_hop", title="Planeta Hop", genre="Plataformas", version="0.2.1",
        status="open_beta", platforms=["Web", "Android", "PC"], tags=["Espacio", "Plataformas"],
        desc="Salta entre órbitas gravitacionales y encuentra la salida del sistema. "
             "Doce niveles, un solo botón.",
        hours=20, downloads=2140, author="u_pixel", dtype="LINK",
        extra="Se juega directo en el navegador, sin instalación.",
    ),
    dict(
        slug="dungeon_scribe", title="Dungeon Scribe", genre="Roguelike / Mazmorras", version="0.1.4",
        status="closed_beta", platforms=["PC", "Web"], tags=["Roguelike", "Mazmorras"],
        desc="Eres el escriba del calabozo: dibujas el mapa mientras los héroes avanzan. "
             "Si mientes en el mapa, mueren.",
        hours=30, downloads=310, author="u_frank", dtype="DIRECT",
        extra="Build comprimida en .zip. Requiere teclado.",
    ),
    dict(
        slug="pixel_farm_88", title="Pixel Farm 88", genre="Simulación retro", version="0.5.0",
        status="early_access", platforms=["Android", "Web"], tags=["Simulación", "Retro", "Farming"],
        desc="Una granja de 8 bits que crece mientras duermes. Cultivos, vecinos cotillas "
             "y un mercado que se mueve solo.",
        hours=44, downloads=1720, author="u_retro", dtype="LINK",
        extra="Sincroniza con la nube cada 5 minutos.",
    ),
    dict(
        slug="void_runner", title="Void Runner", genre="Runner sci-fi", version="0.1.0",
        status="coming_soon", platforms=["Web"], tags=["Runner", "SciFi", "Difícil"],
        desc="Un corredor infinito en el vacío. Todavía sin fecha: queremos pulir el "
             "control antes de abrirlo.",
        hours=60, downloads=120, author="u_neko", dtype="LINK",
        extra="Apúntate a la lista para la primera build.",
    ),
    dict(
        slug="sakura_blade", title="Sakura Blade", genre="Acción / Anime", version="0.9.1",
        status="tech_test", platforms=["PC", "Web"], tags=["Acción", "Anime", "Combos"],
        desc="Combos de katana con frames de impacto dibujados a mano. Prueba técnica "
             "del sistema de parry.",
        hours=76, downloads=2530, author="u_sara", dtype="LINK",
        extra="Recomendado con mando. Reporta el input lag si lo notas.",
    ),
    dict(
        slug="bit_cafe", title="Bit Café", genre="Gestión cozy", version="0.6.0",
        status="alpha", platforms=["Web", "iOS", "Android"], tags=["Cozy", "Gestión", "PixelArt"],
        desc="Regenta un cibercafé de los 90: servidores, torneos y clientes que no se van. "
             "Alpha temprana, todo puede cambiar.",
        hours=98, downloads=640, author="u_maria", dtype="LINK",
        extra="Solo español por ahora, inglés en camino.",
    ),
]

# ------------------------------------------------------------- Posts extra
SHOWCASES = [
    dict(
        slug="neon_drift", title="Neon Drift", genre="Racing arcade", version="0.4.2",
        hours=2, author="u_dark",
        desc="Llevo seis meses con este arcade de carreras y por fin lo enseño. Drift "
             "con física propia, boost por derrape y una banda sonora synthwave.",
        url="https://devplay.app/games/neon-drift",
    ),
    dict(
        slug="sakura_blade", title="Sakura Blade", genre="Acción / Anime", version="0.9.1",
        hours=26, author="u_sara",
        desc="Cada golpe tiene un frame de impacto dibujado a mano. Hoy abrimos la prueba "
             "técnica del parry para que lo destrocéis.",
        url="https://devplay.app/games/sakura-blade",
    ),
    dict(
        slug="astral_garden", title="Astral Garden", genre="Puzles / Relax", version="0.3.0",
        hours=52, author="u_luna",
        desc="Un puzle de constelaciones para jugar sin prisa. Ya está la build web, "
             "falta pulir el tutorial.",
        url="https://devplay.app/games/astral-garden",
    ),
]

DEV_LOGS = [
    dict(
        hours=5, author="u_pixel", cover="planeta_hop",
        content="Bitácora #12 — Planeta Hop\nHoy reescribí la gravedad orbital: ahora los "
                "saltos se sienten como un péndulo en vez de un tiro parabólico. También "
                "metí partículas de polvo estelar. Mañana toca el nivel 9.",
    ),
    dict(
        hours=14, author="u_dark", cover="neon_drift",
        content="Bitácora #04 — Neon Drift\nEl motion blur estaba matando los 60 fps en "
                "móvil. Lo cambié por un blur de 3 pasadas con muestreo temporal y "
                "recuperé 18 fps. Capturas dentro.",
    ),
    dict(
        hours=33, author="u_maria", cover="bit_cafe",
        content="Bitácora #07 — Bit Café\nAñadí el sistema de reputación del café: si "
                "atiendes rápido suben las propinas, si dejas a alguien esperando se va "
                "y te deja una reseña de una estrella.",
    ),
    dict(
        hours=57, author="u_neko", cover="void_runner",
        content="Bitácora #02 — Void Runner\nPrototipo del control: un solo botón, "
                "mantener para cargar salto. Estoy probando dificultad adaptativa en vez "
                "de niveles fijos.",
    ),
    dict(
        hours=88, author="u_luna", cover="astral_garden",
        content="Notas de diseño — Astral Garden\nQuité el cronómetro. El juego mejora "
                "mucho cuando no te empuja. Ahora la presión viene del tablero, no del reloj.",
    ),
]

POSTS = [
    dict(hours=1, author="u_frank",
         content="¡Bienvenidos a DevPlay! 🚀 Versión nueva: feed, betas y descubrir "
                 "conectados a la API real. Decidme qué se rompe."),
    dict(hours=7, author="u_maria",
         content="¿Alguien ha probado Flame 1.2? El sistema de componentes nuevos me está "
                 "ahorrando la mitad de boilerplate."),
    dict(hours=12, author="u_sara",
         content="Recordatorio: si tu HUD necesita un tutorial para entenderse, el HUD "
                 "está mal, no el jugador."),
    dict(hours=24, author="u_retro",
         content="Encontré un CRT de 14 pulgadas en un mercadillo por 15 €. Funciona. "
                 "Hoy duermo bien."),
    dict(hours=40, author="u_neko",
         content="Buscamos un artista 3D para un proyecto cozy de gestión. Remoto, "
                 "part-time, revenue share. DM abiertos."),
    dict(hours=64, author="u_dark",
         content="Post-proceso del día: aberration cromática + grano a 0.15. Todo lo demás "
                 "es ruido."),
]

POLLS = [
    dict(
        hours=18, author="u_frank",
        question="¿Con qué motor o framework estás haciendo tu juego ahora mismo?",
        options=[
            ("GameMaker", 34), ("Godot", 61), ("Unity", 48), ("Unreal", 19),
            ("Motor propio", 12),
        ],
    ),
    dict(
        hours=70, author="u_sara",
        question="¿Qué estado de beta te da más confianza al probar un juego?",
        options=[
            ("Alpha abierta", 22), ("Beta cerrada con invitación", 41),
            ("Acceso anticipado de pago", 17), ("Demo técnica", 29),
        ],
    ),
]

STORE_ITEMS = [
    ("item_badge", "Insignia Retro Arcade",
     "Muestra tu pasión por los clásicos con una insignia brillante en tu perfil.",
     150, "avatar", "Gamepad2", None, None),
    ("item_frame", "Borde Neón Cyberpunk",
     "Efecto de resplandor neón animado para tu avatar.", 300, "avatar", "Sparkles", None, None),
    ("item_boost", "Multiplicador DevCoins x2",
     "Duplica los DevCoins obtenidos al publicar e interactuar durante una semana.",
     500, "powerup", "Zap", "coins_x2", 7),
    ("item_theme", "Tema Consola CRT",
     "Paleta verde fósforo para toda la interfaz, con líneas de barrido opcionales.",
     420, "powerup", "Monitor", "theme_crt", None),
    ("item_premium", "DevPlay Pro (mensual)",
     "Sin límites de subida, análisis de betas y badge Pro en tu perfil.",
     900, "premium", "Crown", "pro", 30),
    ("item_bundle", "Pack Fundador",
     "Insignia fundador + borde neón + multiplicador de 30 días, todo junto.",
     1200, "bundle", "Package", "founder", 30),
]

# post -> usuarios que dan like
LIKES = {
    "p_show_neon": ["u_frank", "u_maria", "u_sara", "u_neko", "u_pixel", "u_luna", "u_retro"],
    "p_show_sakura": ["u_dark", "u_maria", "u_frank", "u_luna", "u_pixel"],
    "p_show_astral": ["u_sara", "u_frank", "u_maria"],
    "p_beta_neon_drift": ["u_frank", "u_sara", "u_maria", "u_neko"],
    "p_beta_sakura_blade": ["u_frank", "u_dark", "u_pixel", "u_maria", "u_luna", "u_retro"],
    "p_beta_planeta_hop": ["u_frank", "u_luna", "u_sara"],
    "p_beta_bit_cafe": ["u_sara", "u_luna"],
    "p_beta_pixel_farm_88": ["u_frank", "u_pixel", "u_maria"],
    "p_beta_astral_garden": ["u_frank", "u_sara", "u_maria", "u_dark"],
    "p_beta_dungeon_scribe": ["u_dark", "u_luna"],
    "p_beta_void_runner": ["u_frank"],
    "p_dev_1": ["u_frank", "u_maria", "u_sara"],
    "p_dev_2": ["u_frank", "u_neko", "u_pixel", "u_maria"],
    "p_dev_3": ["u_frank", "u_luna"],
    "p_dev_4": ["u_maria"],
    "p_dev_5": ["u_sara", "u_frank", "u_pixel"],
    "p_post_1": ["u_pixel", "u_luna", "u_maria", "u_sara", "u_neko"],
    "p_post_2": ["u_frank", "u_dark"],
    "p_post_3": ["u_frank", "u_maria", "u_luna", "u_neko"],
    "p_post_4": ["u_pixel", "u_dark", "u_frank"],
    "p_post_5": ["u_frank", "u_luna", "u_maria"],
    "p_post_6": ["u_frank"],
    "p_poll_1": ["u_pixel", "u_luna", "u_maria", "u_sara", "u_neko", "u_dark"],
    "p_poll_2": ["u_frank", "u_maria", "u_retro"],
}

COMMENTS = [
    ("p_show_neon", "u_frank", "El drift se siente brutal. ¿Piensas meter modo foto?"),
    ("p_show_neon", "u_sara", "La paleta y el HUD están limpísimos, enhorabuena."),
    ("p_show_sakura", "u_dark", "Los frames de impacto son una barbaridad."),
    ("p_beta_planeta_hop", "u_luna", "El nivel 7 me costó la vida, pero volveré."),
    ("p_beta_bit_cafe", "u_sara", "Necesito poder cambiar el nombre del café, por favor."),
    ("p_post_1", "u_pixel", "¡Quedó brutal la nueva interfaz! 🔥"),
    ("p_post_3", "u_maria", "Muy de acuerdo. Un HUD que explica es un HUD que estorba."),
    ("p_poll_1", "u_neko", "Godot por aquí, pero Unity no se va a ningún lado."),
    ("p_dev_2", "u_frank", "Ese truco del blur temporal me lo llevo."),
    ("p_beta_neon_drift", "u_maria", "Probado en Android, 60 fps estables."),
]


def build(session) -> None:
    # -------------------------------------------------------------- usuarios
    users = {}
    for data in USERS:
        user = User(**data, password_hash=hash_password("devplay123"),
                    is_guest=False, is_private=False, created_at=ago(240))
        session.add(user)
        users[user.id] = user
    session.flush()
    print(f"  usuarios         {len(users)}")

    # ----------------------------------------------------------------- posts
    posts: dict[str, Post] = {}

    for item in SHOWCASES:
        key = f"p_show_{item['slug']}"
        post = Post(
            id=key, author_id=item["author"], type="GAME_SHOWCASE",
            content=f"{item['title']} · {item['genre']} · v{item['version']}\n\n{item['desc']}",
            media_urls=m(f"covers/{item['slug']}.png"),
            created_at=ago(item["hours"]), updated_at=ago(item["hours"]),
        )
        session.add(post)
        posts[key] = post

    for idx, item in enumerate(DEV_LOGS, start=1):
        key = f"p_dev_{idx}"
        post = Post(id=key, author_id=item["author"], type="DEV_LOG",
                    content=item["content"],
                    media_urls=m(f"covers/{item['cover']}.png") if item.get("cover") else None,
                    created_at=ago(item["hours"]), updated_at=ago(item["hours"]))
        session.add(post)
        posts[key] = post

    for idx, item in enumerate(POSTS, start=1):
        key = f"p_post_{idx}"
        post = Post(id=key, author_id=item["author"], type="POST",
                    content=item["content"], media_urls=None,
                    created_at=ago(item["hours"]), updated_at=ago(item["hours"]))
        session.add(post)
        posts[key] = post

    # betas: post + ficha
    for item in BETAS:
        post_key = f"p_beta_{item['slug']}"
        post = Post(
            id=post_key, author_id=item["author"], type="BETA",
            content=f"{item['title']} está en {item['status'].replace('_', ' ')}. "
                    f"{item['desc']}",
            media_urls=m(f"covers/{item['slug']}.png"),
            created_at=ago(item["hours"]), updated_at=ago(item["hours"]),
        )
        session.add(post)
        posts[post_key] = post
        session.flush()

        beta = Beta(
            id=f"b_{item['slug']}", post_id=post.id, title=item["title"],
            description=item["desc"], download_type=item["dtype"],
            external_url=f"https://devplay.app/games/{item['slug'].replace('_', '-')}"
            if item["dtype"] == "LINK" else None,
            file_url=f"{MEDIA}/builds/{item['slug']}-{item['version']}.zip"
            if item["dtype"] == "DIRECT" else None,
            file_name=f"{item['slug']}-{item['version']}.zip" if item["dtype"] == "DIRECT" else None,
            file_size=48_234_496 if item["dtype"] == "DIRECT" else None,
            beta_status=item["status"], genre=item["genre"], version=item["version"],
            platforms=arr(item["platforms"]), tags=arr(item["tags"]),
            install_instructions=item["extra"],
            cover_image=f"{MEDIA}/icons/{item['slug']}.png",
            screenshots=json.dumps([f"{MEDIA}/covers/{item['slug']}.png"]),
            downloads=item["downloads"],
            created_at=ago(item["hours"]),
        )
        session.add(beta)

    # encuestas
    for idx, poll in enumerate(POLLS, start=1):
        post_key = f"p_poll_{idx}"
        post = Post(id=post_key, author_id=poll["author"], type="POLL",
                    content=poll["question"], media_urls=None,
                    created_at=ago(poll["hours"]), updated_at=ago(poll["hours"]))
        session.add(post)
        posts[post_key] = post
        session.flush()

        poll_row = Poll(id=f"poll_{idx}", post_id=post.id, question=poll["question"],
                        allow_multiple=False, created_at=ago(poll["hours"]))
        session.add(poll_row)
        session.flush()
        for pos, (text, votes) in enumerate(poll["options"]):
            session.add(PollOption(id=f"opt_{idx}_{pos}", poll_id=poll_row.id, text=text,
                                   position=pos, vote_count=votes))

    session.flush()
    print(f"  posts            {len(posts)}")

    # likes / comentarios
    total_likes = 0
    for post_id, likers in LIKES.items():
        for uid in likers:
            session.add(Like(id=f"l_{post_id}_{uid}", post_id=post_id, user_id=uid,
                             created_at=ago(1)))
            total_likes += 1

    for i, (post_id, uid, text) in enumerate(COMMENTS, start=1):
        session.add(Comment(id=f"c_{i:03d}", post_id=post_id, user_id=uid, content=text,
                            created_at=ago(1 + i)))

    print(f"  likes            {total_likes}")
    print(f"  comentarios      {len(COMMENTS)}")

    # follows
    graph = {
        "u_frank": ["u_pixel", "u_luna", "u_neko", "u_maria", "u_dark", "u_sara", "u_retro"],
        "u_pixel": ["u_frank", "u_maria", "u_retro"],
        "u_luna": ["u_frank", "u_sara"],
        "u_neko": ["u_frank", "u_dark"],
        "u_maria": ["u_frank", "u_luna", "u_pixel"],
        "u_dark": ["u_frank", "u_neko"],
        "u_sara": ["u_frank", "u_maria"],
        "u_retro": ["u_frank", "u_pixel", "u_sara"],
    }
    n = 0
    for follower, followees in graph.items():
        for followee in followees:
            session.add(Follow(id=f"f_{follower}_{followee}", follower_id=follower,
                               followee_id=followee, created_at=ago(120)))
            n += 1
    print(f"  follows          {n}")

    # tienda
    for item_id, name, desc, price, cat, icon, effect, duration in STORE_ITEMS:
        session.add(StoreItem(id=item_id, name=name, description=desc, price=price,
                              category=cat, icon=icon, effect=effect, duration=duration,
                              created_at=ago(200)))
    print(f"  tienda           {len(STORE_ITEMS)}")

    session.commit()


def main() -> None:
    if DB_PATH.exists():
        shutil.copy2(DB_PATH, BACKUP_PATH)
        print(f"backup -> {BACKUP_PATH.name}")

    engine = create_engine(f"sqlite:///{DB_PATH}", echo=False)
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)

    session = sessionmaker(bind=engine)()
    try:
        build(session)
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
    print("BD reconstruida correctamente")


if __name__ == "__main__":
    main()
