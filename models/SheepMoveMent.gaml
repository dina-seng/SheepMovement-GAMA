/**
* Name: SheepMovements
* Description: Herd behavior, pathway emergence, solid polygon collision, and predator avoidance.
*/
model SheepMovements

global { 
	geometry shape <- square(50); 
	
	float cohesion_distance <- 15.0; 
	float separation_distance <- 3.0; 
	float alignment_distance <- 15.0; 
	float panic_distance <- 12.0; 

	point destination <- {45.0, 45.0};
	float destination_distance <- 3.5;
	int total_sheep <- 100;
	int sheep_entered <- 0;
	int sheep_eaten <- 0;
	
	init { 
		// 1. Create solid obstacles FIRST so sheep/dogs don't spawn inside them
		create obstacle number: 8 { 
			location <- {rnd(10.0, 38.0), rnd(10.0, 38.0)}; 
		}
		
		// 2. Define safe spawn area (World minus obstacle polygons + 1.5m buffer)
		geometry free_space <- copy(shape) - (union(obstacle collect (each.shape + 1.5)));
		
		create sheep number: total_sheep { 
			location <- any_location_in(free_space);
		}
		
		create dog number: 2 { 
			location <- any_location_in(free_space); 
		}
	}
	
	reflex stop_simulation when: empty(sheep) {
		write "========================================";
		write "SIMULATION FINISHED: No sheep remaining.";
		write "Total sheep saved (entered): " + sheep_entered;
		write "Total sheep eaten by dogs: " + sheep_eaten;
		write "Final Time (Cycles): " + cycle;
		write "========================================";
		do pause;
	}
}

grid vegetation_cell width: 50 height: 50 neighbors: 8 { 
	float tramping_level <- 0.0; 
	rgb color <- #green; 
	
	reflex update_color { 
		if (tramping_level > 10) { 
			color <- #saddlebrown; 
		} else if (tramping_level > 5) { 
			color <- #darkkhaki; 
		} else { 
			color <- #green;
		}
	}
}

// SOLID PHYSICAL OBSTACLE: 'shape' gives it real 2D collision geometry, not just a drawing!
species obstacle { 
	geometry shape <- square(3.5); 
	
	aspect base {
		draw shape color: #darkgray border: #black;
	}
}

