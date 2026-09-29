model flocking

global {
    geometry shape <- square(50);
    int number_of_sheep <- 100;
    int number_of_obstacles <- 5;

    // Flocking parameters
    float cohesion_distance <- 15.0;
    float separation_distance <- 3.0;
    float alignment_distance <- 15.0;

    init {
        create sheep number: number_of_sheep { location <- any_location_in(world); }
        create obstacle number: number_of_obstacles { location <- any_location_in(world); }
    }
}

grid vegetation_cell width: 50 height: 50 neighbors: 8 {
    float tramping_level <- 0.0;
    rgb color <- #green;

    reflex update_color {
        if (tramping_level > 10) { color <- #saddlebrown; }
        else if (tramping_level > 5) { color <- #darkkhaki; }
        else { color <- #green; }
    }
}

species obstacle {
    aspect base {
        draw square(2.0) color: #gray;
    }
}

species sheep skills: [moving] {
    float speed <- 2.0;

    // The new flocking reflex replaces the old random wander
    reflex flock {
        list<sheep> cohesion_neighbors <- sheep at_distance cohesion_distance;
        list<sheep> alignment_neighbors <- sheep at_distance alignment_distance;
        list<sheep> separation_neighbors <- sheep at_distance separation_distance;
        list<obstacle> nearby_obstacles <- obstacle at_distance 5.0;

        float cohesion_heading <- heading;
        float alignment_heading <- heading;
        float separation_heading <- heading;
        float obstacle_heading <- heading;

        if (length(cohesion_neighbors) > 0) {
          
            point average_location <- mean(cohesion_neighbors collect each.location);
            cohesion_heading <- location towards average_location;
        }

        if (length(alignment_neighbors) > 0) {
            alignment_heading <- mean(alignment_neighbors collect each.heading);
        }

        if (length(separation_neighbors) > 0) {
            list<float> separation_headings <- [];
            loop s over: separation_neighbors {
                add item: (s.location towards location) to: separation_headings;
            }
            separation_heading <- mean(separation_headings);
        }

        if (length(nearby_obstacles) > 0) {
            // FIXED: Separated the agent assignment from the float math
            obstacle nearest_obs <- nearby_obstacles closest_to self;
            obstacle_heading <- nearest_obs.location towards location;
        }

        // Combine all desires into one final direction
        heading <- mean([cohesion_heading, alignment_heading, separation_heading, obstacle_heading]);
        
        do move; // Move forward based on the new heading
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

experiment SheepMovementExperiment type: gui {
    output {
        display main_display type: opengl {
            grid vegetation_cell;
            species obstacle aspect: base;
            species sheep aspect: base;
        }
    }
}