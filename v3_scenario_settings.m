function scenario = v3_scenario_settings(name)
%V3_SCENARIO_SETTINGS Fixed-size, documented V3 Simulink fault scenarios.
% Each world is 3x2 [centerX; centerY; radius] per column, and state 5x1.
% Scenario overrides are ephemeral: never modify generated .slx binaries.
if nargin < 1 || isempty(name), name='baseline'; end
scenario.name=char(name);
scenario.world=[50 1000;40 1000;7 0];
scenario.goal=[100;80];
scenario.initialState=[0;0;0;0;100];
scenario.expectedCode=1; % GOAL_REACHED
scenario.expectedReplans=0;
scenario.expectedKnown=0;
scenario.requiresClearance=true;
scenario.description='Previously verified one-circle baseline.';
switch scenario.name
    case 'baseline'
        scenario.expectedReplans=1;
        scenario.expectedKnown=1;
    case 'two_unknown'
        % Second synthetic circle intersects the path after the first detour.
        % This is a NEW stress test, not a claim of previously passing V3.
        scenario.world=[50 75;40 69;7 6];
        scenario.expectedReplans=2;
        scenario.expectedKnown=2;
        scenario.description='Two hidden physical circles, online route changes.';
    case 'collision_at_start'
        scenario.initialState=[50;40;0;0;100];
        scenario.expectedCode=2; % COLLISION must take priority
        scenario.requiresClearance=false;
        scenario.description='Deliberate start inside the first obstacle.';
    case 'critical_battery'
        scenario.initialState=[0;0;0;0;4];
        scenario.expectedCode=3; % LOW_BATTERY
        scenario.requiresClearance=false;
        scenario.description='Critical charge at initial sample.';
    case 'invalid_state'
        scenario.initialState=[NaN;0;0;0;100];
        scenario.expectedCode=4; % INVALID_STATE
        scenario.requiresClearance=false;
        scenario.description='Nonfinite true-state injection at t=0.';
    case 'goal_at_start'
        scenario.initialState=[100;80;0;0;100];
        scenario.expectedCode=1; % GOAL_REACHED
        scenario.expectedReplans=0;
        scenario.expectedKnown=0;
        scenario.requiresClearance=true;
        scenario.description='Already at goal with near-zero velocity.';
    otherwise
        error('UAV3:UnknownScenario','Unknown V3 scenario: %s', ...
            scenario.name);
end
assert(isequal(size(scenario.world),[3 2]) && ...
    isequal(size(scenario.goal),[2 1]) && ...
    isequal(size(scenario.initialState),[5 1]), ...
    'UAV3:ScenarioShape','V3 inputs must have fixed signal dimensions.');
end
