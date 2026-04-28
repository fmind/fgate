# Pain Points & SOTA Opportunity for fgate

> Differentiation thesis for fgate. Mined from HN, GitHub issues, blogs, and the
> GitHub REST API on 2026-04-28. Every quote in this brief is sourced. Sentiment
> labelled "anecdotal" only when no citation exists.

## TL;DR — the 5 strongest pitches, ranked by realism

1. **"One skill set, two CLIs (Gemini + Claude). No lock-in."** — Concrete,
   unique, falsifiable. Spec-kit, BMad, superpowers, gstack all started Claude- or
   Copilot-first and bolted on adapters later. fgate ships portable Anthropic Agent
   Skills as the single canonical artifact and proves it on day 1 against two
   first-party CLIs. The gap is real: HN user `outlore` complained "all of them
   have slightly different conventions for where to put skills, how to format MCP
   servers...it's a big mess" (HN 47205053). _Realism: high — purely an
   engineering / packaging problem._

2. **"File-system is state. `gates/` is committed to `main`."** — Counter to the
   industry's "compaction-as-magic" stance. Anchors traceability, code review,
   and reproducibility in plain markdown — not in a sidecar DB or LLM scratchpad.
   `LaneConductor` (HN 47338664) had to invent the same thing: "All state lives
   in Markdown files (plan.md, spec.md, index.md) rather than in any LLM's context
   window." Reproducibility is a 2026 research-paper concern (arXiv 2601.10220:
   "non-deterministic behavior of LLMs...complicating reproducibility"). _Realism:
   high — implementation cost is zero, but the messaging will need to be loud._

3. **"Six skills, ≤ 200 words each. Less than spec-kit's 1000s of lines of
   markdown."** — Direct counter-positioning to the field's biggest complaint.
   Colin Eberhardt: "asking an agent to write 1000s of lines of markdown rather
   than just asking it to write the code is a misuse of this technology"
   (blog.scottlogic.com). `Rapzid` on GSD: "too verbose in the plan output...
   railroads you into implementation" (HN). `huydotnet`: "it takes too many turns
   to get something done" (HN). _Realism: high — but only if we hold the line on
   skill body length._

