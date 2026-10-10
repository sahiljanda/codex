// Standing script name "Sana" with an outline heart
// Inspired by the "Name With Personalized Heart" 3D printed sign.
//
// Print lying flat (as modelled), then stand it up on its bottom edge.
// For two colours: set part = "name" and part = "heart", export each STL,
// and load both into your slicer as one multi-part object.

/* [Text] */
name        = "Sana";
// Install a script font (e.g. Great Vibes, Pacifico, Dancing Script from Google Fonts)
font        = "Great Vibes:style=Regular";
name_length = 120;   // overall width of the name in mm
thickness   = 8;     // depth of the sign (Z when printing flat)
bold        = 0.8;   // thickens thin script strokes (0 = off)

/* [Heart] */
heart_size   = 26;   // heart width in mm
heart_stroke = 3;    // outline wall width
heart_angle  = -15;  // tilt, like the reference photo
heart_overlap = 6;   // how far the heart tucks into the last letter
heart_lift   = 0;    // raise/lower heart relative to the baseline

/* [Stand] */
flat_cut = 0.6;      // shave the bottom so it stands flat

/* [Output] */
part = "all"; // [all, name, heart]

$fn = 96;

// ---------- 2D shapes ----------

module name_2d() {
    offset(r = bold)
        resize([name_length, 0], auto = true)
            text(name, size = 40, font = font, halign = "left", valign = "baseline");
}

// Solid heart, point at the origin, width ~= s
module heart_solid(s) {
    r = s / 4;
    translate([0, r * sqrt(2)])
        rotate(45) {
            square(2 * r, center = true);
            translate([0,  r]) circle(r);
            translate([r,  0]) circle(r);
        }
}

module heart_outline(s, w) {
    difference() {
        heart_solid(s);
        offset(delta = -w) heart_solid(s);
    }
}

module heart_2d() {
    translate([name_length - heart_overlap + heart_size / 2, heart_lift])
        rotate(heart_angle)
            heart_outline(heart_size, heart_stroke);
}

// Keep everything above the flat-bottom line
module stand_trim() {
    intersection() {
        children();
        translate([-50, -flat_cut]) square([name_length + heart_size * 3, 200]);
    }
}

// ---------- 3D parts ----------

module name_part() {
    linear_extrude(thickness) stand_trim() name_2d();
}

module heart_part() {
    // subtract the name so the two colours don't overlap
    linear_extrude(thickness) stand_trim() difference() {
        heart_2d();
        name_2d();
    }
}

if (part == "all" || part == "name")
    color("white") name_part();
if (part == "all" || part == "heart")
    color("hotpink") heart_part();
