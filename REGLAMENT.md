# Setka — Cursor + Gemini agent tizimi (v3)

Bitta dasturchi. Bir nechta ixtisoslashgan agent. Kod yozishdan oldin loyiha tushuniladi.
Asl v2 (Claude Code + tmux) `legacy-claude-code/` ichida. Bu hujjat asosiy: **Cursor** va **Google Antigravity (Gemini)**.

Nusxa: bu papkani har qanday mahsulot loyihasiga `scripts/apply-to-project.sh` bilan ko‘chirib qo‘yasiz.

---

## 0. G‘oya

Bitta chat hammaga javobgar bo‘lsa, ipni yo‘qotadi. Setkada har bir rolning o‘z o‘qi va taqiqlari bor:

1. **Orchestrator** — tushunadi, so‘raydi, ticket yozadi, parallel ishni boshlaydi. Mahsulot kodi yozmaydi.
2. **Backend / Frontend** — parallel quradi. Bir-birining fayliga tegmaydi.
3. **Pentester** — buzib ko‘radi, topadi, o‘zi tuzatmaydi. Muammo quruvchiga qaytadi.
4. **Devops** — asl vazifa/spec bilan solishtiradi. Qolgan narsa quruvchiga qaytadi.
5. **QA** — ishga tushiradi, bug topadi, o‘zi tuzatmaydi.

Besh shart:

1. Rol — nima qiladi va nima qilmaydi.
2. Shina (`bus.sh`) — yo‘qolmaydigan xabar.
3. Doska (`board/`) — kim nima qilyapti.
4. Commit yo‘li — branch → test → pentest gate → chiqarish.
5. Egasi so‘zi — pul, prod, maxfiy narsa faqat odamning aniq «ha»sida.

---

## 1. Rollar

| Rol | Tutadi | Qilmaydi |
|---|---|---|
| **orchestrator** | maqsad, doska, egasi, chiqarish | mahsulot kodi; o‘zini pentest qilmaydi |
| **backend** | Django/DRF, Postgres, Redis, bot | UI, prod, `.env` qiymatlari; `main`ga push yo‘q |
| **frontend** | UI, e2e | backend, migratsiya, `.env`, prod; `main`ga push yo‘q |
| **devops** | CI, deploy, spec-tekshiruv | mahsulot kodi |
| **qa** | stend/prod ssenariy, dalil | tuzatmaydi |
| **pentester** | har sha uchun xavfsizlik gate | tuzatmaydi |

Qoidalar:

1. Bir o‘q — bir ijrochi. Begona faylni o‘zing tuzatma, ticket yoz.
2. Bir ism — bir tirik nusxa.
3. Iloji bo‘lsa har rolning git worktree `w/<rol>/…`.
4. Ish yo‘q bo‘lsa kut. O‘zingga ish izlama.
5. Xat yozish kod yozishdan ko‘p bo‘lsa — tarkibni qisqartir.

---

## 2. Tekshiruv tamoyillari

1. O‘lchov, taxmin emas. Raqam + buyruq + kim ishlatgani.
2. Gate sha ga bog‘langan. Ishchi daraxt emas, `origin/main` yoki aniq sha.
3. Test faqat qizarishni bilar ekan dalil. Tuzatishni olib tashla — test tushishi kerak.
4. «Bo‘sh / 0 / 200» asbob ishlamaganini anglatishi mumkin.
5. Uch natija: HA / YO‘Q / SUDI QILIB BO‘LMAYDI.
6. Verdict chegarasi ovoz chiqarib aytiladi.
7. Egaga rost gap: natija yoki «X da tiqilib qoldik, Y kerak, muddat Z».

---

## 3. Aloqa

### 3.1 Fayl shinasi — yo‘qolmasin

Papka: `$BUS_DIR` (standart `~/bus`). Protokol: `bus.sh`.

Har qadamda:

1. `./bus.sh beat <rol>`
2. `scripts/live.sh <rol> working|waiting|done "<hozir nima qilyapman>" [TV-N] [grill|spec|tickets|build|gate|qa|done]` — ofis: `http://127.0.0.1:8765`
3. `./bus.sh read <rol>` — kursor bo‘yicha, grep emas
4. Har xatga ACK: `./bus.sh ack <men> <id> <yuboruvchi>`
5. 10 daqiqadan ACK yo‘q — `pending` → qayta yubor yoki ALERTS
6. Bir ism — bir nusxa

```
[MSG <id>] OT <kim> -> <kimga> | <ISO-vaqt> | <mavzu>
SUT: bitta gap
FAKT: raqam, yo‘l, sha
KERAK: aniq harakat — yoki «info, harakat yoq»
```

### 3.2 Egasi

Asosiy ish kompyuterda. Telegram — zaxira (ha/yo‘q, status). Kod review telefonlardan qabul qilinmaydi.

---

## 4. TaskView / doska

Asosiy doska: mahalliy `board/` (TaskView MCP ixtiyoriy).

Ustunlar: Backlog → Ishda → Gate pentester → Chiqarishga tayyor → Prodda (tekshirilmagan) → Done.

Teglar: orchestrator, backend, frontend, devops, qa, pentester, `egaga`, `muzlatilgan`.

Qoidalar:

