# THE NETWORK — ECONOMY SPECIFICATION v0.1

**Status:** DRAFT
**Version:** 0.1
**Date:** August 25, 2026
**Subordinate to:** [`source-of-truth.md`](./source-of-truth.md) (Game Design Foundation v0.1)

---

## AUTHORITY & SCOPE

This document defines how the foundational resources named in Source of Truth §5 and §20 interact economically. It is **not** a technical spec, **not** an implementation plan, and does not introduce gameplay features beyond what the Source of Truth already names or explicitly leaves open for this task (§20).

Per Source of Truth §18, none of the formulas below are locked. Per §17, the *principles* they must obey are locked. Where a design choice below could conflict with a locked principle, it is marked **⚑ FLAG** rather than resolved silently, per the Authority Rule.

Everything in "Locked Rules" is a direct derivation of an already-locked Source of Truth principle. Everything in "Proposed Formulas" is illustrative and subject to playtesting — numbers are placeholders to demonstrate shape and scaling behavior, not tuned values.

---

## 1. RESOURCE INVENTORY

| Resource | Scope | Type | Status per SoT |
|---|---|---|---|
| Personal Money | Player | Stock (balance) | Named §5 as "Money/Wealth" |
| Organizational Capital | Org | Stock (treasury) | Implied §6 ("set budgets"), named §20 |
| Influence | Player + Org | Stock, non-tradeable | Named §5, §20 |
| Reputation | Player + Org | Stock, non-tradeable | Named §5, §20 |
| Performance | Player | Rolling score, not a spendable currency | Named §5, §20 |
| R&D | Org | Stock (invested capital → capability) | Named §20 only — new to §5's list; **⚑ FLAG (see §12)** |
| Revenue | Org | Flow (inbound) | Named §20 only |
| Expenses | Org | Flow (outbound) | Named §20 only |
| Contracts | Org (+ Player, indirectly) | Transaction unit | Named §6 ("negotiate contracts"), §20 |
| Connections | Player | Stock, non-tradeable | Named §5; not in §20's list — carried forward here as it gates Contract access (§6) |
| Career/Rank | Player | Ordinal state | Named §4, §5 |

Two currencies only are directly spendable/transferable: **Personal Money** and **Organizational Capital**. Influence, Reputation, Performance, Connections, and R&D are **non-tradeable progression resources** — they can be earned and consumed by systems, but never bought with money or traded between players. This is the mechanism that keeps SoT §4's "Performance > Time" and the multi-path philosophy (§13) intact: status must be earned through play, not purchased.

---

## 2. LOCKED RULES (derived from Source of Truth §17)

These are not new decisions — they are the Source of Truth's locked principles restated as economic constraints. If a future formula violates one of these, that formula is wrong, not the rule.

1. **Personal Money and Organizational Capital are separate pools with no implicit access.** An employee, manager, or even a CEO cannot spend org capital as personal money without an explicit, recorded transaction (salary, bonus, dividend, reimbursement). This is required by §10 (Accountability) — misuse of organizational funds must be a detectable, reportable action, which is only possible if the pools are structurally distinct.
2. **No resource may be earned primarily through time-elapsed.** Passive/idle income (dividends, branch upkeep-adjusted revenue, etc.) must always be a *function of prior performance and decisions*, never of raw clock time or AFK presence. (§4)
3. **Rank advancement must gate on responsibility-appropriate resources, not raw wealth alone.** A player cannot buy their way to Director; Money may be a precondition (e.g., Founder seed capital) but never a sufficient one — Performance and Reputation thresholds are always co-requisites. (§4, §7)
4. **Founding an organization is a state transition, not a purchase.** It must consume/require multiple resource types (Money + Reputation + Influence + a performance track record), never money alone, or it collapses into "buy your way to Founder." (§7)
5. **Costs and complexity must scale with organizational stage**, so that startup, growing, major, and mega-corp stages face materially different economic problems rather than the same problem at a bigger number. (§11)
6. **The system must be able to record and penalize misuse of org authority via economic consequences** (fines, wealth penalties, position removal economically enforced) even though the legal/enforcement system itself is not yet designed. (§10)
7. **New players are not shown the full resource graph on day one.** Personal Money and basic Contracts are the only economic concepts a brand-new Associate needs; Org Capital, R&D, Influence-spending, and cross-org mechanics are disclosed progressively as rank rises. (§12)
8. **The world persists through organizational failure.** Liquidation must be a state an org enters and exits the ecosystem from — not a state that corrupts or halts the server. (§14)

---

## 3. DEFINITIONS

### 3.1 Personal Money
Liquid, player-owned currency. Fully liquid — can be spent, saved, or used as Founder seed capital.

