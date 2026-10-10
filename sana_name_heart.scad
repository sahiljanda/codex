// "Sana" premium standing script sign with heart
// One colour, one solid piece, no fonts needed: every letter is drawn as
// calligraphy strokes with thin hairlines and swelling downstrokes.
// Print lying flat (front face up), then stand it on its flat bottom.

/* [Size] */
scale_by  = 1.0;   // 1.0 = about 182 x 66 mm
thickness = 10;    // depth of the sign in mm (deeper = steadier)

/* [Strokes] */
hair  = 2.2;       // hairline width (keep >= 1.6 for strength)
heavy = 6.4;       // widest point of the downstrokes
slant = 6;         // italic slant in degrees

/* [Finish] */
chamfer   = 0.8;   // bevel on the front edges for a polished look
flat_cut  = 1.0;   // flat foot line (mm above baseline); every letter sits on it

$fn = 32;

// ---------- stroke engine ----------

function bez(p, t) =
    pow(1 - t, 3) * p[0] + 3 * pow(1 - t, 2) * t * p[1] +
    3 * (1 - t) * t * t * p[2] + t * t * t * p[3];

// width along a stroke: blend start->end plus a swell in the middle
function swell_of(s) = len(s) > 6 ? s[6] : 0;
function wid(s, t) = s[4] + (s[5] - s[4]) * t + swell_of(s) * sin(180 * t);

// s = [p0, p1, p2, p3, start_w, end_w, swell]
module stroke(s, n = 40) {
    for (i = [0 : n - 1]) {
        t0 = i / n;
        t1 = (i + 1) / n;
        hull() {
            translate(bez(s, t0)) circle(d = wid(s, t0));
            translate(bez(s, t1)) circle(d = wid(s, t1));
        }
    }
}

module stroke_list(segs) { for (s = segs) stroke(s); }

module ball(p, d) { translate(p) circle(d = d); }

HW = hair;
KW = heavy;
SWL = KW - HW;        // swell amount for a thin-thick-thin stroke

function rot(p, a) = [p[0] * cos(a) - p[1] * sin(a), p[0] * sin(a) + p[1] * cos(a)];

// ---------- letters (upright, baseline y = 0, slant applied later) ----------

// Capital S: hairline entry sweeping up, curl over the top, swelling spine,
// bottom bowl, then a baseline loop that flows into the "a".
S_STROKES = [
    // entry hairline rising from the left
    [[2, 24], [6, 44], [26, 64], [42, 66], HW, HW],
    // over the top and turning down-left (starts to swell)
    [[42, 66], [52, 66], [50, 56], [40, 56], HW, HW],
    [[40, 56], [30, 56], [20, 54], [20, 46], HW, KW],
    // the spine: heavy diagonal swing to the right
    [[20, 46], [20, 36], [42, 32], [42, 18], KW, KW],
    // bottom bowl curling back to the left
    [[42, 18], [42, 2], [22, -1], [12, 4], KW, HW],
    [[12, 4], [6, 8], [8, 14], [14, 12], HW, HW],
    // baseline swash out to the right
    [[14, 12], [20, 10], [28, 1], [40, 1], HW, HW],
];
S_START = [2, 24];

// floating hairline swash off the S, sailing over the lowercase letters
SWASH = [
    [[48, 63], [66, 64], [92, 60], [112, 48], HW + 0.4, HW],
    [[112, 48], [118, 44], [118, 38], [113, 39], HW, HW],
    [[113, 39], [109, 40], [110, 45], [114, 44], HW, HW],
];

// lowercase a at x = ox: oval bowl + straight stem, x-height 24
function a_letter(ox) = [
    // left of the bowl swells, right side stays thin
    [[ox + 10, 24], [ox + 4, 24], [ox, 19], [ox, 12], HW, KW * 0.85],
    [[ox, 12], [ox, 5], [ox + 4, 0], [ox + 10, 0], KW * 0.85, HW],
    [[ox + 10, 0], [ox + 15, 0], [ox + 18, 5], [ox + 18, 12], HW, HW],
    [[ox + 18, 12], [ox + 18, 19], [ox + 15, 24], [ox + 10, 24], HW, HW],
    // straight stem with a small exit hook
    [[ox + 18.5, 24], [ox + 18.5, 17], [ox + 18.5, 10], [ox + 18.5, 3], KW * 0.9, KW * 0.9],
    [[ox + 18.5, 3], [ox + 18.5, 0.5], [ox + 20.5, 0], [ox + 23, 1.5], KW * 0.9, HW],
];

