// "Happy First Birthday" premium plaque - one colour
// Layered plate (bevelled base + raised bevelled panel), double border,
// corner stars, serif capitals, "1" medallion, and a tiny maker's mark.
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

/* [Text] */
line1  = "HAPPY";
line2  = "FIRST";
line3  = "BIRTHDAY";
makers = "CRAFTED BY  ISHAAN  ·  SAHIL  ·  ARMAAN";
serif      = "Liberation Serif:style=Bold";
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

module diamond(s) { rotate(45) square(s, center = true); }

// "1" in a double ring, with lines and diamonds running out each side
module medallion() {
    difference() { circle(r = 12); circle(r = 10.6); }
    difference() { circle(r = 9.6); circle(r = 9.0); }
    words("1", 11, 1);
    for (s = [-1, 1]) {
        translate([s * 37, 0]) square([46, 1.2], center = true);
        translate([s * 62, 0]) diamond(3.6);
        translate([s * 69, 0]) diamond(2.0);
    }
}

module artwork_2d() {
    // double border + corner stars
    ring(14, 1.8);
    ring(18, 0.9);
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (plate_w / 2 - 25), y * (plate_h / 2 - 25)]) star(4.5, 4);

    // HAPPY with small stars either side
    translate([0, 55]) words(line1, 10, 1.6);
    for (s = [-1, 1]) translate([s * 47, 55]) star(3.2);

    // main lines
    translate([0, 27]) words(line2, 24, 1.12);
    translate([0, -4]) words(line3, 24, 1.08);

    translate([0, -36]) medallion();
}

// tiny maker's mark along the bottom, kept separate so it can be lower
module makers_mark_2d() {
    translate([0, -60]) words(makers, 3.2, 1.15, serif_thin);
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

plaque();
