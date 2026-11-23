# UAV V3 — independently executable Simulink architecture

## Purpose

A separate *Model-Based Design demonstrator* for seven students. It creates
**nine** independent `.slx` models: the seven participant-owned blocks, plus
shared Dynamics and Mission Lifecycle, and **one top-level** model
`UAV3_Team_Model.slx`. No `InterfacePlaceholder` blocks.

In contrast to V1/V2, the V3 planner detects changes through a sensor
input and can change its active waypoint during **Simulink execution**.
It is an intentionally simplified fixed-size 2D route-replanning algorithm,
**not** a code port of the more capable MATLAB Advanced V2 route planner.

Inputs are fixed-size vectors; Signal Routing (Goto/From) keeps the main
diagram legible without long lines. A top-level Unit Delay breaks the
feedback loop between Model References.

## Run in MATLAB Online

```matlab
run('tests/run_v3_algorithm_tests.m')
build_v3_simulink_model
r = run_v3_simulink_demo(true);
run('tests/run_v3_simulink_tests.m')
```

**Unverified until the user actually runs those commands in MATLAB Online.**
If something fails, keep the diagnostic and make a new GitHub commit; do
not change the known-working `UAVF_Team_Model.slx` or delete earlier models.

New `.slx` are generated in `models/v3/generated/`. Existing files are
preserved; if changing a source algorithm after generation, explicitly
back up the binary `.slx`, then rebuild that V3 model separately.

## Responsibilities

| ID | Model | MATLAB Function source |
|---|---|---|
| 01 | UAV3_Navigation_01 | `team/01_Карпухин_Эрнест/v3_navigation.m` |
| 02 | UAV3_Control_02 | `team/02_Живоглядов_Иван/v3_control.m` |
| 03 | UAV3_Replanner_03 | `team/03_Лемченко_Богдан/v3_replanner.m` |
| 04 | UAV3_Detection_04 | `team/04_Дзедзей_Александр/v3_detection.m` |
| 05 | UAV3_GroundStation_05 | `team/05_Терехов_Арсений/v3_ground.m` |
| 06 | UAV3_Safety_06 | `team/06_Пучков_Артём/v3_safety.m` |
| 07 | UAV3_Energy_07 | `team/07_Касимов_Иван/v3_energy.m` |

`UAV3_Dynamics` and `UAV3_MissionLifecycle` are shared references,
**not** additional participants.

## Formal signal contracts

- World map: 3×2, each column `[x;y;radius]`.
- Detected observations: 4×2, `[x;y;radius;visible]`.
- Navigation: 4×1, `[x;y;vx;vy]`.
- Target: 2×1; planned event state: 3×1 `[new;known;detourActive]`.
- Acceleration 2×1, energy 3×1, global state 5×1.
- Ground-station telemetry: 9×1.
- Mission status code: 0=FLYING, 1=GOAL_REACHED, 2=COLLISION,
  3=LOW_BATTERY, 4=INVALID_STATE.

GPS outage stimulus: t in [8,10) seconds. Range sensor: 35 meters.
Default world contains a circle with center [50,40] radius 7 m; the second
fixed input slot is a distant placeholder. The route planner initially
knows no circle and may change waypoint upon sensor discovery.

## Limitations

- Simulated XY point mass, idealized synthetic GPS and circle detection.
- Fixed-size two-slot map, one-shot detour logic, no advanced path solver.
- Offline Advanced MATLAB V2 has a separate, richer planner with
  explicit segment verification; these implementations are **different**.
- The model does not guarantee collision-free flight in arbitrary worlds
  and is **not** code for physical UAVs.
- Successful baseline V2 runs must not be attributed to untested V3.
