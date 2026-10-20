const PIPE = [
  ["grill", "Grill"],
  ["spec", "Spec"],
  ["tickets", "Ticket"],
  ["build", "Qurish"],
  ["gate", "Gate"],
  ["qa", "QA"],
  ["done", "Done"],
];
const COLORS = {
  orchestrator: { hair: "#2b1c12", body: "#1f4b57", arm: "#1f4b57" },
  backend: { hair: "#3a2a1a", body: "#2f6f4a", arm: "#2f6f4a" },
  frontend: { hair: "#5a2418", body: "#c45c48", arm: "#c45c48" },
  devops: { hair: "#1a1a1a", body: "#3d4a55", arm: "#3d4a55" },
  pentester: { hair: "#111", body: "#3b2a4a", arm: "#3b2a4a" },
  qa: { hair: "#6b3a12", body: "#c4a15a", arm: "#c4a15a" },
};
const STATE_UZ = {
  working: "Ishlamoqda",
  waiting: "Kutmoqda",
  done: "Ishini tugatdi",
  offline: "Ofisda yo‘q",
  blocked: "To‘xtab qoldi",
};
const STAGE_UZ = Object.fromEntries(PIPE);

const desksEl = document.getElementById("desks");
const corkEl = document.getElementById("cork");
const pipeEl = document.getElementById("pipe");
const stampEl = document.getElementById("stamp");
const demoBtn = document.getElementById("demoBtn");
const dossier = document.getElementById("dossier");
const closeBtn = document.getElementById("closeDossier");

let demo = false;
let data = { people: [], tickets: [], pipeline: "grill" };
let selected = null;
let lastSig = "";

function sceneSig(d) {
  return JSON.stringify({
    p: (d.people || []).map((x) => [x.id, x.state, x.now, x.ticket, x.stage, (x.events || []).length, (x.messages || []).length]),
    t: (d.tickets || []).map((x) => [x.id, x.column, x.title, x.role]),
    pipe: d.pipeline,
    ev: (d.events || []).map((e) => [e.t, e.role, e.state, e.now]),
  });
}

function personSvg(id) {
  const c = COLORS[id] || COLORS.orchestrator;
  return `<div class="person" aria-hidden="true">
    <div class="head"><i class="hair" style="background:${c.hair}"></i></div>
    <div class="body" style="background:${c.body}"></div>
    <i class="arm l" style="background:${c.arm}"></i>
    <i class="arm r" style="background:${c.arm}"></i>
    <div class="legs"></div>
  </div>`;
}

function renderPipe(current) {
  const idx = PIPE.findIndex(([id]) => id === current);
  pipeEl.innerHTML = PIPE.map(
    ([id, label], i) => {
      const cls = i < idx ? "did" : i === idx ? "on" : "";
      return `<li class="${cls}">${label}</li>`;
    }
  ).join("");
}

function noteColor(role) {
  return {
    orchestrator: "#f3d27a",
    backend: "#b7e0c2",
    frontend: "#f0b6a8",
    devops: "#c5d0d8",
    pentester: "#d4c2e4",
    qa: "#efe0a8",
  }[role] || "#f3d27a";
}

function renderCork(tickets) {
  if (!tickets.length) {
    corkEl.innerHTML = '<p style="margin:8px;font-size:12px;color:#5c3a1e">Doska bo‘sh. Ticket chiqsa shu yerga yopishadi.</p>';
    return;
  }
  corkEl.innerHTML = tickets
    .map(
      (t) => `<button type="button" class="sticky" data-role="${t.role}" style="background:${noteColor(t.role)}">
        <small>${t.id} · ${t.column}</small>${escapeHtml(t.title)}
      </button>`
    )
    .join("");
  corkEl.querySelectorAll(".sticky").forEach((btn) => {
    btn.addEventListener("click", () => openRole(btn.getAttribute("data-role")));
  });
}

function renderDesks(people) {
  desksEl.innerHTML = people
    .map((p) => {
      const st = STATE_UZ[p.state] || p.state;
      const say = escapeHtml((p.now || "").slice(0, 88));
      return `<button type="button" class="desk ${p.state}" data-pos="${p.id}" data-id="${p.id}" aria-label="${p.label}: ${st}. ${say}">
        ${personSvg(p.id)}
        <p class="say">${say || "Stolda."}</p>
        <span class="steam" aria-hidden="true"><i></i></span>
        <div class="table">
          <span class="lamp"></span>
          <span class="screen"><span></span><span></span><span></span></span>
        </div>
        <div class="tag"><span class="dot"></span><b>${p.label}</b>${st}</div>
      </button>`;
    })
    .join("");
  desksEl.querySelectorAll(".desk").forEach((btn) => {
    btn.addEventListener("click", () => openRole(btn.getAttribute("data-id")));
  });
}

