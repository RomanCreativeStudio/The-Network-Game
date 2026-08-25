# THE NETWORK — PROGRESSION SPECIFICATION v0.1

**Status:** DRAFT
**Version:** 0.1
**Date:** August 25, 2026
**Subordinate to:** [`source-of-truth.md`](./source-of-truth.md) (Game Design Foundation v0.1) — authoritative.
**Related, non-binding:** [`economy-specification-v0.1.md`](./economy-specification-v0.1.md) — its proposed formulas (Performance Rating, Contract Win Probability, etc.) are treated here as *candidate inputs*, not fixed requirements. Where this document uses one of them, that use is itself a proposal, not an inherited lock.

---

## AUTHORITY & SCOPE

This document defines the progression system named in the Source of Truth's development sequence (§19, step 4) and referenced throughout §4 (Progression Philosophy), §7 (Founder System), and §12 (Accessibility Philosophy). It does not implement gameplay code, does not lock any numeric threshold, and does not introduce features beyond what the Source of Truth already names or leaves open for this task.

Per the Authority Rule, any place this document's design pressure conflicts with — or would require quietly extending — a Source of Truth principle is marked **⚑ FLAG** rather than resolved silently.

---

## 1. CAREER / RANK STRUCTURE

The Source of Truth (§4) names a conceptual rank ladder and explicitly states rank *names* are not locked:

Associate → Specialist → Manager → Director → VP → Chief → Executive → CEO

This document adopts that ladder as-is for v0.1 (no renaming), and treats **Founder** as a *branch off* the ladder rather than a rung on it — consistent with SoT §7 ("This is NOT simply another promotion. The player leaves the existing hierarchy").

```
 Associate → Specialist → Manager → Director → VP → Chief → Executive → CEO
                                                                    │
                                                                    │ (branch, not a rung)
                                                                    ▼
                                                                 FOUNDER
                                                          (own organization,
                                                           own internal ladder)
```

A Founder's own organization may (eventually) run its own internal copy of this same ladder for its employees — that org-design detail is out of scope here and belongs to Organization Systems (SoT §19 step 5).

**⚑ FLAG:** SoT §4 lists the ladder as "conceptual" and explicitly not locked, including the *number* of ranks. This document keeps 8 ranks for continuity with the Economy Specification's references to "Associate," "Manager," "Executive," "Founder," but the count and names remain open for confirmation, not newly locked here.

---

## 2. PURPOSE AND RESPONSIBILITIES PER RANK

Directly derived from SoT §4's "conceptual responsibility" list, expanded only where SoT already implies detail (e.g., §6's list of organizational actions), never invented beyond it.

| Rank | Purpose (SoT §4) | Responsibilities Unlocked |
|---|---|---|
| **Associate** | Learn fundamentals | Complete individual tasks/proposals; earn Personal Money; build initial Performance and Reputation history. No authority over others or budgets. |
| **Specialist** | (Not detailed in SoT — a depth track between Associate and Manager) | Handle higher-complexity individual work; eligible for higher-value Contract assignment (individual contributor ceiling). **⚑ FLAG:** SoT names "Specialist" in the ladder (§4) but gives it no distinct purpose text, unlike every other rank. Purpose above is inferred narrowly from ladder position, not invented as new mechanics — flagged for confirmation. |
| **Manager** | Manage people/projects | Assign tasks to Associates/Specialists; see team Performance; request (not set) a department budget allocation. |
| **Director** | Manage departments | Set department-level budget requests (subordinate to SoT §6 "set budgets"); hire/fire within department; own department-level Contract commitments. |
| **VP** | Make strategic decisions | Approve/reject Director proposals; allocate budget across multiple departments; represent the org in cross-department negotiation. |
| **Chief** (e.g., CFO/COO-style) | Control major organizational functions | Own a company-wide function (e.g., finance, operations) end-to-end; direct authority over Org Capital allocation within that function. |
| **Executive** | Make organization-wide decisions | Company-wide strategic authority just short of final accountability; can initiate (not unilaterally complete) M&A/restructuring proposals. |
| **CEO** | Responsible for organizational performance | Final accountability for the org's Revenue/Expenses/Reputation; can approve M&A, restructuring, liquidation-avoidance actions; answerable under SoT §10 Accountability. |
| **Founder** | Build the organization itself | Full authority over a newly created org; sets its initial budgets, hires its first employees, bears full Accountability exposure (§10) from day one. |

