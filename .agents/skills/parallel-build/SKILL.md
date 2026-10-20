---
name: parallel-build
description: Starts backend and frontend as parallel subagents after tickets are approved. Use when the owner accepted to-tickets and implementation may begin.
---

# Parallel qurish

Shart: tasdiqlangan ticketlar. Aks holda `/start-project` ga qayt.

## Contract

`docs/agents/contract.md` yoki OpenAPI. Yo‘q bo‘lsa avval shu (qisqa) ticket — keyin ikkala o‘q.

## Spawn

Bir vaqtda ikkita subagent:

- **backend** — Django/DRF/Postgres/Redis; bot ticketlari bo‘lsa Telegram-Bot-template. TV-N ro‘yxati, contract yo‘li, «frontendga tegma».
- **frontend** — skillui + oil-ui + better-interface (`frontend-beauty`), contract, «Django ga tegma».

Cursor: Task tool, `run_in_background` ikkalasiga. Antigravity: `invoke_subagent`.

Ular tugagach sha ni orchestrator oladi → pentester (ketma-ket yoki ikkala sha alohida) → devops-check → qa.

Bir o‘q FAIL qilsa, ikkinchisi to‘xtamaydi, lekin contract buzilsa ikkalasiga ham ticket.
