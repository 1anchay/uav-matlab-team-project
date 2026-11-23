# Extended V3 Simulink acceptance (actual measured runs)

**Status: 6/6 PASS.** Failures are kept in the results.

| Scenario | Expected code | Observed code | Replans | Clearance (m) | Verdict |
|---|---:|---:|---:|---:|---|
| baseline | 1 | 1 | 1 | 11.750 | PASS |
| two_unknown | 1 | 1 | 2 | 11.750 | PASS |
| collision_at_start | 2 | 2 | 1 | -7.000 | PASS |
| critical_battery | 3 | 3 | 0 | 57.031 | PASS |
| invalid_state | 4 | 4 | 0 | NaN | PASS |
| goal_at_start | 1 | 1 | 0 | 57.031 | PASS |

The experiment uses a simplified two-circle fixed-size 2D world. No hardware safety certification is implied.
