---
name: devops-check
description: Compares the original owner prompt, spec, and tickets to git diff. Use when a slice claims done or before deploy. Missing work becomes tickets; devops does not implement product code.
---

# Spec vs diff

1. O‘qi: eganing birinchi so‘rovi (board izohi), `docs/agents/spec.md`, `board/tickets/*.md`.
2. `git diff origin/main` + graphify.
3. Checklist: har ticket qabul mezoni bormi, contract bormi, test bormi, CI bormi, secret commit bo‘lmaganmi.
4. Qolgan yoki buzilgan talab — TV-N, teg quruvchi. Xat bus orqali. Mahsulot kodini o‘zing yozma.
5. To‘liq + pentester PASS → orchestratorga chiqarishga tayyor.

Forgejo yo‘q bo‘lsa GitHub Actions. Image: trivy, prodga digest. `main` himoyasi: to‘g‘ridan-to‘g‘ri push va force-push yo‘q.