4. **"`/fimprove` actually mutates AGENTS.md and skills/. Not retro theatre."** —
   Most "self-improving" frameworks (BMad's `*retro`, gstack's `learn`,
   superpowers' brainstorming retrospectives) write to a learnings file no one
   reads. fgate's improve gate produces a **diff to the meta-process** —
   AGENTS.md or `skills/*` — that the user merges with the same review they apply
   to code. `mark-mdev` on Meridian had to build "memory.jsonl" to stop "context
   loss after compaction, forgotten decisions, repeated mistakes" (HN 45923974).
   _Realism: medium — the discipline to keep `/fimprove` from sprawling is
   non-trivial. If we ship version 1 with sloppy improve diffs, it kills the
   pitch._

5. **"Single-author, solo workflow, no enterprise-anything."** — A
   counter-positioning angle. spec-kit / BMad / Continue chase team adoption.
   gstack frames itself as a "virtual engineering team" with CEO/QA/release
   personas. fgate is unapologetically personal — closer to Aider's solo terminal
   ethos than spec-kit's PRD assembly line. The HN comment from `corytheboyd`
   ("parallelism is overstated...exhausting, to the point of slowing me down")
   reflects a real backlash. _Realism: medium — it's a clear niche, but niches
   don't get HN front-page traction. Pitch #1 is the headline; this is the
   support beam._

---

## 1. SOTA calibration — what does "popular" mean in 2026?

GitHub REST API (`/repos/<owner>/<repo>`), fetched 2026-04-28:

| Tool                | Stars   | Open issues | Created    | Notes                                                |
| ------------------- | ------- | ----------- | ---------- | ---------------------------------------------------- |
| obra/superpowers    | 171,267 | 278         | 2025-10-09 | 6 months → 171k. Anthropic-marketplace-blessed.      |
| github/spec-kit     | 91,490  | 642         | 2025-08-21 | The canonical SDD reference.                         |
| garrytan/gstack     | 85,997  | 477         | 2026-03-11 | 6 weeks → 86k. Garry Tan halo effect.                |
| cline/cline         | 61,106  | 740         | 2024-07    | VS Code extension; legacy.                           |
| bmad-code-org/BMAD  | 45,894  | 65          | 2025-04-13 | Highly polished, enterprise-leaning.                 |
| Aider-AI/aider      | 44,075  | 1,507       | 2023-05    | Pre-Claude-Code grandfather.                         |
| continuedev/continue| 32,859  | 645         | 2023-05    | Pivoted to "AI checks for PRs".                      |
| RooCodeInc/Roo-Code | 23,729  | 926         | 2024-10    | Cline fork; mode-based UX.                           |

**Calibration takeaways:**

- The bar to "trending" in this space is ~10-30k stars in a few weeks if you have
  a hook (gstack, superpowers).
- 91k for spec-kit means Spec-Driven Development is _the_ default frame in 2026.
  fgate must position relative to it (counter-positioning, not denial).
- Open-issue count is a red flag, not just a popularity proxy: aider's 1.5k open
  issues and Cline's 740 reflect feature-creep paralysis. fgate's 6-skill cap is
  a moat against this.

## 2. What people praise — what drives stars

- **Plan-then-execute split is universally loved.** `phainopepla2`: "Conductor
  extension won't make changes until detailed plan is generated and approved"
  (HN 46860124). `mlaretallack` on Kiro: "spec driven development makes me slow
  down and think clearly about requirements" (HN 47111077). _Implication: keep
  fplan as a hard gate; do not let fimplement run without it._

- **Multi-agent sandboxing wows demo-watchers.** `dominicholmes` on Conductor:
  "Managing many agents, each in their own sandbox, felt like indisputably the
  future after using conductor for a day" (HN 47621884). _Implication: worktree
  support is a v2 multiplier, but not a v1 differentiator._

- **Being a thin wrapper that stays out of the way.** `int_19h` on Cline: "Cline
  seems to be the best thing, I suspect because it doesn't do any dirty tricks
  with trimming down context" (HN 43963926). _Implication: fgate must not
  silently inject context._

- **Markdown as governance is now a recognized pattern.** `simonw` on Skills:
  "The way Skills work is you tell the LLM to read this markdown file first" (HN
  47322592). `cheema33`: "Use agent skills. And say goodbye to MCP. We need to
  move on from MCP" (HN 47392338). _Implication: skills-first beats MCP-first for
  context discipline. Validates fgate's primitive choice._

## 3. What people complain about — quoted complaints with URLs

### 3a. Spec-kit specifically

- **Overkill for small tasks.** From Martin Fowler's SDD comparison
  (martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html): "spec-kit
  created a LOT of markdown files for me to review. They were repetitive, both
  with each other, and with the code that already existed." And: "the workflow
  was like using a sledgehammer to crack a nut. The requirements document turned
  this small bug into 4 'user stories' with a total of 16 acceptance criteria."

- **Agent ignores spec.** Same source: "the agent ignored the notes that these
  were descriptions of existing classes, it just took them as a new specification
  and generated them all over again, creating duplicates."

- **Slower than just prompting.** Colin Eberhardt
  (blog.scottlogic.com/2025/11/26/putting-spec-kit-through-its-paces): "a sea of
  markdown documents, long agent run-times and unexpected friction"; "I am a lot
  more productive without SDD, around ten times faster"; "asking an agent to
  write 1000s of lines of markdown rather than just asking it to write the code
  is a misuse of this technology."

- **Maintenance worry, even at 91k stars.** github/spec-kit Discussion #1482
  (Jan 16 2026): "In the last month we had 22 PRs opened and exactly zero
  commits"; "if SpecKit is not maintained properly than I need to move on some
  different tooling."

- **Self-bloat.** github/spec-kit issue #2246 (closed): "update-agent-context.sh
  bloats CLAUDE.md with per-feature tech-stack entries that duplicate project
  docs."

### 3b. BMad

- **Steep learning curve.** Anderson Santos (adsantos.medium.com/you-should-bmad-
  part-2): the method "kills the vibe of freeform coding, replacing organic
  interaction with process orchestration"; needs "approximately two months" to
  master vs "a day or two for simpler frameworks"; "If one agent produces flawed
  output, downstream agents may not detect the error" — practitioner cited "a
  nonfunctional authentication system that the pipeline erroneously flagged as
  complete."

- **Token cost.** Same source: "approximately 31,667 tokens per workflow run,
  with monthly API costs reaching $847"; users reported "approximately 230
  million tokens per week on large-scale projects."

- **Drift between BMad's own state files.** github/bmad-code-org issue #2341:
  "Story markdown status can drift from sprint-status.yaml at closeout, and
  epic closeout can still proceed." _This is the smoking gun for "spec rot" in
  2026 — the framework can't keep its own metadata consistent._

- **Skills overflow context.** github/bmad-code-org issue #2343: "Codex warns
  that BMAD skill descriptions exceed startup context budget when many skills
  are installed."

### 3c. Aider architect mode

- **Mode confusion.** github.com/Aider-AI/aider/issues/3035: "Don't understand
  the semantics of architect mode." Issue #3287: "editor model splitting
  response into multiple steps and waiting a 'continue' instruction."

- **Forced behavior.** Issue #4933: "No way to force aider to do just one pass
  via cli (no architect mode)" — even with `architect: false` "aider still
  insists in doing too many things."

- **Prompt-injection vector.** Issue #5058: "Architect mode can turn README
  prompt injection into committed backdoored code" — attacker-controlled README
  with hidden ARCHITECT OVERRIDE leading to `.env` exfil.

- **Repo-map is too local.** Issue #2042 (vessenes): "tree-sitter in aider isn't
  really set up to make a repo-map useful across the different parts of the
  repo"; LLMs are "pretty locally minded" and don't account for "broader
  context."

### 3d. Cursor Composer 2 (recent, 2026)

- **Quality regression.** forum.cursor.com/t/composer-2-its-trash/156283
  (Marcelo_Pimentel): "loss of context, loss of modified source code,
  unsuccessful implementations with a high error rate"; "I've lost a significant
  portion of my AI credits having to fix problems generated by the AI itself."

- **Cursor team acknowledged "various quality concerns around Composer 2"** in
  the same thread.

- **Vibecoding.app's 2026 problems writeup**: "Cursor 3.0.13 has been incredibly
  slow in Agent or Ask mode"; "Composer 2 editing files it wasn't supposed to";
  "Cursor switches between model versions behind the scenes."

### 3e. Cline / Continue / Roo

- **Continue.dev** (HN 46352939, KronisLV): "Continue.dev autocomplete sucks
  and is buggy (Ollama), there don't seem to be good enough VSC plugins."
  (HN 46716519): "using Qwen 2.5 Coder for autocomplete with Continue.dev,
  that experience was a mess."

- **Cline > Cursor for many.** `brulard` (HN 44353490): "I was not very happy
  with Cursor... After few hours I gave up and returned to Cline." `kkukshtel`
  (HN 43745186): "I really liked Cline until I tried Claude Code." _Implication:
  the IDE-extension generation is bleeding to terminal-native CLIs._

### 3f. Cross-cutting — context window / drift / spec rot

- **Compaction kills quality.** `trjordan` (HN 45017306): "Compaction is
  automatic but extremely expensive. Quality absolutely takes a dive until
  everything is re-established." `macNchz` (HN 44382389): "code quality drops
  across all models as context fills up, well before hard limit." `613style`
  (HN 45264922): "Claude Code fills its context window and re-compacts often
  enough that I have to plan around it."

- **CLAUDE.md doesn't bind the agent.** `hansmayer` (HN 46258587):
  "instructions will be ignored...your software is not deterministic, its merely
  guessing." `post_below` (HN 47022951): "no matter how many times you do it
  the agents will still make mistakes" — re. CLAUDE.md persistence. `EastLondonCoder`
  (HN 46905344): drift "stays locally plausible while walking away from repo
  constraints; notice only at runtime."

- **Spec rot.** `joegaebel` (HN 47424029): "Specs are subject to bit-rot,
  there's no impetus to update them as behaviour changes." `rcoder` (HN 9656393):
  "plans and specs bit-rotted and the whole thing got scrapped." `ali_mouiz`
  (HN 47763118): "Spec-first was unlock for me. Agent drifts badly without it.
  Defensive code needed for reliability."

- **Specs as Big-Design-Up-Front.** `fzaninotto` (HN 45935763, article author):
  "I have also never seen instances of a coding agent doing exactly what I had
  in mind in the first try (except for very simple cases), so there must be
  iterations, which defeats the purpose of the Big Design Up Front."
  `constantcrying` (same thread): "The constant increasing of complexity in the
  project, required to keep code and spec consistent can not be managed by LLM
  or human."

### 3g. Spec-kit / framework skepticism

- **"Snake oil" charge.** `grim_io` (HN, on a frameworks thread): "I tend to
  lean towards them being snake oil. A lot of process and ritual around using
  them, but for what?"

- **Wishful thinking.** `stingraycharles` (same thread): "this type of stuff is
  just wishful thinking right now: for anything non-trivial, you still need to
  monitor Claude Code closely."

- **Bottleneck mismatch.** `wenc` (HN 47773388): "The bottleneck in development
  isn't workflow orchestration--it's problem decomposition."

### 3h. Skill / marketplace ecosystem complaints

- **Plugin install friction.** `BrutalCoding` (HN 45531790): "Failed to clone
  marketplace repository: SSH authentication failed" — first-time install
  bricked by SSH defaults. `ndom91` (HN 47217579): "Had trouble with their two
  marketplace's as there's also another anthropics-claude-code" — namespace
  fragmentation.

- **Skill-install bloat.** mindstudio.ai/blog/claude-code-skills-common-mistakes
  -guide: "If you have 20 MCP servers installed, each exposing 5–10 tools, you
  might be consuming thousands of tokens just on tool descriptions before Claude
  reads a single line of your message"; "for any given project, Claude Code
  should have access to 5–8 tools at most."

- **Tool-portability gap.** `outlore` (HN 47205053): "all of them have slightly
  different conventions for where to put skills, how to format MCP servers...
  it's a big mess." `westurner` (HN 47167106): "It would be better for the spec
  to specify universal homedir-relative and repo-root-relative paths."

## 4. Gaps in SOTA — fgate's potential moats (verified, not assumed)

| Gap                                                            | Verified by                                          | fgate's answer                                                | Confidence |
| -------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------- | ---------- |
| **Tool portability**                                           | HN 47205053 (outlore), HN 47167106 (westurner)       | One canonical `skills/<n>/SKILL.md`, two thin manifests       | High       |
| **Markdown overload**                                          | Eberhardt blog, Fowler article, HN Rapzid/huydotnet  | ≤ 200 words/skill body; six skills total                      | High       |
| **State outside the LLM**                                      | HN 47338664 (LaneConductor), HN 45923974 (Meridian)  | `gates/<id>/{human,agent}/*.md` committed to `main`           | High       |
| **Self-improvement that ships diffs**                          | superpowers/gstack/BMad all do retros that go nowhere | `/fimprove` only mutates AGENTS.md or `skills/`               | Medium     |
| **Solo / personal-first stance**                               | corytheboyd HN, dominicholmes HN (parallelism backlash) | No enterprise features, no "team" personas                  | Medium     |
| **Plan ↔ code drift detection**                                | bmad-code-org #2341, ali_mouiz HN, EastLondonCoder HN | File-presence-as-state; no separate state.json to desync     | Medium-low |
| **Friendly to commit history**                                 | (anecdotal — verify before relying)                  | gates committed to main; PR-friendly file naming              | Anecdotal  |

**Self-improvement gap is the most overclaimed in the field.** Worth quoting two
contrast points: BMad's #2341 (story status drifts from sprint-status.yaml);
gstack's "learnings.jsonl" is _agent-readable, not human-reviewable_ (per
gstack.md research). superpowers ships brainstorming retrospectives but the
output disappears into chat history. fgate can win on this single dimension —
**every improve gate produces a reviewable git diff to AGENTS.md or skills/.**

