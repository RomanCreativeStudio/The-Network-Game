# THE NETWORK — MVP DEFINITION v0.1

**Status:** DRAFT
**Version:** 0.1
**Date:** August 25, 2026
**Subordinate to:** [`source-of-truth.md`](./source-of-truth.md) — authoritative.
**Related, non-binding:** [`economy-specification-v0.1.md`](./economy-specification-v0.1.md), [`progression-specification-v0.1.md`](./progression-specification-v0.1.md), [`organization-systems-specification-v0.1.md`](./organization-systems-specification-v0.1.md) — all three are proposed, not locked. This document's job is to select the smallest slice of them that proves the core loop is fun; everything not selected remains valid future design, not rejected design.

---

## AUTHORITY & SCOPE

Per the Source of Truth's development sequence (§19, step 6), this is the MVP definition following the Economy, Progression, and Organization Systems specifications. SoT §19 states directly: *"The MVP must contain a focused, fun core loop rather than dozens of incomplete systems."* This document's single governing test, applied to every proposed feature:

> **Does this make the first 20–30 minutes more fun, understandable, or replayable?**

If a feature from a subordinate spec fails this test, it is cut to Post-MVP or Future Vision here — not discarded from the design, just deferred. Per the task instructions, mergers, acquisitions, buyouts, liquidation, courts, full governance, mega-corporation systems, and advanced political systems are explicitly excluded except where a minimal placeholder is unavoidable as a dependency (none were found to be unavoidable — see §16).

No gameplay code is implemented or specified at the Luau level here.

---

## 0. THE CORE LOOP, MAPPED TO MVP

| Loop step (task brief) | MVP mechanic that proves it |
|---|---|
| JOIN | Player spawns into one of a small number of pre-seeded organizations (§7). |
| GET A ROLE | Player becomes an Associate with a chosen Task category (§3). |
| WORK | Player accepts and completes Tasks (§4). |
| MAKE DECISIONS | Each Task includes a genuine choice point with risk/reward tradeoffs (§5). |
| PERFORM | Decision outcomes compute a Performance Rating (§6, reusing Economy Spec §5.1). |
| EARN RESOURCES | Personal Money and Performance/Reputation accrue from completed Tasks (§6). |
| ADVANCE | Performance + Reputation clear a threshold → promotion (§10). |
| GAIN RESPONSIBILITY | First promotion (Associate → Manager) unlocks the ability to assign Tasks to others (§10). |
| INTERACT WITH PLAYERS | Shared world presence, Manager→report Task assignment, visible org roster (§9). |
| WANT TO KEEP PLAYING | A visible next tier, a visible peer/leaderboard signal, persistence across sessions (§14, §19–§20). |

This table is the spine the rest of the document justifies feature-by-feature against.

---

## 1. MVP PLAYER EXPERIENCE: FIRST JOIN → FIRST MEANINGFUL PROMOTION

1. Player joins the game, is placed into a starting hub (§12), and either auto-assigned to a seeded organization or given a light choice between a small number of them (§7).
2. Player receives their first Task with an in-context explanation of what a Task is (§2).
3. Player completes Tasks, each with an embedded decision point (§5); Personal Money and Performance accrue visibly (§6).
4. Once Performance + Reputation clear the (initially untuned, playtested) threshold, the player is promoted — first to a light intermediate step, then meaningfully to **Manager** (§3, §10).
5. As Manager, the player can assign a Task to another player in their org for the first time — the session's first taste of organizational authority (Organization Systems Spec §6, cut down to this single interaction for MVP).
6. Session ends (or continues) with the player able to see what's still locked (Director+, Founder, other org systems) as a visible "there's more" signal (§17, §20).

**Required for MVP.** This is the loop the whole document exists to protect.

---

## 2. FIRST-TIME-PLAYER ONBOARDING

Directly implements SoT §12's "First job: Learn basic work/proposals" — and nothing beyond it.