---

## 3. PROMOTION REQUIREMENTS

### 3.1 Locked constraint (SoT §4, §17)

**Performance > Time**, and **Rank = Responsibility**. These are locked. Any promotion requirement that can be satisfied by elapsed time/login-streak alone, without a Performance component, violates SoT §4 directly and is out of bounds for this document to propose.

### 3.2 Proposed requirement shape (not locked)

Promotion to rank *N+1* is proposed to require **all** of the following, not any single one:

1. **Performance requirement** — a sustained Performance rating (per Economy Spec §3.5/§5.1, itself non-binding here) at or above a rank-appropriate bar, evaluated over a rolling window, not a single lucky task.
2. **Reputation requirement** — a minimum Reputation score, since higher rank means more people trust this player with more authority (SoT §5 — Reputation as "how trusted/respected").
3. **Influence requirement** — from Manager upward only. Lower individual-contributor ranks (Associate, Specialist) should not require Influence, since Influence per the Economy Spec is earned through visible, higher-stakes actions that individual contributors don't yet have access to. **This is a proposed design choice, not derived from a lock.**
4. **Proposal/task requirement** — a minimum count and/or quality bar of completed proposals/tasks/contracts appropriate to the rank, so promotion reflects demonstrated work, not just accumulated scores.
5. **Money requirement — proposed as absent for employee-track promotions.** Personal Money should not gate Associate→CEO promotion at all; wealth is not evidence of responsibility-readiness, and gating career promotion on money would silently reintroduce a pay-to-progress path the Source of Truth's multi-path philosophy (§13) does not endorse. **⚑ FLAG:** this is a recommendation, not a lock — SoT §18 leaves "exact rank requirements" fully open, so a future decision could still introduce one; this document flags that doing so should be treated as a deliberate design change, not a default.

### 3.3 Rank-relative bar, not absolute

Consistent with the Economy Specification's anti-inflation stance (its §8.1, non-binding but reused here as a reasonable candidate), Performance/Reputation/Influence bars should scale relative to the org's own current stage and to server-wide norms, not sit at fixed absolute numbers — otherwise a mega-corp's inflated internal metrics would make promotion trivial while a startup's modest numbers would make it near-impossible for equally skilled play.

---

## 4–7. PERFORMANCE, INFLUENCE, REPUTATION, MONEY REQUIREMENTS — DETAIL

*(Combined here since they share the same "requirement family" structure; §3.2 above states the shape, this section states rank-by-rank direction of travel.)*

| Rank | Performance | Influence | Reputation | Money |
|---|---|---|---|---|
| Associate → Specialist | Baseline consistency bar | None required | Baseline (no negative marks) | None |
| Specialist → Manager | Higher bar, individual-work-based | None required | Moderate | None |
| Manager → Director | Higher bar, now includes managed-team outcomes | Low bar (first Influence gate) | Moderate-high | None |
| Director → VP | High, sustained | Moderate | High | None |
| VP → Chief | High, sustained | Moderate-high | High | None |
| Chief → Executive | Very high, sustained | High | Very high | None |
| Executive → CEO | Very high, sustained + org-outcome-linked | Very high | Very high, org-wide track record | None |
| Any rank → **Founder** | High, sustained, *individual* track record (not delegated to a team) | High | High | **Yes — seed capital required** (see §12) |

No numeric values are proposed — SoT §18 marks exact requirements as unlocked, and the Economy Specification (§11.4) already flagged numeric thresholds as an explicit open decision this document should not resolve unilaterally either.

