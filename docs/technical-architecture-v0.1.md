# THE NETWORK — TECHNICAL ARCHITECTURE SPECIFICATION v0.1

**Status:** DRAFT
**Version:** 0.1
**Date:** August 25, 2026
**Subordinate to:** [`source-of-truth.md`](./source-of-truth.md) — authoritative.
**Builds on:** [`economy-specification-v0.1.md`](./economy-specification-v0.1.md), [`progression-specification-v0.1.md`](./progression-specification-v0.1.md), [`organization-systems-specification-v0.1.md`](./organization-systems-specification-v0.1.md), [`mvp-definition-v0.1.md`](./mvp-definition-v0.1.md) — all treated as proposed inputs; this document's job is to make the MVP definition buildable, not to reopen its design decisions.

---

## AUTHORITY & SCOPE

Per SoT §19's development sequence (step 7, following MVP definition), this document defines *how* the MVP gets built — data model, server/client boundaries, security model, persistence strategy — without writing gameplay code. Per the task instructions, it is explicitly scoped to make the MVP buildable **without architecting a dead end** for the long-term vision (player-founded orgs, M&A, mega-corporations, governance, courts). No Luau/Roblox code is written here.

Two guardrails from the task govern every decision below:
- **Do not over-engineer systems MVP does not need** (e.g., no cross-server org sync, no distributed transactions, no external backend — none of these exist yet).
- **Do not foreclose systems the Source of Truth already commits to** (e.g., orgs must still be real, addressable, persistent entities even in MVP, or Founder/M&A/mega-corp systems would require a rewrite rather than an extension).

---

## ARCHITECTURE DECISION: ORGANIZATION PERSISTENCE MODEL

### The question

MVP Definition §13 flagged this as the single highest-leverage open decision: should organizations be **server-local** (each server instance is independent, no shared state) or **cross-server** (a single shared, globally-consistent org visible from every server)?

### The analysis

| Axis | Server-local | Cross-server (naive/global) |
|---|---|---|
| MVP requirements | Sufficient — MVP has no player-driven org mutation that needs cross-server visibility (Organization Systems Spec §21: startup orgs are Founder/seed-only; MVP caps at Manager with no budgets) | Unneeded complexity for a loop that doesn't touch it |
| Roblox DataStore constraints | No contention; each server's read/write pattern is independent | No native multi-key transactions; a single org key written by many concurrent servers would hit per-key request budgets and throttle |
| Scalability | Trivial — no shared bottleneck | Requires sharding/locking/external backend once concurrent writers grow |
| Consistency | Trivial within a server (single Lua VM, no races) | Real distributed-consistency problems (double promotion, double-spend) without a leader/authority mechanism |
| Exploit/security risk | Small, well-understood attack surface | Wider surface — spoofed/replayed cross-server `MessagingService` traffic, cross-server race exploitation |
| Player experience | Invisible to the player at MVP scale; matches the pattern most large-scale Roblox social/economy titles actually use | Not needed to make the MVP loop feel good |
| Future player-founded orgs | Compatible, *conditioned on* orgs already being persistent DataStore records (not hardcoded constants) | Natural fit, but arriving there via naive global-key writes doesn't scale past modest concurrency anyway |
| Future M&A | Compatible if the schema is `OrgId`-addressable with sub-entities (Departments/Branches) — true regardless of hosting model | Same requirement either way |
| Future mega-corporations | The real long-term stress case: many concurrent writers to one org. Needs sharded sub-records or an external authority *eventually*, regardless of which model MVP starts with | Same eventual need |
| Future governance/courts | Needs an addressable, persistent record + audit trail — a schema property, not a hosting-model property | Same |
| Development complexity | Low for MVP | High, for a need MVP does not have |
| Migration/rewrite risk | **Low if and only if orgs are modeled as persistent `OrgId`-keyed DataStore records now** — hosting becomes additive later. **High if orgs are hardcoded per-server constants** — would require a full data-model rewrite to introduce persistence at all. | N/A — already paying a cost for a capability not yet used |

### The decision — LOCKED for this document

**Hybrid: Persistent Organization Identity, Server-Local Hosting.**

