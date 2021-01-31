/*
 * Wool Winder: An OpenScad script for generate a wool winder machine.
 * Copyright (C) 2021  Carlos Falgueras García
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

include<involute_gears.scad>

// This variable will be overwritten by make to choose a module

/*****************/
/* CONFIGURATION */
/*****************/
gears_big_radius   = 70;        // Radius of the big rotating gear
gears_small_radius = 15;        // Radius of the small fixed gear
gears_thickness    = 10;        // Thickness of both gears
gears_angle        = 45;        // Angle between gears
gears_pitch        = 250;       // Pitch of both gears (less teeth the bigger)

support_thickness  = 10;        // Thickness of gears support
support_clearance  = 2;         // Distance between support and gears

pole_radius        = 12.5;      // Radius of the winding pole
pole_height        = 140;       // Height of the winding pole

bearing_ext_radius = 17/2;      // External radius of bearings
bearing_int_radius = 4;         // Internal radius of bearings
bearing_thickness  = 5;         // Thickness of bearings

shaft_height       = 60;        // Height of the shaft

belt_height        = 35;        // Vertical position of the transmission belt
belt_radius        = 2.5;       // Radius for the belt guides

nut_radius         = 7.25;      // Circumcircle radius of the nuts
nut_thickness      = 6;         // Thickness of the nuts

base_screw_radius  = 2;         // Radius of screws of both bases

crank_radius       = 75;        // Radius of crank disk
crank_thickness    = 10;        // Thickness of crank disk
crank_hdl_height   = 25;        // Height of crank handle
crank_hdl_radius   = 7.5;       // Radius of crank handle

guide_angle        = 20;        // Angle of the wool guide
guide_hole_radius  = 2;         // Size of the guide hole

threaded_rod_clearance = 1.2;   // Factor for the radius of the holes for the threaded rod

ec = threaded_rod_clearance; // [GLOBAL] Edge clearance
$fa = $preview? 30: 5;
$fs = 0.1;


/*************/
/* FUNCTIONS */
/*************/
function fix_rad(r, pitch) = ceil(r * 360 / pitch) * pitch / 360;

function pitch_apex(r1, r2, ang, pitch) =
	fix_rad(r2, pitch) * sin(ang) + (fix_rad(r2, pitch) * cos(ang) +
	fix_rad(r1, pitch)) / tan(ang);

function cone_distance(r1, r2, ang, pitch) =
	sqrt(pow(pitch_apex(r1, r2, ang, pitch), 2) + pow(fix_rad(r1, pitch), 2));

function pitch_angle(r1, r2, ang, pitch) =
	asin(fix_rad(r1, pitch) / cone_distance(r1, r2, ang, pitch));

function num_teeth(r, pitch) = fix_rad(r, pitch) * 360 / pitch;

function shaft_belt_offset(t) = t*2;
function crank_belt_offset(t) = t/2;
function guide_rod_depth(r)   = r*4;
function guide_hole_offset(r) = r*2;
function guide_hole_width(r)  = r*2.5;
function guide_hole_offset_fixed(r, a) =
	guide_hole_offset(r) + guide_hole_width(r)/2*tan(a);


/*******************/
/* GENERIC MODULES */
/*******************/
module empty(); // Use this as placeholder for temporally remove a children

module torus(r1, r2) {
	rotate_extrude(convexity = 10)
		translate([r1, 0, 0])
			circle(r = r2);
}

module wheel_holes(r1, r2, n, offset=0, cl=0.8) {
	h = r2 + (r1-r2)/2;
	step = 360/n;
	r = min(h * sin(step/2*cl), (r1-r2)/2*cl);
	difference() {
		children(0);
		for (i = [0:n-1])
			rotate([0, 0, offset+i*step])
				translate([h, 0, 0])
					cylinder(r=r, h=1000, center=true);
	}
}

module big_gear_origin(r1, r2, ang, pitch) {
	pitch_apex1  = pitch_apex(r1, r2, ang, pitch);
	pitch_apex2  = pitch_apex(r2, r1, ang, pitch);
	pitch_angle1 = pitch_angle(r1, r2, ang, pitch);
	pitch_angle2 = pitch_angle(r2, r1, ang, pitch);

	translate ([0,0,pitch_apex1])
	rotate([0,-(pitch_angle1+pitch_angle2),0])
	translate([0,0,-pitch_apex2])
		children();
}