### 3.2 Organizational Capital
Liquid, org-owned treasury. Not owned by any individual; access is role-gated (e.g., only budget-holders for their department, only Founder/CEO for company-wide allocation — exact governance model is an **open decision**, §14).

### 3.3 Influence
A non-tradeable score representing a player's or org's ability to affect outcomes beyond direct economic transactions — winning contested contracts, contested elections/leadership, hostile-takeover attempts, lobbying. Influence is **earned only through visible, verifiable actions** (successful high-stakes contracts, legal victories, elections won, mergers led) — never purchased directly with money. This keeps political/social power tied to demonstrated capability, consistent with §13's principle that no path (including "just be rich") is automatically the winning path.

### 3.4 Reputation
A non-tradeable trust score, tracked separately for players and for organizations. Reputation is **earned/lost via outcomes**, not spent — it is read by other systems (contract eligibility, loan terms, hiring, Founder eligibility, legal credibility) as a gate or multiplier, never drawn down as a resource pool.

### 3.5 Performance
A rolling, decision-quality-based score — *not* a currency, never directly spent. It exists to answer "how good are this player's recent decisions/work," and feeds Reputation gain, bonus pay, promotion eligibility, and Contract quality multipliers. Performance is computed from outcomes of discrete actions (tasks, contracts, decisions), explicitly excluding hours-logged or login-streak inputs, to satisfy SoT §4.

### 3.6 R&D
An organizational investment resource: a portion of Org Capital deliberately allocated (not spent on immediate operations) that converts over time into **Capability**, i.e. unlocked contract tiers, reduced expense ratios, or new product/service lines. R&D is what lets an org escape competing purely on price/headcount and instead compete on capability — this is the mechanic that differentiates "Growing Org" from "Major Org" in SoT §11.

**⚑ FLAG:** R&D is named explicitly in SoT §20 as something this spec must define, but it does not appear in §5's foundational resource list. Treating it as an organizational sub-mechanism of Organizational Capital (an allocation, not a new currency) keeps it inside the already-locked resource model rather than inventing a seventh tradeable currency. Flagging this interpretation for confirmation rather than assuming it silently.

### 3.7 Revenue
A flow, not a stock: the inbound Organizational Capital generated per period, primarily from completed Contracts, plus any passive business income from owned branches/products.

### 3.8 Expenses
A flow: outbound Organizational Capital per period — payroll, branch upkeep, R&D allocation, taxes/fees, debt interest.

### 3.9 Contracts
The atomic unit of organizational economic activity — a scoped exchange of work-for-Revenue between an org and a client (NPC-issued or another player-org). Contracts are the primary vehicle through which Performance, Reputation, and Influence convert into Revenue.

### 3.10 Connections
A non-tradeable resource representing relationship access — which Contracts, job offers, or introductions a player can even see/reach before Reputation/Influence determine whether they win them. Functions as a *visibility/access filter* layered before the Contract-bidding formulas in §5.

---

## 4. RESOURCE FLOW MAP

```
                 ┌─────────────┐
                 │ PERFORMANCE │ (rolling score, decision-quality based)
                 └──────┬──────┘
                         │ feeds
                         ▼
   ┌───────────┐   ┌───────────────┐   ┌────────────┐
   │CONNECTIONS│──▶│   CONTRACTS   │◀──│ INFLUENCE  │
   └───────────┘   │ (bid → win →  │   └────────────┘
                    │  execute →    │         ▲
                    │  complete)    │         │ raises/lowers
                    └───────┬───────┘         │
                            │ generates        │
                            ▼                  │
                     ┌─────────────┐           │
                     │   REVENUE   │           │
                     └──────┬──────┘           │
                            ▼                   │
                 ┌─────────────────────┐        │
                 │ ORGANIZATIONAL      │        │
                 │ CAPITAL             │        │
                 └──────┬──────────────┘        │
           ┌────────────┼───────────────┐       │
           ▼            ▼               ▼       │
     ┌──────────┐ ┌───────────┐   ┌──────────┐  │
     │ EXPENSES │ │    R&D    │   │ PAYOUTS  │  │
     │ (payroll,│ │(allocation│   │(salary,  │  │
     │ upkeep,  │ │→capability│   │ bonus,   │  │
     │ debt,tax)│ │ unlocks)  │   │ dividend)│  │
     └──────────┘ └───────────┘   └────┬─────┘  │
                                         ▼         │
                                  ┌─────────────┐  │
                                  │PERSONAL MONEY│  │
                                  └──────┬───────┘  │
                                         │ seeds     │
                                         ▼           │
                                  ┌─────────────┐    │
                                  │  FOUNDING   │────┘
                                  │ (new org)   │  (+ Reputation
                                  └─────────────┘   + Performance track record,
                                                      per Locked Rule #4)

     Contract outcomes (win/lose, complete/breach) also feed back into
     REPUTATION and INFLUENCE (both directions — success raises,
     failure/misconduct lowers, tying back to §10 Accountability).
```

