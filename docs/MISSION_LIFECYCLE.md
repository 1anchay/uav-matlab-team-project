# Mission lifecycle supervisor (shared component)

The seven personal Model References remain unchanged. A shared supervisory function
`models/functional/mission_supervisor.m` receives the true 2D state, final goal
and obstacle geometry. It determines terminal mission status:

| Code | Name | Meaning |
|---|---|---|
| 0 | FLYING | Continue the simulation |
| 1 | GOAL_REACHED | Stable arrival within 3 m and speed ≤1 m/s |
| 2 | COLLISION | Drone center is inside an obstacle circle |
| 3 | LOW_BATTERY | Charge ≤5% |
| 4 | INVALID_STATE | Non-finite state or goal |

The terminal output drives a standard Simulink `Stop Simulation` sink.
The supervisor is **not** an eighth team member and is independent of the
safety control, route planner and navigation estimator.

Run the isolated contract test without Simulink:

```matlab
run('tests/run_mission_lifecycle_tests.m')
```

For existing generated `UAVF_Team_Model.slx`, run:

```matlab
repair_functional_mission
run_functional_demo
run('tests/run_functional_simulink_tests.m')
```

`repair_functional_mission` preserves all seven model references and backs up
the top-level `.slx`. **Real execution in MATLAB Online is still pending.**