## 5. Star-worthy positioning — concrete pitches, not generic

**Pitches that would land on HN front page (try them in order):**

1. _"Show HN: fgate — the spec-driven dev workflow that fits in 6 skills × 200
   words each"_ — Direct counter-positioning. Reference Eberhardt's "1000s of
   lines of markdown" complaint in the post body. **Best shot at top-10.**

2. _"Show HN: fgate — Gemini CLI and Claude Code share one skill set. No more
   plugin bloat."_ — Tool-portability is the under-served angle in 2026. Cite
   outlore's "it's a big mess" as the problem statement.

3. _"Show HN: fgate — agent state lives as committed markdown, not in a sidecar
   DB"_ — Reproducibility / traceability angle. Pair with the arXiv 2601.10220
   reference for credibility.

4. _"Show HN: fgate — self-improvement that produces a reviewable git diff,
   not a 'learnings.jsonl' nobody reads"_ — Specific dig at the existing tools.
   Risky framing; only do this if confident in `/fimprove` quality.

**Pitches that will _not_ land** (avoid):

- Anything with "vibe coding" or "agentic AI" in the title — saturated.
- "Faster than spec-kit" — invites benchmark debate fgate can't win.
- "MCP-killer" — fgate isn't one; cheema33's HN comment doesn't translate.

