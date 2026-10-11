// "Happy First Birthday" premium plaque - one colour
// Layered plate with bunting, balloons, a one-candle cake, confetti,
// elegant lettering and a tiny maker's mark.
// Uses only OpenSCAD's built-in Liberation Serif font - nothing to install.
// Print flat, back down, no supports.

/* [Plaque] */
plate_w   = 240;   // width in mm
plate_h   = 176;   // height in mm
plate_t   = 4;     // base plate thickness
panel_in  = 8;     // raised panel inset from the edge
panel_t   = 1.6;   // raised panel height
corner_r  = 8;     // corner radius
bevel     = 1.6;   // bevel around the base edge
relief    = 2.0;   // how far the lettering stands out
mark_relief = 0.8; // height of the tiny maker's mark
keyhole   = true;  // two keyhole slots on the back for hanging
gold      = "#d4af37"; // preview colour

/* [Text] */
line1  = "Happy";
line2  = "FIRST BIRTHDAY";
makers = "ISHAAN  ·  SAHIL  ·  ARMAAN";
serif      = "Liberation Serif:style=Bold";
serif_it   = "Liberation Serif:style=Bold Italic";
serif_thin = "Liberation Serif:style=Regular";

$fn = 48;

// ---------- 2D helpers ----------

module rrect(w, h, r) {
    offset(r = r) square([w - 2 * r, h - 2 * r], center = true);
}

// border line inset from the plate edge
module ring(inset, width) {
    difference() {
        rrect(plate_w - 2 * inset, plate_h - 2 * inset, max(corner_r - inset / 3, 1));
        rrect(plate_w - 2 * (inset + width), plate_h - 2 * (inset + width),
              max(corner_r - inset / 3 - width, 0.5));
    }
}

module words(t, size, spacing, font = serif) {
    text(t, size = size, font = font, halign = "center", valign = "center", spacing = spacing);
}

function star_r(i, r) = i % 2 == 0 ? r : r * 0.42;
module star(r, points = 5) {
    polygon([for (i = [0 : 2 * points - 1])
        [star_r(i, r) * cos(90 + i * 180 / points), star_r(i, r) * sin(90 + i * 180 / points)]]);
}

module outline(w) { difference() { children(); offset(delta = -w) children(); } }

// thin line between two points
module seg(p, q, w = 1.2) { hull() { translate(p) circle(d = w); translate(q) circle(d = w); } }

// curved string for the bunting
function bunting_y(x) = 50 + 14 * pow(x / 64, 2);

module bunting() {
    for (x = [-64 : 4 : 60]) seg([x, bunting_y(x)], [x + 4, bunting_y(x + 4)]);
    for (i = [0 : 8]) {
        x = -56 + i * 14;
        a = atan(2 * 14 * x / (64 * 64));
        translate([x, bunting_y(x)]) rotate(a) {
            flag = [[-5.5, 0], [5.5, 0], [0, -11]];
            if (i % 2 == 0) polygon(flag);
            else { outline(1.2) polygon(flag); translate([0, -4]) circle(d = 2); }
        }
    }
}

module balloon(r) {
    outline(1.6) scale([1, 1.25]) circle(r = r);
    // shine
    intersection() {
        outline(1.0) scale([1, 1.25]) circle(r = r * 0.68);
        translate([-r, 0]) square([r * 0.9, r * 1.4]);
    }
    // knot
    translate([0, -r * 1.25]) polygon([[-2, -2.4], [2, -2.4], [0, 0.6]]);
}

// wavy string from p down to q
module string(p, q) {
    n = 12;
    for (i = [0 : n - 1]) {
        t0 = i / n; t1 = (i + 1) / n;
        seg(p + (q - p) * t0 + [1.8 * sin(t0 * 720), 0],
            p + (q - p) * t1 + [1.8 * sin(t1 * 720), 0], 1.1);
    }
}

module balloon_bunch() {
    translate([-89, 18]) balloon(10);
    translate([-73, 34]) balloon(8.5);
    string([-89, 3], [-81, -34]);
    string([-73, 21], [-81, -34]);
    // little bow where the strings meet
    translate([-81, -34]) {
        for (s = [-1, 1]) scale([s, 1]) polygon([[0, 0], [5, 2.6], [5, -2.6]]);
        circle(d = 2.6);
    }
}

module cake() {
    // bottom tier with scalloped icing
    translate([0, -45]) outline(1.4) offset(r = 1.5) square([42, 13], center = true);
    for (x = [-18 : 6 : 18]) translate([x, -40]) outline(1.1) circle(r = 3);
    // top tier
    translate([0, -32.5]) outline(1.4) offset(r = 1.5) square([28, 10], center = true);
    for (x = [-10 : 5 : 10]) translate([x, -29]) circle(d = 1.8);
    // plate line
    seg([-28, -53.5], [28, -53.5], 1.4);
    // one candle with a flame
    translate([0, -22.5]) outline(1.0) square([3.6, 10], center = true);
    hull() { translate([0, -15]) circle(r = 2.2); translate([0, -10]) circle(d = 0.6); }
}

CONFETTI_DOTS  = [[-30, 47], [34, 44], [-46, 18], [50, 22], [-56, -10], [58, -14],
                  [-40, -40], [42, -42], [-18, 60], [20, 62], [-94, -50], [94, -50]];
CONFETTI_STARS = [[-48, 34], [46, 36], [-36, -22], [38, -24], [-94, 52], [94, 52],
                  [-64, -48], [66, -50]];

module confetti() {
    for (p = CONFETTI_DOTS) translate(p) circle(d = 2);
    for (p = CONFETTI_STARS) translate(p) star(2.6);
}

module artwork_2d() {
    ring(14, 1.8);
    ring(18, 0.9);
    bunting();
    balloon_bunch();
    mirror([1, 0]) balloon_bunch();
    confetti();
    translate([0, 27]) words(line1, 20, 1.05, serif_it);
    translate([0, 1]) words(line2, 9.5, 1.15);
    cake();
}

module makers_mark_2d() {
    translate([0, -63]) words(makers, 3.2, 1.15, serif_thin);
}

// ---------- 3D ----------

// stepped bevel on the top edge of an extruded shape
module bevelled(h, c, steps = 5) {
    linear_extrude(h - c) children();
    for (i = [1 : steps])
        translate([0, 0, h - c + (i - 1) * c / steps])
            linear_extrude(c / steps) offset(delta = -c * i / steps) children();
}

module keyhole_cut() {
    translate([0, 0, -0.01]) {
        cylinder(d = 9, h = 3.2);
        translate([-2.25, 0, 0]) cube([4.5, 9, 3.2]);
        translate([0, 9, 0]) cylinder(d = 4.5, h = 3.2);
    }
}

module plaque() {
    top = plate_t + panel_t - 0.02;
    difference() {
        union() {
            bevelled(plate_t, bevel) rrect(plate_w, plate_h, corner_r);
            translate([0, 0, plate_t - 0.01])
                bevelled(panel_t, 0.8, 4)
                    rrect(plate_w - 2 * panel_in, plate_h - 2 * panel_in, corner_r - 2);
        }
        if (keyhole)
            for (x = [-plate_w / 4, plate_w / 4])
                translate([x, plate_h / 2 - 40, 0]) keyhole_cut();
    }
    translate([0, 0, top]) bevelled(relief, 0.5, 3) artwork_2d();
    translate([0, 0, top]) linear_extrude(mark_relief) makers_mark_2d();
}

color(gold) plaque();
