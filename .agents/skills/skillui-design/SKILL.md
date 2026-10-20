---
name: skillui-design
description: Extracts a website design system into markdown/tokens with skillui so frontend can rebuild that look. Use when the owner gives a reference URL, Dribbble/site to copy, or says dizayn.
---

# skillui

Frontend yozishdan oldin. AI taxminiy rang tanlamasin.

```bash
npx skillui --url <https://reference> --mode ultra
# yoki: skillui --url ... --mode ultra
```

Chiqish papkasidagi `DESIGN.md`, `LAYOUT.md`, `COMPONENTS.md`, `tokens/`, screenshotlarni loyihaga ko‘chir: `docs/design/` (yoki skillui bergan papka).

Frontend agentga yo‘lni ber. Mos kelmasa — skillui qayta, ko‘zbo‘yamachilik yo‘q.

Keyin `frontend-beauty`: oil-ui yo‘nalishlari (reference ni buzmasdan), qurilgach better-interface.

Ultra uchun Playwright kerak bo‘lishi mumkin. Ultra yiqilsa default mode, keyin screenshot bilan to‘ldir.