- Every organization — including MVP's seeded ones — is a real, persistent record in DataStore, addressed by a stable `OrgId`. It is never a hardcoded server-side constant with no backing record.
- Player identity and progression (rank, Personal Money, Performance, Reputation, Influence, org membership) is always globally persistent per player via DataStore, independent of which server they're on.
- For MVP, each server independently loads and hosts the *live session* state of the org(s) present on it. No cross-server synchronization of organization state is built for MVP, because MVP introduces no player-driven mutation to organization-level data that requires it (Task-assignment authority in MVP is a session-scoped interaction, not a write to shared org capital or a shared roster requiring cross-server consistency).
- The seam for future cross-server behavior (player-founded orgs whose members are scattered across concurrent servers, mega-corp-scale contention) is **additive**: a hosting/leader pointer, `MessagingService`-based near-real-time sync, and/or (at real scale) an external authoritative backend — layered on top of the already-persistent, already-addressable `OrgId` record, not a redesign of it.

This resolves MVP Definition's OD-4 for the purposes of this document. If a future decision explicitly wants true real-time cross-server orgs sooner than the Founder system requires, that is a **new** architectural decision, not an extension of this one — flagged in §23.

---

## 1. CHOSEN ORGANIZATION PERSISTENCE MODEL

(Restated concisely as the section the task requested; full rationale above.)

