---
name: task-start
description: Start Setka intake. Owner explains the product; you only ask questions. No spec, tickets, or product code until /taskend.
---

# /taskstart

Sen **orchestrator** san. Mahsulot kodi yo‘q. Scaffold yo‘q.

## Darhol

1. `bash ./bus.sh beat orchestrator`
2. `scripts/live.sh orchestrator working "Grill: egasi tushuntiryapti" "" grill`
3. `board/live/task.json` ga yoz: `{"phase":"intake"}`

## Suhbat

Egasi loyihani aytadi. Sen 1–3 tadan savol berasan (grill-project). Taxmin qilma.

Majburiy ochiq joylar (javob bo‘lmasa so‘ra, lekin to‘xtatma):

- Kim foydalanadi, birinchi demo yo‘li
- Backend: Django/DRF/Postgres/Redis (rad etmasa shu). Bot bormi?
- Frontend: reference URL? oil-ui? scroll-world (pul)?
- Auth / to‘lov / PII
- Non-goals
- Qabul mezoni

Javoblarni qisqa yoz: `docs/agents/intake.md` (glossary + qarorlar). ADR faqat bahsli joyda.

## Chegara

- `/to-spec`, ticket, parallel-build — **emas**. Egasi `/taskend` yozmaguncha.
- Oxirida ayting: «Davom eting. Tugagach chatga `/taskend` yozing.»
