---
name: task-end
description: Owner finished explaining. Write spec and TV-N tickets from this chat, then start backend/frontend (and Antigravity workers). Orchestrator writes no product code.
---

# /susi-end

`/susi-start` suhbatini yopish. Egasi tushuntirishni tugatdi — keyingi jarayon (spec, ticket, qurish) boshlanadi.

## 1. Yozuv (kod yo‘q)

1. `scripts/live.sh orchestrator working "Spec va ticket yozilmoqda" "" spec`
2. `.agents/skills/to-spec-setka` — faqat suhbatdagi qarorlar. `docs/agents/spec.md`
3. `.agents/skills/to-tickets-setka` — vertikal TV-N, `scripts/board.sh add`. `/susi-end` = intake tasdiq; ticketlarni yozib qurishga o‘t.
4. Contract yo‘q bo‘lsa qisqa `docs/agents/contract.md` (endpoint nomlari, egasi aytgani).
5. Graphify: kod daraxti bo‘lsa `graphify-first`. Yo‘q bo‘lsa o‘tkaz.
6. Dizayn URL bo‘lsa skillui natijasini frontend ticketiga bog‘la.

Bloklovchi noma’lum (to‘lov kaliti, prod domen) bo‘lsa — bitta ro‘yxat, defaultni yoz, «ASSUMPTION». Suhbatni qayta ochma.

## 2. Qurishni boshlash

Orchestrator **mahsulot kodi yozmaydi**.

1. `scripts/live.sh orchestrator working "Backend va frontend parallel" "" build`
2. `board/live/task.json`: `{"phase":"build"}`
3. Cursor: `parallel-build` — backend va frontend subagent, `run_in_background`. Har biriga TV-N, spec, contract, taqiq.
4. Terminaldan Antigravity (3 akkaunt):

```bash
./susi worker backend
./susi worker frontend
```

Pentester hali emas — sha yo‘q.

5. Bus:

```bash
bash ./bus.sh send orchestrator backend "Qurish" "Tasdiqlangan ticketlarni qil" "board/tickets + docs/agents/spec.md" "Frontendga tegma"
bash ./bus.sh send orchestrator frontend "Qurish" "Tasdiqlangan ticketlarni qil" "board/tickets + docs/agents/spec.md" "Django ga tegma"
```

## 3. Eganga

Qisqa: qaysi TV-N, kimga, ofis `http://127.0.0.1:8765`.

Pul, prod, secret — alohida «ha» bo‘lmasa yo‘q.

## 4. Backend/frontend sha berganidan keyin (avtomatik keyingi qadam)

Quruvchi `bus.sh send` qiladi: sha + TV-N. Orchestrator kod yozmaydi.

1. `./susi worker pentester` + bus → pentester. Skill: `pentest-gate`. **Patch yo‘q.**
2. `VERDICT: FAIL` → yangi ticket quruvchiga, yangi sha, qayta gate.
3. `VERDICT: PASS` → `./susi worker devops` (yoki shu 3-oyna). Skill: `devops-check`. Kamchilik → ticket.
4. Devops yashil → `./susi worker qa`. Skill: qa. Bug → ticket, tuzatmaydi.
5. QA qabul + pentester PASS + eganing aniq «ha» → chiqarish (devops skript, egasi ishlatadi).

Bir o‘q FAIL bo‘lsa ikkinchisi to‘xtamaydi. Contract buzilsa ikkalasiga ham ticket.
