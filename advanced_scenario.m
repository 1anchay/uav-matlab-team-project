function [scenario, cfg] = advanced_scenario(name, cfg)
%ADVANCED_SCENARIO Fixed scenarios for Advanced Mission V2 (MATLAB-only).
% 'unexpected': obstacle is in physics/sensor but initially unknown to planner.
if nargin < 2 || isempty(cfg)
    cfg = advanced_config();
end
if nargin < 1 || isempty(name)
    name = 'unexpected';
end
scenario = init_scenario(cfg);
scenario.name = name;

switch name
    case 'nominal'
        scenario.knownMask = true(1,numel(scenario.obstacles));
    case 'unexpected'
        scenario.obstacles = struct('center',[50 40], ...
            'radius',7,'name','Unexpected crossing obstacle');
        scenario.knownMask = false(1,numel(scenario.obstacles));
    case 'two_unknown'
        scenario.obstacles = struct('center',{[46 37],[77 61]}, ...
            'radius',{6,6},'name',{'Hidden A','Hidden B'});
        scenario.knownMask = false(1,numel(scenario.obstacles));
    case 'clear'
        scenario.obstacles = scenario.obstacles([]);
        scenario.knownMask = false(1,0);
    case 'gps_outage'
        scenario.obstacles = scenario.obstacles([]);
        scenario.knownMask = false(1,0);
        cfg.advanced.gpsOutageFirst = 55;
        cfg.advanced.gpsOutageLast = 78;
    case 'radio_blackout'
        scenario.obstacles = scenario.obstacles([]);
        scenario.knownMask = false(1,0);
        cfg.advanced.packetLossProbability = 1;
    case 'critical_battery'
        scenario.obstacles = scenario.obstacles([]);
        scenario.knownMask = false(1,0);
        scenario.initialState.battery = cfg.safety.criticalBatteryPercent-1;
    otherwise
        error('UAV:Advanced:UnknownScenario','Unknown scenario: %s',name);
end
end