module small_gear(r1, r2, r3, h, ang, pitch) {
	difference() {
		bevel_gear (
			number_of_teeth = num_teeth(r1, pitch),
			cone_distance = cone_distance(r1, r2, ang, pitch),
			outside_circular_pitch = pitch,
			face_width = h,
			$fn = $preview? 5 : 15
		);
		cylinder(r=r3, h=50);
		translate([0, 0, h]) mirror([0, 0, 1]) children(0);
	}
}

module big_gear(r1, r2, r3, h, ang, pitch) {
	wheel_holes(r2, r3, 4)
	difference() {
		bevel_gear (
			number_of_teeth = num_teeth(r2, pitch),
			cone_distance = cone_distance(r1, r2, ang, pitch),
			outside_circular_pitch = pitch,
			face_width = h,
			backlash = 1,
			$fn = $preview? 3 : 15
		) {
			children(1);
			children(2);
		}
		mirror([0, 0, 1])
			children(0);
	}
}

module pole(r1, r2, h) {
	$fn = $preview? 15 : 0;
	difference() {
		cylinder(r=r2, h=h);
		cylinder(r=r1*ec, h=h*4, center=true);
		children(0);
		translate([0, 0, h])
			children(1);
	}
	translate([0, 0, h]) {
		difference() {
			cylinder(r=r2, h=5);
			cylinder(r=r1*ec, h=20, center=true);
			translate([-r2, -r2, -2.5])
				cube([r2*1.7, r2*2, 10]);
			translate([-r2, -r2, 0])
				cube([r2*2, r2*2/3, 2]);
			translate([-r2, r2/3, 0])
				cube([r2*2, r2*2/3, 2]);
		}
	}
}

module gears_support(r1, r2, r3, h, ang, pitch, clearance) {
	hcl  = h+clearance;
	r1cl = r1*1.2;
	r2cl = r2*1.2;

	translate([0, 0, hcl]) {
	difference() {
		union() {
		difference() {
			translate([-r1cl, -r1cl, -hcl]) {
				cube([2*r1cl, 2*r1cl, h]);
			}
			translate([0, 0, -clearance])
				children(1);
		}

		difference() {
			big_gear_origin(r1, r2, ang, pitch) {
				translate([-r2cl, -r1cl, -hcl]) {
					difference() {
						cube([r2cl*1.5, r1cl*2, h]);
						translate([r2cl, r1cl, h])
							cylinder(r=r3, h=50, center=true);
						translate([r2cl, r1cl, 0])
						rotate([0, 0, 90])
							children(3);
					}
				}
				translate([0, 0, -clearance])
					children(4);
			}

			translate([-r1cl*2, -r1cl*2, -clearance-h*5])
				cube([4*r1cl, 4*r1cl, h*4]);
		}
		}
		translate([0, 0, -hcl])
			children(2);
	}
	children(0);
	translate([0, 0, -clearance])
		children(4);
	}
}

module washer(r1, r2, h) {
	difference() {
		cylinder(r=r1, h=h);
		cylinder(r=r2, h=h*4, center=true);
	}
}

module bearing(r1, r2, h) {
	difference() {
		union() {
			difference() {
				cylinder(r=r1, h=h);
				translate([0, 0, -h/2])
					cylinder(r=r1*0.9, h=h*2);
			}
			cylinder(r=r2*1.1, h=h);
			translate([0, 0, h*0.1])
				cylinder(r=r1, h=h*0.8);
		}
		translate([0, 0, -h/2])
			cylinder(r=r2, h=h*2);
	}
}

module bearing_hole(r1, r2, h, clearance, open = false) {
	ro = r2+(r1-r2)*2/3;
	ri = open? ro : r2*ec;
	mirror([0, 0, 1]) {
		cylinder(r=r1*clearance, h=h*2, center=true);
		cylinder(r=ro, h=h*1.3);
		cylinder(r=ri, h=h*20);
		%bearing(r1, r2, h);
	}
}

module base(r1, r2, r3, h) {
	h1 = h*1/4;
	h2 = h*3/4;
	r4 = r1*2;

