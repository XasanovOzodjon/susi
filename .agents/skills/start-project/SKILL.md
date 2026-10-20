---
name: start-project
description: Opens or creates a product, then runs the Setka no-code intake. Alias of /taskstart when locating a folder/repo first. Use for new app, GitHub, boshlash/loyiha. Does not write product code.
---

# /start-project

Mahsulot kodi yozilmaydi. Papkani topgach **`/taskstart`** skillini ishlat (savol-javob). Qurish faqat **`/taskend`**.

## 1. Qayerda loyiha

Egadan aniqla (bir savolda, variantlar bilan):

- Yangi papka (nom)
- Mavjud lokal papka
- GitHub `owner/repo` yoki URL

GitHub: `gh repo view` / clone. Mavjud papka: `git status`, README, `graphify-out/` bormi. Yangi: papka + `git init` faqat ega ha desa. Hali Django/UI scaffold yo‘q.

## 2. Setka bormi

Agar `REGLAMENT.md` + `.cursor/agents/orchestrator.md` yo‘q bo‘lsa, shu harnessdan `scripts/apply-to-project.sh` ni shu papkaga ishlat (yoki ko‘rsat).

## 3. Skill zanjiri (kod yo‘q)

Ketma-ket, har birini haqiqatan ishlat:

1. Matt Pocock `/setup-matt-pocock-skills` — `docs/agents/issue-tracker.md` paydo bo‘lmaguncha.
2. `/grill-with-docs` (yoki `.agents/skills/grill-project`) — tushunmaguncha.
3. `/to-spec` — faqat qarorlar yozuvi.
4. `/to-tickets` — ega tasdiqlamaguncha qurish yo‘q.
5. Graphify: `.agents/skills/graphify-first`.
6. Dizayn URL bo‘lsa: skillui. UI bor bo‘lsa: oil-ui yo‘nalishlari ticketga yoziladi (qurish hali yo‘q).

## 4. Keyin

Ticketlar tasdiqlangach `.agents/skills/parallel-build`. Oldin emas.

Har bir ega topshirig‘i — `scripts/board.sh add` bilan TV-N, javob `TV-N` bilan.
