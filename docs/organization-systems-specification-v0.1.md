# THE NETWORK — ORGANIZATION SYSTEMS SPECIFICATION v0.1

**Status:** DRAFT
**Version:** 0.1
**Date:** August 25, 2026
**Subordinate to:** [`source-of-truth.md`](./source-of-truth.md) (Game Design Foundation v0.1) — authoritative.
**Related, non-binding:** [`economy-specification-v0.1.md`](./economy-specification-v0.1.md) and [`progression-specification-v0.1.md`](./progression-specification-v0.1.md) — both are proposed specifications, not locks. Where this document builds on either, it says so explicitly; where either would be *contradicted* by something proposed here, that is flagged rather than silently resolved.

---

## AUTHORITY & SCOPE

This document defines the organization system named in the Source of Truth's development sequence (§19, step 5) and referenced throughout §6 (Organizations), §7 (Founder System), §8 (Corporate Conflict), §9 (Legal System), and §10 (Accountability). It does not implement gameplay code, does not lock any numeric threshold, and does not invent features beyond what the Source of Truth already names or leaves open.

Two locked principles get special attention throughout, per the task's explicit instruction:

- **Rank = Responsibility** (SoT §4): every rank defined here must carry real, exercisable authority (over people, budget, or decisions) — never just a bigger number beside a name.
- **Performance > Time** (SoT §4): nothing in the org structure may make advancement — personal or organizational — a function of elapsed time rather than demonstrated capability.

---

## 1. ORGANIZATION CREATION / FOUNDING

