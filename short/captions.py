#!/usr/bin/env python3
"""Build an ASS subtitle file with viral-style animated captions.

Two kinds of events:
  * hook  - oversized headline that slams in, overshoots, then settles
  * pop   - word-by-word captions that scale-pop, one chunk at a time
"""

PLAY_W, PLAY_H = 1080, 1920

FONT_FILE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Widest a line may draw. Keeps text clear of the frame edge, and leaves room
# for the outline plus the overshoot the pop animation scales through.
HOOK_MAX_W = 940
CAP_MAX_W = 920

_font_cache = {}


def _measure(text, size):
    """Rendered width of `text` at `size`, in pixels."""
    try:
        from PIL import ImageFont
    except ImportError:
        # No PIL: fall back to a conservative average-advance estimate.
        return len(text) * size * 0.62

    font = _font_cache.get(size)
    if font is None:
        try:
            font = ImageFont.truetype(FONT_FILE, size)
        except OSError:
            return len(text) * size * 0.62
        _font_cache[size] = font
    return font.getbbox(text)[2] - font.getbbox(text)[0]


def fit_size(lines, base, scale_x, max_w, overshoot=1.0):
    """Largest size <= base at which every line fits inside `max_w`."""
    widest = max((l for l in lines), key=lambda t: _measure(t, base), default="")
    if not widest:
        return base
    for size in range(base, 23, -2):
        if _measure(widest, size) * (scale_x / 100.0) * overshoot <= max_w:
            return size
    return 24

HEADER = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {PLAY_W}
PlayResY: {PLAY_H}
ScaledBorderAndShadow: yes
WrapStyle: 2
YCbCr Matrix: TV.709

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Hook,DejaVu Sans,118,&H00FFFFFF,&H000000FF,&H00101010,&H99000000,-1,0,0,0,104,104,1.5,0,1,9,5,5,60,60,0,1
Style: HookAcc,DejaVu Sans,118,&H0033E0FF,&H000000FF,&H00101010,&H99000000,-1,0,0,0,104,104,1.5,0,1,9,5,5,60,60,0,1
Style: Cap,DejaVu Sans,92,&H00FFFFFF,&H000000FF,&H00101010,&H99000000,-1,0,0,0,102,102,1.0,0,1,8,4,2,70,70,0,1
Style: CapAcc,DejaVu Sans,92,&H0033E0FF,&H000000FF,&H00101010,&H99000000,-1,0,0,0,102,102,1.0,0,1,8,4,2,70,70,0,1
Style: Tag,DejaVu Sans,58,&H00FFFFFF,&H000000FF,&H00101010,&H99000000,-1,0,0,0,100,100,2.0,0,1,6,3,8,60,60,70,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""


def ts(t):
    """Seconds -> ASS 0:00:00.00 timestamp."""
    t = max(0.0, t)
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = t % 60
    return f"{h}:{m:02d}:{s:05.2f}"


def esc(s):
    return s.replace("\\", "\\\\").replace("{", "\\{").replace("}", "\\}")


class Ass:
    def __init__(self):
        self.events = []

    def _add(self, layer, start, end, style, text):
        self.events.append(
            f"Dialogue: {layer},{ts(start)},{ts(end)},{style},,0,0,0,,{text}"
        )

    def hook(self, start, end, lines, y=760, accent_idx=None):
        """Headline that slams in with an overshoot, holds, then snaps out.

        `lines` is a list of text rows; `accent_idx` marks which row is coloured.
        """
        n = len(lines)
        upper = [l.upper() for l in lines]
        # One size for the whole block: sizing each line on its own would leave
        # the short line looking bigger than the long one.
        size = fit_size(upper, 118, 104, HOOK_MAX_W, overshoot=1.04)
        line_h = int(size * 1.28)
        top = y - (n - 1) * line_h / 2

        for i, raw in enumerate(lines):
            style = "HookAcc" if accent_idx is not None and i == accent_idx else "Hook"
            cy = top + i * line_h
            delay = i * 0.07
            st = start + delay
            # Slam in from small + rotated, overshoot past 100%, settle, then a
            # slow drift so the card never looks frozen.
            tags = (
                r"{\an5\pos(%d,%d)\fs%d\fad(0,140)"
                r"\fscx40\fscy40\frz%s"
                r"\t(0,110,\fscx116\fscy116\frz0)"
                r"\t(110,210,\fscx100\fscy100)"
                r"\t(210,%d,\fscx104\fscy104)}"
            ) % (PLAY_W // 2, int(cy), size, "-7" if i % 2 == 0 else "6",
                 max(400, int((end - st) * 1000)))
            self._add(2, st, end, style, tags + esc(raw.upper()))

    def pop(self, cues, y=1430, accent_words=()):
        """Word-chunk captions. `cues` is a list of (start, end, text)."""
        acc = {w.upper().strip(".,!?") for w in accent_words}
        for start, end, text in cues:
            words = text.split()
            if not words:
                continue
            chunks = _chunk(words)
            span = max(0.18, end - start)
            per = span / len(chunks)
            for j, ch in enumerate(chunks):
                cs = start + j * per
                ce = cs + per + 0.04  # slight overlap kills any 1-frame gap
                txt = " ".join(ch).upper()
                style = "CapAcc" if acc and any(
                    w.upper().strip(".,!?") in acc for w in ch
                ) else "Cap"
                size = fit_size([txt], 92, 102, CAP_MAX_W, overshoot=1.12)
                tags = (
                    r"{\an5\pos(%d,%d)\fs%d"
                    r"\fscx58\fscy58"
                    r"\t(0,80,\fscx112\fscy112)"
                    r"\t(80,150,\fscx100\fscy100)}"
                ) % (PLAY_W // 2, y, size)
                self._add(3, cs, ce, style, tags + esc(txt))

    def tag(self, start, end, text, y=1760):
        tags = r"{\an5\pos(%d,%d)\fad(120,160)\alpha&H30&}" % (PLAY_W // 2, y)
        self._add(1, start, end, "Tag", tags + esc(text.upper()))

    def render(self, path):
        with open(path, "w", encoding="utf-8") as f:
            f.write(HEADER)
            f.write("\n".join(self.events))
            f.write("\n")


def _chunk(words):
    """Group words so each on-screen chunk stays short and readable."""
    out, cur, n = [], [], 0
    for w in words:
        # Long words go alone; otherwise keep chunks under ~14 characters.
        if cur and (n + len(w) + 1 > 14 or len(cur) >= 3):
            out.append(cur)
            cur, n = [], 0
        cur.append(w)
        n += len(w) + 1
    if cur:
        out.append(cur)
    return out