	difference() {
		difference() {
			union() {
				translate([0, 0, h2]) {
					cylinder(r=r1, h=h1*0.80);
					cylinder(r=r2+(r1-r2)*1/3, h=h1);
				}
				cylinder(r1=r4, r2=r1, h=h2);
			}
			cylinder(r=r2, h=(h1+h2)*4, center=true);
			children(0);
		}

		for (i = [0:4]) {
			rotate([0, 0, i*90]) {
				translate([r1 + (r4 - r1)/2, 0, h2*1/4]) {
					cylinder(r=r3*2.5, h=h2);
					translate([0, 0, -h2/2])
						cylinder(r=r3, h=h2);
				}
			}
		}
	}

	translate([0, 0, h])
		children(1);
}

module shaft(r1, r2, r3, h1, h2) {
	difference() {
		cylinder(r=r1, h=h1);
		translate([0, 0, h2])
			torus(r1, r3);
		mirror([0,0,1])
			children(0);
		cylinder(r=r2*ec, h=h1*4, center=true);
	}
	translate([0, 0, h1]) {
		children(1);
		children(2);
	}
}

module pins(r1, r2, h, hole=false) {
	r2 = hole? r2*1.3 : r2;
	h  = hole? h*2.3  : h;

	for (i = [0:4])
		rotate([0, 0, i*90])
			translate([r1*0.8, 0, 0])
				cylinder(r=r2, h=h, center=hole, $fn=20);
}

module nut(r1, r2, h, hole=false) {
	if (hole) {
		translate([0, 0, h*0.1])
			cylinder(r=r1*1.04, h=h*2, $fn = 6, center=true);
	} else {
		difference() {
			cylinder(r=r1, h=h, $fn = 6);
			cylinder(r=r2, h=h*4, center=true);
		}
	}
}

module crank(r1, r2, r3, h1, h2) {
	r4 = r2*0.8;
	r5 = r2*0.5;
	wheel_holes(r1, r2, 5, offset=45)
	difference() {
		cylinder(r=r1, h=h1);
		mirror([0, 0, 1])
			children(0);
		translate([0, 0, crank_belt_offset(h1)])
			torus(r1, r3);
		translate([r1*0.8, 0, 0]) {
			crank_handle(r4, r5, r2, h1, h2, 1);
		}
	}
	children(1);
	translate([r1*0.8, 0, 0])
		crank_handle(r4, r5, r2, h1, h2);
}

module crank_handle(r1, r2, r3, h1, h2, cl=0) {
	cylinder(r=r2+cl, h=h1*1.1);
	cylinder(r=r1+cl, h=h1*0.3+cl);
	translate([0, 0, h1])
		cylinder(r1=r2, r2=r3, h=h2);
}

module guide_bottom(r1, r2, a) {
	h_b   = 20;
	h_bb  = h_b*0.15;
	r_bt  = r1*1.1;
	r_bb  = (r1+r2)*3;

	difference() {
		hull() {
			cylinder(r=r_bb, h=h_bb);
			rotate([0, -a, 0])
				translate([0, 0, h_b])
					cylinder(r=r_bt);
		}
		rotate([0, -a, 0])
			cylinder(r=r1, h = h_b*4, center=true);
		for (i=[1:4])
			rotate([0, 0, 45+90*i])
				translate([r_bb-r2*2.5, 0, 0]) {
					cylinder(r=r2, h=h_b*4, center=true);
					translate([0, 0, h_bb])
						cylinder(r=r2*1.75, h=h_b);
				}
		rotate([0, -a, 0])
		rotate([0, 0, 180/6]) {
			nut(
				r1   = nut_radius,
				r2   = bearing_int_radius,
				h    = nut_thickness+nut_radius*tan(a),
				hole = true
			);
			translate([0, 0, nut_radius*tan(a)])
				%nut(
					r1   = nut_radius,
					r2   = bearing_int_radius,
					h    = nut_thickness,
					hole = false
				);
		}
	}
}

module guide_top(r1, r2, a) {
	r_h1  = r2;
	r_h2  = r2*5;
	w     = guide_hole_width(r1);
	h     = guide_hole_offset(r1);
	depth = guide_rod_depth(r1);

	difference() {
		hull() {
			translate([0, 0, -depth])
				cylinder(r=r1+1,h=2);

			translate([w/2, 0, h])
			rotate([0, -90+a, 0])
				cylinder(r1=r_h1+1.5, r2=r_h2+1.5, h=w);
		}
		translate([w/2, 0, h])
		rotate([0, -90+a, 0]) {
			cylinder(r1=r_h1, r2=r_h2, h=w*1.001);
			cylinder(r=r_h1, h=w*4, center=true);
		}
		translate([0, 0, -depth-1])
			cylinder(r=r1, h=depth+1);
	}
}

