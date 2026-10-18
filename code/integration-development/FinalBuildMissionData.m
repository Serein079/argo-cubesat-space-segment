function [d, x0, ctrl, sim, comm] = BuildMissionData()
% BUILDMISSIONDATA
% Mission-specific integrated data definition for the ARGO 6U CubeSat.
%
% ARGO = Autonomous Rendezvous and Guidance Observer
% Mission: demonstrate autonomous vision-based relative navigation
% for uncooperative targets in a 500 km Sun-synchronous orbit.
%
% This script defines one consistent set of parameters for:
% orbit, structure, inertia, power, thermal, communications and ADCS.
%
% 中文说明：
% 本脚本用于为ARGO任务统一定义轨道、结构、惯量、电源、热控、
% 通信和姿态控制参数，供MissionSim综合仿真调用。
% 所有子系统共用这里的参数，确保前后一致。

%% ------------------------------------------------------------------------
% Simulation options
%% ------------------------------------------------------------------------
sim = struct;
sim.days               = 0.2;       % simulate ~4.8 hr, enough for several orbits
sim.dT                 = 1;         % time step [s]
sim.makePlots          = true;
sim.visualizeModel     = true;

% Mode cycle for integrated mission operation
% Example: SUNPOINT -> PAYLOAD -> DOWNLINK -> repeat
sim.modeCycleSec       = 5400;      % ~ one LEO orbit order of magnitude

%% ------------------------------------------------------------------------
% Start from integrated RHS default structure
%% ------------------------------------------------------------------------
d = RHSCubeSatIntegral;

%% ------------------------------------------------------------------------
% Spacecraft model: ARGO 6U CubeSat
%% ------------------------------------------------------------------------
model = '6U';

% Surface faces for drag and SRP disturbance modelling
[area, nFace, rFace] = CubeSatFaces(model, 1);

% Total spacecraft mass [kg]
% Draft report definition: about 9.0 kg for the 6U ARGO spacecraft
d.mass = 9.0;

% Inertia tensor [kg*m^2]
% First-pass estimate from CubeSat geometry and mass.
% This is a baseline and can later be refined from CAD / mass budget.
d.inertia = InertiaCubeSat(model, d.mass);

% Surface disturbance model
d.surfData.area     = area;
d.surfData.nFace    = nFace;
d.surfData.rFace    = rFace;
d.surfData.att.type = 'eci';

%% ------------------------------------------------------------------------
% Reaction wheel assembly (3-axis active control)
%% ------------------------------------------------------------------------
% Use reaction wheels because ARGO carries an optical payload and needs
% tighter pointing than passive stabilisation can provide.
d.kWheels    = 14:16;       % wheel state indices in integrated state vector
d.inertiaRWA = 2.0e-5;      % reaction wheel rotor inertia [kg*m^2]
d.tRWA       = [0;0;0];     % initial wheel control torque [N*m]

%% ------------------------------------------------------------------------
% Power model
%% ------------------------------------------------------------------------
% Triple-junction GaAs solar cells
% 4 deployable panels are used to support payload + ADCS + comms demand.
%
% BODY-frame solar-cell normals:
% +X, -X, +Y, -Y body sides plus deployable-panel effective normals.
% This is a simplified power list for integrated simulation.

d.power.solarCellNormal = [ ...
     1  -1   0   0   1  -1   0   0; ...
     0   0   1  -1   0   0   1  -1; ...
     0   0   0   0   0   0   0   0];

d.power.solarCellEff       = 0.295;    % triple-junction GaAs efficiency
d.power.effPowerConversion = 0.90;     % EPS conversion efficiency

% Effective solar cell area per face/panel [m^2]
% Keep consistent with 6U bus + deployable panel concept.
d.power.solarCellArea = [ ...
    0.020 0.020 0.020 0.020 0.035 0.035 0.035 0.035];

% Baseline load [W]
% This will be overwritten by MissionMode.m in different modes.
d.power.consumption = 8.0;

% Battery capacity [J]
% ARGO selected battery: 40 Wh Li-ion
d.power.batteryCapacity = 40 * 3600;   % = 144000 J

%% ------------------------------------------------------------------------
% Thermal model (isothermal whole-spacecraft approximation)
%% ------------------------------------------------------------------------
% Surface optical properties:
% solar cells, MLI / goldized Kapton, radiators
aC = 0.80;  eC = 0.82;   % solar-cell-covered surfaces
aG = 0.30;  eG = 0.04;   % goldized Kapton / MLI-like surface
aR = 0.15;  eR = 0.80;   % radiator surface