Reputation and Influence are drawn separately at both the **player** level and the **org** level; an org's Reputation is not simply the average of its employees', but is materially influenced by leadership decisions and Contract track record — exact aggregation is an open decision (§9).

---

## 5. PROPOSED FORMULAS (illustrative — not locked)

All constants below are placeholders to illustrate *shape* (linear vs. diminishing vs. scaling-with-size), not tuned values. Real values require simulation/playtesting per SoT §19 step 10-11.

**5.1 Performance Rating (exponential moving average, rewards consistency over grind)**

```
PR_t = α · TaskQualityScore_t + (1 − α) · PR_(t−1)
```
where `α ≈ 0.2–0.3`. `TaskQualityScore` is computed per completed task/contract/decision from outcome quality (on-time, on-spec, client/peer rating), never from time spent or login frequency — this is the direct enforcement of Locked Rule #2.

**5.2 Contract Win Probability**

```
P(win) = clamp(
    BaseChance
  + w1 · NormalizedReputation
  + w2 · NormalizedInfluence
  + w3 · BidCompetitiveness
  − w4 · RivalStrength
  , 0, 1)
```
`NormalizedReputation`/`Influence` are 0–1 scaled versions of the player/org score. This is the mechanism by which Reputation and Influence become *functionally meaningful* rather than decorative numbers (satisfying SoT §5's closing requirement).

**5.3 Contract Revenue**

```
Revenue = ContractBaseValue × QualityMultiplier(Performance) × ReputationMultiplier
```
`ContractBaseValue` should NOT be a fixed absolute number (see §8 Anti-Inflation) — it should be indexed to a rolling server-wide average, discussed below.

**5.4 Organizational Expenses**

```
Expenses = Payroll + Σ(BranchUpkeep_i^1.1) + R&D_Allocation + DebtInterest + Taxes
```
`Payroll` scales linearly with headcount × average salary. `BranchUpkeep` is deliberately given a mild superlinear exponent (~1.1, illustrative) so that scaling headcount/branches purely for scale's sake creates real cost pressure — this is the lever that keeps Mega-Corporation-stage play from being "Major Org but bigger with no new problem," per SoT §11 and Locked Rule #5.

**5.5 Net Organizational Cashflow**

```
NetCF_period = Revenue − Expenses
OrgCapital_t = OrgCapital_(t−1) + NetCF_period
```

**5.6 R&D → Capability**

```
InnovationPoints_t = Σ(R&D_Allocation × SpecialistPerformanceMultiplier)
```
Innovation Points spend against a capability tree that unlocks higher Contract tiers or reduces the effective Expense multiplier — never converts back into direct Revenue or Money, to avoid R&D becoming a laundering shortcut around Contract-based earning.

**5.7 Debt & Liquidation Trigger**

```
if OrgCapital_t < 0:  Debt_t = |OrgCapital_t| × (1 + r)   [r = small periodic interest rate]
if Debt sustained > N consecutive periods AND no funding secured:
    → Liquidation event
```

**5.8 Founder Seed Requirement (conceptual, not numeric)**

```
FounderEligible = (PersonalMoney ≥ SeedThreshold)
               AND (Reputation ≥ RepThreshold)
               AND (Influence ≥ InfThreshold)
               AND (PerformanceTrackRecord meets consistency bar over time window)
```
No individual threshold is proposed here — this is intentionally left as an open decision (§9) since SoT §18 explicitly marks "Exact organization requirements" as not yet locked.

---

## 6. HOW PLAYERS EARN / SPEND EACH RESOURCE

| Resource | Earn | Spend |
|---|---|---|
| Personal Money | Salary, performance bonus, dividends (if owner/equity holder), completed personal contracts | Founder seed capital, personal upkeep/status items, legal fees/fines, investment |
| Org Capital | Contract Revenue, loans/investment, funding rounds | Payroll, branch upkeep, R&D allocation, taxes, debt interest, dividends out |
| Influence | Winning contested contracts, legal victories, elections, leading mergers, holding senior positions | Unlocking political/legal actions (running for office, initiating takeover attempts, lobbying), Contract win-probability boost |
| Reputation | Successful contract completion, ethical conduct, promotions, favorable legal rulings | Not spent directly — read as a gate/multiplier by Contracts, loans, hiring, Founder eligibility |
| Performance | Quality of completed tasks/decisions (rolling) | Not spent — feeds bonus pay, promotion eligibility, Contract QualityMultiplier |
| R&D (org) | Allocated share of Org Capital + specialist employee Performance | Unlocking Contract tiers, reducing Expense multiplier |
| Connections | Networking actions, working under/with established players, org tenure | Unlocking visibility into higher-tier Contracts/job offers (access filter, not a spend) |

---

## 7. HOW PROGRESSION USES RESOURCES

- **Rank advancement (Associate → CEO):** gated by Performance rating thresholds + Reputation thresholds appropriate to the rank's responsibility, per Locked Rule #3. Money is never a sufficient condition on its own.
- **Founder transition:** requires Personal Money (seed capital) + Reputation + Influence + a sustained Performance track record — a genuine multi-resource state transition, not a purchase (Locked Rule #4, formula §5.8).
- **Organizational growth (Startup → Mega-Corp):** driven by Revenue outpacing the superlinear Expense curve, R&D unlocking higher Contract tiers, and Reputation/Influence widening Contract access — never by elapsed time alone.
- **Onboarding disclosure:** a new Associate only interacts with Personal Money and basic Contracts; Org Capital, R&D, and Influence-spending mechanics are surfaced only once the player reaches Manager/Executive/Founder stages, per Locked Rule #7 and SoT §12's conceptual learning progression.

---

## 8. ANTI-INFLATION / ECONOMY SAFEGUARDS

1. **Dynamic, relative contract pricing.** `ContractBaseValue` (§5.3) should be indexed to a rolling server-wide average of recent successful org revenue, not a fixed absolute number — this prevents veteran-player wealth accumulation from silently inflating the effective value of all future contracts.
2. **Superlinear cost scaling at size.** BranchUpkeep and similar fixed costs scale slightly faster than linear with org size (§5.4), creating a natural ceiling that keeps "just get bigger" from being a dominant, risk-free strategy.
3. **Recycling sinks.** Status/political spend (legal fees, lobbying, running for office) should remove money from circulation rather than transferring it to another player, to act as a currency sink independent of the player-to-player economy.
4. **No idle/passive income without a decision basis.** Any recurring income (dividends, branch revenue) must be a function of a prior decision's ongoing performance (e.g., a branch's own Reputation/Performance-linked revenue), not a flat time-based trickle — enforces Locked Rule #2 and closes the most common idle-farming exploit vector.
5. **Rate limits / diminishing returns on repeated identical actions**, to blunt bot-like or macro'd repetition of the same low-effort task for Performance/Revenue farming. Exact anti-macro technical detection is out of scope for this document (technical architecture phase, SoT §19 step 7).
6. **Transfer taxes or limits on direct player-to-player money transfer**, to reduce RMT/alt-account laundering risk. Exact percentage/limit is an open decision.
7. **Non-tradeable status resources.** Influence, Reputation, Performance, Connections are never directly purchasable or player-transferable (§1), which structurally prevents a wealthy player from simply buying political/social dominance — this is the single biggest anti-inflation *and* anti-P2W safeguard in the model, and follows directly from SoT §13 (no single path should trivially dominate).

---

## 9. STARTUP VS. MEGA-ORGANIZATION ECONOMICS

| Stage | Core Problem (SoT §11) | Economic Shape |
|---|---|---|
| Startup | "How do I survive?" | Low fixed costs, thin/negative margins, small Contracts only (low Reputation ceiling limits access), single point of failure |
| Growing Org | "How do I expand?" | Expenses begin scaling with headcount/branches; R&D starts unlocking better Contract tiers; Reputation-building becomes the binding constraint |
| Major Org | "How do I compete?" | Competes for large/exclusive Contracts against rival orgs directly (PvP-adjacent); Influence becomes as important as Revenue; increased visibility invites rival action (recruitment raids, contract undercutting) |
| Mega-Corp | "How do I maintain control?" | Fixed costs and scrutiny scale heavily (superlinear Expenses, §5.4); high visibility invites legal/political challenge (SoT §9, §10); R&D floor required just to stay competitive rather than to get ahead; acquisition/hostile-takeover target |

This asymmetry (small = nimble/low-ceiling, mega = high-ceiling/high-burn/high-exposure) is what keeps the "problems change, don't disappear" principle (Locked Rule #5) mechanically true rather than aspirational.

---

## 10. FAILURE / DEBT / LIQUIDATION FOUNDATIONS

- **Org-level debt** accrues when `OrgCapital < 0` (§5.7), with periodic interest.
- **Liquidation trigger:** debt sustained beyond a threshold *and* no funding secured within a grace period → Liquidation event. Assets, Contracts-in-progress, and employees become available back into the ecosystem (per SoT §14 — the world persists through org failure), rather than simply deleting them.
- **Org failure ≠ player failure.** A Founder whose org is liquidated should retain their Personal Money, Reputation, and Performance history (though org-level Reputation is lost with the org) — enabling the "REBUILD" step of SoT §14's long-term vision and the Golden Rule (§16: "impossible to completely finish," which implies failure is recoverable, not a hard stop).
- **Personal-level financial distress** (e.g., from legal fines under a future legal system, §9) needs its own consequence ladder short of an unrecoverable soft-lock — e.g., partial wage garnishment, asset seizure, Reputation penalty. **This is intentionally left as an open decision** (§11 below) since SoT §18 marks "Exact liquidation mechanics" as not yet locked, and no personal-bankruptcy mechanic is named anywhere in the Source of Truth.

---

## 11. OPEN DECISIONS

These require an explicit design decision (and, where relevant, a Source of Truth update) before formulas can be finalized:

1. **Org Capital governance model** — single treasury with role-gated access, or hierarchical sub-budgets per department (SoT §6 implies department-level budgets — needs an explicit ledger model).
2. **Contract sourcing mix** — ratio of NPC-issued (safe, PvE) vs. player-org-to-player-org (PvP, competitive) Contracts, and at what org stage PvP contracts become available.
3. **Reputation/Influence aggregation at the org level** — is org Reputation a function of employee Reputation, leadership decisions, Contract history, or a weighted mix?
4. **Numeric thresholds** for all rank/Founder/liquidation gates (§5.8, §5.7) — entirely unset by design; requires playtesting data.
5. **Personal bankruptcy consequence ladder** (§10) — not named in the Source of Truth at all; needs either an explicit design decision or confirmation it's out of scope for now.
6. **Equity/investor gameplay** — whether players can hold equity/dividends in orgs they don't work for. Implied by "dividends" in §6.1 of this document but not stated in the Source of Truth; **⚑ FLAG** — this would be a new feature and needs explicit sign-off before being treated as in-scope.
7. **R&D as an org sub-mechanism vs. a full seventh currency** (§3.6) — flagged for confirmation.
8. **Whether/how future monetization intersects the economy.** SoT §18 explicitly leaves monetization unlocked. This spec's recommendation (§8.7 — status resources are never purchasable) implies monetization should stay cosmetic/convenience-only to preserve the economic model's integrity, but that is a *recommendation*, not something this document can lock.

---

## 12. RISKS

- **Snowball/runaway wealth.** Even with the proposed sinks (§8), a rich-gets-richer feedback loop between Reputation/Influence and Contract access could lock out new players from meaningful Contracts. Needs tiered/matchmade Contract pools or explicit playtesting before being trusted.
- **Legal system dependency.** Several safeguards here (personal fines, misconduct penalties, §10) assume a legal/accountability enforcement system that does not exist yet (SoT §9, §10 are both "not yet locked"). Until that system is speced, these are economic *hooks* pointing at a system that isn't built.
- **Onboarding complexity vs. SoT §12.** Ten named resources is a lot of surface area; if disclosure isn't carefully staged (§7's onboarding note), this design risks violating the "simple on the surface" principle it's supposed to serve.
- **Alt-account / RMT abuse.** Player-to-player money transfer, dividends, and Contract payouts are all potential laundering vectors between alt accounts. Technical safeguards are out of scope here and must be addressed at the architecture phase (SoT §19 step 7).
- **Illustrative formulas are unvalidated.** Every constant/exponent in §5 is a placeholder chosen to demonstrate scaling *shape*, not a tuned value — treating any of them as final before simulation/playtesting would contradict SoT §18 and §19.
- **R&D's status as a resource is an interpretation, not a given** (§3.6, §11.7) — if a future design decision splits it into an independent currency, several formulas here (§5.6, Expenses in §5.4) would need rework.

---

## 13. RECOMMENDED NEXT TASK

Per the Source of Truth's development sequence (§19: Source of Truth → Game Design Specifications → **Economy** → **Progression** → Organization systems → MVP...), the next task should be:

**PROGRESSION SPECIFICATION v0.1** — defining exact rank requirements, promotion mechanics, and the Founder-eligibility gate this document deliberately left as conceptual-only (§5.8, §11.4). Progression is the most-referenced dependency left unresolved by this document, and Organization Systems (mergers, acquisitions, department budgets — §11.1) depends on rank/authority being defined first.

---

**END OF ECONOMY SPECIFICATION v0.1**
