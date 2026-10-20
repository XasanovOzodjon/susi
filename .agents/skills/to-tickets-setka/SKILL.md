---
name: to-tickets-setka
description: Splits an approved spec into tracer-bullet tickets with blockers. Use after /to-spec. Quizzes the owner before publishing. No product code.
---

# Tickets

Matt Pocock `/to-tickets` bor bo‘lsa — o‘shani ishlat.

Har ticket — tor **vertikal** slice (schema + API + UI + test), bitta context oynaga sig‘adi, o‘zi demo qilinadi.

1. Prefactor alohida, birinchi.
2. Backend-only yoki frontend-only horizontal qatlam qilma (contract ticket bundan mustasno).
3. Blockerlar aniq.
4. Ega oldin ro‘yxatni ko‘radi: nom, blocker, nima demo. Tasdiqdan keyin yoziladi.
5. `scripts/board.sh add` + `board/tickets/TV-N.md`. Tracker sozlangan bo‘lsa u yerga ham.

Tasdiqlanmagan ticket bo‘yicha hech kim kod yozmaydi.