// lowercase n at x = ox: straight legs, smooth arch
function n_letter(ox) = [
    [[ox + 2, 24], [ox + 2, 16], [ox + 2, 8], [ox + 2, 0], KW * 0.9, KW * 0.9],
    [[ox + 2, 14], [ox + 4, 21], [ox + 7, 24], [ox + 11, 24], HW, HW],
    [[ox + 11, 24], [ox + 15, 24], [ox + 17, 21], [ox + 17, 16], HW, KW * 0.9],
    [[ox + 17, 16], [ox + 17, 11], [ox + 17, 7], [ox + 17, 3], KW * 0.9, KW * 0.9],
    [[ox + 17, 3], [ox + 17, 0.5], [ox + 19, 0], [ox + 21.5, 1.5], KW * 0.9, HW],
];

// joining hairline from an exit at (x0, 1.5) up to (x1, y1)
function join(x0, x1, y1) =
    [[x0, 1.5], [x0 + 3, 3], [x1 - 4, y1 - 8], [x1, y1], HW, HW];

A1 = 52;           // first a
N1 = A1 + 28;      // n
A2 = N1 + 27;      // second a

// Heart: drawn like a pen stroke, heavier on the left lobe
HEART = [
    [[0, 0], [-6, 8], [-18, 13], [-18, 24], HW + 0.6, HW, SWL * 0.3],
    [[-18, 24], [-18, 33], [-6, 35], [0, 26], HW, HW],
    [[0, 26], [6, 35], [18, 33], [18, 24], HW, HW],
    [[18, 24], [18, 13], [6, 8], [0, 0], HW, HW + 0.6, SWL * 0.3],
    // pen flick crossing out past the point
    [[0, 0], [-3, -3], [-9, -3], [-13, 1], HW + 0.6, HW],
];
heart_angle = -8;
heart_pos   = [A2 + 52, 3];
heart_join  = heart_pos + rot(bez(HEART[0], 0.5), heart_angle);

LIFT = 9;           // small letters float this high above the table

module sana_upright() {
    stroke_list(S_STROKES);
    ball(S_START, HW * 1.9);
    // S swash rises up into the floating "a"
    stroke([[40, 1], [48, 2], [A1 - 5, LIFT + 16], [A1 + 7, LIFT + 24.5], HW, HW]);

    // floating lowercase letters
    translate([0, LIFT]) {
        stroke_list(a_letter(A1));
        stroke(join(A1 + 23, N1 + 2, 22));
        stroke_list(n_letter(N1));
        stroke([[N1 + 21.5, 1.5], [A2 - 3, 6], [A2 - 4, 21], [A2 + 7, 24.5], HW, HW]);
        stroke_list(a_letter(A2));
    }

    // last a swoops down to the heart, which stands on the table
    stroke([[A2 + 23, LIFT + 1.5], [A2 + 28, LIFT + 2.5], heart_join - [8, 1], heart_join, HW, HW]);
    translate(heart_pos) rotate(heart_angle) stroke_list(HEART);
}

// italic slant (shear x by y)
module slanted() {
    multmatrix([[1, tan(slant), 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
        children();
}

// flat foot so it stands up
module sign_2d() {
    intersection() {
        slanted() sana_upright();
        translate([-100, flat_cut]) square([600, 300]);
    }
}

// body plus a stepped bevel on the front face
module sign_3d() {
    steps = 4;
    linear_extrude(thickness - chamfer) sign_2d();
    for (i = [1 : steps])
        translate([0, 0, thickness - chamfer + (i - 1) * chamfer / steps])
            linear_extrude(chamfer / steps)
                offset(delta = -chamfer * i / steps) sign_2d();
}

scale([scale_by, scale_by, 1]) sign_3d();