/********************/
/* ASSAMBLY MODULES */
/********************/
module BASE(belt_offset) {
	base(
		r1 = bearing_ext_radius * threaded_rod_clearance,
		r2 = bearing_int_radius,
		r3 = base_screw_radius,
		h  = belt_height - belt_offset
	) {
		NUT_HOLE();
		children(0);
	}
}

module SHAFT() {
	shaft(
		r1 = bearing_ext_radius * threaded_rod_clearance,
		r2 = bearing_int_radius,
		r3 = belt_radius,
		h1 = shaft_height,
		h2 = shaft_belt_offset(bearing_thickness)
	) {
		BEARING_HOLE();
		PINS(t = support_thickness, hole = false);
		children(0);
	}
}

module PINS(t, hole) {
	r1 = bearing_ext_radius * threaded_rod_clearance;
	r2 = r1 * 0.15;
	h  = support_thickness * 0.2;
	pins(
		r1   = r1,
		r2   = r2,
		h    = h,
		hole = hole
	);
}

module GEARS_SUPPORT() {
	gears_support(
		r1        = gears_small_radius,
		r2        = gears_big_radius,
		r3        = bearing_int_radius,
		h         = support_thickness,
		ang       = gears_angle,
		pitch     = gears_pitch, // TODO: This should be unnecessary
		clearance = support_clearance
	) {
		children(0);
		BEARING_HOLE();
		PINS(t = support_thickness, hole = true);
		NUT_HOLE();
		%WASHER();
	}
}

module WASHER() {
	washer(
		r1 = bearing_int_radius + (bearing_ext_radius-bearing_int_radius) * 0.5,
		r2 = bearing_int_radius,
		h  = support_clearance
	);
}

module SMALL_GEAR() {
	small_gear(
		r1     = gears_small_radius,
		r2     = gears_big_radius,
		r3     = bearing_int_radius,
		h      = gears_thickness,
		ang    = gears_angle,
		pitch  = gears_pitch
	) {
		NUT_HOLE();
	}
}

module BIG_GEAR() {
	big_gear(
		r1          = gears_small_radius,
		r2          = gears_big_radius,
		r3          = bearing_int_radius,
		h           = gears_thickness,
		ang         = gears_angle,
		pitch       = gears_pitch
	) {
		BEARING_HOLE();
		PINS(t = gears_thickness);
		children(0);
	}
}

module POLE() {
	pole(
		r1 = bearing_int_radius,
		r2 = pole_radius,
		h  = pole_height
	) {
		PINS(t = gears_thickness, hole=true);
		BEARING_HOLE();
	}
}

module GEARS() {
	SMALL_GEAR();
	big_gear_origin(
		r1    = gears_small_radius,
		r2    = gears_big_radius,
		ang   = gears_angle,
		pitch = gears_pitch
	) {
		rotate([0, 0, 0])
		BIG_GEAR()
			POLE();
	}
}

module CRANK() {
	crank(
		r1 = crank_radius,
		r2 = crank_hdl_radius,
		r3 = belt_radius,
		h1 = crank_thickness,
		h2 = crank_hdl_height
	) {
		BEARING_HOLE(open=true);
		children(0);
	}
}

module GUIDE_TOP() {
	guide_top(
		r1 = bearing_int_radius,
		r2 = guide_hole_radius,
		a  = guide_angle
	);
}

module GUIDE_BOTTOM() {
	guide_bottom(
		r1 = bearing_int_radius,
		r2 = base_screw_radius,
		a  = guide_angle
	);
}

module GUIDE() {
	h =	  belt_height - shaft_belt_offset(bearing_thickness)
		+ shaft_height
		+ support_thickness
		+ support_clearance
		+ gears_big_radius / cos(gears_angle)
		+ pole_radius / cos(gears_angle)
	;

	r     = bearing_int_radius;
	a     = guide_angle;
	ho    = guide_hole_offset_fixed(r, a);
	h_fix = h/cos(a);
	h_rod = h_fix - ho - r*tan(a);

	echo(str("Guide rod lenght = ", h_rod, "mm"));

	GUIDE_BOTTOM();

