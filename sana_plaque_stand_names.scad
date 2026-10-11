// Replacement stand for the "Happy First Birthday Sana" plaque, with the
// family's names big and readable on a sloped front face.
// Fits the plaque you already printed (8 mm thick, 220 mm wide).
// Print base down, no supports. One colour.

show_plaque = true;  // preview only: shows a see-through plaque in the slot

/* [Names] */
love_text  = "LOVE";
names_text = "ISHAAN  ·  SAHIL  ·  ARMAAN  ·  GUCCI";
names_size = 8;      // big names
love_size  = 4;
regular    = "Liberation Serif:style=Regular";
text_relief = 1.0;   // how far the names stand out

/* [Stand] */
stand_l   = 240;     // length (a bit wider than the plaque)
stand_d   = 70;      // depth front to back
back_h    = 24;      // height at the back / slot area
front_h   = 8;       // height at the front edge
flat_from = -8;      // where the sloped face meets the flat top
corner_r  = 10;      // rounded corners seen from above

/* [Fit - must match the printed plaque] */
plaque_w  = 220;
plaque_h  = 140;
thick     = 8;       // plaque thickness
lean      = 12;      // plaque leans back (degrees)
slot_deep = 7;       // keep under 8 so the plaque's border is not covered
slot_gap  = 0.5;     // clearance; 0.7 if tight, 0.3 if loose
slot_y    = 6;       // slot position on the flat top

gold = "#d4af37";
$fn = 64;

// sloped front face
slope_p0  = [-stand_d / 2, front_h];
slope_p1  = [flat_from, back_h];
slope_len = norm(slope_p1 - slope_p0);
slope_a   = atan2(back_h - front_h, flat_from + stand_d / 2);

module rrect(w, h, r) {
    offset(r = r) square([w - 2 * r, h - 2 * r], center = true);
}

// side profile (y = front/back, z = up), extruded along the length
module body() {
    intersection() {
        rotate([90, 0, 90]) linear_extrude(stand_l + 2, center = true)
            polygon([[-stand_d / 2, 0], [stand_d / 2, 0], [stand_d / 2, back_h],
                     slope_p1, slope_p0]);
        linear_extrude(back_h + 1) rrect(stand_l, stand_d, corner_r);
    }
}

// places 2D children on the sloped face, v mm up the slope
module on_slope(v) {
    translate([0, slope_p0[0], slope_p0[1]]) rotate([slope_a, 0, 0])
        translate([0, v, -0.01]) children();
}

module names() {
    on_slope(slope_len * 0.38)
        linear_extrude(text_relief)
            text(names_text, size = names_size, font = regular,
                 halign = "center", valign = "center", spacing = 1.12);
    on_slope(slope_len * 0.78)
        linear_extrude(text_relief)
            text(love_text, size = love_size, font = regular,
                 halign = "center", valign = "center", spacing = 2.2);
}

module in_slot() {
    translate([0, slot_y, back_h - slot_deep]) rotate([-lean, 0, 0]) children();
}

module stand() {
    difference() {
        body();
        in_slot() translate([-plaque_w / 2 - 5, -thick - slot_gap / 2, 0])
            cube([plaque_w + 10, thick + slot_gap, 60]);
    }
    names();
}

color(gold) stand();

// see-through plaque for checking the look (not part of the STL)
if (show_plaque)
    %in_slot() translate([-plaque_w / 2, -thick, 0]) cube([plaque_w, thick, plaque_h]);