**Locked (inherited):** Founding is a departure from the employee hierarchy, not a promotion within it, and requires multiple resource types simultaneously — never Money alone (SoT §7; Economy Spec Locked Rule #4; Progression Spec §12).

**Proposed creation flow:**

1. A player clears the `FounderEligible` gate (Progression Spec §12: rank floor + Money + Reputation + Influence + sustained Performance track record — no numbers proposed).
2. The player declares the new organization's identity (§2 below).
3. The player commits Personal Money as seed capital, which becomes the new org's starting Organizational Capital (Economy Spec §5.8, Locked Rule #1 — personal and org pools remain structurally separate from the moment of creation).
4. The Founder becomes the org's initial and sole authority holder — there is no hierarchy to inherit; department/branch structure (§4, §5) is built up from nothing, consistent with §21 (Startup Organizations) below.

**⚑ FLAG — open decision:** Is "Founder" a permanent title distinct from "CEO" that the founding player always holds (even if they later delegate day-to-day authority to a hired CEO), or does founding simply install the player *as* CEO with no separate Founder status? SoT §7 treats Founder as a defining identity ("Build the organization itself"), and Progression Spec §2 gives Founder and CEO distinct purposes, which suggests they are not the same role — but neither document resolves whether a Founder can ever cease being the org's top authority while the org still exists. Left open; matters directly for §13 (CEO/Executive authority) and §19 (Board/Governance foundations).

---

## 2. ORGANIZATION IDENTITY

SoT does not specify what data defines an organization beyond it being player-created and player-competed-over (§6, §8). Proposed minimal identity, kept intentionally light to avoid inventing unrequested systems (branding, logos, etc. are UI/technical concerns, out of scope per SoT §18):

- **Name** (player-chosen, presumably subject to the same moderation/uniqueness rules as any other player-facing text — a technical/platform concern, out of scope here).
- **Organizational Reputation** (Economy Spec §3.4) — tracked distinctly from any individual member's personal Reputation, per Economy Spec's open aggregation question (its §11.3).
- **Organizational Capital** (treasury) — per Economy Spec Locked Rule #1.
- **Stage** — Startup / Growing / Major / Mega-Corp, per Economy Spec §9 and Progression Spec §17. Not a separate resource; a descriptive bucket derived from size/Revenue/Capital for the purposes of scaling rules elsewhere in this document (§21–24).

**⚑ FLAG — open decision:** Whether organizations need an "industry/sector" classification (so Contract-bidding, §16, can be scoped to relevant orgs) is implied by SoT §8's "compete for contracts" but never stated explicitly. Not proposed as a locked feature here; flagged as a dependency for whoever specs the Contract/marketplace system in more detail.

---

## 3. ORGANIZATIONAL HIERARCHY

**Locked (inherited):** Organizations have a rank hierarchy players rise through (SoT §6); rank must equal responsibility, not just a label (SoT §4).

**Proposed structure:** this document adopts the Progression Specification's ladder (Associate → Specialist → Manager → Director → VP → Chief → Executive → CEO, with Founder as a branch, Progression Spec §1) as the org's internal hierarchy, and proposes it as a **strict single-superior tree** for v0.1: every employee has exactly one direct superior, and authority flows down that single line. This is proposed for accessibility (SoT §12 — a matrix/dual-reporting structure is harder to explain to a new player) and is explicitly **not** a lock; a matrix structure remains an open option for later stages (§30).

```
                          FOUNDER (§1, ⚑ authority relative to CEO open)
                             │
                            CEO
                             │
                         Executive(s)
                             │
                          Chief(s)
                        /          \
                      VP            VP
                    /    \        /    \
              Director  Director Director Director
                 │          │        │        │
              Manager(s) Manager(s) ...      ...
                 │
           Specialist/Associate(s)
```

Each layer's authority (over people, budget, decisions) is defined per-domain in §6–§14 below, so that rank is never *only* a position on this chart.

---

## 4. DEPARTMENTS

**Locked (inherited):** Leaders can "create departments" and "set budgets" (SoT §6).

**Proposed definition:** a Department is a functional subdivision of an organization — a named container with its own budget allocation (§14), its own employees, and a Director as its head (Progression Spec §2: "Director: Manage departments"). Departments are generic containers in v0.1; this document does not propose fixed department types (e.g., "Sales," "Engineering") since SoT names no specific business domains and doing so would invent scope.

A department may itself contain Managers, each supervising Associates/Specialists, per the hierarchy tree in §3.

**Open decision:** minimum/maximum department count per org stage; whether departments can be merged/split/renamed after creation (a restructuring action, likely belonging to §26/M&A-adjacent mechanics rather than this document).

---

## 5. BRANCHES

**Locked (inherited):** Leaders can "open branches" (SoT §6).

**Proposed definition:** a Branch is a separate operational unit of the organization, distinct from a Department. Where a Department is a *functional* slice (what work is done), a Branch is proposed as an *operational/locational* slice (where/how it's done) — consistent with Economy Spec §5.4's `BranchUpkeep` term, which already models branches as individually cost-bearing units.

**⚑ FLAG — open decision (relationship between Departments and Branches):** neither SoT nor the Economy/Progression specs state whether Branches contain their own internal Department structure (large-org pattern: each branch has its own Sales/Ops/etc.) or exist in parallel to a single company-wide Department structure (all Departments are company-wide; Branches are just additional revenue-generating locations with their own upkeep and a local lead). This document does not resolve it — it is flagged as a structural decision that materially affects §12 (Branch Authority) and should be made explicitly, not inferred by an implementer.

**Proposed gating:** opening a new branch is an org-growth action that should require sufficient Organizational Capital (to fund `BranchUpkeep`, Economy Spec §5.4) — consistent with Locked Rule #5 (costs scale with organizational stage). Whether it additionally requires an Organizational Performance or Reputation threshold (§17) is an open decision.

---

## 6. ROLES AND RESPONSIBILITIES

This document adopts the Progression Specification's rank-purpose table (its §2) as-is and does not restate it in full. It adds only the organization-structural authority each rank exercises *within a specific org* (as opposed to Progression's org-agnostic description of what each rank generally does):

| Rank | Organizational authority (this document) |
|---|---|
| Associate / Specialist | No authority over others; executes assigned Tasks (§15) within a Department. |
| Manager | Assigns Tasks to their direct reports; recommends (not finalizes) hiring/firing within their team, subject to Director approval (§7, §8). |
| Director | Heads a Department (§4); finalizes hiring/firing within it; requests department budget (§14); owns department-level Contract commitments (§16). |
| VP | Oversees multiple Departments and/or a Branch (§5); allocates budget across the Departments/Branches under them; approves Director-level hiring/firing escalations. |
| Chief | Owns a company-wide function (e.g., finance, operations — not named further, to avoid inventing business-domain specifics) end-to-end; direct Organizational Capital allocation authority within that function. |
| Executive | Organization-wide strategic authority; can initiate (not unilaterally complete) restructuring/M&A-adjacent proposals (§26). |
| CEO | Final accountability for org-wide Revenue/Expenses/Reputation (§17); approves company-wide budget strategy, large Contracts, and restructuring actions. |
| Founder | Full original authority over the org they created (§1); scope relative to a later-appointed CEO is the open decision flagged in §1. |

This table is the direct mechanism by which **Rank = Responsibility** is kept true structurally: every rank above Associate/Specialist is defined by a specific, exercisable authority (hire/fire scope, budget scope, or decision scope) — not by a numeric stat increase.

---

## 7. HIRING

**Locked (inherited):** Organizations can "recruit players" (SoT §6); rival-org recruitment is explicitly named as a form of corporate conflict (SoT §8: "recruit employees from rivals").

**Proposed rules:**
- Hiring authority is rank-scoped per §6: a Manager can recommend hires into their own team; a Director finalizes hires into their Department; VP+ can hire across Departments/Branches they oversee.
- A new hire consumes no Organizational Capital up front in this document's model beyond the ongoing Payroll obligation it creates (Economy Spec §5.4) — no separate "hiring cost" resource is proposed, to avoid inventing a new sink not named in either subordinate spec.
- **Poaching** (recruiting a rival org's employee) is explicitly named as legitimate conflict (SoT §8) and is not restricted by this document beyond whatever the target employee's own agency allows (an employee can always leave voluntarily, per Progression Spec §11).

**Open decision:** the exact discovery/application mechanic (posted job board vs. direct invite vs. scouting) is a UX/technical concern out of scope here.

---

## 8. FIRING

**Locked (inherited):** Organizations can "fire... employees" (SoT §6); firing is explicitly the example vector SoT §10 (Accountability) uses to illustrate power abuse ("A CEO repeatedly fires employees to promote friends").

**Proposed rules:**
- Firing authority mirrors hiring authority in §7 (rank-scoped: a superior can remove someone within their direct authority scope, per the hierarchy tree in §3).
- Every firing action is recorded (actor, target, stated reason, timestamp) — directly required by SoT §10 ("The system can record relevant actions") and by this document's general accountability approach (§20).
- **No approval gate or cooldown is proposed to prevent firing.** SoT §10's own stated principle is "Risk/reward gameplay is preferred over simply eliminating every form of bad behavior" — so this document does not propose blocking unfair firing outright, only making it visible and consequence-bearing if misconduct is later proven by the (not-yet-designed) accountability/legal system.

---

## 9. PROMOTIONS / DEMOTIONS

This document does not redefine promotion/demotion mechanics — those belong to the Progression Specification (its §3–§11) and are treated as subordinate-but-adopted here. This section only maps Progression Spec §10.2's "Model B" (human-in-the-loop approval) onto the org hierarchy defined in §3:

**Proposed mapping:** the "superior" whose approval a promotion/demotion requires (where Model B applies) is the candidate's direct superior on the hierarchy tree — e.g., a Director's promotion to VP requires approval from the VP/Chief layer above them, per Progression Spec §10.2's rationale that senior-rank promotions warrant a real organizational trust decision, not a pure system rollout.

This is a direct, narrow extension of Progression Spec §10.2 into an org-structural context — not a new mechanic.

---

## 10. PERSONNEL MANAGEMENT

**Proposed scope** (broader than hiring/firing/promotion, covering day-to-day people-management named implicitly by SoT §6's "manage employees"):

- **Task assignment** — Managers assign Tasks (§15) to their direct reports.
- **Transfers** — moving an employee between Departments or Branches. Proposed authority: VP+ (since a transfer crosses Department/Branch boundaries, which is exactly the scope VP-level oversight covers per §6).
- **Performance visibility** — a superior can see their direct/indirect reports' Performance rating (Economy Spec §3.5) as an input to Task assignment, promotion recommendations (§9), and — where misconduct is suspected — a report (§20).

No new resource or mechanic is proposed here beyond organizing existing rank-scoped authority from §6–§9 under one heading.

---

## 11. DEPARTMENT AUTHORITY

Consolidating §4 and §6–§10 into a single authority boundary for Departments:

**A Director can, within their own Department, unilaterally:**
- Assign Tasks/Projects (§15) to their reports.
- Hire/fire within the Department (§7, §8).
- Spend within their approved Department budget (§14).
- Commit the Department to a Department-scoped Contract (§16).

**A Director cannot, without escalation to VP+:**
- Reallocate budget between Departments.
- Hire/fire outside their own Department.
- Commit the organization to a cross-Department or organization-defining Contract.

This boundary is the concrete expression of "Rank = Responsibility" at the Department level: a Director's rank is meaningful because it comes with a bounded-but-real sphere of unilateral authority, not because it unlocks a bigger number.

---

## 12. BRANCH AUTHORITY

Mirrors §11's shape, applied to Branches, with the caveat from §5's flagged open decision: if Branches contain their own internal Department structure, Branch authority is layered on top of Department authority (a Branch lead oversees multiple Directors within their Branch, similar to a VP); if Branches are parallel/flat, a Branch lead's authority is closer to a Director's, scoped to their Branch's local budget and personnel instead of a functional Department.

**This document does not resolve which model applies** (§5 flag) — both authority shapes are described here so that whichever structural decision is made, the authority-scoping principle (bounded-but-real unilateral authority, escalation beyond it) still applies.

---

## 13. CEO / EXECUTIVE AUTHORITY

**Locked (inherited):** CEO is "responsible for organizational performance" (SoT §4); Executive "makes organization-wide decisions" (SoT §4).

**Proposed authority:**
- CEO/Founder (relationship per §1's open flag) hold final authority over org-wide budget strategy (§14), large/organization-defining Contracts (§16), and can approve restructuring or M&A-adjacent proposals initiated by Executives (§6).
- CEO/Executive can **override** a lower-level decision (a Director's Department-scoped call, a VP's cross-Department allocation) — but per this document's general accountability approach (§20), an override should be recorded distinctly from a routine in-scope decision, since an override is exactly the kind of concentrated-authority action SoT §10 exists to make investigable.
- **This authority is bounded by Organizational Capital reality**, not just by title: a CEO cannot spend Organizational Capital the org does not have (Economy Spec §5.5–§5.7) — authority is over allocation, not over the org's actual financial constraints.

---

## 14. BUDGETS AND SPENDING AUTHORITY

This is the section that most directly operationalizes "Rank = Responsibility," so it is treated in full detail.

**Locked (inherited):** Organizational Capital and Personal Money are separate pools with no implicit access (Economy Spec Locked Rule #1, itself derived from SoT §10's Accountability requirement); leaders "set budgets" (SoT §6).

**Proposed budget hierarchy:**

```
CEO / Founder
   sets overall Organizational Capital allocation strategy
        │
        ▼
Chiefs / VPs
   allocate budget across the Departments/Branches they oversee
        │
        ▼
Directors
   spend within their Department's approved budget;
   request increases upward
        │
        ▼
Managers
   request spend from their Director for team-level needs
        │
        ▼
Associates / Specialists
   no independent spending authority
```

- **Discretionary spending ceiling scales with rank.** This is the proposed mechanism that makes budget authority a genuine, *measurable* form of responsibility rather than a flavor label: a Manager's unilateral spend ceiling is small; a Director's is larger but bounded to their Department; a Chief's spans a whole company-wide function; CEO/Founder is bounded only by total Organizational Capital.
- **Any spend beyond a rank's ceiling requires escalation** (recorded request → approval by the next layer up), mirroring §11's Department Authority boundary.
- **R&D allocation** (Economy Spec §3.6, §5.6) is proposed as a Chief/CEO-level budget category specifically, since it is a company-wide capability investment rather than a Department-local operating expense — though a Department could still request R&D-adjacent investment upward, same as any other budget increase request.

**No numeric ceilings are proposed** — consistent with both subordinate specs' stance that exact thresholds are open decisions (Economy Spec §11.4, Progression Spec's open-decisions list).

---

## 15. PROJECTS / TASKS

**Locked (inherited):** Organizations can "run projects" (SoT §6).

**Proposed distinction from Contracts (§16):** a **Task** is the smallest unit of individual work (what an Associate/Specialist executes, feeding their Performance rating per Economy Spec §5.1). A **Project** is a Manager/Director-level grouping of Tasks toward a goal, which may or may not correspond to a specific external Contract (an internal efficiency initiative, e.g., is a Project without a Contract; a won Contract typically becomes a Project internally, per §16).

This keeps Task/Project as the internal execution layer and Contract as the external economic transaction layer (Economy Spec §3.9), rather than conflating the two.

---

## 16. CONTRACTS

This document adopts the Economy Specification's Contract lifecycle and formulas (its §3.9, §5.2–§5.3) as non-binding candidate mechanics and adds only organizational authority over them:

- **Bidding/accepting a Contract** is rank-scoped by Contract size/scope: Director-level for Department-scoped Contracts, VP+ for cross-Department or large Contracts, CEO/Founder for organization-defining Contracts (mirroring the escalation pattern in §11 and §14).
- **Execution** of an accepted Contract becomes a Project (§15) owned by the Department/Branch that won it, staffed via normal Task assignment (§10).
- **Contract failure/breach** (Economy Spec §3.9) reflects on both the responsible Department/Branch's and the org's Reputation (§2), and — per §20 — is recordable if breach resulted from a rank-authority abuse (e.g., a Director committing to a Contract deliberately understaffed to sabotage a rival internal team) rather than ordinary business risk.

---

## 17. ORGANIZATION PERFORMANCE

**⚑ FLAG — inferred, not explicitly named as a formal metric anywhere in SoT/Economy/Progression**, though strongly implied by SoT §4's "CEO: Responsible for organizational performance." Proposed as a distinct construct from individual player Performance (Economy Spec §3.5):

**Proposed composition (illustrative, not locked):** Organizational Performance aggregates from Revenue-to-Expense ratio trend (Economy Spec §5.5), Contract success/failure rate (§16), and Organizational Reputation trend (§2) over a rolling window — mirroring the shape of the individual Performance Rating formula (Economy Spec §5.1) at the org level.

**Proposed uses:**
- An input (alongside Organizational Capital) to gating org-growth actions like opening a new Branch (§5) or entering higher Contract tiers (Economy Spec §5.6).
- The primary basis on which CEO/Executive accountability (SoT §10, §4) is actually evaluated — "responsible for organizational performance" needs *something* measurable to be responsible for, and this is this document's proposal for what that is.

No numeric formula or threshold is locked; this section exists to name the construct and flag that it is an inference, not a citation, from the subordinate documents.

---

## 18. INTERNAL ORGANIZATION POLITICS

SoT §8 names leadership disputes, protests, strikes, internal political movements, board conflicts, elections, leadership removal, and revolutions as intended future content, under the explicit principle: **"Drama should emerge from systems, not primarily from scripted events."**

**This document does not design any of those mechanics** — none of them appear in SoT §17's locked list, and inventing specific implementations (a strike system, an election system) here would violate the task's instruction not to invent features as locked requirements.

**What this document does provide** is the systemic substrate SoT §8 says drama should emerge *from*: the rank-scoped authority (§6, §11–§13), budget hierarchy (§14), and hiring/firing/accountability structures (§7, §8, §20) defined above are exactly the kind of concrete, asymmetric-power systems that could produce emergent political conflict (a Director denied a promotion by a VP has a real, structural grievance; a CEO who fires too many Directors for cause creates a visible, recorded pattern investigable under §20). This document flags itself as the **dependency** a future Governance/Social Systems spec would build on, rather than proposing politics mechanics directly.

---

## 19. BOARD / GOVERNANCE FOUNDATIONS

SoT §8 mentions "board conflicts" and "leadership removal," implying some governance body exists conceptually, but neither its composition nor its powers are named anywhere in the Source of Truth (not in the locked list, §17, and implicitly covered by §18's "not yet locked" mechanics generally).

**Proposed minimal foundation, explicitly not a full design:**
- At Major/Mega-Corp stage (§23–§24), a board-like check on CEO/Founder authority is a plausible future addition — consistent with real-world corporate structure and with the "Mega-Corp: how do I maintain control?" problem SoT §11 (Anti-Boredom) explicitly wants to remain live at that stage.
- **This document proposes no composition, voting mechanic, or removal power for a board.** It only notes that if/when such a system is designed, it would need to interact with the CEO/Executive authority defined in §13 and the Founder-authority question flagged in §1 — both are called out specifically so a future Governance spec does not have to guess how they were intended to connect.

**Recommended as a dependency, not resolved here** (see §29, §32).

---

## 20. EMPLOYEE PROTECTIONS / ACCOUNTABILITY FOUNDATIONS

**Locked (inherited, directly from SoT §10):**
- The system can record relevant actions (hiring, firing, promotion/demotion, budget spend, Contract commitments — this document's contribution is naming *which* org actions qualify as "relevant" for recording, per §7–§9, §14, §16).
- Players can report potential misconduct.
- An investigation may occur.
- Proven misconduct's potential consequences include: Reputation loss, wealth penalties, Influence loss, position removal, organizational consequences, other appropriate penalties.
- The exact enforcement system is **NOT YET LOCKED** — this document does not design it.
- **Principle:** risk/reward gameplay is preferred over eliminating every form of bad behavior — so this document proposes **transparency and recordability**, not prevention, as its protection mechanism (consistent with §8 Firing's explicit non-restriction).

**This document's proposed contribution (scoped narrowly to what it can define without inventing the legal system):**
- A recorded action log entry requires, at minimum: actor (who), action type (hire/fire/promotion/demotion/budget spend/Contract commitment/override), target (who/what it affected), and timestamp. No "reason" field is required to be truthful or complete — the log records that an action happened and by whom, not a verified justification; adjudicating *whether* a stated reason was legitimate is exactly the not-yet-designed legal system's job (SoT §9).
- Reportability: any org member (or, per SoT §10's phrasing "players can report," possibly any player) can flag a recorded action for investigation — this document does not decide who has standing to report, that belongs to the legal system spec.

---

## 21. STARTUP ORGANIZATIONS

Per Economy Spec §9 ("How do I survive?") and Progression Spec §17:

- **Structural shape:** typically no Departments, no Branches — a flat team of the Founder plus a handful of direct hires (Associates/Specialists, possibly one Manager).
- **Budget hierarchy (§14) is close to trivial**: Founder holds essentially all spending authority since there is no intermediate layer to delegate to yet.
- **Hiring/firing (§7–§8) is Founder-only** in practice, since no Director/Manager layer exists.
- Internal politics (§18) and governance (§19) are not yet meaningfully present — there's no board, no competing internal factions, consistent with SoT §11's "survive" framing rather than "maintain control."

---

## 22. GROWING ORGANIZATIONS

Per Economy Spec §9 ("How do I expand?"):

- **First Departments and/or first Branch appear** — this is the stage at which §4/§5's structures first become load-bearing.
- **First Manager/Director hires** — the Founder begins delegating hiring/firing/budget authority per §7, §8, §14, which is the first real test of the authority-scoping model, since it's the first point a superior *other than the Founder* exists.
- Budget delegation (§14) becomes meaningful for the first time: the Founder must decide how much discretionary spend to actually grant a new Director, rather than holding all authority personally.

---

## 23. LARGE ORGANIZATIONS

Per Economy Spec §9 ("How do I compete?"):

- **Full hierarchy active**: Director/VP/Chief layers populated, multiple Departments and Branches operating in parallel.
- Budget authority (§14) is meaningfully distributed — Directors and VPs are making real allocation decisions, not just executing Founder intent.
- **Contract competition intensifies** (§16): Large orgs bid against rival orgs directly (Economy Spec §9's "PvP-adjacent" framing), raising the stakes of Contract-authority decisions in §16.
- This is the stage at which internal politics (§18) first has real structural fuel — enough hierarchy layers exist for genuine competing interests (a Director passed over for VP, a Chief whose function is underfunded relative to another).

---

## 24. MEGA-CORPORATIONS

Per Economy Spec §9 ("How do I maintain control?") and SoT §11:

- Every layer of §6's hierarchy is populated at scale; Executive layer is fully active.
- Budget authority (§14) at this scale carries the highest accountability exposure (§20) — large discretionary ceilings are exactly what SoT §10's misconduct concern targets.
- **Governance foundations (§19) become most relevant here** — this is the stage where a board-like check is most plausible, per SoT §11's "maintain control" framing implying the CEO/Founder's authority is under the most pressure to remain legitimate.
- Superlinear cost scaling (Economy Spec §5.4) means Department/Branch budget requests (§14) are proportionally harder to satisfy even with a large treasury — the org-structural expression of "problems change, don't disappear" (SoT §11, Locked Rule #5).

---

## 25. ORGANIZATION FAILURE FOUNDATIONS

Adopts Economy Specification §10 (debt, Liquidation trigger, world persists through org failure per SoT §14) and adds org-structural detail:

- On Liquidation, the hierarchy (§3) dissolves: Director/VP/Chief/Executive/CEO roles cease to exist for that org.
- Employees (all ranks) are released back into the ecosystem — available for hiring by other organizations, consistent with SoT §14's "the world should continue even when individual organizations fail."
- Departments/Branches cease operating; any Contracts-in-progress (§16) become available for other orgs to pick up, per Economy Spec §10.
- **Personal resources persist**: every employee, including the former Founder/CEO, keeps their Personal Money, personal Reputation, personal Influence, and Performance history (Economy Spec §10, Progression Spec §13.2) — only the org-level Reputation and Organizational Capital are lost with the org.

---

## 26. COMPATIBILITY WITH FUTURE MERGERS, ACQUISITIONS, BUYOUTS, RESTRUCTURING, LIQUIDATION AND COURTS

None of these systems are designed by this document (all remain "NOT YET LOCKED" per SoT §18). This section checks that nothing proposed above would need structural rework when they arrive:

- **Mergers/Acquisitions/Buyouts:** because Departments (§4) and Branches (§5) are already modeled as sub-units with their own budget/personnel/authority scope, a partial acquisition (one Department or Branch changing ownership rather than the whole org) is structurally representable without redesigning the hierarchy model — though the actual transfer mechanic is undesigned.
- **Restructuring:** the strict single-superior tree (§3) makes reassigning reporting lines a well-defined operation (change one edge in the tree) rather than requiring a matrix-structure rework — this is one practical argument (not a lock) for §3's proposed tree-over-matrix choice.
- **Liquidation:** already handled in §25, symmetric with Economy Spec §10.
- **Courts (SoT §9):** would consume this document's action-recording foundation (§20) the same way Progression Spec flagged for promotion records — evidence for a Contract dispute (§16), employment dispute (§7, §8), or abuse-of-authority case (§13's override recording, §14's budget escalation records) all already have a natural source in this document's proposed logs, without needing new recording mechanics invented specifically for courts.

**⚑ FLAG:** this compatibility check is a design *intent*, not a guarantee — because none of M&A, restructuring, liquidation-in-detail, or courts are actually specified yet, this section cannot confirm compatibility, only the absence of an obvious structural conflict as currently understood.

---

## 27. ANTI-ABUSE / ANTI-FAVORITISM SAFEGUARDS

Directly targeting SoT §10's own example (a CEO firing employees to promote friends):

- **Pattern visibility, not prevention** (per §20's principle): the action log (§20) makes a disproportionate pattern — one superior repeatedly firing and rehiring/promoting a small clique — visible and reportable, without the system needing to pre-judge intent.
- **Budget abuse is structurally constrained, not just logged**: because Organizational Capital access requires an explicit, recorded transaction (Economy Spec Locked Rule #1), a Director cannot silently divert Department budget to personal use — any transfer to a Personal Money balance is, by construction, a distinct, recorded, and therefore investigable transaction type, not a side-channel.
- **Escalation ceilings limit blast radius**: because spending and hiring/firing authority are bounded by rank scope (§11, §14) rather than unlimited at any single layer, a single abusive actor's damage is capped by their position in the hierarchy — a rogue Manager can damage their team; a rogue CEO's damage is larger but was already the position SoT §10's example specifically worries about, and is exactly where §20's recording is most load-bearing.
- **Anti-boosting via hiring is a live risk this document does not fully solve**: nothing here prevents a Director from hiring a real-world associate/friend who is *technically* qualified. This document does not propose merit-verification mechanics beyond what Progression Spec already defines (Performance/Reputation/Influence thresholds must still be met to *promote* that hire later, per Progression Spec §3) — hiring itself is not gated by merit in this document, only later advancement is. Flagged as a risk (§31), not solved.

---

## 28. HOW ORGANIZATIONS REMAIN FUN FOR BOTH EMPLOYEES AND EXECUTIVES

Directly serving SoT §2 (both Employee and Executive/Leader fantasies are named as equally valid) and §11 (Anti-Boredom):

- **Employees** get meaningful agency through Task/Project execution (§15) feeding directly into Performance (Progression Spec §3–§9) and real promotion — the loop stays "my work quality matters" without requiring an Associate to understand Departments, budgets, or Contracts they aren't yet exposed to (SoT §12 progressive disclosure, reused from Progression Spec §14).
- **Executives** get meaningful agency through budget authority that scales with rank (§14) and hiring/firing/Contract-commitment authority (§7, §8, §16) that is real and consequential — not cosmetic. This is the structural answer to SoT §4's warning against "a larger number beside the player's name": a VP's discretionary budget ceiling and cross-Department authority is a *materially different kind of play* than a Manager's, not just a bigger stat.
- **Both remain subject to the same accountability substrate** (§20), which keeps executive power from feeling consequence-free (serving the Rival/Lawyer fantasies too, §2) while not preventing employees from experiencing real risk/reward in their own scope (a Director's Department-scoped Contract failure, §16, is a real setback, not a padded one).

---

## 29. DEPENDENCIES ON ECONOMY + PROGRESSION

This document is not self-contained; it explicitly reuses (as non-binding candidates, per both subordinate specs' own stance):

- **From Economy Specification:** the Personal Money / Organizational Capital separation (Locked Rule #1, foundational to §1, §14, §20, §27 here); Contract lifecycle and win-probability formulas (§3.9, §5.2–§5.3, reused in §16); Revenue/Expense/BranchUpkeep formulas (§5.4–§5.5, reused in §5, §14, §24); R&D-as-allocation model (§3.6, §5.6, reused in §14); debt/Liquidation model (§5.7, §10, reused in §25).
- **From Progression Specification:** the rank ladder and per-rank purpose (§1, §2, reused in §3, §6); promotion evaluation models (§10.2, reused in §9); Founder eligibility gate (§12, reused in §1); demotion/removal principles (§11, reused in §8); the employee/executive/founder stage-differentiation logic (§17, reused throughout §21–§24).

**Numeric tuning is not owned by this document** and must happen jointly across all three specs (Economy, Progression, Organization Systems), not independently — restating the same caution both subordinate documents already raised about each other.

---

## 30. OPEN DECISIONS

1. Whether "Founder" is a permanent title distinct from CEO, and what authority relationship holds if a Founder ever delegates day-to-day CEO-style authority to someone else (§1, §13).
2. Whether organizations need an industry/sector classification for Contract scoping (§2).
3. Whether the org hierarchy should ever become a matrix (dual-reporting) structure rather than the strict single-superior tree proposed here (§3).
4. Minimum/maximum Department count per org stage; whether Departments can be merged/split/renamed post-creation (§4).
5. The relationship between Departments and Branches — nested (each Branch has its own Departments) or parallel (Branches are flat, Departments are company-wide) (§5, §12).
6. Numeric budget ceilings per rank (§14) — entirely unset by design.
7. Whether opening a Branch requires an Organizational Performance/Reputation threshold in addition to Organizational Capital (§5).
8. The exact formula/composition of Organizational Performance (§17) — proposed as a construct here, not as a formula.
9. Who has standing to report misconduct (any player vs. org members only) (§20).
10. Composition, powers, and voting mechanics of any future board/governance body (§19) — deliberately left fully open.
11. The exact hiring discovery/application mechanic (job board, direct invite, scouting) (§7).

---

## 31. RISKS

- **Hiring is not merit-gated in this document.** A superior can hire a friend/alt who is technically eligible; only later *promotion* is merit-gated by Progression Spec. This leaves a favoritism vector at the hiring stage that §27's safeguards only make visible after the fact, not prevent.
- **Strict single-superior tree (§3) is a proposed simplification**, not a lock — if a matrix structure turns out to be needed for realistic large-org play, several authority-scoping sections (§11–§14) would need rework, though §26 argues the tree model is at least not an obvious blocker for future M&A/restructuring.
- **Organizational Performance (§17) is this document's own inference**, not a cited requirement — if a future decision defines it differently (or decides it shouldn't exist as a formal metric), several dependent proposals here (Branch-opening gates §5, CEO accountability basis §13) would need to be revisited.
- **Escalation-based authority (§11, §14) could become a bottleneck at Mega-Corp scale** if not paired with efficient delegation — SoT §11's "how do I maintain control" problem is supposed to be hard, but an over-centralized approval chain risks becoming *tedious* rather than *meaningfully hard*, which would cut against SoT §12's "fun/accessible" intent. Needs playtesting, not resolvable on paper.
- **Governance (§19) is the least-specified section of this document by design** — it exists mainly to avoid leaving CEO/Founder authority totally unchecked at scale, but provides no actual mechanism, so the Mega-Corp "maintain control" problem (SoT §11) currently has no answer beyond "costs are higher." This is flagged as the most significant open gap for the next governance-focused spec to close.
- **Action-log recording (§20, §27) assumes future systems (courts, investigations) will consume it correctly.** If the eventual legal system's evidentiary needs differ from what's logged here, retrofitting could be costly. Not resolvable until SoT §9 is specced.

---

## 32. IMPLEMENTATION-READINESS ASSESSMENT & RECOMMENDED NEXT TASK

**Not implementation-ready**, by design, consistent with SoT §19's layered development rule. What this document establishes:

- A concrete, rank-scoped authority model (hiring, firing, budget, Contract-commitment) that makes "Rank = Responsibility" mechanically true rather than aspirational at every layer from Manager to CEO/Founder.
- A structural separation (Department vs. Branch, Task/Project vs. Contract) that keeps the org model legible without inventing unrequested business-domain detail.
- Explicit, narrow hooks into systems that don't exist yet (governance/board, legal/courts, M&A) rather than silently inventing simplified stand-ins for them — each hook names exactly what the future system would need to plug into.
- A stage-differentiated shape (Startup → Mega-Corp) that keeps organizational problems changing rather than just scaling in magnitude, per SoT §11.

What's missing before implementation could reasonably begin:
- All numeric thresholds (budget ceilings, Branch-opening gates, Organizational Performance formula) — open decisions §30 items 6–8.
- The Founder-vs-CEO authority question (§30 item 1), which several other sections (§13, §19) depend on.
- A Governance/Social Systems spec to give the Mega-Corp "maintain control" problem an actual mechanism (currently just economic pressure, per §31).

Per the Source of Truth's development sequence (§19: Source of Truth → Game Design Specifications → Economy → Progression → Organization systems → **MVP definition** → Technical architecture → Implementation...), the three core system specs now exist. The next task should be:

**MVP DEFINITION v0.1** — selecting a focused, fun core loop from everything specced so far (SoT §19: "The MVP must contain a focused, fun core loop rather than dozens of incomplete systems"), explicitly deciding which pieces of the Economy, Progression, and Organization Systems specs are in scope for a first playable slice (likely: Associate-through-Manager progression, a single Startup-stage organization, basic Contracts) and which are deliberately deferred (Founder/mega-corp play, governance, M&A, legal system) — rather than writing another full systems spec before any of this has been validated as fun.

---

**END OF ORGANIZATION SYSTEMS SPECIFICATION v0.1**