**Exact rank-by-rank aggregation formula** (how Performance/Reputation/Influence combine — weighted sum, all-must-clear-a-floor, etc.) is left as an **open decision** (§16 below); this document only fixes that all three must matter (never money alone, never time alone).

---

## 8. MONEY REQUIREMENTS WHERE APPROPRIATE

Employee-track promotion: **no** Money requirement (§3.2.5).

Money requirements are appropriate in exactly one place in this ladder: **Founder eligibility**, where Personal Money functions as seed capital for the new organization's initial Org Capital — this mirrors the Economy Specification's Founder Seed Requirement (its §5.8) and Locked Rule #4 ("Founding an organization... must consume/require multiple resource types... never money alone"). See §12.

---

## 9. PROPOSAL / TASK REQUIREMENTS

A "proposal" here follows SoT §12's phrase "learn basic work/proposals" for the First Job stage, and the Economy Specification's Contract mechanic. Proposed structure:

- Each rank has a minimum number of successfully completed proposals/tasks/Contracts appropriate to that rank's scope (individual task at Associate, department-level Contract ownership at Director, etc.).
- **Quality, not quantity, should dominate the bar** — a small number of high-quality, on-time, on-spec proposals should outweigh a large number of low-quality ones, consistent with SoT §4. This is why "Proposal/task requirement" is listed as a *distinct* requirement from raw Performance rating in §3.2 — Performance is a rolling quality score, while this requirement ensures a minimum *breadth* of demonstrated work exists for evaluators (human or system) to judge.
- Exact counts/thresholds: **open decision**, not proposed numerically here.

---

## 10. PROMOTION EVALUATION

### 10.1 What is being decided

Whether a candidate who *meets* the thresholds in §3–9 is actually promoted. Meeting thresholds should be necessary but not always sufficient — consistent with SoT §10 Accountability, a candidate under active investigation for misconduct should not be promotable even if their numbers clear the bar.

### 10.2 Proposed evaluation model (not locked)

Two non-exclusive evaluation paths are proposed, left open as an explicit **open decision** for which is default at which rank:

- **A. Systemic/automatic evaluation.** Once thresholds (§3.2) are met and no open misconduct investigation exists, the promotion becomes available (either auto-granted or unlocked for the player to claim). Appropriate for lower ranks (Associate → Manager) to keep entry accessible per SoT §12.
- **B. Human-in-the-loop evaluation.** A superior (Manager approving a Director promotion, VP approving a Chief promotion, etc.) must explicitly approve, even once thresholds are met — appropriate for higher ranks where "Rank = Responsibility" (§4) means a real organizational trust decision, and where SoT §10's Accountability concern (leaders promoting friends improperly) is most relevant.

