/********************************************************
 * Trimmer Tray - vsergeev
 * https://github.com/vsergeev/3d-trimmer-tray
 * CC-BY-4.0
 *
 * Release Notes
 *  * v1.0 - 06/20/2023
 *      * Initial release.
 ********************************************************/

/* [Basic] */

// number of rows
box_rows = 2;

// number of columns
box_cols = 2;

// in mm
box_x_width = 40;

// in mm
box_y_height = 20;

// in mm
box_z_height = 30;

// in mm
tray_x_width = 42.5;

// in mm
tray_y_height = 25;

// in mm
tray_z_height = 4;

// enable riser pegs
risers_enabled = true;

/* [Advanced] */

// in mm
base_z_thickness = 2.5;

// in mm
box_xy_wall_thickness = 2.5;

// in mm
base_xy_radius = 2.5;

// in mm
riser_xy_diameter = 5;

// in mm
riser_z_height = 2;

// in mm
riser_xy_offset = riser_xy_diameter - 1;

/* [Hidden] */

$fn = 100;

overlap_epsilon = 0.01;

/******************************************************************************/
/* Derived Constants */
/******************************************************************************/

box_overall_width = box_cols * box_x_width + (box_cols + 1) * box_xy_wall_thickness;
box_overall_height = box_rows * box_y_height + (box_rows + 1) * box_xy_wall_thickness;

tray_overall_width = tray_x_width + box_xy_wall_thickness * 2;
tray_overall_height = tray_y_height + box_xy_wall_thickness * 2;

function box_position(x, y) = [(x + 1) * box_xy_wall_thickness + (x + 0.5) * box_x_width - box_overall_width / 2,
                               (y + 1) * box_xy_wall_thickness + (y + 0.5) * box_y_height];

tray_position = [0, -tray_overall_height / 2];

/******************************************************************************/
/* Helper Operations */
/******************************************************************************/

module radius(r) {
    offset(r=r)
        offset(delta=-r)
            children();
}

/* Simple 45 degree outer chamfer on a profile */
module chamfer(profile_width, profile_height, depth) {
    scale_factor = [(profile_width - 2 * depth) / profile_width, (profile_height - 2 * depth) / profile_height];

    difference() {
        linear_extrude(height=depth, convexity=2)
            children();

        translate([0, 0, depth / 2 + overlap_epsilon])
            rotate([180, 0, 0])
                linear_extrude(height=depth + overlap_epsilon * 3, scale=scale_factor, center=true, convexity=2)
                    children();
    }
}

/******************************************************************************/
/* 2D Profiles */
/******************************************************************************/

module profile_box_footprint() {
    translate([0, box_overall_height / 2])
        radius(base_xy_radius)
            square([box_overall_width, box_overall_height], center=true);
}

module profile_box() {
    radius(base_xy_radius)
        square([box_x_width, box_y_height], center=true);
}

module profile_tray_footprint() {
    translate([0, -tray_overall_height / 2]) {
        union() {
            radius(base_xy_radius)
                square([tray_overall_width, tray_overall_height], center=true);

            /* Undo radius from inside corners */
            translate([0, tray_overall_height / 4])
                square([tray_overall_width, tray_overall_height / 2], center=true);
        }
    }
}

module profile_tray() {
    radius(base_xy_radius)
        square([tray_x_width, tray_y_height], center=true);
}

module profile_riser_footprint() {
    circle(d = riser_xy_diameter);
}

/******************************************************************************/
/* 3D Extrusions */
/******************************************************************************/

module trimmer_tray() {
    /* Boxes */
    union() {
        difference() {
            /* Positive */
            linear_extrude(base_z_thickness + box_z_height)
                profile_box_footprint();

            /* Negative */
            for (x = [0 : box_cols - 1], y = [0: box_rows - 1]) {
                translate(concat(box_position(x, y), base_z_thickness))
                    linear_extrude(box_z_height + overlap_epsilon)
                        profile_box();
            }
        }

        /* Chamfers */
        for (x = [0 : box_cols - 1], y = [0: box_rows - 1]) {
            translate(concat(box_position(x, y), base_z_thickness))
                chamfer(box_x_width, box_y_height, base_z_thickness)
                    profile_box();
        }

        /* Risers */
        if (risers_enabled) {
            for (x = [-1, 1], y = [-1, 1]) {
                translate(concat([x * (box_overall_width / 2 - riser_xy_offset),
                                  y * (box_overall_height / 2 - riser_xy_offset) + box_overall_height / 2],
                                 -riser_z_height))
                    linear_extrude(riser_z_height + overlap_epsilon)
                        profile_riser_footprint();
            }
        }
    }

    /* Tray */
    translate([0, overlap_epsilon]) {
        union() {
            difference() {
                /* Positive */
                linear_extrude(base_z_thickness + tray_z_height)
                    profile_tray_footprint();

                /* Negative */
                translate(concat(tray_position, base_z_thickness))
                    linear_extrude(tray_z_height + overlap_epsilon)
                        profile_tray();
            }

            /* Chamfer */
            translate(concat(tray_position, base_z_thickness))
                chamfer(tray_x_width, tray_y_height, tray_z_height)
                    profile_tray();

            /* Risers */
            if (risers_enabled) {
                for (x = [-1, 1]) {
                    translate(concat([x * (tray_overall_width / 2 - riser_xy_offset),
                                      -tray_overall_height + riser_xy_offset], -riser_z_height))
                        linear_extrude(riser_z_height + overlap_epsilon)
                            profile_riser_footprint();
                }
            }
        }
    }
}

/******************************************************************************/
/* Top Level */
/******************************************************************************/

trimmer_tray();