% Surface directions in body frame
% 6 body directions plus extra effective surfaces for deployables
d.uSurface = [ ...
     1 -1  0  0  0  0  1 -1  0  0; ...
     0  0  1 -1  0  0  0  0  1 -1; ...
     0  0  0  0  1 -1  0  0  0  0];

% Assign material properties to surfaces
d.alpha   = [aC aC aC aC aR aR aC aC aG aG];
d.epsilon = [eC eC eC eC eR eR eC eC eG eG];

% Surface areas [m^2]
% Approximate values for preliminary integral simulation
d.area = [0.020 0.020 0.020 0.020 0.030 0.030 0.035 0.035 0.035 0.035];

% Average specific heat capacity [J/(kg*K)]
d.cP = 900;

% Average internal absorbed power for thermal model [W]
% Dominated by avionics + vision processing unit during operation.
d.powerTotal = 8.0;

%% ------------------------------------------------------------------------
% Geometry / structural visualisation
%% ------------------------------------------------------------------------
d.thicknessWall         = 4.0;      % mm
d.thicknessRail         = 8.5;      % mm
d.densityWall           = 2700;     % kg/m^3 equivalent aluminium
d.massComponents        = 5.0;      % lumped internal components [kg]
d.cMComponents          = [0;0;0];
d.sigma                 = [zeros(2,6); 1 1 1 1 1 1];  % fully diffuse optical reflection
d.cD                    = 2.7;      % drag coefficient

% Deployable solar-panel definition
% Four panels arranged symmetrically around the 6U body.
d.solarPanel.dim        = [100 200 10];  % [mm mm mm]
d.solarPanel.nPanels    = 1;

% Inner-edge locations of four panels [mm]
d.solarPanel.rPanel = [ ...
     50  -50    0    0; ...
      0    0   50  -50; ...
    150  150  150  150];

% Panel hinge / tilt directions
d.solarPanel.sPanel = [ ...
     1  -1   0   0; ...
     0   0   1  -1; ...
     0   0   0   0];

% Panel cell normals in deployed configuration
d.solarPanel.cellNormal = [ ...
     0   0   0   0; ...
     0   0   0   0; ...
     1   1   1   1];

d.solarPanel.sigmaCell  = [1;0;0];
d.solarPanel.sigmaBack  = [0;0;1];
d.solarPanel.mass       = 0.15;     % kg per panel

if sim.visualizeModel
    [v, f, data] = CubeSatModel(model, d);
    DrawCubeSat(v, f, data);
end

%% ------------------------------------------------------------------------
% Orbit / epoch : 500 km Sun-synchronous orbit
%% ------------------------------------------------------------------------
x0 = d.x0;

% Earth constants
mu  = 398600.4418;     % km^3/s^2
Re  = 6378.137;        % km

% Mission orbit
alt   = 500;                           % km
a     = Re + alt;                      % semi-major axis [km]
e     = 0.001;                         % near-circular
inc   = deg2rad(97.4);                 % typical SSO inclination
raan  = deg2rad(0.0);
omega = deg2rad(0.0);
M     = deg2rad(0.0);

el = [a; e; inc; raan; omega; M];
[r, v] = El2RV(el);

x0(1:3) = r;
x0(4:6) = v;

% Initial quaternion / angular velocity
% Start from default integrated-state values; can later be aligned to LVLH
% in MissionSim / MissionMode if required.
d.jD0 = Date2JD([2026 4 1 10 30 0]);   % representative mission epoch

%% ------------------------------------------------------------------------
% Atmosphere model
%% ------------------------------------------------------------------------
d.atm = [];  % use simpler SCT density handling

%% ------------------------------------------------------------------------
% Communications / ground station
%% ------------------------------------------------------------------------
comm = struct;

% Example Australian ground station (Sydney region)
% IMPORTANT: SCT expects radians.
latGS = deg2rad(-33.8688);
lonGS = deg2rad(151.2093);

comm.rGS   = LatLonToR(latGS, lonGS);
comm.dLink = DataRateOrbit;

%% ------------------------------------------------------------------------
% Controller: LVLH-pointing 3-axis PID with reaction wheels
%% ------------------------------------------------------------------------
ctrl = PID3Axis;

% PIDMIMO(Kp, Ki, Kd, ...)
% Keep structure compatible with tutorial baseline.
[ctrl.a, ctrl.b, ctrl.c, ctrl.d] = PIDMIMO(1, 1, 0.01, 200, 0.1, sim.dT);

ctrl.inertia       = d.inertia;
ctrl.max_angle     = deg2rad(1.0);    % 1 deg pointing threshold
ctrl.accel_sat     = [50;50;50];      % actuator acceleration saturation
ctrl.mode          = 2;               % active pointing mode
ctrl.q_target_last = x0(7:10);

end