**⚑ FLAG:** Model B introduces a specific mechanic (a superior's approval step) that is not explicitly named in the Source of Truth, though it is a direct, narrow implication of §10's own example ("A CEO repeatedly fires employees to promote friends" — which presupposes promotion is a decision a superior makes, not a pure system rollout). Flagging this inference rather than treating it as already locked.

### 10.3 Recorded for Accountability

Every promotion decision (who approved, what thresholds were met at the time) should be recorded, since SoT §10 requires that "the system can record relevant actions" for future investigation — this document treats that as a locked requirement inherited directly from §10's text, applied here to promotions specifically.

---

## 11. DEMOTION / REMOVAL

SoT does not name demotion explicitly, but §10 (Accountability) explicitly names "Position removal" as a potential consequence of proven misconduct, and §11 (Anti-Boredom) implies stage-appropriate problems can include setbacks. Proposed scope, kept narrow to avoid inventing an unrequested system:

- **Removal for proven misconduct** (SoT §10) — a direct, locked-in-principle consequence once the (not-yet-designed) legal/accountability enforcement system rules against a player.
- **Removal/demotion for sustained Performance collapse** — proposed, not locked. If a player's Performance rating falls sharply and persistently below the bar for their current rank, an org should have some mechanism to demote or reassign them, mirroring real organizational accountability and reinforcing "Rank = Responsibility" (a rank a player can no longer perform at is not being staffed responsibly). Exact mechanism (automatic vs. superior-initiated) is an **open decision**.
- **Voluntary departure** is always available and is not a "removal" — a player can leave a rank/org at will, which is a precondition for §13 (Founder departure) and generally consistent with player freedom (SoT §13).
- **What is *not* proposed:** no permanent, irreversible rank loss / server-wide blacklist mechanic — nothing in the Source of Truth supports a punishment that would contradict the Golden Rule (§16 — "impossible to completely finish" implies setbacks are recoverable, per the same reasoning applied to org Liquidation in the Economy Specification §10).

---

## 12. FOUNDER ELIGIBILITY

Directly inherits Economy Specification §5.8 and Locked Rule #4 (itself derived from SoT §7): Founder eligibility requires **multiple resource types simultaneously**, never Money alone.

**Proposed eligibility gate (shape, not numbers):**

```
FounderEligible =
      PersonalMoney ≥ SeedThreshold
  AND Reputation    ≥ RepThreshold
  AND Influence     ≥ InfThreshold
  AND PerformanceTrackRecord meets a sustained-consistency bar over a time window
      (not a single spike)
```

- **Rank floor:** proposed that Founder eligibility should not be reachable from Associate/Specialist — SoT §7 describes a player who has accumulated "sufficient wealth, reputation, influence, experience," which implies some accumulated career history, not a brand-new player converting Money alone into a company. Exact minimum rank (e.g., "Manager or above") is an **open decision**.
- **No numeric thresholds proposed** — consistent with Economy Specification §11.4 and SoT §18.
- **Founder eligibility is a gate, not an automatic transition** — reaching it makes founding *available*, it does not force it; a player can clear the bar and continue as an employee indefinitely, preserving SoT §13's multi-path freedom.

---

## 13. LEAVING AN ORGANIZATION TO FOUND ONE

SoT §7 is explicit: "The player leaves the existing hierarchy and becomes responsible for building something themselves." This document treats the following as directly locked from that sentence:

1. **Founding requires leaving** the current org's rank ladder — a Founder does not simultaneously hold their old employee rank at their old org while running a new one. (Whether they can remain a passive equity holder / investor in their old org is a distinct question — flagged below.)
2. **Personal resources carried forward:** Personal Money, Reputation (personal), Influence (personal), and Performance history all belong to the player, not the org, and are proposed to persist through the transition — consistent with Economy Specification §10's point that org failure doesn't erase personal history, applied symmetrically here to a voluntary departure.
3. **Org-level resources do not transfer:** the departing player's old org keeps its own Org Capital, org Reputation, and remaining employees; the new org starts from the Founder's personal contribution only (seed capital, §12), consistent with Economy Spec Locked Rule #1 (personal/org pools are separate).

**⚑ FLAG / Open decision:** Whether a departing Founder can retain equity/dividends in their former org (an investor relationship) is exactly the "equity/investor gameplay" item the Economy Specification already flagged as out-of-scope-until-confirmed (its §11.6). This document does not resolve it, and treats the default as **no retained relationship** unless a future decision adds one.

---

## 14. NEW-PLAYER PROGRESSION

Directly follows SoT §12's conceptual learning progression, applied specifically to what a new player must do to earn their first promotion:

- **First job (Associate):** the player interacts only with individual tasks/proposals and Personal Money. No Org Capital, no Influence-spending, no cross-org mechanics are surfaced (Economy Spec Locked Rule #7, applied here).
- **First promotion (→ Specialist/Manager):** Reputation and basic Influence concepts are introduced for the first time, matching SoT §12's "Promotion: Learn influence/progression."
- **Time-to-first-promotion should be short for a genuinely skillful new player** — this is the sharpest test of "Performance > Time" (SoT §4): if a new player cannot meaningfully progress within their first sessions purely on the strength of good decisions, the requirement design has failed the locked principle, regardless of what the exact numbers turn out to be.
- Onboarding UI/tutorial mechanics themselves are explicitly out of scope (SoT §18: "Exact tutorial... NOT YET LOCKED"; SoT §19 places tutorial/UX work later in the sequence).

---

## 15. FAST-SKILLFUL PROGRESSION VS. EXCESSIVE GRINDING

This is the central tension SoT §4 exists to resolve, and this document proposes the following concrete mechanisms (none locked, all consistent with the lock):

**Mechanisms that reward skill/speed:**
- Performance rating (Economy Spec §5.1) is a rolling *quality* average, structurally incapable of being improved by simply doing more low-quality work faster.
- No rank requirement in §3–9 includes a login-streak, playtime, or "time since last promotion" term.
- A skilled player who clears every threshold quickly should be promotable immediately — no artificial cooldown between promotions is proposed.

**Mechanisms that resist pure grinding:**
- Proposal/task requirements (§9) are capped by *quality-weighted* counting, not raw repetition — a system should be able to discount repeated near-identical low-effort tasks (mirroring Economy Spec §8.5's anti-macro diminishing-returns proposal, non-binding but reused as a candidate here).
- Reputation and Influence gates (§3.2) require *outcomes*, not attempts — grinding failed or low-value attempts does not accumulate these.

**⚑ FLAG — genuine tension, not resolved here:** a rolling-window Performance requirement (§3.2.1) inherently takes *some* minimum elapsed time to demonstrate "sustained" consistency — one perfect task cannot mathematically fill a rolling average window instantly. This is a deliberate, small amount of time-gating in service of *proving* consistency (distinct from *requiring* grind), but it is worth naming explicitly as the one place time enters the model at all, so it doesn't silently expand into a bigger grind requirement during implementation.

---

## 16. ANTI-BOOSTING / ABUSE SAFEGUARDS

Scoped narrowly to progression-specific abuse vectors; general economic exploit safeguards belong to the Economy Specification (its §8) and are not repeated here except where progression-specific.

- **Collusive task/proposal inflation** (e.g., two players trading trivial "approvals" back and forth to inflate each other's Proposal/Performance counts) — proposed countermeasure: proposal quality scoring should weight *evaluator diversity* (many different evaluators/clients) over raw count, and same-pair repeated transactions should be discounted, mirroring the diminishing-returns principle already proposed in Economy Spec §8.5.
- **Alt-account boosting** (a high-rank alt manufacturing easy wins for a low-rank main) — a progression-specific instance of the Economy Spec's general alt-account risk (its §12). No new mechanic is invented here; this is flagged as depending on the same technical safeguard the Economy Spec already deferred to the architecture phase.
- **Superior-approval abuse** (a Director promoting an unqualified friend, per SoT §10's own example) — this is exactly the scenario §10 exists to catch. Promotion records (§10.3 above) are the progression system's contribution to making that investigable; the investigation/enforcement mechanism itself is the not-yet-designed legal/accountability system (SoT §9, §10) and is out of scope here.
- **Threshold gaming via rank-relative bars** (§3.3) — if bars scale relative to org/server norms, a player could theoretically found or join an artificially weak org to face an artificially low bar. Flagged as an **open risk** (§18) rather than solved — likely needs a server-wide floor beneath the relative bar, which is a numeric-tuning decision out of scope for this document.

---

## 17. HOW PROGRESSION DIFFERS BY STAGE

| Stage | Progression shape |
|---|---|
| **Employee** (Associate → CEO track, working inside someone else's org) | Ladder-based, thresholds per §3–9, evaluated per §10, demotion risk per §11. |
| **Executive** (VP/Chief/Executive/CEO specifically) | Same ladder, but Proposal/task requirements shift from individual output to organization-outcome ownership (a VP's "proposal" is a strategic decision whose Contract/Revenue outcome is attributable to them), and Accountability exposure (§10.3, SoT §10) is highest here since these ranks hold the most delegable authority. |
| **Founder** | Leaves the ladder entirely (§13); progression becomes organizational (does their org survive Startup → Growing → Major → Mega-Corp, per Economy Spec §9) rather than personal-rank-based. A Founder's *personal* Reputation/Influence/Performance still exist and still matter (e.g., for re-entering the employee ladder if their org fails, §11's "no permanent removal" principle), but they are no longer chasing a "next rank." |
| **Startup org** | Internal promotion thresholds (if the Founder chooses to run an internal ladder for early hires) should be lightweight — a 3-person startup cannot meaningfully support an 8-rank hierarchy. Exact scaling is an **open decision**, but the principle (thresholds relative to org stage, §3.3) already implies startup-stage bars should be reachable, not major-corp-scale. |
| **Mega-corporation** | Same ladder, but §10.2's Model B (human-in-the-loop approval) becomes more load-bearing — at mega-corp scale, automatic/systemic promotion (Model A) risks becoming a rubber stamp exactly where SoT §10's misconduct concern is sharpest. This is a proposed emphasis, not a new mechanic. |

---

## 18. HOW PROGRESSION SUPPORTS MULTIPLE VALID PLAYER PATHS

Directly serving SoT §13 (Player Freedom) and §2 (Core Player Fantasy):

- The ladder is not the only progression axis. A player pursuing the **Lawyer/Judge** fantasy (§2) or the **Rival** fantasy would progress along tracks this document does not define (legal system progression is explicitly out of scope — SoT §9 is not yet locked) — this document only guarantees the *employee/executive/founder* axis does not become mandatory scaffolding those other paths must pass through.
- **Founder eligibility does not require reaching CEO.** §12's gate is expressed as rank-floor-plus-resources, not "must be CEO first" — a Manager with strong enough personal Reputation/Influence/Performance and seed capital can found, preserving the Entrepreneur fantasy (§2) as a genuinely earlier off-ramp than climbing the entire ladder.
- **No rank is a prerequisite for social/political play** (elections, alliances, courts — SoT §8, §9) beyond whatever Influence/Reputation those systems themselves require — this document does not gate them behind employee rank, since SoT names them as a separate (Social) pillar (§15).

---

## 19. HOW PROGRESSION AVOIDS MAKING CEO THE PERMANENT ENDGAME

This is the direct progression-system contribution to SoT §11 (Anti-Boredom) and §16 (Golden Rule):

- **CEO is a responsibility state, not a victory state.** Per §2 of this document, CEO's purpose is "responsible for organizational performance" — an ongoing accountability, not a completed achievement. The Org's own economic pressure (Economy Spec §9: Major Org → Mega-Corp introduces *harder* problems, not easier ones) means reaching CEO increases exposure to Accountability risk (§10), competitive/legal challenge (SoT §8, §9), and liquidation risk (Economy Spec §10) rather than removing them.
- **Founder branches off CEO, and Founder-of-a-mega-corp faces the same open-ended problem ladder** (Startup → ... → Mega-Corp → Crisis → Rebuild, SoT §14) — there is no rank or state above CEO/Founder that represents "finished."
- **Multiple paths remain available after CEO.** A player who reaches CEO can still pursue Founder (leaving to start their own org, §13), can still engage the Social pillar (politics, courts, rivalries), and remains subject to demotion/removal (§11) and organizational failure (Economy Spec §10) — the ladder does not lock in permanent status once climbed.
- **⚑ FLAG — genuinely open:** this document proposes CEO is not locked-in permanent status, but does not yet define what *voluntary* post-CEO goals look like beyond "found something new" or "engage other pillars." SoT §14's later stages (Crisis, Restructure/Liquidation, Rebuild) are the intended source of ongoing CEO-stage problems, but those systems are explicitly not yet designed (SoT §18) — flagged as a dependency (§20 below), not solved here.

---

## 20. COMPATIBILITY WITH FUTURE MERGERS, ACQUISITIONS, COURTS, GOVERNANCE, LIQUIDATION, ORGANIZATIONAL CONFLICT

None of these systems are designed by this document (all remain "NOT YET LOCKED" per SoT §18). This section only checks that nothing proposed above would need to be *undone* when they arrive:

- **Mergers/Acquisitions:** because org-level Reputation/Capital are already modeled as distinct from personal Reputation/Money (Economy Spec Locked Rule #1, reused throughout this document), an org merging or being acquired should not require rewriting any individual's personal progression state — only org-level records change ownership. No conflict anticipated.
- **Courts/Legal system:** this document's Accountability hooks (§10.3 promotion records, §11 misconduct-driven removal) are deliberately built as *hooks pointing at* the not-yet-built legal system, not a parallel enforcement mechanism — when the legal system is speced, it should be able to consume these records rather than progression needing rework. Flagged in Economy Spec §12 already; restated here as it directly affects §10–11.
- **Governance** (elections, board conflicts, leadership removal — SoT §8): this document's demotion/removal section (§11) intentionally does not define *who* can trigger removal beyond the misconduct case, leaving room for a future governance system (e.g., a board vote, an election loss) to become an additional removal trigger without contradicting anything locked here.
- **Liquidation** (Economy Spec §10): already handled symmetrically — §13.2 of this document (personal resources persist through voluntary org departure) uses the same reasoning as Economy Spec §10 (personal resources persist through involuntary org failure). A Founder whose org liquidates keeps their personal Reputation/Performance/Money and can re-enter the employee ladder or found again, consistent with SoT §14's "REBUILD."
- **Organizational conflict** (strikes, protests, revolutions — SoT §8): not addressed by this document at all; flagged as a clean dependency gap rather than an invented placeholder mechanic.

---

## SUMMARY: LOCKED / PROPOSED / OPEN / RISKS / DEPENDENCIES

### Locked (inherited directly from Source of Truth, restated as progression constraints)
- Performance > Time; no promotion requirement may be satisfiable by elapsed time/login-streak alone. (§4)
- Rank = Responsibility; each rank must unlock real responsibility, not just a label. (§4)
- Founder eligibility requires multiple resource types simultaneously, never Money alone; founding is a departure from the hierarchy, not a promotion within it. (§7)
- All promotion/removal-relevant actions should be recorded for future Accountability investigation. (§10)
- New players are shown only basic work/Personal Money mechanics first; Influence/Reputation/org mechanics are disclosed progressively by rank. (§12)
- No path (employee ladder, Founder, or otherwise) is the single correct or mandatory route; the progression system must not force players onto one axis. (§13)
- CEO/Founder status must not function as a permanent, problem-free endgame. (§11, §16)
- Personal resources (Money, Reputation, Performance, Influence) persist through org-level change (departure or failure) — the player, not just the org, must be able to rebuild. (§14, §16)

### Proposed (this document's design choices — not locked, open to revision)
- 8-rank ladder retained as-is from SoT's conceptual list; Founder modeled as a branch, not a rung.
- Promotion requires Performance + Reputation + (Manager-and-above) Influence + Proposal/task history, evaluated together — never Money for employee-track ranks.
- Rank-relative (not fixed-absolute) requirement bars.
- Two-model evaluation (systemic for lower ranks, human-approval for higher ranks), with all decisions recorded.
- Demotion permitted for proven misconduct (locked) and proposed, not locked, for sustained Performance collapse.
- Founder eligibility gate requires a minimum rank floor (unspecified) in addition to the resource thresholds.
- Anti-boosting countermeasures modeled on evaluator-diversity weighting and discounting repeated same-pair transactions.

### Open decisions (require explicit design sign-off before numeric/mechanical finalization)
1. Whether "Specialist" gets a distinct defined purpose or is folded into Associate/Manager (§2).
2. All numeric thresholds for every requirement at every rank (§3–9, §12) — none proposed here.
3. Exact aggregation formula for combining Performance/Reputation/Influence into a single promotion decision (§3.2).
4. Default evaluation model (systemic vs. human-approval) per rank (§10.2).
5. Mechanism for Performance-collapse demotion: automatic vs. superior-initiated (§11).
6. Minimum rank floor for Founder eligibility (§12).
7. Whether a departing Founder can retain equity/dividends in their former org (§13) — mirrors Economy Spec's open equity-gameplay question.
8. Internal ladder scaling for very small (startup-stage) organizations (§17).

### Risks
- Rolling-window Performance requirements introduce a small, structurally necessary amount of time-to-prove-consistency — must not be allowed to expand into disguised grind during implementation (§15).
- Rank-relative requirement bars could be gamed by joining/founding a deliberately weak org to face an artificially low bar (§16) — no countermeasure proposed yet.
- Human-in-the-loop promotion approval (§10.2 Model B) is a direct enabler of the exact misconduct scenario SoT §10 warns about (a superior promoting friends) — it is *necessary* for Accountability to have a hook, but is itself a risk surface until the legal/enforcement system exists to check it.
- This document assumes the Economy Specification's Performance/Reputation/Influence formulas as candidate inputs; if those formulas change materially, several proposed requirement shapes here (§3.2, §15) would need re-validation.
- Ten-plus interacting requirement types (rank × 4 requirement families) is a lot of surface area to keep genuinely simple-on-the-surface for new players (SoT §12) — mitigated by §14's progressive disclosure, but unverified without a UX/tutorial pass.

### Dependencies
- **Legal/Accountability enforcement system** (SoT §9, §10) — this document's misconduct-driven removal (§11) and Accountability recording (§10.3) are hooks pointing at a system that does not yet exist.
- **Governance system** (SoT §8) — this document leaves room for governance-triggered removal but does not define it.
- **Organization Systems spec** (SoT §19 step 5) — owns department budget-setting detail (§2's Director/VP responsibilities reference it), internal org ladders (§17), and M&A mechanics that §20 above checks for compatibility only.
- **Economy Specification numeric tuning** — several requirement shapes here reuse Economy Spec formulas as non-binding candidates; both documents' numbers need to be tuned together, not independently.

---

## IMPLEMENTATION-READINESS ASSESSMENT

**Not implementation-ready**, by design, consistent with SoT §19's layered development rule. What this document *does* establish:

- A stable rank/responsibility structure and a consistent requirement *shape* (multi-resource, never time-alone, never money-alone for employees) that Organization Systems and later specs can build against.
- A clear, load-bearing distinction between "Locked" (must not be violated by any future numeric design) and "Proposed" (expected to be tuned/revised).
- Explicit hooks into systems that don't exist yet (legal/accountability, governance, org systems) rather than silently inventing simplified stand-ins for them.

What's missing before implementation could reasonably begin:
- All numeric thresholds (open decision #2) — requires either designer judgment calls or simulation/playtesting data, per SoT §19 steps 10–11.
- The aggregation formula (open decision #3) and evaluation model default (open decision #4) — both are prerequisites for even a minimal promotion-check function.
- Organization Systems spec, since department budgets, internal org ladders, and hiring/firing authority (§2) are referenced here but owned there.

## RECOMMENDED NEXT TASK

Per the Source of Truth's development sequence (§19: Source of Truth → Game Design Specifications → Economy → Progression → **Organization Systems** → MVP...), the next task should be:

**ORGANIZATION SYSTEMS SPECIFICATION v0.1** — defining departments, branches, budget-setting authority (referenced but not owned by §2 of this document), hiring/firing mechanics, and the internal structure a Founder's new organization actually has — which this document assumed exists but deliberately did not define.

---

**END OF PROGRESSION SPECIFICATION v0.1**