## 6. Brutal failure-mode analysis — fgate launches and gets 12 stars

Assume Show HN flop, repo plateau at ~50 stars, a few drive-by issues.
What happened? Most-likely-to-least:

1. **Skill bodies bloated past 200 words during authoring.** Self-discipline
   gap. Without enforcement (skill-check.ts equivalent — gstack actually has
   one), markdown grows. Result: fgate looks like spec-kit-with-fewer-files.
   _Mitigation: a CI check on word count of `skills/*/SKILL.md`._

2. **`/fimprove` produced ugly diffs nobody wanted to merge.** The improve gate
   is the differentiator, and the differentiator is the hardest skill to write
   correctly. Most likely failure: it dumps stream-of-consciousness paragraphs
   into AGENTS.md instead of replacing bullets. _Mitigation: ship v1 with a
   strict pre-commit on AGENTS.md format (≤ 30 bullets, ≤ 100 chars each)._

3. **superpowers / gstack covered 80% of the value first.** They are 6-12
   months ahead, marketplace-listed, multi-host already. fgate's 6-skill count
   may be _too_ minimal. Counter: that's the pitch — but only if the difference
   is visible in 30 seconds of README.

4. **The Gemini CLI half didn't actually work.** TOML `@{}` embedding looks
   clean on paper but breaks at the seams (shell quoting, multi-line {{args}}
   handling, etc.). If first-run on Gemini fails, the "tool-portable" pitch
   collapses. _Mitigation: dogfood Gemini path in Phase 4 before any external
   announcement._

