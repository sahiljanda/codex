# Blox Fruits · Loadout Auction

A single-file browser game. Two captains get **$20 each**, **five items** go under the hammer, and
whoever assembles the better PvP inventory wins. Play against the AI or hot-seat against a friend.

Open `index.html` in any browser. No build step, no dependencies, no internet needed.

## The rules

- **All five lots are revealed up front.** You can see the Godhuman coming in lot 4 — budget accordingly.
- **Sealed bids.** Both captains bid in secret on each lot. Highest bid wins the item and pays what
  they bid; the loser pays nothing. Bid **$0** to pass — if both pass, the lot goes unsold.
- **Ties** go to whoever holds the priority token, which then flips to the other captain.
- **Money you keep is worth nothing** at the end, except as a tiebreaker.

## Scoring the inventory

Every item has a PvP rating (0–100). Your score is:

```
sum of item ratings
  − a second item in a category you already own only counts 30% (bench gear)
  + 6 points per extra category you cover
```

So sweeping three swords is a trap: the second and third are benched. Ties break on your single
best item, then on leftover cash.

## Modes

| | |
|---|---|
| **1 player vs AI** | Three difficulties — Rookie (Deckhand Dobo), Pirate (Captain Marla), Admiral (Admiral Vex). Your win/loss record per difficulty is kept in `localStorage`. |
| **2 players, one device** | Bids are masked as you type, with a pass-the-device screen between captains. |

Budget ($15–$50) and lot count (3–10) are both adjustable.

Against a reasonably sensible bidding strategy, the AI levels play out as roughly **31% / 53% / 61%**
win rates (Rookie / Pirate / Admiral) over 600 simulated auctions each — Rookie is free money,
Pirate is a coin flip, Admiral is hard but beatable.

## The item pool — 119 items

| Category | Count |
|---|---|
| Blox Fruits | 42 (Rocket → Kitsune, all rarities) |
| Swords | 35 (Katana → Cursed Dual Katana) |
| Guns | 10 (Slingshot → Soul Guitar) |
| Fighting Styles | 12 (Combat → Godhuman) |
| Races | 6 (Human, Shark, Ghoul, Cyborg, Mink, Angel) |
| Accessories | 14 (Bear Ears → Tomoe Ring) |

## Tweaking it

Items live in the `RAW` array at the top of the `<script>` block in `index.html`:

```js
["Dough","fruit","Mythical",88,"🍩","The combo fruit — awakened Dough defined PvP."],
//  name   category  rarity  rating  emoji  blurb
```

The rating is the only number scoring uses — disagree with a placement, change it. Adding an item is
one more line. The scoring knobs `BENCH_MULT` (0.3) and `COVER_BONUS` (6) sit just below the array,
and the AI's valuation lives in `aiBid()`.

Ratings are one opinionated snapshot of community consensus, not official data.

Fan-made. Not affiliated with Blox Fruits, Gamer Robot or Roblox.

---

*An earlier blind-ranking version of this game is preserved in commit `cf437c6` if you ever want it back.*