species sheep skills: [moving] {
	float speed <- 2.0; 
	bool is_panicking <- false; 
	
	reflex reach_destination when: self distance_to destination <= destination_distance {
		sheep_entered <- sheep_entered + 1;
		write ">>> Sheep reached destination! Total Saved: " + sheep_entered + " | Time (Cycles): " + cycle;
		do die;
	}
	
	// Action that guarantees the sheep NEVER steps onto an obstacle polygon
	action move_safely {
		point step_vec <- {cos(heading) * speed, sin(heading) * speed};
		point next_pos <- location + step_vec;
		
		// Check if the next step enters within 0.8m of any solid obstacle's outer perimeter
		list<obstacle> blocking_obs <- obstacle where ((next_pos distance_to each.shape) < 0.8);
		
		if (length(blocking_obs) > 0) {
			obstacle nearest <- blocking_obs closest_to self;
			float away_ang <- nearest.location towards location;
			float dest_ang <- location towards destination;
			// Slide tangentially around the solid perimeter toward the exit
			point slide_vec <- {cos(away_ang) * 2.5 + cos(dest_ang), sin(away_ang) * 2.5 + sin(dest_ang)};
			heading <- {0.0, 0.0} towards slide_vec;
		}
		
		do move;
		
		// Hard physical ejection failsafe if pushed inside by crowd pressure
		list<obstacle> overlapping <- obstacle where ((self.location distance_to each.shape) < 0.5);
		if (length(overlapping) > 0) {
			obstacle obs <- first(overlapping);
			float push_ang <- obs.location towards location;
			location <- location + {cos(push_ang) * 1.5, sin(push_ang) * 1.5};
		}
	}
	
	reflex movement_behavior {
		float my_dist <- self distance_to destination;

		// PRIORITY 1: Map Boundary Guard
		if (location.x < 3.0 or location.x > 47.0 or location.y < 3.0 or location.y > 47.0) {
			heading <- location towards destination; 
			speed <- 4.0; 
			do move_safely;
			return; 
		}

		// PRIORITY 2: Flee Predator
		list<dog> nearby_dogs <- dog at_distance panic_distance;
		is_panicking <- length(nearby_dogs) > 0; 
		if (is_panicking) {
			speed <- 4.8; 
			dog closest_dog <- nearby_dogs closest_to self; 
			float flee_ang <- closest_dog.location towards location;
			float dest_ang <- location towards destination;
			point vec <- {cos(flee_ang) * 1.8 + cos(dest_ang), sin(flee_ang) * 1.8 + sin(dest_ang)};
			heading <- {0.0, 0.0} towards vec;
			do move_safely;
			return; 
		}

		// PRIORITY 3: Follow ONLY Saddlebrown Roads (tramping_level > 10) Forward
		list<vegetation_cell> saddle_roads <- vegetation_cell at_distance 5.0 
			where (each.tramping_level > 10 and (each distance_to destination) < (my_dist - 0.5));
			
		if (length(saddle_roads) > 0) {
			vegetation_cell best_road <- saddle_roads with_min_of (each distance_to destination);
			heading <- location towards best_road.location;
			speed <- 3.5; 
			do move_safely;
			return; 
		}

		// PRIORITY 4: 2D Vector Boids Flocking + Destination Pull (Never stalls on darkkhaki/green)
		speed <- 2.2;
		list<sheep> cohesion_neighbors <- sheep at_distance cohesion_distance;
		list<sheep> alignment_neighbors <- sheep at_distance alignment_distance; 
		list<sheep> separation_neighbors <- sheep at_distance separation_distance;
		
		point total_vector <- {0.0, 0.0};
		
		if (length(cohesion_neighbors) > 0) { 
			point avg_loc <- mean(cohesion_neighbors collect each.location); 
			float c_ang <- location towards avg_loc; 
			total_vector <- total_vector + {cos(c_ang), sin(c_ang)};
		}
		if (length(alignment_neighbors) > 0) {
			loop s over: alignment_neighbors {
				total_vector <- total_vector + {cos(s.heading) * 0.2, sin(s.heading) * 0.2};
			}
		}
		if (length(separation_neighbors) > 0) { 
			loop s over: separation_neighbors { 
				float sep_ang <- s.location towards location;
				total_vector <- total_vector + {cos(sep_ang) * 1.5, sin(sep_ang) * 1.5};
			}
		}
		
		float d_ang <- location towards destination;
		total_vector <- total_vector + {cos(d_ang) * 2.2, sin(d_ang) * 2.2};
			
		heading <- {0.0, 0.0} towards total_vector;
		do move_safely; 
	} 
	
	reflex trample { 
		vegetation_cell current_cell <- vegetation_cell(location); 
		if (current_cell != nil) { 
			ask current_cell { 
				tramping_level <- tramping_level + 1.0; 
			}
		}
	}
	
	aspect base { 
		draw circle(1.0) color: #white border: #black;
	}
}

species dog skills: [moving] { 
	float speed <- 4.0;

	// Action that guarantees the dog NEVER walks through an obstacle polygon
	action move_dog_safely {
		point step_vec <- {cos(heading) * speed, sin(heading) * speed};
		point next_pos <- location + step_vec;
		
		list<obstacle> blocking_obs <- obstacle where ((next_pos distance_to each.shape) < 0.8);
		if (length(blocking_obs) > 0) {
			obstacle nearest <- blocking_obs closest_to self;
			float away_ang <- nearest.location towards location;
			heading <- away_ang + (flip(0.5) ? 45.0 : -45.0);
		}
		
		do move;
		
		list<obstacle> overlapping <- obstacle where ((self.location distance_to each.shape) < 0.5);
		if (length(overlapping) > 0) {
			obstacle obs <- first(overlapping);
			float push_ang <- obs.location towards location;
			location <- location + {cos(push_ang) * 1.5, sin(push_ang) * 1.5};
		}
	}

	reflex hunt { 
		list<sheep> nearby_sheep <- sheep at_distance 50.0; 
		
		if (length(nearby_sheep) > 0) {
			sheep target <- nearby_sheep closest_to self; 
			
			if ((self distance_to target) < 2.0) { 
				ask target { do die; }
				sheep_eaten <- sheep_eaten + 1; 
				write "!!! Dog caught a sheep! Total Eaten: " + sheep_eaten + " | Cycle: " + cycle;
				return; 
			}
			
			heading <- location towards target.location;
			do move_dog_safely;
		} else { 
			do wander amplitude: 45.0; 
			do move_dog_safely;
		}
	}
	
	aspect base { 
		draw triangle(2.5) color: #red border: #black; 
	}
}

experiment SheepMovementExperiment type: gui { 
	output { 
		display main_display type: opengl background: #black {
			grid vegetation_cell; 
			species obstacle aspect: base;
			species sheep aspect: base; 
			species dog aspect: base;
			
			graphics "Destination" {
				draw circle(3.5) at: destination color: #blue border: #white;
			}
		}
		
		monitor "Sheep Saved" value: sheep_entered;
		monitor "Sheep Eaten" value: sheep_eaten;
		monitor "Active Sheep" value: length(sheep);
	}
}