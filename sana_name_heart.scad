// "Sana" premium standing script sign with heart
// One colour, one solid piece, no fonts needed: every letter is drawn as
// calligraphy strokes with thin hairlines and swelling downstrokes.
// Print lying flat (front face up), then stand it on its flat bottom.

/* [Size] */
scale_by  = 1.0;   // 1.0 = about 190 x 66 mm
thickness = 10;    // depth of the sign in mm (deeper = steadier)

/* [Strokes] */
hair  = 2.0;       // hairline width (keep >= 1.6 for strength)
heavy = 6.4;       // widest point of the downstrokes
slant = 14;        // italic slant in degrees

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

// lowercase a at x = ox, x-height 24
function a_letter(ox) = [
    // bowl: hairline over the top, heavy down the left, hairline back up
    [[ox + 18, 21], [ox + 12, 26], [ox + 2, 24], [ox + 1, 13], HW, HW, SWL * 0.6],
    [[ox + 1, 13], [ox, 3], [ox + 6, -1], [ox + 12, 2], HW, HW, SWL * 0.5],
    [[ox + 12, 2], [ox + 16, 4], [ox + 18, 10], [ox + 19, 16], HW, HW],
    // stem: heavy downstroke into a hairline exit
    [[ox + 20, 24], [ox + 20, 14], [ox + 19, 5], [ox + 21, 1.5], HW, HW, SWL],
];

// lowercase n at x = ox
function n_letter(ox) = [
    // first leg
    [[ox + 3, 24], [ox + 3, 16], [ox + 3, 8], [ox + 3, 0.5], HW, HW, SWL],
    // hairline arch
    [[ox + 3, 8], [ox + 6, 22], [ox + 12, 27], [ox + 17, 25], HW, HW],
    // second leg swelling down
    [[ox + 17, 25], [ox + 22, 23], [ox + 20, 10], [ox + 20, 4], HW, HW, SWL],
    [[ox + 20, 4], [ox + 20, 1], [ox + 22, 0.5], [ox + 23, 1.5], HW, HW],
];

// joining hairline from (x0, 1.5) up to the top of the next letter
function join(x0, x1) =
    [[x0, 1.5], [x0 + 4, -1], [x1 - 4, 12], [x1, 23], HW, HW];

A1 = 51;           // first a
N  = A1 + 30;      // n
A2 = N + 33;       // second a

// Heart: drawn like a pen stroke, heavier on the left lobe
HEART = [
    [[0, 0], [-6, 8], [-18, 13], [-18, 24], HW + 0.6, HW, SWL * 0.35],
    [[-18, 24], [-18, 33], [-6, 35], [-1, 27], HW, HW],
    // little curl in the dip of the heart
    [[-1, 27], [-2, 18], [7, 18], [3, 27], HW, HW],
    [[3, 27], [8, 35], [18, 33], [18, 23], HW, HW],
    [[18, 23], [18, 12], [6, 7], [0, 0], HW, HW + 0.6, SWL * 0.25],
    // pen flick crossing out past the point
    [[0, 0], [-3, -3], [-9, -3], [-13, 1], HW + 0.6, HW],
];
heart_angle = -14;
heart_pos   = [A2 + 52, 3];
heart_join  = heart_pos + rot(bez(HEART[0], 0.5), heart_angle);

module sana_upright() {
    stroke_list(S_STROKES);
    stroke_list(SWASH);
    ball(S_START, HW * 1.9);
    stroke([[40, 1], [46, 1], [A1 - 2, 14], [A1 + 9, 24.5], HW, HW]);

    stroke_list(a_letter(A1));
    stroke(join(A1 + 21, N + 3));

    stroke_list(n_letter(N));
    stroke([[N + 23, 1.5], [N + 28, 2], [A2 - 2, 14], [A2 + 9, 24.5], HW, HW]);

    stroke_list(a_letter(A2));
    // last a sweeps out into the heart
    stroke([[A2 + 21, 1.5], [A2 + 27, -1], [A2 + 30, 12], heart_join, HW, HW]);

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
