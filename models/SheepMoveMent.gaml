model cheakach

global { 
	geometry shape <- square(50);
	
	float cohesion_distance <- 15.0; 
	float separation_distance <- 3.0; 
	float alignment_distance <- 15.0; 
	float panic_distance <- 15.0; 
	
	// NEW: Destination and completion tracking
	point destination <- {45.0, 45.0};
	float destination_distance <- 2.0;
	int total_sheep <- 100;
	int sheep_entered <- 0;
	int sheep_eaten <- 0;
	
	init { 
		create sheep number: total_sheep { 
			location <- any_location_in(world);
		}
		
		create obstacle number: 5 { 
			location <- any_location_in(world); 
		}
		
		create dog number: 2 { 
			location <- any_location_in(world); 
		}
	}
	
	// NEW: Global reflex to stop simulation when all sheep are saved
	reflex stop_simulation when: empty(sheep) {
		write "========================================";
		write "ALL SHEEP SAVED! SIMULATION STOPPED.";
		write "Total sheep entered: " + sheep_entered;
		write "Total Sheep Eaten: " + sheep_eaten;
		write "Simulation time (cycle): " + cycle;
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
		} else if (tramping_level > 5){ 
			color <- #darkkhaki; 
		} else { 
			color <- #green;
		}
	}
}

species obstacle { 
	aspect base {
		draw square(2.0) color: #gray;
	}
}

species sheep skills: [moving] {
	float speed <- 2.0; 
	bool is_panicking <- false; 
	
	// NEW: Sheep reach destination, log to console, and disappear
	reflex reach_destination when: self distance_to destination <= destination_distance {
		sheep_entered <- sheep_entered + 1;
		write "Sheep entered! Total Saved: " + sheep_entered + " | Time (Cycles): " + cycle;
		do die;
	}
	
	// NEW: Wall avoidance to prevent getting permanently stuck on map edges
	reflex avoid_walls {
		if (location.x < 2.0 or location.x > 48.0 or location.y < 2.0 or location.y > 48.0) {
			heading <- location towards destination; 
			speed <- 3.0; 
			do move;
		} else {
			speed <- 2.0; 
		}
	}
	
	reflex flee_dog { 
		list<dog> nearby_dogs <- dog at_distance panic_distance;
		is_panicking <- length(nearby_dogs) > 0; 
		
		if (is_panicking) {
			speed <- 5.0; 
			dog closest_dog <- nearby_dogs closest_to self; 
			heading <- closest_dog.location towards location; 
			do move;
		}
	}
	
	reflex flock when: !is_panicking {
		list<obstacle> nearby_obstacles <- obstacle at_distance 5.0; 
		list<vegetation_cell> nearby_roads <- vegetation_cell at_distance 6.0 where (each.tramping_level > 10);
		
		
		if (length(nearby_obstacles) > 0 ) {
			obstacle nearest_obs <- nearby_obstacles closest_to self; 
			heading <- nearest_obs.location towards location; 
			do move;
			return; 
		}
		
		// PRIORITY 2: Strict Road Following Override
		if (length(nearby_roads) > 0) {
			
			heading <- location towards destination;
			speed <- 3.0; // Move faster on dirt roads
			do move;
			return; 
		}
		
	
		list<sheep> cohesion_neighbors <- sheep at_distance cohesion_distance;
		list<sheep> alignment_neighbors <- sheep at_distance alignment_distance; 
		list<sheep> separation_neighbors <- sheep at_distance separation_distance;
		
		float cohesion_heading <- heading; 
		float alignment_heading <- heading; 
		float separation_heading <- heading; 
		
		if (length(cohesion_neighbors) > 0 ) { 
			point average_location <- mean(cohesion_neighbors collect each.location); 
			cohesion_heading <- location towards average_location; 
		}
		
		if (length(alignment_neighbors) > 0 ) {
			alignment_heading <- mean(alignment_neighbors collect each.heading);
		}
		
		if (length(separation_neighbors) > 0) { 
			list<float> separation_headings <- [];
			loop s over: separation_neighbors { 
				add item: (s.location towards location) to: separation_headings;
			}
			separation_heading <- mean(separation_headings);
		}
			
		heading <- mean([
			cohesion_heading, 
			alignment_heading, 
			separation_heading
		]);
		
		do move; 
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
		draw circle(1.0) color: #white;
	}
}

species dog skills: [moving] { 
	float speed <- 3.5;  

	reflex move { 
		list<obstacle> nearby_obstacles <- obstacle at_distance 2.0;
		list<sheep> nearby_sheep <- sheep at_distance 50.0; // Dog vision range
		
		if(length(nearby_obstacles) > 0 ) { 
			// Priority 1: Obstacle bounce
			obstacle nearest_obs <- nearby_obstacles closest_to self;
			heading <- nearest_obs.location towards location;
			do move;
		} else if (length(nearby_sheep) > 0) {

			sheep target <- nearby_sheep closest_to self; 
			
			if (location distance_to target.location < 1.5) {
				ask target {
					do die;
				}
				sheep_eaten <- sheep_eaten + 1; 
			} else {
				
				heading <- location towards target.location;
				do move;
			}
		} else { 
		
			do wander amplitude: 45.0; 
		}
	}
	
	aspect base { 
		draw triangle(2.0) color: #red; 
	}
}

experiment SheepMovementExperiment type: gui { 
	output { 
		display main_display type: opengl {
			grid vegetation_cell; 
			species obstacle aspect: base;
			species sheep aspect: base; 
			species dog aspect: base;
			
			// NEW: Visually draw the destination
			graphics "Destination" {
				draw circle(2.0) at: destination color: #blue;
			}
		}
	}
}