- **Required:** A short, in-context (not a wall of text) explanation of: what a Task is, how to complete one, what Personal Money and Performance mean, and that completing Tasks well leads to promotion.
- **Required:** Onboarding does **not** mention Organizational Capital, Departments, Branches, Contracts-as-bidding, R&D, Influence, or Founder — per Progression Spec §14 and Economy Spec Locked Rule #7 (progressive disclosure by rank), these stay hidden until (post-MVP) systems that use them exist.
- **Recommended:** A single guided "first Task" that cannot be failed badly (a soft, forgiving first decision) so the player's very first choice still feels meaningful without punishing inexperience — protects the "understandable" half of the governing test.
- **Post-MVP:** Any tutorial for Manager-level responsibilities beyond the one Task-assignment interaction (§1) — Director-and-above onboarding per Progression Spec §14's later stages is out of scope until those ranks exist in-game.

---

## 3. INITIAL CAREER / RANK PATH

Progression Spec's full ladder (Associate → Specialist → Manager → Director → VP → Chief → Executive → CEO, plus Founder) is a **proposed**, not locked, structure — SoT §4 itself calls the ladder "conceptual" and not locked. MVP does not need to implement all of it to prove the loop.

- **Required:** **Associate → Manager**, with **Specialist** treated as a light intermediate step (Progression Spec flagged Specialist's purpose as underspecified — MVP resolves that flag narrowly by using it as a "you're getting good at this" waypoint with no new authority, exactly matching its individual-contributor-depth reading in Progression Spec §2).
- **Required:** Manager is the ceiling for MVP — it is the first rank with real authority (Task assignment) per Organization Systems Spec §6, which is exactly the minimum needed to prove "Rank = Responsibility" once, concretely.
- **Post-MVP:** Director and above. These ranks' defining authority (budgets, hiring, Departments, Contracts) all depend on Organization Systems Spec features (§4–§5, §14) that are themselves Post-MVP (§7 below) — implementing the rank without the authority it's supposed to unlock would violate "Rank = Responsibility" rather than serve it.
- **Post-MVP:** Founder. SoT §7 itself frames Founder as reached after accumulating "sufficient wealth, reputation, influence, experience" — not a session-one outcome. Excluding it from MVP is not a scope cut against the vision, it's consistent with the vision's own framing of when Founder becomes available.

---

## 4. CORE JOB/TASK LOOP

- **Required:** Accept a Task → engage its decision point (§5) → receive an outcome-quality score → receive Personal Money + a Performance Rating update (Economy Spec §5.1, reused here) → Task returns to available pool or a new one appears.
- **Required:** Task completion and reward calculation must be **server-authoritative** (§15) — this is a security requirement, not a design one, but it belongs in the loop's definition because it's non-negotiable for MVP to be trustworthy.
- **Recommended:** 2–3 distinct Task *categories* available to choose from at Associate rank (e.g., differing in decision style, not in mechanical depth) — gives "GET A ROLE" a light flavor of choice without requiring Departments (Organization Systems Spec §4, Post-MVP) to exist.
- **Post-MVP:** Task→Project grouping (Organization Systems Spec §15) and Task assignment authority beyond the single Manager→report interaction in §1 — a full Project/Contract execution pipeline is not needed to prove the core loop once.

---

## 5. PROPOSAL/DECISION LOOP

This is the mechanic that answers the brief's explicit "MAKE DECISIONS" step — without it, the Task loop (§4) degenerates into a single-button clicker, which the governing test would reject outright.

- **Required:** Each Task presents at least one genuine choice point with visible risk/reward tradeoffs (e.g., a faster/riskier option vs. a slower/safer one, or a values-flavored choice affecting Reputation vs. Money differently) — the choice's outcome feeds the TaskQualityScore input to Performance (Economy Spec §5.1).
- **Required:** Decisions must have **legibly different outcomes**, not cosmetic flavor text with an identical result — a new player should be able to tell, after the fact, that their choice mattered.
- **Recommended:** Manager-level "review a report's Proposal" as an optional richer interaction once a Manager exists in the org — this is real player-to-player interaction (§9) but must **not** be required for an Associate to progress, since it would create a hard dependency on another specific player being online. **Fallback required if implemented:** an NPC/automatic review path when no Manager is available, to prevent solo/low-population sessions from soft-locking a player's progression.
- **Post-MVP:** Full Contract-bidding-and-negotiation decision trees (Economy Spec §5.2) — a single Task's decision point is a much smaller thing than bidding on a Contract, and that gap is intentional for MVP.

---

## 6. MONEY / INFLUENCE / REPUTATION / PERFORMANCE USAGE IN MVP

| Resource | MVP status | Rationale |
|---|---|---|
| **Personal Money** | **Required.** Earned from every completed Task; the primary visible reward number. | Directly serves "EARN RESOURCES." No mandatory sink is required in MVP — see Open Decisions §*OD-1* below. |
| **Performance** | **Required.** Rolling rating (Economy Spec §5.1) computed from decision-quality outcomes only, never time/logins. | This is the mechanical proof of "Performance > Time" — it must exist and must visibly drive promotion for the MVP to test the locked principle at all. |
| **Reputation** | **Required, but light.** A single visible trust number that rises with good decisions and gates promotion alongside Performance. No spending, no loan-rate/legal-credibility uses yet. | Needed because Progression Spec's promotion requirement shape (never Performance alone) depends on it; deeper uses (Economy Spec §6) are Post-MVP. |
| **Influence** | **Recommended, minimal — read-only.** A number that appears for the first time at first promotion (not before), consistent with SoT §12's stated learning progression ("Promotion: Learn influence/progression"), but it gates nothing and spends on nothing in MVP. | **⚑ FLAG:** cutting Influence entirely would contradict SoT §12's explicit sequencing (Influence is supposed to appear *at* first promotion, not later). Making it visible-but-inert at that exact moment honors the sequencing without adding gameplay complexity — flagged as the resolution to a real tension, not a silent cut. |
| **Org Capital / R&D / formal Contracts / Expenses** | **Post-MVP.** | These are Director+/organizational-management concepts (Organization Systems Spec §14) that don't exist in MVP's Associate→Manager scope; introducing them would violate progressive disclosure (SoT §12) for no session-one benefit. |

---

## 7. BASIC ORGANIZATION STRUCTURE REQUIRED FOR MVP

- **Required:** At least **one** pre-seeded organization players join at start — not player-founded. **⚑ FLAG:** SoT §17 locks "player-owned organizations" and "player-driven ecosystem" as core identity; a seeded starter org does not contradict this, since SoT §1's own loop begins "Start with nothing → build a career..." *before* "create their own organization" — MVP is testing the *first* leg of that loop, not replacing the later one. Flagged for confirmation rather than assumed silently correct.
- **Recommended:** **2–3** seeded organizations rather than exactly one, so "JOIN" includes a light, replayable choice ("which org do I join?") without requiring inter-org Contracts, competition, or player founding — purely a flavor/identity choice at this stage.
- **Required:** The org's internal hierarchy is capped at **Manager** for MVP purposes (§3) — Director and above do not need to exist as filled roles, even if the org's *data model* reserves space for them (§17).
- **Post-MVP:** Departments, Branches (Organization Systems Spec §4–§5), Organizational Capital as a player-managed budget, Organizational Reputation as a distinct tracked value from the org's aggregate member Reputation.

---

## 8. BASIC HIRING/MANAGEMENT REQUIRED FOR MVP

- **Required:** "Hiring" in MVP is just **joining** — a lightweight self-serve flow (pick an org, become an Associate), not the rank-scoped recruit/interview mechanic Organization Systems Spec §7 describes for Director+ hiring authority.
- **Required:** "Management" in MVP is the single Manager→report Task-assignment interaction described in §1 and §4 — this is the entire management surface needed to prove Rank = Responsibility once.
- **Post-MVP:** Firing, promotion/demotion approval workflows (Progression Spec §10.2 Model B), budget-request delegation (Organization Systems Spec §14), transfers between Departments/Branches (§10) — none of these have anything to attach to yet without Directors/Departments existing.

---

## 9. PLAYER-TO-PLAYER INTERACTION

- **Required:** Shared world presence — players in the same org/hub can see each other, reinforcing that this is a multiplayer economy, not a solo idle game.
- **Required:** The Manager→report Task-assignment interaction (§1, §4) as the one asymmetric, meaningful interaction MVP guarantees.
- **Recommended:** A simple visible roster or light leaderboard (e.g., top Performance this session, or just "who else is a Manager") — cheap to build, directly serves "replayable" via social comparison, without needing full Reputation-driven social systems.
- **Post-MVP:** Rival-org recruitment, Contract negotiation between orgs, alliances, elections, disputes (SoT §8) — none of these have the organizational depth (Departments, cross-org Contracts, governance) to attach to yet.

---

## 10. PROMOTION SYSTEM REQUIRED FOR MVP

A deliberately narrowed instance of Progression Specification §3.2:

- **Required:** Promotion requires **Performance rating ≥ threshold** AND **Reputation ≥ threshold**, evaluated together — never either alone, and never a time-elapsed component, directly preserving the locked "Performance > Time" principle.
- **Required:** **No Money requirement** for Associate→Specialist→Manager promotion, consistent with Progression Spec §3.2.5's recommendation.
- **Required evaluation model:** **Systemic/automatic** (Progression Spec §10.2 Model A) — once thresholds are met, promotion happens immediately, no superior-approval step. This is deliberately chosen over Model B (human-in-the-loop) for MVP specifically because a new player's first promotion must not be blockable by another player's absence or inaction — Model B is reserved for higher ranks in the full design and is Post-MVP here.
- **Post-MVP:** Numeric thresholds are explicitly **not** proposed here (per both subordinate specs' stance) — they must be set via playtesting during implementation (§23), not guessed in this document.
- **Post-MVP:** Demotion (Progression Spec §11) — not needed to prove the core loop's *upward* arc in a first session, and risks feeling punitive to a brand-new player before the loop has even landed. Explicitly deferred, not rejected.

---

## 11. BASIC UI/SCREENS REQUIRED

- **Required:** A persistent HUD showing Rank, Personal Money, and Performance.
- **Required:** A Task screen — view available Task(s), accept, engage the decision point (§5), see the outcome and reward.
- **Required:** A promotion notification/moment — this is the payoff beat for the entire loop and must be legible and satisfying, not a silent stat change.
- **Recommended:** A simple profile/org screen showing your rank, your org, and (post-first-promotion) a light Influence readout (§6).
- **Recommended:** The roster/leaderboard from §9, if implemented.
- **Post-MVP:** Budget dashboards, Contract-bidding screens, Department/Branch management UI, any legal/governance UI — none of the underlying systems exist yet.

---

## 12. BASIC MAP/WORLD REQUIREMENTS

- **Required:** A single hub location representing the seeded organization(s) — enough space for players to see each other and for a Task-acceptance point (kiosk/NPC/board) to exist.
- **Recommended:** If multiple seeded orgs exist (§7), visually distinct spaces for each, purely for identity/flavor, not for mechanical separation.
- **Post-MVP:** Multiple branches, a full city/map representing the long-term "world" vision (SoT §18 explicitly marks "exact map/city" as not yet locked) — completely out of scope for MVP, which needs only enough space to prove the loop.

---

## 13. SERVER/SESSION REQUIREMENTS

- **Required:** A standard Roblox server instance sized for meaningful but manageable multiplayer presence (exact player-count target is a technical/tuning decision, not proposed numerically here).
- **⚑ FLAG — significant scope decision:** MVP is proposed to treat each server's seeded organization(s) as **server-local**, not a single global cross-server organization. This is a substantial simplification relative to SoT's long-term "persistent player-driven corporate ecosystem" (§1) framing, which likely implies cross-server org persistence eventually. Flagging this explicitly as a deliberate MVP-scope decision, not an assumption the Source of Truth already settled — it should be confirmed before the technical architecture phase (§24) locks it in, since reversing it later is a real architecture cost, not just a content cut.
- **Post-MVP:** Any cross-server economy synchronization, global leaderboards spanning all servers, or a single persistent organization shared by every player in the game.

---

## 14. DATA PERSISTENCE REQUIREMENTS

- **Required:** Player-level persistence across sessions: Rank, Performance rating, Personal Money, Reputation, (post-first-promotion) Influence, and org membership. Without this, "WANT TO KEEP PLAYING" has nothing to come back to — this is a retention-critical requirement, not just a technical nicety.
- **Required:** Task-completion history sufficient to recompute/verify the rolling Performance average (Economy Spec §5.1) — at minimum a rolling window of recent outcome scores, not necessarily a full permanent log for MVP.
- **Recommended:** A lightweight action record (who did what, when) even at MVP scale, so the Organization Systems Spec's accountability approach (§20) has *something* to build forward from later, without MVP needing to build any investigation/reporting UI itself (§17).
- **Post-MVP:** Full organizational financial ledgers, Contract history, Department/Branch records — nothing to persist yet since those systems don't exist in MVP.

---

## 15. MINIMUM ANTI-EXPLOIT/SECURITY REQUIREMENTS

- **Required:** All Task completion and reward calculation (Money, Performance, Reputation deltas) must be **server-authoritative** — a client must never be able to report its own outcome or reward value.
- **Required:** Basic rate-limiting/cooldown on repeated identical Task completion, to blunt the simplest macro/spam exploitation of the Performance/Money loop — a narrow, MVP-scoped instance of Economy Spec §8.5 and Progression Spec §16's anti-boosting concerns.
- **Required:** Promotion threshold checks are server-side only; a client cannot self-report meeting a threshold.
- **Post-MVP:** Full anti-alt-account detection, transfer-tax/limit mechanics (Economy Spec §8.6), evaluator-diversity-weighted anti-collusion scoring (Progression Spec §16) — these matter most once player-to-player Money transfer and cross-player evaluation exist, neither of which is in MVP scope.

---

## 16. EXPLICITLY OUT OF SCOPE FOR MVP

Per the task's explicit instruction, none of the following are implemented, and none required a minimal placeholder to make the core loop work — each is cleanly separable:

- Founder system / player-founded organizations
- Organizational Capital as a player-managed budget; Departments; Branches
- R&D
- Formal Contract bidding/negotiation (beyond the single embedded Task decision point, §5)
- Mergers, Acquisitions, Buyouts
- Restructuring, Liquidation
- Courts / legal system
- Full governance / board mechanics
- Mega-corporation-stage systems
- Advanced political systems (strikes, elections, revolutions, alliances)
- Demotion / firing
- Rank Director and above
- Cross-server economy

No placeholder stub was found necessary for any of these to make the Required-for-MVP loop function — this is confirmed explicitly because the task called out the risk of unnecessary placeholders.

---

## 17. HOW FUTURE SYSTEMS ARE PRESERVED WITHOUT IMPLEMENTING THEM

- **Data model headroom, not feature stubs.** Player records should reserve fields for Influence (already partially surfaced, §6), and org records should be shaped so that adding Departments/Branches/Capital later (Organization Systems Spec §4–§5) is an *extension*, not a migration — but MVP does not build any UI or logic against those fields beyond what §6–§11 already specify.
- **The rank ladder is not truncated, only unpopulated.** Director-and-above ranks remain valid future design (Progression Spec §1) — MVP simply has no path to reach them yet, which is different from removing them from the design.
- **Accountability hooks stay minimal but present.** The lightweight action record (§14) is the same shape Organization Systems Spec §20 already described as a future-legal-system dependency — MVP's version is small, but not a different shape that would need rework.
- **Nothing here locks the eventual cross-server/global-org question (§13's flag) — it is deliberately left open, not answered by omission.**

---

## 18. MVP SUCCESS METRICS

Proposed, not locked — intended to validate whether the "20–30 minutes" governing test was actually met:

- **% of new players who reach first promotion (Associate → Manager) within a single session.**
- **% of new players who reach at least the Specialist waypoint within ~10 minutes** (a proxy for "Performance > Time" actually feeling fast for a skillful/attentive player).
- **Average Tasks completed per session** and **decision-point engagement** (did players read/consider the choice, or did they speed through it — hard to measure directly without telemetry, flagged as a Post-MVP instrumentation dependency, §22).
- **Day-1 / Day-2 return rate** — the most direct signal for "WANT TO KEEP PLAYING."
- **Qualitative signal (playtesting, not automated):** do players report that their in-Task decisions felt meaningful, or that outcomes felt arbitrary?

**Recommended, not Required for MVP itself:** building the telemetry pipeline to measure these automatically — the metrics should be *defined* now so implementation and playtesting can target them, but instrumentation work is Post-MVP scope, adjacent to but distinct from the core loop.

---

## 19. FIRST-PLAY-SESSION GOALS

- Player understands what a Task is and completes their first one within roughly the first 2–5 minutes.
- Player experiences at least one decision point that visibly affected their outcome before the 10-minute mark.
- Player sees their Performance/Money numbers move in response to their own choices, not passively.
- Player either reaches or can clearly see how close they are to their first promotion by session's end.

---

## 20. 20-MINUTE RETENTION GOAL

A skillful, attentive player should be able to reach **first promotion (to Manager)** within roughly 20–30 minutes of focused play — this is the concrete, testable expression of "Performance > Time" the whole MVP exists to validate. A player who does not quite reach it should still have completed enough Tasks to see visible, legible progress toward it (not a flat/unclear bar), and should have experienced at least one Manager→report interaction either as the assigner or the assignee if any Manager exists in their org/session.

**Exact numeric thresholds that make this true are not proposed here** — they are an implementation/playtesting output (§23), not a design-document guess.

---

## 21. RISKS

- **Threshold tuning risk.** If Performance/Reputation thresholds are set too high, the 20-minute goal (§20) fails outright; too low, and "Performance > Time" feels trivial rather than meaningful. This can only be resolved by playtesting, not by this document.
- **Decision-point content risk.** The entire "MAKE DECISIONS" step (§5) depends on Task decision content that this document does not design (that's a content-design task, §22) — if those choices end up feeling cosmetic, the MVP's central claim (decisions matter) fails regardless of how correctly the surrounding systems are built.
- **Population risk.** A single seeded org's Manager→report interaction (§1, §9) depends on another player being online and at the right rank — low-population sessions could leave a player never experiencing the interaction step at all. Needs a fallback (NPC substitute, or accepting that the interaction moment isn't guaranteed every session) — flagged as an open decision (§*OD-2*).
- **Scope-perception risk.** Marketing/expectation-setting for a game whose Source of Truth describes mega-corporations, courts, and revolutions, when the actual MVP is "complete Tasks at one company until you can assign a Task to someone else," needs care — not a design risk, but a communications one worth naming.
- **Server-locality risk (§13's flag).** If cross-server org persistence turns out to be required sooner than expected (e.g., players expect a truly global economy immediately), the server-local MVP decision could require early architecture rework.

---

## 22. DEPENDENCIES

- **Technical architecture decisions** not yet made: DataStore schema, server-authoritative validation approach, server-local vs. cross-server org model (§13's flag) — all belong to the next spec (§24), not this one.
- **Task/decision content design** — the actual decision prompts, their options, and what makes one choice "better" than another in-fiction is a content-design task this document deliberately does not attempt (it's downstream of this spec, not part of it).
- **Numeric threshold tuning** for Performance/Reputation promotion gates (§10) and Task rewards (§6) — requires either simulation or live playtesting once implementation exists; this document only fixes the *shape* of the requirement, not values.
- **Telemetry/instrumentation** for the success metrics in §18 — a Recommended, not Required, adjacent workstream.

---

## 23. IMPLEMENTATION PHASES

Proposed, sequenced to de-risk the parts most load-bearing for the core loop first:

1. **Phase 0 — Data & persistence skeleton.** Player record schema (Rank, Money, Performance, Reputation, Influence-stub, org membership) with headroom per §17; basic DataStore read/write.
2. **Phase 1 — Task loop, server-authoritative.** Accept → complete → server computes outcome/reward → Money and Performance update. No decision-point richness required yet — prove the pipe works first.
3. **Phase 2 — Decision points.** Add the genuine choice-point mechanic (§5) to Tasks; this is the phase most likely to need iteration since it's the crux of "fun," not just "functional."
4. **Phase 3 — Promotion.** Server-side threshold check (§10), promotion notification (§11), rank change persisted.
5. **Phase 4 — Manager interaction.** The single Task-assignment authority unlock (§1, §4, §9), including the no-Manager-available fallback (§21, §*OD-2*).
6. **Phase 5 — Onboarding & UI polish.** First-Task guidance (§2), HUD, profile/roster screens (§11).
7. **Phase 6 — Playtesting & threshold tuning.** Validate against §18's metrics and §20's retention goal; adjust numeric thresholds — this phase is expected to loop, not run once.

---

## 24. RECOMMENDED TECHNICAL ARCHITECTURE MILESTONE AFTER MVP APPROVAL

Per SoT §19's development sequence (Source of Truth → Game Design Specifications → Economy → Progression → Organization Systems → **MVP definition** → **Technical Architecture** → Implementation...), once this MVP definition is approved, the next task is:

**TECHNICAL ARCHITECTURE SPECIFICATION v0.1** — covering, at minimum: the DataStore schema for the Phase 0 player/org records (§14, §17), the server-authoritative validation approach for Task completion and promotion checks (§15), and — most importantly, per the flag in §13 — an explicit decision on server-local vs. cross-server organization persistence, since that choice shapes nearly everything downstream and this document deliberately left it open rather than assume it.

---

## OPEN DECISIONS

- **OD-1: Does Personal Money need a sink in MVP?** No spending mechanic is proposed for MVP (Founder seed capital, the only sink either subordinate spec names, is Post-MVP). Money may simply accumulate as a pure "score" for MVP's duration. Flagged as acceptable for a first session (a growing number is itself motivating) but worth confirming isn't expected to feel hollow by session's end.
- **OD-2: Fallback when no Manager is online** for the Manager→report interaction (§9, §21) — NPC stand-in, skip the interaction that session, or something else. Not resolved here.
- **OD-3: Exact number of seeded starting organizations** (one vs. two-to-three, §7) — a content/production-cost decision as much as a design one.
- **OD-4: Server-local vs. cross-server organization persistence** (§13) — the single highest-leverage open decision in this document; recommended to be resolved explicitly before or during the Technical Architecture spec (§24), not assumed.
- **OD-5: Whether the light Influence readout (§6) should exist at all in MVP**, versus fully deferring it — this document proposes "visible but inert" as the resolution to the SoT §12 sequencing tension, but that specific resolution is itself an open decision, not a lock.

---

## MVP READINESS ASSESSMENT

**Design-ready to begin Phase 0, not implementation-ready end-to-end.** This document fixes the *shape* of the smallest fun loop (one seeded org, Associate→Manager, Task-plus-decision-point, systemic promotion, one Manager interaction) and is deliberately aggressive about excluding everything else named in the four prior specs. What remains before full implementation can proceed:

- The single largest open item is **OD-4 (server-local vs. cross-server orgs)** — this is an architecture decision, not a content one, and reversing it late would be costly.
- Numeric thresholds (Performance/Reputation bars, Task rewards) are intentionally unset and must come from the Technical Architecture + playtesting phases, not from this document.
- Decision-point *content* (what the actual choices are) is explicitly out of this document's scope and is the biggest "will it actually be fun" unknown.

## EXACT NEXT TECHNICAL TASK

**Technical Architecture Specification v0.1** (§24) — starting with the server-local vs. cross-server organization decision (OD-4), then the DataStore schema and server-authoritative validation approach for the Phase 0–3 implementation phases in §23.

## RECOMMENDED IMPLEMENTATION ORDER

1. Technical Architecture Specification v0.1 (resolves OD-4 and the persistence/validation approach).
2. Implementation Phase 0–1 (data skeleton + server-authoritative Task loop, §23).
3. Decision-point content design pass (the actual Task choices) — in parallel with or immediately after Phase 1, since it gates Phase 2.
4. Implementation Phases 2–5 (§23).
5. Playtesting/tuning loop (Phase 6) against the success metrics (§18) and the 20-minute retention goal (§20) — expected to iterate before MVP is considered validated, not a one-time pass.

---

**END OF MVP DEFINITION v0.1**
