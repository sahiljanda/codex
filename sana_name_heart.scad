// "Sana" standing script name with heart - one colour, no fonts needed.
// Letters are drawn as connected calligraphy strokes (Bezier curves),
// so the whole sign is one solid piece.
// Print lying flat, then stand it up on its flat bottom edge.

thickness = 8;     // depth of the sign in mm
stroke_w  = 3.6;   // base stroke width in mm (thin strokes)
thick_w   = 5.6;   // width of the heavy downstrokes
scale_by  = 1.0;   // 1.0 = about 162 x 64 mm
flat_cut  = 0;     // height of the flat bottom cut (raise for a wider foot)

$fn = 24;

// ---------- Bezier stroke helpers ----------

function bez(p, t) =
    pow(1 - t, 3) * p[0] + 3 * pow(1 - t, 2) * t * p[1] +
    3 * (1 - t) * t * t * p[2] + t * t * t * p[3];

// seg = [p0, p1, p2, p3, start_width, end_width]
module seg_stroke(seg, n = 28) {
    w0 = len(seg) > 4 ? seg[4] : stroke_w;
    w1 = len(seg) > 5 ? seg[5] : w0;
    for (i = [0 : n - 1]) {
        t0 = i / n;
        t1 = (i + 1) / n;
        hull() {
            translate(bez(seg, t0)) circle(d = w0 + (w1 - w0) * t0);
            translate(bez(seg, t1)) circle(d = w0 + (w1 - w0) * t1);
        }
    }
}

module path(segs) { for (s = segs) seg_stroke(s); }

T = stroke_w;
B = thick_w;

// ---------- Letters (baseline at y = 0) ----------

// Capital S with top flourish and a bottom loop that runs into the "a"
S = [
    // little curl at the start of the top stroke
    [[32, 52], [32, 46], [41, 48], [41, 55], T, T],
    // big arc over the top
    [[41, 55], [41, 64], [22, 66], [16, 55], T, T],
    // top bowl going down-left
    [[16, 55], [12, 47], [6, 46], [8, 38], T, B],
    // spine of the S (heavy diagonal)
    [[8, 38], [12, 30], [32, 24], [30, 12], B, B],
    // bottom bowl curling left
    [[30, 12], [28, 1], [10, -1], [6, 6], B, T],
    // loop back under and out to the right (joins the a)
    [[6, 6], [4, 12], [12, 10], [22, 3], T, T],
];

// rotate a 2D point
function rot(p, a) = [p[0] * cos(a) - p[1] * sin(a), p[0] * sin(a) + p[1] * cos(a)];

// lowercase a at x = ox (bowl + stem), x-height ~22
function a_letter(ox) = [
    // bowl, counter-clockwise from top right
    [[ox + 16, 20], [ox + 8, 25], [ox, 20], [ox, 10], T, B],
    [[ox, 10], [ox, 0], [ox + 11, -1], [ox + 16, 8], B, T],
    // stem
    [[ox + 17, 22], [ox + 17, 14], [ox + 16.5, 5], [ox + 19, 1], B, B],
];

// lowercase n at x = ox
function n_letter(ox) = [
    // first leg
    [[ox + 2, 22], [ox + 2, 15], [ox + 2, 7], [ox + 2, 0.5], B, B],
    // arch
    [[ox + 2, 7], [ox + 4, 22], [ox + 17, 26], [ox + 17, 13], T, B],
    // second leg
    [[ox + 17, 13], [ox + 17, 7], [ox + 16.5, 3], [ox + 19, 1], B, B],
];

A1 = 42;            // first a
N  = A1 + 27;       // n
A2 = N + 29;        // second a

// Heart outline (point at bottom) in local coords, ~32 mm wide
HEART = [
    [[0, 0], [-4, 6], [-16, 12], [-16, 22], B, T],
    [[-16, 22], [-16, 31], [-5, 33], [0, 24], T, T],
    [[0, 24], [5, 33], [16, 31], [16, 22], T, T],
    [[16, 22], [16, 12], [4, 6], [0, 0], T, B],
];
heart_angle = -12;
heart_pos   = [A2 + 46, 0];
heart_join  = heart_pos + rot(bez(HEART[0], 0.55), heart_angle);

module sana_2d() {
    path(S);
    // S tail runs up into the top of the first a
    seg_stroke([[22, 3], [32, -2], [A1 - 4, 12], [A1 + 6, 22], T, T]);

    path(a_letter(A1));
    // a -> n
    seg_stroke([[A1 + 19, 1], [A1 + 23, -1], [N - 2, 12], [N + 2, 22], T, T]);

    path(n_letter(N));
    // n -> a
    seg_stroke([[N + 19, 1], [N + 24, -1], [A2 - 4, 12], [A2 + 6, 22], T, T]);

    path(a_letter(A2));
    // last a tail sweeps into the heart
    seg_stroke([[A2 + 19, 1], [A2 + 24, -1], [A2 + 26, 10], heart_join, T, T]);

    translate(heart_pos) rotate(heart_angle) path(HEART);
}

// Flat bottom so it stands up
module sign_2d() {
    intersection() {
        sana_2d();
        translate([-50, flat_cut]) square([400, 200]);
    }
}

scale([scale_by, scale_by, 1])
    linear_extrude(thickness) sign_2d();
