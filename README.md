# Blox Fruits · Blind Ranking

A single-file browser game. Items from Blox Fruits are dealt to you **one at a time**, and you have to
lock each one into a ranking slot before you see what's coming next. No takebacks. At the end your
list is scored against a meta ranking.

Open `index.html` in any browser. No build step, no dependencies, no internet needed.

## How it works

1. **Pick your pool** — Blox Fruits, Swords, Guns, Fighting Styles, Races, Accessories (any mix).
2. **Pick your slot count** — 5, 10, 15, 20, or *Every item* in the pool.
3. **Pick your draw**
   - *Balanced* — one item from each power band, the fairest test of your reads.
   - *Chaos* — pure random; expect three commons in a row.
   - *Endgame* — top half of the pool only, so there are no free calls.
4. **Rank blind** — click a slot, or press `1`–`9` / `0` for the first ten. `#1` is the best.
5. **Get scored** — every head-to-head pair inside your list is checked against the meta ordering.
   Random placement averages ~50%, so anything above that is real knowledge.

## What's in the item database

| Category | Count |
|---|---|
| Blox Fruits | 42 (Rocket → Kitsune, all rarities) |
| Swords | 35 (Katana → Cursed Dual Katana) |
| Guns | 10 (Slingshot → Soul Guitar) |
| Fighting Styles | 12 (Combat → Godhuman) |
| Races | 6 (Human, Shark, Ghoul, Cyborg, Mink, Angel) |
| Accessories | 14 (Bear Ears → Tomoe Ring) |
| **Total** | **119** |

## Tweaking the rankings

Every item lives in the `RAW` array near the top of the `<script>` block in `index.html`:

```js
["Dough","fruit","Mythical",88,"🍩","The combo fruit — awakened Dough defined PvP."],
//  name   category  rarity  meta  emoji  blurb
```

`meta` is a 0–100 score for overall PvP / endgame value and is the only thing scoring uses — the game
ranks whatever items it dealt you by that number. Disagree with a placement? Change the number.
Adding an item is one more line in the same array; nothing else needs touching.

Meta scores are one opinionated snapshot of community consensus, not official data.

Fan-made. Not affiliated with Blox Fruits, Gamer Robot or Roblox.
