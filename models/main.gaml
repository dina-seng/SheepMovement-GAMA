/**
* Name: main
* Based on the internal empty template. 
* Author: ADMIN
* Tags: 
*/


model main

/* Insert your model definition here */


global {
	
	int number_of_sheep <- 100; 
	int number_of_obstacles <- 5; 
	
	init {
		create sheep number: number_of_sheep{
			location <- {rnd(50), rnd(50)}; 
		}
		
		create obstacle number: number_of_obstacles{
			location <- {rnd(50), rnd(50)};
		}
	}
}
	
	grid vegetation_cell width: 50 height: 50 neighbors: 8 { 
		
		float tramping_level <- 0.0; 
		rgb color <- #green; 
		
		reflex update_color{ 
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
		
		reflex move{ 
			do wander amplitude: 45.0; 
		}
		
		reflex trample{ 
			vegetation_cell current_cell <- vegetation_cell(location);
			
			if(current_cell != nil)  {
				ask current_cell { 
					tramping_level <- tramping_level + 1.0;
				}
			}
		}
		
		aspect base{ 
			draw circle(1.0) color: #white; 
		}
	}
	
	experiment SheepMovementExperiment type: gui { 
		
		output {
			display main_display type: opengl { 
				grid vegetation_cell; 
				species obstacle aspect: base; 
				species sheep aspect: base;
		} }
		
	}
