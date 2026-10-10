// "Happy First Birthday Sana" premium arched plaque
// Arched plate with bevelled edge, double border, serif capitals,
// hand-drawn calligraphy "Sana" + heart, and a "1" medallion with stars.
// Uses only OpenSCAD's built-in Liberation Serif font - nothing to install.
// Print flat, back down, no supports. Two-tone: change filament at plate_t.

/* [Plaque] */
plate_w   = 180;   // width in mm
plate_h   = 220;   // height in mm (top is a half circle)
plate_t   = 5;     // plate thickness
bevel     = 1.6;   // bevel around the plate edge
relief    = 2.0;   // how far the artwork stands out
keyhole   = true;  // keyhole slot on the back for hanging

/* [Text] */
line1 = "HAPPY";
line2 = "FIRST BIRTHDAY";
serif = "Liberation Serif:style=Bold";

/* [Name strokes] */
hair  = 2.2;
heavy = 6.4;
slant = 6;
name_scale = 0.78;

// preview colours only
plate_colour = "#1d2a3a";
art_colour   = "#d4af37";

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

// ---------- layout helpers ----------

module slanted() {
    multmatrix([[1, tan(slant), 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
        children();
}

// arch: rectangle with a half-circle top, centred on the origin
module arch(w, h) {
    r = w / 2;
    translate([0, -h / 2]) {
        translate([-r, 0]) square([w, h - r]);
        translate([0, h - r]) circle(r = r, $fn = 160);
    }
}

module arch_ring(w, h, inset, width) {
    difference() {
        offset(delta = -inset) arch(w, h);
        offset(delta = -inset - width) arch(w, h);
    }
}

module caps(t, size, spacing) {
    text(t, size = size, font = serif, halign = "center", valign = "center", spacing = spacing);
}

function star_r(i, r) = i % 2 == 0 ? r : r * 0.42;
module star(r, points = 5) {
    polygon([for (i = [0 : 2 * points - 1])
        [star_r(i, r) * cos(90 + i * 180 / points), star_r(i, r) * sin(90 + i * 180 / points)]]);
}

// thin line with a diamond in the middle
module divider(len) {
    translate([-len / 2, -0.6]) square([len / 2 - 5, 1.2]);
    translate([5, -0.6]) square([len / 2 - 5, 1.2]);
    rotate(45) square(4.2, center = true);
}

// name artwork centred on the origin
module name_art() {
    scale(name_scale) translate([-93, -33]) slanted() sana_upright();
}

module medallion() {
    difference() { circle(r = 13); circle(r = 11.4); }
    text("1", size = 14, font = serif, halign = "center", valign = "center");
    for (s = [-1, 1]) {
        translate([s * 24, 0]) star(4.5);
        translate([s * 36, 0]) star(2.8);
    }
}

module artwork_2d() {
    arch_ring(plate_w, plate_h, 6, 1.8);
    arch_ring(plate_w, plate_h, 10, 0.9);
    translate([0, 62]) caps(line1, 9, 1.35);
    translate([0, 45]) caps(line2, 9.5, 1.12);
    translate([0, 31]) divider(70);
    translate([0, -4]) name_art();
    translate([0, -42]) divider(70);
    translate([0, -68]) medallion();
}

// stepped bevel on the top edge of an extruded shape
module bevelled(h, c, steps = 5) {
    linear_extrude(h - c) children();
    for (i = [1 : steps])
        translate([0, 0, h - c + (i - 1) * c / steps])
            linear_extrude(c / steps) offset(delta = -c * i / steps) children();
}

module keyhole_cut() {
    translate([0, 0, -0.01]) {
        cylinder(d = 9, h = 3.2, $fn = 32);
        translate([-2.25, 0, 0]) cube([4.5, 9, 3.2]);
        translate([0, 9, 0]) cylinder(d = 4.5, h = 3.2, $fn = 32);
    }
}

module plaque() {
    color(plate_colour) difference() {
        bevelled(plate_t, bevel) arch(plate_w, plate_h);
        if (keyhole) translate([0, plate_h / 2 - 45, 0]) keyhole_cut();
    }
    color(art_colour) translate([0, 0, plate_t - 0.01])
        bevelled(relief, 0.5, 3) artwork_2d();
}

plaque();
