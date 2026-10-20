# Setka — Cursor + Gemini agent tizimi

Do‘stingiz qoldirgan papka **Claude Code** uchun 6 kishilik “setka” edi: orchestrator, backend, frontend, devops, qa, pentester, fayl-shina, TaskView, Forgejo. Asl reglament: `РЕГЛАМЕНТ.md`. Eski launcher: `launch-team.sh`.

Bu v3 shu g‘oyani **Cursor obunasi** va **Antigravity (Gemini)** ga ko‘chiradi. Maqsad bitta mahsulot emas — vibe-codingni osonlashtiradigan **sizning agent tizimingiz**.

## Nima qiladi

Loyihani ochasiz yoki GitHub nomini berasiz. Agent **avval kod yozmaydi**. To‘rt bosqichda siz bilan gaplashadi:

1. `/setup-matt-pocock-skills` — tracker, label, `docs/agents/`
2. `/grill-with-docs` — savol-javob, glossary, ADR
3. `/to-spec` — qarorlar yozuvi
4. `/to-tickets` — vertikal ticketlar, siz tasdiqlaysiz

Keyin:

- **Graphify** — kod xaritasi, token tejash (barcha rollarga)
- **skillui** — berilgan sayt dizaynini md/token qilib frontendga beradi
- **oil-ui** — 2–3 dizayn yo‘nalishi, ega tanlaydi
- **better-interface** (jakubkrehel) — tipografika, rang, layout, a11y, polish
- **scroll-world** — ixtiyoriy kino/scroll landing (pul tasdiqlangach)
- **Backend + Frontend parallel** — Django/DRF/Postgres/Redis va UI
- **Pentester** — Strix + cybersecurity skills; o‘zi tuzatmaydi, quruvchiga qaytaradi
- **Devops** — asl vazifa vs qilingan ish; qolganini qaytaradi
- **QA** — hammasini ishga tushiradi, bug yozadi, tuzatmaydi
- **claude-mem** — chatlar esda qoladi
- **ECC** — reja, test, review, xotira, xavfsizlik asboblari