- **LOCKED:** Organizations are persistent, `OrgId`-addressable DataStore records from day one, even in MVP.
- **LOCKED:** Organization *hosting* (which server currently treats itself as authoritative for an org's live mutable state) is server-local for MVP — no cross-server org sync is built.
- **LOCKED:** Player progression data is always globally persistent per player, independent of server/org hosting.
- **RECOMMENDED:** MVP's seeded organizations (Organization Systems Spec §21, MVP Definition §7) are provisioned once (e.g., via a one-time seed/migration script or a fixed set of known `OrgId`s) rather than re-created ad hoc per server — this keeps the "persistent record, not a constant" property true even though their content barely changes during MVP.

---

## 2. SERVER/CLIENT RESPONSIBILITIES

- **LOCKED:** The server is authoritative for **all** state that affects Money, Performance, Reputation, Influence, Rank, or organizational authority. This is a direct technical implementation of Organization Systems Spec §20 and MVP Definition §15's server-authoritative requirements — restated here as an architectural boundary, not optional guidance.
- **LOCKED:** The client is responsible for: rendering UI, capturing player input/choices, and requesting actions from the server. The client **never** computes or transmits a reward, outcome score, or threshold-check result the server is expected to trust.
- **RECOMMENDED:** The client may hold a **read-only, server-pushed copy** of the player's own state (Money, Performance, Rank, etc.) for responsive UI — but this copy is display-only and is never read back by the server as input to any decision.

---

## 3. SERVER-AUTHORITATIVE SECURITY MODEL

- **LOCKED:** Every player-initiated action that changes persisted state (Task completion, decision-point choice, promotion, Task assignment) is validated entirely server-side against server-held data, never against client-supplied values.
- **LOCKED:** Any numeric value the client sends (a chosen decision option, a target player for Task assignment) is treated as an **index/reference into a server-known set**, never as a value to be trusted directly (e.g., the client sends "I chose option 2," not "I earned $500").
- **RECOMMENDED:** All Remote endpoints (§4) perform, in order: (1) sender identity/session validity check, (2) rate-limit/debounce check, (3) payload shape/type validation, (4) domain validation (e.g., "is this a valid Task the player currently has open," "is this player actually this target's Manager"), before any state mutation.

---

## 4. REMOTEEVENT/REMOTEFUNCTION STRATEGY

- **RECOMMENDED:** Prefer `RemoteEvent` over `RemoteFunction` for client→server action requests. `RemoteFunction` calls can be exploited to hang/never-return on a modified client, and MVP's actions (accept Task, submit decision, request Task assignment) don't need a synchronous return value — the server can push the result back via a separate server→client `RemoteEvent`.
- **RECOMMENDED, minimal fixed set for MVP:**
  - `RequestTask` (client → server): request an available Task.
  - `SubmitDecision` (client → server): submit a choice for an open Task's decision point.
  - `TaskResult` (server → client): pushes the computed outcome/reward.
  - `PromotionNotice` (server → client): pushes a promotion event.
  - `AssignTask` (client → server, Manager-only): request assigning an open Task to a direct report.
  - `StateSync` (server → client): periodic/on-change push of the player's own display-only state (§2).
- **LOCKED:** Remotes live in a single, clearly named shared location (e.g., a `Remotes` folder under `ReplicatedStorage`) so the server-side validation surface is easy to audit — not scattered ad hoc through the codebase. (Exact folder path is a §19 concern; the principle — one discoverable Remote surface — is locked here.)
- **POST-MVP:** Any Remote related to budgets, Contracts-as-bidding, Department/Branch management, hiring/firing beyond join, or governance — none of these exist until their owning systems do (Organization Systems Spec §7–§8, §14, §16, all Post-MVP per MVP Definition §7–§8).

---

## 5. DATASTORE/DATA PERSISTENCE ARCHITECTURE

- **LOCKED:** Two top-level persistent record types for MVP: **PlayerData** (keyed by `UserId`) and **OrganizationData** (keyed by `OrgId`) — matching the Economy Spec's Locked Rule #1 (personal/org pools are structurally separate) at the storage layer, not just the gameplay layer.
- **LOCKED:** All DataStore reads/writes go through a single shared wrapper module (not ad hoc `DataStoreService` calls scattered through gameplay code), so retry/backoff (§15), rate-limit budgeting (§22), and schema versioning (§6–§7) are handled in one place.
- **RECOMMENDED:** Adopt a **session-locking pattern** for PlayerData (a well-established Roblox pattern: a player's profile is "checked out" by the server that loaded it, preventing a second server from loading stale data and causing item/currency duplication or rollback on a rejoin-race). **Open decision (§23):** build this in-house vs. adopt an existing, widely-used open-source implementation of the pattern — this document recommends the *pattern*, not a specific dependency.
- **RECOMMENDED:** Writes are **batched/periodic** (e.g., autosave every N minutes plus on-`PlayerRemoving`/`BindToClose`) rather than one DataStore write per single Task completion — protects the request budget (§22) and reduces throttling risk. In-memory server state is the source of truth during a session; DataStore is the durability layer, flushed on the cadence above plus critical checkpoints (promotion, session end).
- **POST-MVP:** `MemoryStoreService` (fast cross-server ephemeral coordination — locks, queues) and any external backend/HTTP service — neither is needed until cross-server org hosting (§1, §21) is actually built.

---

## 6. PLAYER DATA SCHEMA

Proposed shape (illustrative field list, not a locked exact format):

```
PlayerData {
  UserId: number                    -- primary key
  SchemaVersion: number
  OrgId: string | nil                -- nil until joined; matches MVP's single/-few-org join flow
  Rank: enum(Associate, Specialist, Manager)   -- MVP-scoped subset of Progression Spec's full ladder
  PersonalMoney: number
  PerformanceRating: number          -- current rolling value (Economy Spec §5.1)
  PerformanceHistory: [number]       -- bounded recent window feeding the rolling average, NOT unbounded
  Reputation: number
  Influence: number                  -- tracked from first promotion onward (MVP Definition §6); read-only in MVP
  TaskHistory: [TaskRecord]          -- bounded recent log (§17), not a full permanent ledger
  CreatedAt: timestamp
  LastLogin: timestamp
}
```

- **LOCKED:** `PerformanceHistory` and `TaskHistory` are **bounded** (fixed max length, oldest entries dropped) — an unbounded per-player log risks exceeding DataStore's per-key size limit over a long-lived account and is unnecessary for MVP's rolling-average requirement (Economy Spec §5.1 only needs a recent window, not full history).
- **LOCKED:** `SchemaVersion` is present from the first record onward, so any future field addition/rename has a documented migration path rather than an implicit one (directly serves MVP Definition §17's "data model headroom" requirement).
- **RECOMMENDED:** `Rank` is stored as an enum/string matching only the MVP-scoped subset (Associate/Specialist/Manager) — but the *field* is designed to accept the full Progression Spec ladder later without a type change, just an expanded enum.

---

## 7. ORGANIZATION DATA SCHEMA

```
OrganizationData {
  OrgId: string                      -- primary key, stable forever
  SchemaVersion: number
  Name: string
  Seeded: boolean                    -- true for all MVP orgs (not player-founded)
  Stage: enum(Startup, Growing, Major, MegaCorp)   -- MVP orgs are always "Startup"
  MemberCount: number                -- aggregate; NOT a full member-ID list (see below)
  -- Reserved, unused-but-present in MVP:
  Capital: number | nil               -- Economy Spec Org Capital; nil/unused in MVP
  Departments: [DepartmentRecord] | nil   -- Organization Systems Spec §4; empty in MVP
  Branches: [BranchRecord] | nil          -- Organization Systems Spec §5; empty in MVP
}
```

- **⚑ FLAG / LOCKED design constraint:** the org record does **not** store a full list of member `UserId`s inline. Membership is tracked from the **player's** side (`PlayerData.OrgId`) — the org record only holds an aggregate `MemberCount`. This avoids a single hot, ever-growing list inside one DataStore key (a real scaling risk once an org has hundreds/thousands of historical members) and avoids needing a multi-key transaction every time a player joins/leaves (Roblox has no native cross-key atomicity, per the architecture decision above). **Trade-off flagged:** deriving "list all members of Org X" requires either a secondary index (Post-MVP) or iterating player records (impractical at scale) — acceptable for MVP since no MVP feature needs to enumerate an org's full roster from the org record itself (the in-session server already knows who's present).
- **LOCKED:** `Departments`/`Branches`/`Capital` fields exist in the schema (nil/empty for MVP) specifically so Organization Systems Spec's future features are additive field population, not a schema migration — directly implementing MVP Definition §17's "data model headroom, not feature stubs" principle.

---

## 8. ECONOMY DATA BOUNDARIES

- **LOCKED:** `PersonalMoney` lives exclusively in `PlayerData`; `Capital` lives exclusively in `OrganizationData`. No code path may read or write both in a single mutation (this is both a gameplay-integrity rule, per Economy Spec Locked Rule #1, and a storage-layer necessity, since Roblox DataStores have no native multi-key transaction — a mutation spanning both would require a fragile two-step process with partial-failure risk).
- **LOCKED:** In MVP, no gameplay action writes to `OrganizationData.Capital` at all (MVP Definition §6 — Org Capital is Post-MVP). This is enforced architecturally, not just by omission: the MVP-era codebase should have no write path to that field, so its later activation (once Director+ budget authority exists, Organization Systems Spec §14) is a new code path, not a re-enable of dormant risk.

---

## 9. PROGRESSION DATA BOUNDARIES

- **LOCKED:** Rank, Performance, Reputation, and Influence all live in `PlayerData` only. MVP's promotion check (§11) is therefore a **single-key read/write operation** — it never needs to read `OrganizationData`, which keeps promotion validation free of the cross-key-transaction problem entirely for MVP's Manager-cap scope.
- **RECOMMENDED:** Keep this true even as ranks expand post-MVP for as long as possible — a Director-level promotion might eventually need to check organizational conditions (e.g., "does a Department exist for this player to lead"), and when that day comes, it should be treated as a deliberate, explicit cross-record read (with the consistency implications that implies), not something that quietly crept in because Rank and Org data got entangled early.

---

## 10. TASK/DECISION SYSTEM ARCHITECTURE

- **LOCKED:** Task **definitions** (available Tasks, their decision options, and the server-side logic mapping a decision to an outcome-quality score) are static, server-only content (a ModuleScript-based table), not per-instance persisted data. Only the **outcomes** of a specific player completing a specific Task are persisted (as bounded `TaskHistory` entries, §6).
- **LOCKED:** The server is the sole computer of outcome-quality — the client transmits only which option index it chose (§3); the server looks up that option's defined outcome, applies any server-side randomness/variance (if the design calls for it), and computes the resulting Performance/Money/Reputation deltas.
- **RECOMMENDED:** Task definitions and the pure scoring/outcome-computation logic live in a Roblox-service-independent module (no direct `DataStoreService`/`Players` calls inside it) so they can be unit-tested in isolation (§18) — this is where Economy Spec §5.1's formula and its eventual threshold tuning actually live in code.

---

## 11. PROMOTION VALIDATION ARCHITECTURE

- **LOCKED:** Promotion thresholds (Performance/Reputation bars, per Progression Spec §3.2 and MVP Definition §10) are server-only constants — never sent to or checked on the client.
- **LOCKED:** Promotion checking runs server-side, triggered after each Task completion (event-driven, not polled on a timer) — checks the player's current `PerformanceRating`/`Reputation` against the MVP-scoped threshold, and if met, applies the promotion immediately (systemic/automatic model, MVP Definition §10) and persists the change.
- **RECOMMENDED:** The threshold-check logic lives in the same testable, Roblox-service-independent style of module as Task outcome computation (§10), so threshold tuning (an expected, iterative activity per MVP Definition §23 Phase 6) doesn't require touching networking or persistence code.

---

## 12. ORGANIZATION AUTHORITY VALIDATION

- **LOCKED:** The `AssignTask` action (§4) is validated server-side against server-held data only: the requesting player's `Rank` must be Manager (or above, once higher ranks exist), the requesting player and the target player must share the same `OrgId`, and (for MVP's flat structure) the target must be a valid Associate/Specialist in that org. None of these checks trust any client-supplied claim about rank or org membership.
- **LOCKED:** This is the concrete implementation of Organization Systems Spec §11's "Department Authority" boundary concept, scoped down to MVP's single interaction — the same validation *shape* (check rank, check org/department membership, check target validity) is designed to extend to Director/VP/budget-authority checks later without needing a different validation architecture, only additional fields to check.

---

## 13. ANTI-EXPLOIT PRINCIPLES

Consolidating and making concrete the principles already stated in §2–§3 and §10–§12, plus MVP Definition §15:

- **LOCKED:** Never trust client-supplied state, rewards, or outcomes — only client-supplied *choices/references* into server-known data.
- **LOCKED:** Rate-limit/debounce every action Remote per-player (prevents macro/spam exploitation of the Task loop, a narrow MVP-scoped instance of Economy Spec §8.5 and Progression Spec §16).
- **LOCKED:** Idempotency on Task completion (§15) — a duplicated/retried network request must not double-reward.
- **RECOMMENDED:** Sanity-bound all persisted numeric fields server-side on write (e.g., reject/clamp an update that would move `PersonalMoney` or `PerformanceRating` by an implausible delta in one action) as a defense-in-depth measure against a bug or exploit in the computation path, not as the primary security mechanism (the primary mechanism is that the client never supplies the value at all).
- **POST-MVP:** Cross-player collusion detection (evaluator-diversity weighting, Progression Spec §16), alt-account detection, transfer-limit enforcement (Economy Spec §8.6) — all depend on mechanics (player-to-player Money transfer, cross-player evaluation) that don't exist in MVP.

---

## 14. SESSION/SERVER LIFECYCLE

- **RECOMMENDED:**
  1. `PlayerAdded` → acquire session lock (§5) → load `PlayerData` (create default record if new) → push initial `StateSync`.
  2. During session → in-memory state is authoritative; periodic autosave (§5) plus checkpoint saves on promotion.
  3. `PlayerRemoving` → final save → release session lock.
  4. `BindToClose` (server shutdown) → attempt to flush all currently-active player sessions within Roblox's shutdown time budget, with retry; a session that cannot be flushed in time should fail safe (data as of last checkpoint, not corrupted) rather than risk a partial write.
- **LOCKED:** Organization records (§7) are loaded per-server on first need (e.g., first player from that org joins) and are **not** locked/checked-out the way player profiles are, since MVP performs no server-local mutation to `OrganizationData` that requires exclusivity (§8's "no write path in MVP" rule makes this moot for MVP specifically, but the lifecycle design should not assume it stays moot forever — see §21).

---

## 15. FAILURE/RETRY/IDEMPOTENCY STRATEGY

- **LOCKED:** All DataStore calls go through the shared wrapper (§5) with bounded-retry exponential backoff — a transient failure is retried a limited number of times, not indefinitely, and a final failure is logged (§17) and surfaced to a fallback path rather than silently dropped.
- **LOCKED:** Task completion requests carry enough information for the server to detect a duplicate/retried request (e.g., a per-Task-instance identifier the server issued when the Task was accepted) so a network retry cannot double-reward — this is the concrete mechanism behind §13's idempotency principle.
- **RECOMMENDED:** If DataStore is transiently unavailable at save time, hold the pending write in memory and retry on the next autosave cycle rather than blocking gameplay — a save failure should degrade to "will retry shortly," not to a stuck or broken player session.

---

## 16. CONCURRENCY/CONFLICT HANDLING

- **LOCKED (MVP scope):** Within a single server, true parallel-mutation races are limited by Roblox's single-threaded event model, but **per-player action debounce** (§13) is still required to prevent a double-submit (e.g., double-clicking "submit decision") from being processed twice before the first completes.
- **RECOMMENDED (forward-compatible, not exercised by MVP):** The DataStore wrapper (§5) supports `UpdateAsync`-style optimistic-concurrency writes (read-modify-write with automatic retry on conflict) for any field that could plausibly be written by more than one source — even though MVP's `OrganizationData` has no such field yet (§8), building the wrapper to support this now means the future cross-server hosting seam (§1, §21) doesn't require rewriting the persistence layer, only using a capability it already has.
- **POST-MVP:** Distributed locks (`MemoryStoreService`) or leader-election for "which server currently hosts org X's live mutations" — not needed until cross-server org mutation exists.

---

## 17. LOGGING/AUDIT STRATEGY

- **RECOMMENDED:** A lightweight, bounded action record — matching Organization Systems Spec §20's accountability foundation and MVP Definition §14's "lightweight action record" — logging at minimum: actor, action type (Task completion, promotion, Task assignment), target (if applicable), and timestamp. Stored as part of `PlayerData.TaskHistory` (§6) or a small adjacent bounded list — not a separate unbounded audit DataStore for MVP.
- **LOCKED:** This log is designed to be **consumed by**, not implement, the future legal/accountability system (SoT §9–§10, Organization Systems Spec §20) — MVP builds no investigation/reporting UI or enforcement logic against it.
- **POST-MVP / FUTURE:** A full, queryable, long-retention audit trail (needed once courts/governance exist) will likely require an external logging destination (e.g., an HTTP endpoint to a backend service) once volume exceeds what a bounded per-player DataStore field can hold — flagged as Future Architecture (§21), not built now.

---

## 18. TESTING ARCHITECTURE

- **RECOMMENDED:** Separate **pure logic** (Performance-rating computation, promotion-threshold checks, Task-outcome resolution — the modules referenced in §10–§11) from **Roblox-service-dependent** code (DataStore calls, Remotes, `Players` service usage). Pure logic modules take plain data in, return plain data out, with no dependency on Roblox global services — making them testable with a standalone Luau test runner rather than requiring a live Roblox session for every check.
- **RECOMMENDED:** Given that Economy Spec and Progression Spec both explicitly leave numeric thresholds/formulas as tunable (not locked), the pure-logic modules should be structured so their constants (thresholds, weights) are easily swappable for playtesting/tuning (§20's Phase 6) without touching networking or persistence code.
- **POST-MVP:** Full integration/load testing infrastructure (simulating many concurrent players/servers against DataStore) — valuable before a real launch, but not required to validate the MVP loop itself.

---

## 19. DEVELOPMENT FOLDER/MODULE STRUCTURE

Proposed conceptually (no files created here — this document does not implement code):

- **`ServerScriptService/Server/`** — service modules with Roblox-service dependencies: `PlayerDataService` (session lock, load/save), `OrganizationService` (org record load, MVP-scoped), `TaskService` (Task lifecycle, Remote handling), `PromotionService` (threshold checks), each calling into...
- **`ReplicatedStorage/Shared/Logic/`** — the pure, testable modules (§18): Performance computation, Task outcome resolution, promotion threshold evaluation, Task definitions.
- **`ReplicatedStorage/Shared/Remotes/`** — the single discoverable Remote surface (§4).
- **`ReplicatedStorage/Shared/Types/`** — shared type/schema definitions for `PlayerData`/`OrganizationData` (§6–§7), so client display code and server logic agree on shape without duplicating it.
- **`StarterPlayerScripts/Client/`** — UI controllers consuming `StateSync` and sending action requests; no authoritative logic.

**RECOMMENDED**, not locked — a reasonable starting layout that keeps the server-authoritative/pure-logic/client boundaries (§2–§3, §18) structurally visible in the folder layout itself, rather than only as a convention someone has to remember.

---

## 20. MVP IMPLEMENTATION PHASES

Directly adopting MVP Definition §23's phase sequence, with the technical detail this document adds:

1. **Phase 0 — Data & persistence skeleton.** `PlayerData`/`OrganizationData` schemas (§6–§7), DataStore wrapper with retry (§5, §15), session-lock pattern (§5).
2. **Phase 1 — Task loop, server-authoritative.** `TaskService`, `RequestTask`/`TaskResult` Remotes (§4), pure Task-outcome module (§10, §18) with a trivial/no-choice outcome initially — prove the pipe end-to-end before adding decision richness.
3. **Phase 2 — Decision points.** Add real choice options to Task definitions and the outcome-resolution logic; this is expected to iterate (MVP Definition §21's content-design risk).
4. **Phase 3 — Promotion.** `PromotionService`, server-only threshold constants (§11), `PromotionNotice` Remote.
5. **Phase 4 — Manager interaction.** `AssignTask` Remote and its authority validation (§12), including MVP Definition OD-2's no-Manager-available fallback.
6. **Phase 5 — Onboarding & UI polish.** Client controllers, `StateSync`, first-Task guidance.
7. **Phase 6 — Playtesting & threshold tuning.** Exercising the swappable-constants design from §18.

---

## 21. FUTURE EXTENSIBILITY FOR FOUNDER/M&A/COURTS/GOVERNANCE

None of these are designed or built here. This section confirms the architecture above doesn't block them:

- **Founder system / player-founded orgs:** requires (a) a way for a player action to create a new `OrganizationData` record — additive, since the schema (§7) already exists; (b) eventually, cross-server hosting for orgs whose members span servers — additive on top of the persistent-record + optimistic-concurrency-capable wrapper (§16) already built for MVP, not a rewrite of it.
- **M&A:** operates on `OrgId`-addressable records with sub-entities (`Departments`/`Branches` fields already reserved, §7) — a merge/acquisition is a record-transfer operation on an already-addressable schema.
- **Mega-corporations (high-contention orgs):** the real stress case for the persistence model (§1's analysis) — will likely need `OrganizationData` sharded into sub-keys (e.g., per-Department/Branch records rather than one monolithic org record) once a single org's write volume threatens DataStore request budgets (§22). The schema's existing Department/Branch sub-entity shape (§7) is designed to make that sharding a natural evolution, not a redesign.
- **Courts/Legal system, Governance:** consume the bounded action log (§17) as an evidentiary source and will need their own, likely externally-backed, durable case/record storage once volume exceeds a bounded per-player field — flagged as needing an external service, not solved by this document.

**⚑ FLAG:** this section is a compatibility argument, not a guarantee — none of Founder, M&A, mega-corp sharding, or courts/governance storage are specified in enough detail yet to confirm zero friction, only the absence of an obvious structural conflict with what's proposed here (mirroring the same caveat Organization Systems Spec §26 raised about itself).

---

## 22. PERFORMANCE/SCALABILITY CONSIDERATIONS

- **LOCKED constraint to design around:** Roblox DataStores have per-key request budgets (roughly scaling with concurrent player count) and a per-key payload size ceiling (a few MB) — both are why §6–§7's schemas are explicitly **bounded** (capped history lists, no inline full member rosters) and why §5 recommends batched/periodic saves over per-action writes.
- **RECOMMENDED:** Monitor (post-implementation, not part of this document) actual DataStore call volume per server against Roblox's published budget formula, and treat approaching that budget as a signal to increase the autosave interval or further reduce per-write payload size, rather than a signal to change the architecture.
- **POST-MVP:** Any true horizontal-scaling concern (many concurrent servers contending on one org's data) is exactly the mega-corp-stage problem flagged in §21 — not a concern MVP's server-local, low-contention model needs to solve.

---

## 23. OPEN ARCHITECTURAL DECISIONS

1. **Session-lock implementation** (§5) — build in-house vs. adopt an existing, widely-used open-source pattern/module for Roblox profile session-locking. This document recommends the *pattern* only.
2. **Exact Remote payload schemas** (§4) — field-level shapes for each Remote are an implementation detail below this document's altitude.
3. **Exact folder structure** (§19) — proposed as reasonable, not locked; a team convention decision.
4. **`OrderedDataStore`/leaderboard adoption** — MVP Definition §11 recommended a light roster/leaderboard; whether it's backed by `OrderedDataStore` or computed in-memory per-server is unresolved here.
5. **Timing of `MemoryStoreService` adoption** — deferred to whenever cross-server coordination is actually needed (§21); not scheduled by this document.
6. **Timing/necessity of an external backend service** — flagged repeatedly (§17, §21, §22) as the likely eventual answer for mega-corp-scale contention and full audit/court storage, but *when* that becomes necessary is a scaling question this document cannot answer in advance of real usage data.
7. **Seeded-organization provisioning mechanism** (§1) — one-time seed script vs. some other provisioning approach; not resolved here.

---

## 24. RISKS AND MIGRATION RISKS

- **DataStore throttling under real load** is the most concrete technical risk — mitigated by the bounded-schema and batched-write recommendations (§6–§7, §5, §22), but not provable without real playtesting traffic.
- **Session-lock edge cases** (a server crashes while holding a player's lock, blocking that player's next join until the lock expires) are a known Roblox-platform pattern risk — mitigated by using a proven pattern (§5, §23 item 1) rather than a naive custom implementation, but worth explicit awareness.
- **Schema version drift** — if `SchemaVersion` (§6–§7) isn't actually checked and migrated on load once fields change post-MVP, the "headroom" design intent (MVP Definition §17) degrades into the same dead-end risk this document was written to avoid. This is a discipline risk, not a design gap.
- **The biggest migration risk this document is specifically designed to prevent** — organizations as hardcoded server constants with no persistent record — is avoided by the Locked decision in §1. The residual risk is narrower: if MVP's actual implementation drifts from this document (e.g., a developer takes a shortcut and skips giving seeded orgs a real persistent record "since MVP doesn't need it anyway"), the dead-end risk returns. Worth flagging as an implementation-discipline risk, not an architecture gap.
- **Mega-corp-scale sharding (§21) is unproven on paper.** The Department/Branch sub-entity shape is a *reasonable* basis for future sharding, but this document cannot guarantee it will be sufficient without that system actually being designed and load-tested later.

---

## IMPLEMENTATION READINESS

**READY.**

This document resolves the one open question (server-local vs. cross-server organizations) that MVP Definition explicitly flagged as blocking, defines schemas, security model, persistence strategy, and phase sequencing sufficient to begin coding, and does not depend on any further design document to start Phase 0.

## EXACT FIRST CODING MILESTONE

**Phase 0 — Data & Persistence Skeleton:**
1. Define the `PlayerData` schema (§6) and `OrganizationData` schema (§7) as shared type definitions.
2. Build the shared DataStore wrapper module (§5) with bounded-retry backoff (§15) and session-lock acquire/release (§5, §14).
3. Implement `PlayerAdded`/`PlayerRemoving`/`BindToClose` lifecycle (§14) wired to the wrapper: load-or-create a default `PlayerData` record on join, save-and-release on leave.
4. Provision the MVP's seeded `OrganizationData` record(s) (§1, §23 item 7) so at least one real, persistent `OrgId` exists to join against.

No Task/decision/promotion logic is required for this milestone — its sole success criterion is: a player can join, get a persistent record created and correctly loaded on rejoin, and leave without data loss, against a real seeded organization record. This validates the persistence architecture (§1, §5–§7) before any gameplay logic is layered on top of it.

---

**END OF TECHNICAL ARCHITECTURE SPECIFICATION v0.1**
