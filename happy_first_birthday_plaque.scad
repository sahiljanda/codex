// "Happy First Birthday" - premium plaque with display stand, one colour
// Rounded slab with soft filleted edges, raised lettering, a fine outline
// with stars in the top break and the makers' names in the bottom break.
// Comes with a matching stand so it can sit upright. Solid back, no holes.
// Built-in Liberation Serif font only.
//
// part = "separate" shows the two pieces apart, "assembled" shows it standing.
// Export: set part = "plaque", export STL; set part = "stand", export STL.
// Print both flat with no supports (plaque back down, stand base down).

part = "separate"; // [separate, assembled, plaque, stand]

/* [Plaque] */
width    = 220;    // plaque width in mm
height   = 140;    // plaque height in mm
thick    = 8;      // slab thickness
corner_r = 14;     // corner radius
fillet   = 3;      // soft rounded front edge
relief   = 1.2;    // how far the lettering stands out
line_relief = 0.8; // height of the outline and stars
mark_relief = 0.6; // height of the tiny names
inset    = 9;      // outline distance from the edge

/* [Stand] */
stand_w   = 170;   // stand length
stand_d   = 60;    // stand depth
stand_h   = 14;    // stand height
lean      = 12;    // how far the plaque leans back (degrees)
slot_deep = 7;     // how far the plaque sits in the stand
slot_gap  = 0.5;   // clearance so the plaque slides in snugly

gold = "#d4af37";

line1  = "HAPPY";
line2  = "FIRST BIRTHDAY";
line3  = "SANA";
text_size = 12;    // one size for all three main lines
makers = "WITH LOVE  ·  ISHAAN  ·  SAHIL  ·  ARMAAN  ·  GUCCI";
italic  = "Liberation Serif:style=Italic";
regular = "Liberation Serif:style=Regular";

$fn = 64;

// ---------- shapes ----------

module words(t, size, spacing, font) {
    text(t, size = size, font = font, halign = "center", valign = "center", spacing = spacing);
}

module rrect(w, h, r) {
    offset(r = r) square([w - 2 * r, h - 2 * r], center = true);
}

function star_r(i, r) = i % 2 == 0 ? r : r * 0.42;
module star(r) {
    polygon([for (i = [0 : 9])
        [star_r(i, r) * cos(90 + i * 36), star_r(i, r) * sin(90 + i * 36)]]);
}

// block with rounded corners and a soft filleted top edge
module rounded_block(w, h, t, r, f) {
    hull()
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (w / 2 - r), y * (h / 2 - r), 0])
                rotate_extrude($fn = 64) union() {
                    square([r - f, t]);
                    square([r, t - f]);
                    translate([r - f, t - f]) circle(r = f, $fn = 32);
                }
}

// ---------- plaque artwork ----------

module lettering_2d() {
    translate([0, 28]) words(line1, text_size, 1.35, regular);
    translate([0, 6]) words(line2, text_size, 1.35, regular);
    translate([0, -16]) words(line3, text_size, 1.35, regular);
    translate([0, -33]) square([34, 0.8], center = true);
}

// fine outline, stars in the top break, names in the bottom break
module outline_2d() {
    top = height / 2 - inset;
    difference() {
        rrect(width - 2 * inset, height - 2 * inset, corner_r - inset / 2);
        rrect(width - 2 * inset - 1.8, height - 2 * inset - 1.8, corner_r - inset / 2 - 0.9);
        translate([0, top]) square([50, 8], center = true);
        translate([0, -top]) square([132, 6], center = true);
    }
    translate([0, top]) star(5.5);
    for (s = [-1, 1]) translate([s * 14, top]) star(3.4);
    // a star tucked into each corner
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (width / 2 - inset - 11), y * (height / 2 - inset - 11)]) star(4.6);
}

module makers_2d() {
    translate([0, -(height / 2 - inset)]) words(makers, 3.2, 1.12, regular);
}

module plaque() {
    rounded_block(width, height, thick, corner_r, fillet);
    face = thick - 0.01;
    translate([0, 0, face]) linear_extrude(relief) lettering_2d();
    translate([0, 0, face]) linear_extrude(line_relief) outline_2d();
    translate([0, 0, face]) linear_extrude(mark_relief) makers_2d();
}

// ---------- stand ----------

slot_y = 4;                      // slot position, a little behind centre
slot_z = stand_h - slot_deep;    // bottom of the slot

// places a child so its bottom edge sits in the slot, leaning back
module in_slot() {
    translate([0, slot_y, slot_z]) rotate([-lean, 0, 0]) children();
}

module stand() {
    difference() {
        rounded_block(stand_w, stand_d, stand_h, 10, 3);
        in_slot() translate([-width / 2 - 5, -thick - slot_gap / 2, 0])
            cube([width + 10, thick + slot_gap, 40]);
    }
}

// plaque turned upright with its back on the slot's back wall
module plaque_standing() {
    in_slot() rotate([90, 0, 0]) translate([0, height / 2, 0]) plaque();
}

// ---------- output ----------

color(gold) {
    if (part == "plaque") plaque();
    if (part == "stand") stand();
    if (part == "assembled") { stand(); plaque_standing(); }
    // the two pieces side by side, as they come off the printer
    if (part == "separate") {
        plaque();
        translate([0, -height / 2 - stand_d / 2 - 25, 0]) stand();
    }
}