1. Eganing har bir topshirig‘i — avval ticket, keyin ish. Kichiklari ham.
2. Nom: `TV-N · …`. Javob `TV-N` bilan boshlanadi.
3. Har qadam ustunni siljitadi. Dalil (sha, test) qo‘shiladi, o‘chirilmaydi.
4. Olding — muddat qo‘y. Boshqasini kutyapti — bog‘liqlik yoz.
5. Ega qarori — teg `egaga`.

---

## 5. Kod yozishdan OLDIN — 4 bosqich

Mahsulot kodi **faqat** shu zanjirdan keyin:

```
/start-project
  → /setup-matt-pocock-skills   (tracker, label, docs/agents)
  → /grill-with-docs            (savol-javob, glossary, ADR)
  → /to-spec                    (qarorlar yozuvi, yangi qaror yo‘q)
  → /to-tickets                 (vertikal slice, blocker)
  → graphify xarita
  → (UI bo‘lsa) skillui
  → parallel backend + frontend
```

Ticketlar egasi tasdiqlamaguncha **hech kim** mahsulot kodi yozmaydi.

Mavjud GitHub/loyiha bo‘lsa: avval o‘qi (graphify), keyin grill. Yozma.

---

## 6. Commit yo‘li

1. Branch `w/<mavzu>` yangi `origin/main`dan. `git add -A` taqiqlangan.
2. Test + mutant. Build oxirida.
3. Sha pentesterga. Kartochka → Gate.
4. Izoh yangi commit + yangi sha. `main`ga force-push yo‘q.
5. PASS + eganing «ha» → fast-forward `main`.
6. Jonli qabul: prod sha + `/healthz`. Keyin Done.
7. Rollback: feature-flag, revert, digest bo‘yicha oldingi image.

### 6.1 Pentester gate

Har sha:

1. Graphify: o‘zgarish nimalarga ta’sir qiladi.
2. Strix — faqat shu loyiha / ruxsat berilgan stend.
3. Kerakli cybersecurity skill (OWASP, auth, injection…) — katalogni dump qilma.
4. Verdict: PASS / FAIL / SUDI YO‘Q + sha + dalil + chegara.
5. Topilma — ticket egasiga. **Pentester patch qo‘llamaydi.**

### 6.2 Devops tekshiruvi

Asl prompt + spec + ticketlar vs haqiqiy diff.

- Qolgan talab → ticket + quruvchiga qaytarish. Devops o‘zi yozmaydi.
- CI qizil → logni o‘qi, infro tuzat; mahsulot mantiqini emas.

### 6.3 QA

Avval «bosdim → chiqdimi». Sifat ikkinchi. Defekt = qadam + kutilgan + fakt + skrin. Tuzatmaydi.

---

## 7. Steklar

**Backend (majburiy, o‘zgartirish faqat eganing «ha»sida):**
Python · Django · Django REST Framework · PostgreSQL · Redis.

Telegram bot kerak bo‘lsa: [Telegram-Bot-template](https://github.com/XasanovOzodjon/Telegram-Bot-template) asosida `python-telegram-bot`. Django API dan ajratilgan servis.

**Frontend:** orchestrator tanlaydi. Reference URL bo‘lsa avval `skillui`. Keyin **oil-ui** 2–3 farqli yo‘nalish ko‘rsatadi, ega tanlaydi. Qurilgach **better-interface** (jakubkrehel) silliqlaydi. **scroll-world** — kino/scroll landing uchun, faqat eganing pul «ha»sida.

Backend va frontend **parallel**. Shartnoma: OpenAPI/schema ticketlari. UI mock bilan kutaveradi, backend contract ni buzmaydi.

---

## 8. Xotira va xarita (token)

Manbalar tartibi:

1. Shu reglament + `roles/<rol>.md`
2. `bus/handoffs/<rol>.md` kapsula
3. `board/` ticketlari
4. Claude-mem (chatlar xotirasi)
5. Graphify `graphify-out/` (kod xaritasi) — Tencent Code-Graph bo‘lsa, u ham
6. Fayllarning o‘zi — oxirgi chora

Graphify **barcha** rollarga. Kontekst to‘lganda fayllarni qayta o‘qima: `graphify-out/GRAPH_REPORT.md` va `graph.json`.

Chat uzoqlashsa — avval kapsula yoz, keyin yangi chat.

---

## 9. Maxfiy, pul, prod

1. Prodga yozish: scratchpad skript → pentester o‘qiydi → egasi o‘zi ishlatadi.
2. Pul — har safar aniq «ha».
3. Secret chat/git/logda yo‘q. Faqat uzunlik va prefiks.
4. Agent `.env` qiymatini kiritmaydi.

---

## 10. Verdict formati

```
VERDICT: PASS / FAIL / SUDI YOQ, sha
DALIL: o‘lchov, son, nazorat
CHEGARA: verdict NIMANI qamramaydi
```

---

## 11. Setka ishlayapti, agar

1. `bus.sh who` tiniq.
2. Backend → pentester xati 10 daqiqada ACK.
3. Eganing gapidan TV-N chiqadi.
4. Slice: grill → spec → ticket → parallel qurish → test → gate → qa.
5. Yangi chat kechagi TV-N ni mem+kapsuladan aytadi.
6. Pentester o‘zi kod tuzatmagan.
7. Graphify-out yangilangan, agent grep o‘rniga xaritadan so‘raydi.
