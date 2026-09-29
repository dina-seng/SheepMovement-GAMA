model cheakach

global { 
	geometry shape <- square(50);
	
	float cohesion_distance <- 15.0; 
	float separation_distance <- 3.0; 
	float alignment_distance <- 15.0; 
	float panic_distance <- 15.0; 
	
	init { 
		create sheep number: 100 { 
			location <- any_location_in(world);
		}
		
		create obstacle number: 5 { 
			location <- any_location_in(world); 
		}
		
		create dog number: 2 { 
			location <- any_location_in(world); 
		}
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
	
	reflex flee_dog { 
		list<dog> nearby_dogs <- dog at_distance panic_distance;
		is_panicking <- length(nearby_dogs) > 0; 
		
		if (is_panicking) {
			dog closest_dog <- nearby_dogs closest_to self; 
			heading <- closest_dog.location towards location; 
			do move;
		}
	}
	
	reflex flock when: !is_panicking {
		list<sheep> cohesion_neighbors <- sheep at_distance cohesion_distance;
		list<sheep> alignment_neighbors <- sheep at_distance alignment_distance; 
		list<sheep> separation_neighbors <- sheep at_distance separation_distance;
		list<obstacle> nearby_obstacles <- obstacle at_distance 5.0; 
		
		float cohesion_heading <- heading; 
		float alignment_heading <- heading; 
		float separation_heading <- heading; 
		float obstacle_heading <- heading; 
		
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
		
		
		if (length(nearby_obstacles) > 0 ) {
			obstacle nearest_obs <- nearby_obstacles closest_to self; 
			obstacle_heading <- nearest_obs.location towards location; 
		}
			
		heading <- mean([
			cohesion_heading, 
			alignment_heading, 
			separation_heading, 
			obstacle_heading
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
		
		if(length(nearby_obstacles) > 0 ) { 
			obstacle nearest_obs <- nearby_obstacles closest_to self;
			heading <- nearest_obs.location towards location;
			do move;
		}else { 
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
		}
	}
}