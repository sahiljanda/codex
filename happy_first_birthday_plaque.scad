// "Happy First Birthday" - minimal premium plaque, one colour
// Thick rounded-rectangle slab with soft filleted edges, raised lettering,
// a fine inset outline with sparkles in the top break and the makers'
// names set into the bottom break. Built-in Liberation Serif only.
// Print flat, back down, no supports.

width    = 220;    // plaque width in mm
height   = 140;    // plaque height in mm
thick    = 8;      // slab thickness
corner_r = 14;     // corner radius (seen from the front)
fillet   = 3;      // soft rounded front edge
relief   = 1.2;    // how far the lettering stands out
line_relief = 0.8; // height of the outline and sparkles
mark_relief = 0.6; // height of the tiny names
inset    = 9;      // outline distance from the edge
keyhole  = true;   // keyhole on the back for hanging
gold     = "#d4af37";

line1  = "Happy";
line2  = "FIRST BIRTHDAY";
makers = "ISHAAN  ·  SAHIL  ·  ARMAAN";
italic  = "Liberation Serif:style=Italic";
regular = "Liberation Serif:style=Regular";

$fn = 64;

module words(t, size, spacing, font) {
    text(t, size = size, font = font, halign = "center", valign = "center", spacing = spacing);
}

// one corner post: vertical side with a rounded top edge
module corner_post() {
    rotate_extrude($fn = 64)
        union() {
            square([corner_r - fillet, thick]);
            square([corner_r, thick - fillet]);
            translate([corner_r - fillet, thick - fillet]) circle(r = fillet, $fn = 32);
        }
}

module slab() {
    hull()
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (width / 2 - corner_r), y * (height / 2 - corner_r), 0])
                corner_post();
}

module rrect(w, h, r) {
    offset(r = r) square([w - 2 * r, h - 2 * r], center = true);
}

// 4-point sparkle
module sparkle(r) {
    polygon([for (i = [0 : 7])
        (i % 2 == 0 ? r : r * 0.28) * [cos(90 + i * 45), sin(90 + i * 45)]]);
}

module lettering_2d() {
    translate([0, 14]) words(line1, 30, 1.02, italic);
    translate([0, -14]) square([34, 0.8], center = true);
    translate([0, -27]) words(line2, 8, 1.7, regular);
}

// fine outline with a break at the top for the sparkles
// and a break at the bottom for the names
module outline_2d() {
    top = height / 2 - inset;
    difference() {
        rrect(width - 2 * inset, height - 2 * inset, corner_r - inset / 2);
        rrect(width - 2 * inset - 1.8, height - 2 * inset - 1.8, corner_r - inset / 2 - 0.9);
        translate([0, top]) square([34, 6], center = true);
        translate([0, -top]) square([84, 6], center = true);
    }
    translate([0, top]) sparkle(4.6);
    for (s = [-1, 1]) translate([s * 9, top]) sparkle(2.3);
}

module makers_2d() {
    translate([0, -(height / 2 - inset)]) words(makers, 3.2, 1.3, regular);
}

module keyhole_cut() {
    translate([0, 0, -0.01]) {
        cylinder(d = 9, h = 3.5, $fn = 32);
        translate([-2.25, 0, 0]) cube([4.5, 9, 3.5]);
        translate([0, 9, 0]) cylinder(d = 4.5, h = 3.5, $fn = 32);
    }
}

module plaque() {
    difference() {
        slab();
        if (keyhole) translate([0, height / 2 - 32, 0]) keyhole_cut();
    }
    face = thick - 0.01;
    translate([0, 0, face]) linear_extrude(relief) lettering_2d();
    translate([0, 0, face]) linear_extrude(line_relief) outline_2d();
    translate([0, 0, face]) linear_extrude(mark_relief) makers_2d();
}

color(gold) plaque();
