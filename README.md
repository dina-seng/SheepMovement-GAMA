# Sheep Movement Simulation

An agent-based model built with the GAMA Platform. This project simulates how a herd of sheep moves across a field, avoids predators and obstacles, and naturally creates walking trails on the ground over time.

---

## Features

- **Flocking Behavior**: Sheep stay together as a group using standard flocking rules (cohesion, alignment, and separation).
- **Predator Avoidance**: When dogs get close, sheep panic, run faster, and move away from danger.
- **Predator Hunting**: Dogs actively search for and catch the nearest sheep.
- **Pathway Emergence**: As sheep walk over grass cells, they trample the ground. Cells change color from green to light brown and dark brown, forming visible paths that other sheep can follow.
- **Obstacle Collision**: Sheep and dogs detect solid obstacles and slide around them smoothly without passing through.
- **Exit Goal**: Sheep try to reach a safe destination point. When a sheep reaches the exit, it is marked as saved.
- **Simulation Monitors**: Track saved sheep, sheep caught by dogs, and remaining active sheep in real time.

---

## File Overview

All simulation files are located in the `models/` directory:

| File | Description |
| --- | --- |
| `SheepMoveMent.gaml` | **Main model**. Combines flocking, dog hunting, safe pathfinding, trail following, and goal completion. |
| `flocking.gaml` | Focuses on group movement using cohesion, separation, and alignment parameters. |
| `cheakach.gaml` | Adds dog agents and panic reactions to the flocking model. |
| `Sheep-Smart.gaml` | Adds food levels to grid cells so sheep can graze on sweet grass. |
| `extention2_environment.gaml` | Extended model testing different predator numbers and environmental variables. |
| `main.gaml` | Base model with simple random movement and initial ground trampling. |

---

## Requirements

- **GAMA Platform** (version 1.8.2, 1.9, or newer)
  - Download from: [https://gama-platform.org](https://gama-platform.org)

---

## How to Run

1. Open **GAMA Platform**.
2. Click **File** > **Import...** > **General** > **Existing Projects into Workspace**.
3. Choose the root folder of this project (`Sheep Movement`) and click **Finish**.
4. In the Project Explorer, open `models/SheepMoveMent.gaml`.
5. Look at the top of the editor or the Outline panel, and run the experiment named **`SheepMovementExperiment`**.
6. Use the simulation controls (Play, Pause, Step) to watch the herd navigate the map.

---

## Simulation Rules (Sheep Movement)

Sheep make movement decisions based on the following priorities:

1. **Map Boundary Check**: If a sheep gets too close to the edge of the world, it turns back toward the center.
2. **Predator Panic**: If a dog is within `panic_distance`, the sheep flees away at top speed.
3. **Trail Following**: If a well-trampled brown path is nearby and leads toward the goal, sheep prioritize walking along the path.
4. **Flocking & Destination**: When calm, sheep stay with the herd and move in the general direction of the destination `{45, 45}`.
5. **Obstacle Avoidance**: Sheep check their next step. If an obstacle is in front, they slide along the perimeter rather than getting stuck.
