# Setka — doimiy qoidalar (Cursor + Antigravity)

Sen Setka tarmog‘idasan. To‘liq qoida: `REGLAMENT.md`. Rol fayli: `roles/<rol>.md`.

## Har session boshida

1. `bus.sh beat <rol>` va `bus.sh read <rol>` (rol noma’lum bo‘lsa: orchestrator).
2. `scripts/live.sh <rol> working|waiting|done "<hozir nima qilyapman>" [TV-N] [bosqich]` — ofis sahnasi uchun.
3. `board/BOARD.md` va o‘z tegingdagi ticketlarni o‘qi.
4. Kontekst kerak — avval `graphify-out/GRAPH_REPORT.md` va `graph.json`, keyin Claude-mem, keyin fayllar.
5. Mahsulot kodi yozishdan oldin: `docs/agents/` + tasdiqlangan ticketlar bormi? Yo‘q bo‘lsa `/susi-start` (grill). Tugagach `/susi-end` — spec, ticket, qurish. Kod `/susi-end` dan oldin yo‘q.

## Hech qachon

- Ticket tasdiqlanmasdan mahsulot kodi.
- Pentester yoki QA o‘zi patch.
- Secretni chat/git/logga.
- `git add -A` va `main`ga force-push.
- Begona rolning faylini tuzatish.
- Pentester topilmasini o‘zi yopish.

## Qurish

- Backend: Python, Django, DRF, PostgreSQL, Redis.
- Telegram bot: `https://github.com/XasanovOzodjon/Telegram-Bot-template` + python-telegram-bot.
- Frontend: tanlov erkin; reference URL bo‘lsa avval skillui. Keyin oil-ui yo‘nalishlari, qurilgach jakubkrehel `better-interface`. scroll-world — faqat ega so‘rasa va pulni tasdiqlasa.
- Backend va frontend parallel, shartnoma (OpenAPI) orqali.

## Gate

Quruvchi sha ni pentesterga yuboradi. FAIL → quruvchiga yangi ticket, pentest tuzatmaydi.
Devops asl spec/ticket bilan solishtiradi, qolganini qaytaradi.
QA ishga tushiradi, bug yozadi, tuzatmaydi.

## Chiqish formati (rollararo)

```
VERDICT: PASS / FAIL / SUDI YOQ, sha
DALIL: ...
CHEGARA: ...
```