function escapeHtml(s) {
  return String(s || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function renderLog(events) {
  const el = document.getElementById("log");
  if (!events || !events.length) {
    el.innerHTML = "<p>Hali qadam yozilmagan. Agentlar <code>scripts/live.sh</code> yozganda shu yerda ketma-ketlik chiqadi.</p>";
    return;
  }
  el.innerHTML = events
    .slice(0, 12)
    .map((e) => {
      const t = escapeHtml((e.t || "").replace("T", " ").slice(11, 19) || e.t || "");
      const role = escapeHtml(e.role || "");
      const st = STATE_UZ[e.state] || e.state || "";
      const now = escapeHtml(e.now || "");
      const ticket = e.ticket ? ` · ${escapeHtml(e.ticket)}` : "";
      const stage = e.stage ? ` · ${escapeHtml(e.stage)}` : "";
      return `<p><time>${t}</time><b>${role}</b> — ${st}${ticket}${stage}: ${now}</p>`;
    })
    .join("");
}

function openRole(id) {
  const p = data.people.find((x) => x.id === id);
  if (!p) return;
  const firstOpen = selected !== id || dossier.hidden;
  selected = id;
  dossier.hidden = false;
  document.getElementById("dJob").textContent = p.job;
  document.getElementById("dName").textContent = p.label;
  document.getElementById("dState").textContent = `${STATE_UZ[p.state] || p.state}${p.age_s != null ? ` · ${p.age_s}s oldin beat` : ""}`;
  document.getElementById("dNow").textContent = p.now || "—";
  const stageLabel = p.stage ? (STAGE_UZ[p.stage] || p.stage) : (STAGE_UZ[data.pipeline] || data.pipeline);
  document.getElementById("dStage").textContent = `Jarayon: ${stageLabel}${p.ticket ? ` · ${p.ticket}` : ""}`;
  document.querySelectorAll(".desk").forEach((d) => {
    d.classList.toggle("picked", d.getAttribute("data-id") === id);
  });
  const doneEv = (p.events || []).filter((e) => e.state === "done");
  document.getElementById("dDone").innerHTML = doneEv.length
    ? doneEv.map((e) => `<li>${escapeHtml(e.t || "")} — ${escapeHtml(e.now || "")}${e.ticket ? ` (${escapeHtml(e.ticket)})` : ""}</li>`).join("")
    : "<li>Hali tugallangan qadam yozilmagan</li>";
  const tickets = p.tickets || [];
  document.getElementById("dTickets").innerHTML = tickets.length
    ? tickets.map((t) => `<li><strong>${escapeHtml(t.id)}</strong> · ${escapeHtml(t.column)} — ${escapeHtml(t.title)}${t.body ? `<div>${escapeHtml(t.body.slice(0, 280))}</div>` : ""}</li>`).join("")
    : "<li>Ticket yo‘q</li>";
  const msgs = p.messages || [];
  document.getElementById("dMsgs").innerHTML = msgs.length
    ? msgs.map((m) => `<li>${escapeHtml(m.when)} · ${escapeHtml(m.from)} → ${escapeHtml(m.to)}: ${escapeHtml(m.summary || m.subject)}</li>`).join("")
    : "<li>Xat yo‘q</li>";
  const ev = p.events || [];
  document.getElementById("dEvents").innerHTML = ev.length
    ? ev.map((e) => `<li>${escapeHtml(e.t || "")} — ${escapeHtml(e.state || "")}: ${escapeHtml(e.now || "")}</li>`).join("")
    : "<li>Hali live.sh yozilmagan</li>";
  document.getElementById("dHandoff").textContent = p.handoff || "Kapsula yo‘q";
  if (firstOpen) closeBtn.focus();
}

function closeDossier() {
  dossier.hidden = true;
  selected = null;
  document.querySelectorAll(".desk").forEach((d) => d.classList.remove("picked"));
}

async function refresh() {
  const q = demo ? "?demo=1" : "";
  const res = await fetch("/api/live" + q, { cache: "no-store" });
  data = await res.json();
  const s = sceneSig(data);
  stampEl.textContent = demo ? "namuna rejim · " + (data.generated || "") : (data.generated || "");
  if (s !== lastSig) {
    lastSig = s;
    renderPipe(data.pipeline);
    renderCork(data.tickets || []);
    renderDesks(data.people || []);
    renderLog(data.events || []);
  }
  if (selected) openRole(selected);
}

demoBtn.addEventListener("click", () => {
  demo = !demo;
  lastSig = "";
  demoBtn.setAttribute("aria-pressed", String(demo));
  demoBtn.textContent = demo ? "Jonli" : "Namuna";
  refresh().catch(console.error);
});
closeBtn.addEventListener("click", closeDossier);
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") closeDossier();
});

refresh().catch(console.error);
setInterval(() => refresh().catch(() => {}), 2000);
