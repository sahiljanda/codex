// "Happy First Birthday" - minimal premium plaque, one colour
// Thick rounded-rectangle slab with soft filleted edges and the
// lettering engraved into the face. Built-in Liberation Serif only.
// Print flat, back down, no supports.

width    = 220;    // plaque width in mm
height   = 140;    // plaque height in mm
thick    = 8;      // slab thickness
corner_r = 14;     // corner radius (seen from the front)
fillet   = 3;      // soft rounded front edge
engrave  = 1.0;    // depth of the lettering
mark_engrave = 0.6;// depth of the tiny names
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

module lettering_2d() {
    translate([0, 16]) words(line1, 30, 1.02, italic);
    translate([0, -12]) square([34, 0.8], center = true);
    translate([0, -25]) words(line2, 8, 1.7, regular);
}

module makers_2d() {
    translate([0, -52]) words(makers, 3.2, 1.3, regular);
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
        translate([0, 0, thick - engrave]) linear_extrude(engrave + 1) lettering_2d();
        translate([0, 0, thick - mark_engrave]) linear_extrude(mark_engrave + 1) makers_2d();
        if (keyhole) translate([0, height / 2 - 32, 0]) keyhole_cut();
    }
}

color(gold) plaque();