	rotate([0, -a, 0]) {
		translate([0, 0, r * tan(a)])
			%cylinder(r=r, h=h_rod);
		translate([0, 0, h_fix-ho])
			GUIDE_TOP();
	}
}

module CRANK_WASHER() {
	hcl = 2;
	h   = crank_thickness - bearing_thickness + hcl;
	translate([0, 0, h-hcl]) {
		washer(
			r1 = bearing_ext_radius * 0.7,
			r2 = bearing_int_radius,
			h  = h
		);
	}
}

module NUT_HOLE() {
	nut(
		r1   = nut_radius,
		r2   = bearing_int_radius,
		h    = nut_thickness,
		hole = true
	);
	%nut(
		r1   = nut_radius,
		r2   = bearing_int_radius,
		h    = nut_thickness,
		hole = false
	);
}

module BEARING_HOLE(open=false) {
	bearing_hole(
		r1        = bearing_ext_radius,
		r2        = bearing_int_radius,
		h         = bearing_thickness,
		clearance = 1.03,
		open      = open
	);
}

module WINDER(cross_section=false) {
	difference() {
		union(){
			rotate([0,0, 180])
			BASE(belt_offset = shaft_belt_offset(bearing_thickness)) {
				SHAFT() {
					GEARS_SUPPORT() {
						GEARS();
					}
				}
			}
			translate([crank_radius*1.5, 0, 0])
				BASE(belt_offset = crank_belt_offset(crank_thickness)) {
					CRANK()
						CRANK_WASHER();
				}
			translate([-65, 0, 0]) {
				GUIDE();
			}
		}
		if (cross_section)
			translate([-500, -1000, -500])
				cube([1000, 1000, 1000]);
	}
}

module WINDER_SPREAD() {
	BASE(belt_offset = shaft_belt_offset(bearing_thickness));
	translate([0, -bearing_ext_radius*4, 0]) {
		WASHER();
		translate([bearing_ext_radius*2, 0, 0]) {
			WASHER();
			translate([bearing_ext_radius*2, 0, 0])
				CRANK_WASHER();
		}
		translate([0, -bearing_ext_radius*3, 0]) {
			GUIDE_TOP();
			translate([bearing_ext_radius*4, 0, 0])
				GUIDE_BOTTOM();
		}
	}
	translate([bearing_ext_radius*5, 0, 0]) {
		BASE(belt_offset = crank_belt_offset(crank_thickness));
		translate([bearing_ext_radius*4, 0, 0]) {
			SHAFT();
		}
	}

	translate([0, bearing_ext_radius*4, 0]) {
		rotate([-90, 0, 0])
		GEARS_SUPPORT();
		translate([gears_small_radius*4, 0, 0]) {
			SMALL_GEAR();
			translate([(pole_radius+gears_small_radius)*1.5, 0, 0])
				POLE();
		}
		translate([0, bearing_ext_radius*4 + gears_big_radius, 0]) {
			BIG_GEAR();
		}
	}
	translate([-crank_radius*1.5, 0, 0]) {
		CRANK();
	}
}

module RENDER(mn, cross_section) {
	difference() {
	     if (mn == "base_shaft")     BASE(belt_offset = shaft_belt_offset(bearing_thickness));
	else if (mn == "washer")         WASHER();
	else if (mn == "crank_washer")   CRANK_WASHER();
	else if (mn == "guide_top")      GUIDE_TOP();
	else if (mn == "guide_bottom")   GUIDE_BOTTOM();
	else if (mn == "base_crank")     BASE(belt_offset = crank_belt_offset(crank_thickness));
	else if (mn == "shaft")          SHAFT();
	else if (mn == "gears_support")  GEARS_SUPPORT();
	else if (mn == "small_gear")     SMALL_GEAR();
	else if (mn == "pole")           POLE();
	else if (mn == "big_gear")       BIG_GEAR();
	else if (mn == "crank")          CRANK();
	else if (mn == "all")            WINDER_SPREAD();
	else if (mn == "guide")          GUIDE();
	else
		assert(0, str("Invalid module name \"", mn, "\""));

	if (cross_section) {
		translate([0, -1000, 0])
			cube([2, 2, 2]*1000, center=true);
	}
	}
}

module_name = false; // This variable will be overwritten by make to choose a module
cross_section = false; // This variable will be overwritten by make to choose a module
if (module_name)
	RENDER(module_name, cross_section);
else {
	WINDER(cross_section=false);
}