Telegram bot kerak bo‘lsa: [Telegram-Bot-template](https://github.com/XasanovOzodjon/Telegram-Bot-template) + python-telegram-bot.

## GitHub yoki npx bilan o‘rnatish

**npx** (GitHubdan, npm publish shart emas):

```bash
npx github:XasanovOzodjon/Setka -- install ~/Loyihalar/mening-app
cd ~/Loyihalar/mening-app
./setka start
```

**git clone**:

```bash
git clone git@github.com:XasanovOzodjon/Setka.git
./Setka/setka install ~/Loyihalar/mening-app
cd ~/Loyihalar/mening-app
./setka start
```

Shu harness papkasida: `./setka start`

Mashinaga skill CLI lar (bir marta): `./scripts/bootstrap.sh`

Skript ketma-ket aytadi va ochadi:

1. Ofis — http://127.0.0.1:8765
2. **Cursor** — chatga `/taskstart`, loyihani tushuntirasiz, tugagach `/taskend`
3. **Antigravity 1** — backend (1-akkaunt)
4. **Antigravity 2** — frontend (2-akkaunt)
5. **Antigravity 3** — pentester/QA (3-akkaunt)

Har qadamda: Enter = ochish, `s` = o‘tkazish. To‘xtatish: `./setka stop`

`/taskend` spec + ticket yozadi va qurishni boshlaydi (orchestrator kod yozmaydi).

## Antigravity akkauntlar

`./setka start` uchta **alohida profil** ochadi (`~/.setka/agy/1`, `2`, `3`). Bu Chrome profiliga o‘xshaydi — har biri o‘z Google loginini saqlaydi.

1. 1-oyna ochiladi → **Sign in with Google** → backend uchun 1-akkaunt.
2. 2-oyna → **boshqa** Google akkaunt → frontend.
3. 3-oyna → 3-akkaunt → pentester (keyin QA/devops shu yerda).

Bir xil akkauntni uchtasiga kiritmang. Agar noto‘g‘ri akkaunt kirsangiz: o‘sha oynada sign out, yoki `rm -rf ~/.setka/agy/1` qilib qayta `./setka worker backend`.

Har oynada shu papka ochiq bo‘lishi kerak. Chatga Cmd+V (prompt buferda) yoki agentni tanlang: `backend` / `frontend` / `pentester`.

## Backend va frontend tugagach

O‘zingiz «keyingi bosqich» yozishingiz shart emas — quruvchi **sha** ni bus orqali yuboradi, orchestrator ketma-ket ochadi:

1. **Pentester** (3-akkaunt) — Strix, tuzatmaydi. FAIL → ticket quruvchiga, yangi sha, qayta gate.
2. **PASS** bo‘lsa **devops** — spec vs diff. Qolgan ish → ticket.
3. **QA** — stendni yuritadi, bug yozadi, tuzatmaydi.
4. PASS + QA yashil + sizning aniq **«ha»** — chiqarish.

Ofisda (`:8765`) kim gate/qa da ekani ko‘rinadi. Sha kelmasa Cursor da orchestratorga yozing: `sha bor, gate och`.

## Birinchi o‘rnatish (bir marta)

```bash
chmod +x bus.sh scripts/*.sh .cursor/hooks/*.sh
./scripts/bootstrap.sh
```

Bu mashinada allaqachon o‘rnatilgan: Matt Pocock skilllari, Strix pentest skilllari, skillui, ECC (Cursor `--no-hooks` + Antigravity), cybersecurity vendor (`~/.setka/vendor/`).

Graphify CLI sekin o‘rnatilishi mumkin:

```bash
python3 -m pip install --user graphifyy
```

Keyin (interaktiv, bir marta — chat xotirasi):

```bash
npx claude-mem install    # Cursor ni tanlang, provider = Gemini
```

Cursor yoki Antigravity ni qayta oching.

Cybersecurity paketi katta. Istamasangiz: `SETKA_SKIP_CYBER=1 ./scripts/bootstrap.sh`

## Yangi yoki mavjud loyiha

**Shu papkani harness sifatida ochib** chatga yozing:

```
/taskstart
```

Tugagach: `/taskend`. Eski alias: `/start-project`.

Yoki mahsulot papkasiga ko‘chiring:

```bash
./scripts/apply-to-project.sh /path/to/product
cd /path/to/product
./scripts/bootstrap.sh
```

Keyin Cursor/Antigravity da ochib `/start-project`. GitHub `owner/repo` yoki URL berasiz — agent ko‘radi, grill qiladi, ticket yozadi, **keyin** parallel quradi.

## Rollar (Cursor `/orchestrator` … yoki Agent o‘zi chaqiradi)

| Rol | Vazifa |
|-----|--------|
| orchestrator | tushunish, doska, parallel start |
| backend | Django/DRF/Postgres/Redis, bot |
| frontend | UI, skillui + oil-ui + better-interface |
| pentester | gate, tuzatmaydi |
| devops | spec tekshiruv + CI |
| qa | tester, tuzatmaydi |

Antigravity: `.agents/agents/` ichida shu nomlar.

## Ofis sahnasi (localhost)

Qurilishni ko‘rish:

```bash
./scripts/scene.sh
```

Brauzer: [http://127.0.0.1:8765](http://127.0.0.1:8765)

Kichik odamchalar ofisda. Kim ishlayotgani, kutayotgani, tugatgani ko‘rinadi. Stolga bosilsa: hozirgi ish, ticket, xat, qadamlar. Agentlar har qadamda `scripts/live.sh` yozadi. Bo‘sh ofisda **Namuna** tugmasi animatsiyani ko‘rsatadi.

## Doska

TaskView ixtiyoriy. Standart: `board/` + `scripts/board.sh add "…" backend`

## Xotira va xarita

1. Reglament + rol
2. `bus/handoffs/<rol>.md`
3. `board/`
4. claude-mem
5. `graphify-out/` (va Tencent Code-Graph bo‘lsa)
6. Fayllar — oxirgi

## Muhim taqiqlar

- Ticket yo‘q — mahsulot kodi yo‘q
- Pentester/QA patch yo‘q
- Secret git/chatga yo‘q
- Begona tizimga pentest yo‘q — faqat o‘z loyihangiz
