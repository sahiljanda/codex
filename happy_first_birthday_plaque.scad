// "Happy First Birthday" - minimal round plaque, one colour
// Sleek disc with a fine ring, a single candle, elegant lettering
// and a tiny maker's mark. Built-in Liberation Serif font only.
// Print flat, back down, no supports.

diameter  = 200;   // plaque size in mm
plate_t   = 5;     // disc thickness
bevel     = 1.8;   // soft bevel on the front edge
relief    = 1.4;   // how far the design stands out
mark_relief = 0.6; // height of the tiny names
keyhole   = true;  // keyhole on the back for hanging
gold      = "#d4af37";

line1  = "Happy";
line2  = "FIRST BIRTHDAY";
makers = "ISHAAN  ·  SAHIL  ·  ARMAAN";
italic  = "Liberation Serif:style=Italic";
regular = "Liberation Serif:style=Regular";

$fn = 160;

module words(t, size, spacing, font) {
    text(t, size = size, font = font, halign = "center", valign = "center", spacing = spacing);
}

module design_2d() {
    r = diameter / 2;
    // one fine ring
    difference() { circle(r = r - 8); circle(r = r - 9.2); }
    // single candle with a flame
    translate([0, 40]) square([2.6, 16], center = true);
    hull() {
        translate([0, 53]) circle(r = 2.6, $fn = 48);
        translate([0, 60]) circle(d = 0.6, $fn = 16);
    }
    translate([0, 6]) words(line1, 28, 1.02, italic);
    translate([0, -24]) words(line2, 7.5, 1.6, regular);
}

module makers_2d() {
    translate([0, -64]) words(makers, 3.2, 1.3, regular);
}

// stepped bevel on the top edge
module bevelled(h, c, steps = 6) {
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
    difference() {
        bevelled(plate_t, bevel) circle(d = diameter);
        if (keyhole) translate([0, diameter / 2 - 35, 0]) keyhole_cut();
    }
    translate([0, 0, plate_t - 0.01]) bevelled(relief, 0.4, 2) design_2d();
    translate([0, 0, plate_t - 0.01]) linear_extrude(mark_relief) makers_2d();
}

color(gold) plaque();
