# Backend shablon

- Python 3.12+
- Django + Django REST Framework
- PostgreSQL
- Redis (cache / channel / celery broker — loyiha tanlaydi)
- `.env` qiymatlarini agent kiritmaydi; `env.example` da nomlar

Birinchi slice odatda: loyiha yaratish, settings split (base/dev/prod), healthz, DRF router, Postgres + Redis docker compose (faqat local).

Telegram kerak bo‘lsa `templates/telegram-bot.md`.
