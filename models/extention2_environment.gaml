/**
* Name: extention2environment
* Based on the internal empty template. 
* Author: ADMIN
* Tags: 
*/


model extention2environment

/* Insert your model definition here */

global {
	
	geometry shape <- square(50); 
	
	float cohesion_distance <-15.0; 
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
		
		create dog number: 5 { 
			location <- any_location_in(world); 
		}
		
		
	}
}


grid vegetation_cell width: 50 height: 50 neighbors: 8 { 
	
	float tramping_level <- 0.0; 
	float food_level <- rnd(10.0); 
	rgb color <- #green; 
	
	reflex update_color { 
		if (tramping_level > 10) {
			color <- #saddlebrown; // Heavy traffic dirt
		} else if (tramping_level > 5) {
			color <- #darkkhaki;   // Light traffic dirt
		} else if (food_level > 7.0) { 
			color <- #limegreen;   // Sweet, untouched grass
		} else { 
			color <- #green;       // Normal grass
		}
	}
}


species obstacle {

    init {
        int obstacle_type <- rnd(3);

        if (obstacle_type = 1) {
            shape <- circle(rnd(2.0, 5.0));
        } else if (obstacle_type = 2) {
            shape <- rectangle(rnd(10.0, 20.0), 1.0);
        } else {
            shape <- square(rnd(3.0, 6.0));
        }
    }

    aspect base {
        draw shape color: #dimgray;
    }
}

species sheep skills: [moving] { 
	float speed <- 2.0; 
	bool is_panicking <- false; 
	
	reflex flee_dog { 
		
		 list<dog> nearby_dogs <- dog at_distance panic_distance; 
		 
		 is_panicking <- length(nearby_dogs) > 0;
		 
		 if(is_panicking) { 
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
        list<vegetation_cell> nearby_grass <- vegetation_cell at_distance 10.0;

        float cohesion_heading <- heading;
        float alignment_heading <- heading;
        float separation_heading <- heading;
        float obstacle_heading <- heading;
        float food_heading <- heading;
        
        if(length(cohesion_neighbors) > 0 ){ 
        	point average_location <- mean(cohesion_neighbors collect each.location);
        	
        	cohesion_heading <- location towards average_location;
        }
        
        if(length(alignment_neighbors) > 0 ) {
        	alignment_heading <- mean(alignment_neighbors collect each.heading); 
        }
        
        if(length(separation_neighbors) > 0) { 
        	list<float> separation_headings <- []; 
        	
        	loop s over: separation_neighbors { 
        		add item: (s.location towards location) to: separation_headings; 
        	}
        	
        	separation_heading <- mean(separation_headings);
        }
        
        if(length(nearby_obstacles) > 0) { 
        	
        	obstacle nearest_obs <- nearby_obstacles closest_to self; 
        	
        	obstacle_heading <- nearest_obs.location towards location;
        }
        
        if(length(nearby_grass) > 0) {
        	
        	vegetation_cell best_grass <- nearby_grass with_max_of (each.food_level); 
        	
        	food_heading <- location towards best_grass.location; 
        }
        
        heading <- mean ([
        	cohesion_heading, 
        	alignment_heading, 
        	separation_heading, 
        	obstacle_heading, 
        	food_heading
        ]);
        
        do move; 
	}
	
	reflex trample{ 
		
		vegetation_cell current_cell <- vegetation_cell(location); 
		
		if(current_cell != nil) { 
			ask current_cell { 
				tramping_level <- tramping_level + 1.0; 
				
				food_level <- max([0.0, food_level - 0.5]);
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
		do wander amplitude: 45;
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
		
		display "Metrics" {
			chart "Herd & Environment Stats" type: series {
				data "Panicking Sheep" value: sheep count (each.is_panicking) color: #red;
				data "Sweet Grass Remaining" value: vegetation_cell count (each.food_level > 7.0) color: #limegreen;
			}
		}
	}
}

























