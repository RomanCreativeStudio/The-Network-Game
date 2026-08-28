# The-Network-Game

Design docs live in `docs/` (start at `docs/source-of-truth.md`). Server/client
source lives in `src/`, mapped into Roblox by `default.project.json` via
[Rojo](https://rojo.space/). Automated tests live in `tests/` (pure Lua 5.1,
no Roblox runtime required).

## Playtesting in Roblox Studio

### 1. Set up and sync

1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/)
   (the CLI) and the matching **Rojo** Studio plugin.
2. Open Roblox Studio and create a new place from the **Baseplate** template
   (not "Empty" — the MVP has no spawn/floor of its own, and Baseplate
   gives players somewhere to stand and a default spawn point).
3. **Publish the place at least once** (File > Publish to Roblox) before
   your first playtest, even if it's just to your own account. This is
   required for step 4 below to work.
4. In Studio, open **Game Settings > Security** and enable **"Studio Access
   to API Services"**. This is off by default and is required for
   `DataStoreService` (player save/load) to function in Studio — without
   it, every player will fail to load and get kicked after a short retry
   period (the server console will now say so explicitly; see
   `Bootstrap.server.lua`).
5. From the repository root, run `rojo serve` in a terminal, then in Studio
   use the Rojo plugin to **Connect**. Studio's instance tree should now
   mirror `src/`.
6. Click **Play** (or **Start Server + 2 Players** under the Test tab to
   playtest the Manager/second-player flow in one session).

### 2. Playtest checklist

**As a fresh Associate:**
1. You should spawn in and, after a moment, see a small on-screen panel
   with a "Request Task" button and a "Rank: Associate" label.
2. Click **Request Task**. You should see the task prompt ("A client
   report is due...") with three choice buttons, each showing its
   description and the exact money/performance/reputation numbers for
   every possible outcome.
3. Click **"File it thoroughly"** (the careful choice). It's fully
   deterministic: you should see Money +10, Performance +2, Reputation +1
   applied immediately, and the panel should return to showing
   "Request Task" so you can go again.
4. Repeat step 2-3 (always choosing the careful option) **5 times total**.
   After the 5th completion you should see a promotion banner and the rank
   label should change to **"Rank: Manager"**. (5 × Performance +2 = 10,
   5 × Reputation +1 = 5 — exactly the current calibration thresholds; see
   `PromotionConfig.lua`.)
   - The other two choices ("File it quickly" and "Cut corners...") are
     safe to try too, but will change how many completions you need:
     "quick" gives +1 Performance/+0 Reputation, and "cut corners" is a
     60/40 gamble that can also cost Reputation.

**As a Manager (after promotion):**
5. Once you're a Manager, a second panel should appear: "Assign the task
   to another Associate:" listing every *other* player currently in the
   server, each with an **Assign** button.
6. With only one player in the session, this list will be empty — that's
   expected, not a bug.

**Testing the Manager → second-player flow (needs 2 players):**
7. Use Studio's **Test > Start Server + 2 Players** (or two separate
   Studio/client sessions joining the same server). Promote one player to
   Manager per steps 1-4 above; leave the second as an Associate.
8. On the Manager's screen, click **Assign** next to the Associate's name.
   The Manager should see a confirmation message; the Associate should
   immediately see a "[Manager name] assigned you a task" notice and the
   task/choice panel should open for them automatically (no need to click
   "Request Task").
9. The Associate completes it exactly as in step 3. Trying to assign to a
   player who is already a Manager, or who already has a task in progress,
   should fail gracefully (an error message, not a crash).

**Testing leave/rejoin persistence:**
10. After making some progress (a few completed tasks, or after
    promotion), leave the game (close the client / stop the Play session)
    and rejoin. Your Rank, Money, Performance, and Reputation should all
    be exactly as you left them — persistence is handled server-side via
    `DataStoreService` and is independent of anything the client displays.

### 3. What "working" looks like

- Server output (the Studio **Output** window) should show `[Bootstrap]`
  startup lines and no repeated warnings once a player has successfully
  loaded.
- The task/choice/result loop, the promotion banner, and the Manager
  assignment flow should all feel instantaneous (well under a second) —
  all of the above is ordinary `RemoteEvent` round-trips to a
  server that has already computed the result.
- If every player fails to load and gets kicked, re-check steps 3-4 above
  first (publish + "Studio Access to API Services") — that is by far the
  most common cause.