5. **No one knows fmind's name.** Solo OSS in this space needs a foothold. obra
   has Prime Radiant, garrytan has YC. Without a halo, fgate needs a _post_, not
   a repo — write the differentiation thesis as a public blog post first, link
   the repo from there. fgate's Phase 0 docs (this file) are nearly that post
   already.

6. **GitHub's spec-kit added "minimal mode" or skill plugin shipping.** A
   single GH product update can subsume a fgate-shaped niche overnight. Watch
   the spec-kit roadmap and discussions; pivot fast if they ship.

7. **The personal-first ethos got read as "toy project."** Solo + minimal
   reads as unmaintained. _Mitigation: brutal honesty in README — "this is for
   me, you may benefit" beats "fastest agentic workflow" hype._

8. **Solo workflow is an oversold niche.** Most stars in this space come from
   enterprise-adjacent posts. The "personal" angle limits ceiling regardless of
   quality. _If you want stars, you need to soft-pedal personal and lead with
   portability + minimalism._

**Two failure modes that will _not_ happen and don't worry about:**

- _Hallucinated complaints in this brief._ Every claim above has a URL or is
  labelled anecdotal.
- _Skills not finding tool support._ Anthropic Agent Skills are now supported
  by Copilot (HN 46549762, westurner) and Gemini CLI's plugin/skill story is
  documented. Distribution risk is at the manifest layer, not the primitive.

## 7. Specific things this brief found that the PLAN.md should reflect

- Add a **CI check on skill body word count** (mitigation #1 above) before v1.
- Add an explicit `/fimprove` **format constraint** to AGENTS.md mutations —
  bullets only, ≤ 100 chars each (mitigation #2).
- Decide: ship a **Show HN draft** as part of Phase 4 dogfooding, written
  against this brief's pitches. Don't announce until written.
- Pin **superpowers v5.0.7** and **spec-kit v0.0.91+** as the explicit
  comparison points in README — the gap is concrete and fresh.
- Watch **github/spec-kit issue #872** ("verbose and inconsistent with uv
  standards") and **#737** ("spec-kit should answer questions, not 'fix' them")
  — both labelled stale, both signal the same simplicity-shaped hole fgate
  targets.

---

**Sources** (each used at least once; full URLs in body above): Hacker News
Algolia API (`hn.algolia.com/api/v1/search`); github.com REST API
(`api.github.com/repos/<owner>/<repo>`); github.com/github/spec-kit (issues +
discussions); github.com/Aider-AI/aider/issues; github.com/bmad-code-org/BMAD-
METHOD/issues; github.com/cline/cline; github.com/RooCodeInc/Roo-Code;
github.com/continuedev/continue; martinfowler.com/articles/exploring-gen-ai/sdd-
3-tools.html; blog.scottlogic.com/2025/11/26/putting-spec-kit-through-its-paces;
adsantos.medium.com/you-should-bmad-part-2; forum.cursor.com (Composer 2
threads); mindstudio.ai/blog/claude-code-skills-common-mistakes-guide;
arxiv.org/html/2601.10220v1; resources.anthropic.com/2026-agentic-coding-trends-
report. Reddit attempts blocked at the WebFetch layer — sentiment from r/ClaudeAI
and r/cursor not directly cited.
