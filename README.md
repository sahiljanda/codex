# Blox Fruits · Loadout Auction

A single-file browser game. Two captains get an equal purse, items come out of the crate **one at a
time**, and you **bid each other up** until someone folds. Best PvP inventory at the end wins.
Play the AI or hot-seat a friend.

Open `index.html` in any browser. No build step, no dependencies, no internet needed.

## The rules

- **You never see what's coming.** Only the lot on the block is revealed; the rest of the crate stays
  sealed. Blow the purse on lot 1 and you'll watch the Godhuman go for a dollar.
- **Open ascending bidding.** $1 opens it, then it's back and forth — he bids $1, you bid $2, he bids
  $3 — until one captain folds. Last raise standing takes the item and pays what they said.
- Fold before the first bid and it's a **pass**; if both captains pass, the lot goes **unsold**.
- Run out of money and you're **tapped out** — the lot closes automatically.
- Who opens the bidding **alternates** each lot.
- Leftover money is worth nothing at the end, except as a tiebreaker.

## Scoring the inventory

Every item has a PvP rating (0–100). Your score is:

```
sum of item ratings
  − a second item in a category you already own only counts 30% (bench gear)
  + 6 points per extra category you cover
```

So winning three swords is a trap. The lot card tells you live which case you're in before you bid —
*"You already own a Sword, this one rides the bench at 30%"* vs *"New category: full points plus the
+6 bonus"*. Ties break on your single best item, then on leftover cash.

## The floor

A permanent display under the auction shows both captains side by side, updated after every lot:
each item won (bench gear greyed and flagged), the live inventory score, cash left, cash spent, and
how many categories each has covered. The leader's column is highlighted, and the header tells you
who's ahead and by how much with how many lots still in the crate.

## Modes

| | |
|---|---|
| **1 player vs AI** | Three difficulties — Rookie (Deckhand Dobo), Pirate (Captain Marla), Admiral (Admiral Vex). Your record per difficulty is kept in `localStorage`. |
| **2 players, one device** | Bids are public, so just pass the device back and forth as you raise each other. |

Purse ($15–$50) and lot count (3–10) are adjustable.

**Difficulty check.** Over 1500 simulated auctions each against a competent budget-paced bidder, the
AI wins **27% / 47% / 51%** (Rookie / Pirate / Admiral). Rookie bids on feelings; Pirate values items
honestly; Admiral values the *marginal* points an item adds to his own rack, jump-bids to scare you
off, and never pays more than a dollar over what your remaining purse could cover. In an ascending
auction the winner only pays one dollar over the loser's limit, so nobody runs away with it — Admiral
plays you roughly even and punishes every loose bid.

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
one more line. Scoring knobs `BENCH_MULT` (0.3) and `COVER_BONUS` (6) sit just below the array, and
the AI's three difficulty knobs are in `AI_TUNE`:

```js
const AI_TUNE = {
  mult:  [0.85, 1.05, 1.15],   // overall willingness to pay
  exp:   [1.00, 1.30, 2.10],   // how sharply value scales with how good the item is
  noise: [0.50, 0.20, 0.07]    // wobble in the valuation
};
```

Ratings are one opinionated snapshot of community consensus, not official data.

Fan-made. Not affiliated with Blox Fruits, Gamer Robot or Roblox.

---

*Earlier versions: sealed-bid auction in `f13d521`, blind ranking game in `cf437c6`.*
