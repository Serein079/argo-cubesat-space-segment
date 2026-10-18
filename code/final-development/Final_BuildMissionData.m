function [d, x0, ctrl, sim, comm] = ARGO_BuildMissionData()
%ARGO_BUILDMISSIONDATA Mission-consistent parameter file for the ARGO 6U CubeSat.
%
% This file collects orbit, structure, thermal, power, ADCS, payload,
% communication, and simulation parameters into a single mission definition.
% It is intended for use with an integrated Princeton SCT workflow.
%
% Outputs
%   d     : spacecraft / environment / subsystem data structure
%   x0    : initial state vector
%   ctrl  : control parameters used by the ADCS controller
%   sim   : simulation settings and mission-level assumptions
%   comm  : communication / CDH parameters
%
% Notes
%   1) The numerical values are mission-consistent preliminary design values.
%   2) Report-defined values are preserved where already fixed in the ARGO report.
%   3) Remaining values are engineering assumptions chosen to be physically
%      plausible for a 6U LEO CubeSat and consistent with the subsystem budgets.
%   4) Depending on the local SCT version, a small number of field names may
%      need to be adapted in the downstream RHS / plotting scripts.
%
% -------------------------------------------------------------------------
% 1. Load default SCT integrated model if available
% -------------------------------------------------------------------------
if exist('RHSCubeSatIntegral','file') == 2
    d = RHSCubeSatIntegral;
else
    d = struct();
end

% -------------------------------------------------------------------------
% 2. Mission-level simulation settings
% -------------------------------------------------------------------------
sim = struct();
sim.name                = 'ARGO';
sim.description         = '6U CubeSat for autonomous visual navigation around uncooperative debris';
sim.days                = 0.25;           % 6 hours, enough for several SSO orbits
sim.dT                  = 1.0;            % [s] propagation step
sim.makePlots           = true;
sim.visualizeModel      = true;
sim.useQuaternion       = true;
sim.useReactionWheels   = true;
sim.useMagnetorquers    = true;
sim.useDisturbances     = true;
sim.includeThermal      = true;
sim.includePower        = true;
sim.includeComms        = true;
sim.modeCycleSec        = 5676;           % [s] one orbit (~94.6 min)
sim.modeNames           = {'SUNPOINT','PAYLOAD','DOWNLINK','ECLIPSE'};

% Julian date for simulation start. If Date2JD is available, use it.
if exist('Date2JD','file') == 2
    sim.jD0 = Date2JD(2026,4,1,0,0,0);
else
    % Fixed Julian date corresponding approximately to 2026-04-01 00:00:00 UTC
    sim.jD0 = 2461131.5;
end

% -------------------------------------------------------------------------
% 3. Mission and orbit definition
% -------------------------------------------------------------------------
d.mission.name          = 'ARGO';
d.mission.primaryObjective = ...
    'Demonstrate autonomous vision-based navigation and tracking of uncooperative debris in LEO';
d.mission.orbitType     = 'SSO';
d.mission.lifeMonths    = [6 12];

orbit = struct();
orbit.altitude_km       = 500.0;          % Report-defined
orbit.e                 = 0.001;          % Report-defined
orbit.inc_deg           = 97.6;           % Report-defined
orbit.raan_deg          = 0.0;            % Engineering assumption for initialization
orbit.argp_deg          = 0.0;            % Engineering assumption for near-circular orbit
orbit.nu_deg            = 0.0;            % Engineering assumption for initial anomaly
orbit.ltdn              = '10:30';        % Report-defined
orbit.Re_km             = 6378.137;       % Earth equatorial radius
orbit.mu_km3s2          = 398600.4418;    % Earth gravitational parameter
orbit.a_km              = orbit.Re_km + orbit.altitude_km;
orbit.period_s          = 2*pi*sqrt(orbit.a_km^3/orbit.mu_km3s2);
orbit.period_min        = orbit.period_s/60;
orbit.eclipse_s         = 35.6*60;        % Report-defined
orbit.daylight_s        = 59.0*60;        % Report-defined
orbit.betaAssumed_deg   = 0.0;            % Conservative eclipse sizing basis

d.orbit = orbit;

% Convert orbital elements to Cartesian state for x0
[r0_km, v0_kms] = localEl2RV(orbit.a_km, orbit.e, orbit.inc_deg, ...
    orbit.raan_deg, orbit.argp_deg, orbit.nu_deg, orbit.mu_km3s2);

% -------------------------------------------------------------------------
% 4. Spacecraft geometry, structure, mass and inertia
% -------------------------------------------------------------------------
d.sc.formFactor         = '6U';
d.sc.dim_m              = [0.10; 0.20; 0.30];     % Report-defined

d.mass                  = 9.0;                    % [kg] Report-defined
busMass                 = 7.4;                    % [kg] 9.0 total minus 1.6 kg array hardware
panelMass               = 0.4;                    % [kg] each, from 1.6 kg / 4

% Approximate inertia with bus box + 4 panel point-mass contributions.
Ibus = localBoxInertia(busMass, 0.10, 0.20, 0.30);

% Panels are mounted around the body and deployed normal to side faces.
% Distances chosen from 6U half-width plus half panel size.
panelPos = [ ...
     0.10, -0.10,  0.00,  0.00; ...   % x [m]
     0.00,  0.00,  0.15, -0.15; ...   % y [m]
     0.00,  0.00,  0.00,  0.00];      % z [m]
Ipanels = zeros(3);
for k = 1:4
    Ipanels = Ipanels + localPointMassInertia(panelMass, panelPos(:,k));
end

d.inertia               = Ibus + Ipanels;
d.rCM                   = [0;0;0];               % symmetric first-order assumption

d.massBreakdown.bus_kg      = busMass;
d.massBreakdown.panels_kg   = 1.60;              % Report-defined

d.structure.panelDeployed   = true;
d.structure.panelCount      = 4;                 % Report-defined

d.structure.panelSize_m     = [0.10; 0.10];      % Report-defined

d.structure.notes           = 'Symmetric 4-panel configuration chosen to reduce mass-property asymmetry';

% If SCT geometry helper exists, use it for faces; otherwise create simple defaults.
if exist('CubeSatFaces','file') == 2
    try
        [area, nFace, rFace] = CubeSatFaces('6U',1);
        d.area               = area;
        d.nFace              = nFace;
        d.rFace              = rFace;
        d.uSurface           = nFace;
    catch
        [d.area, d.nFace, d.rFace, d.uSurface] = localDefaultCubeFaces();
    end
else
    [d.area, d.nFace, d.rFace, d.uSurface] = localDefaultCubeFaces();
end

% -------------------------------------------------------------------------
% 5. Solar arrays / power geometry
% -------------------------------------------------------------------------
% Four 100 mm x 100 mm deployable panels.
d.solarPanel.rPanel = panelPos;
d.solarPanel.sPanel = repmat([0.10; 0.10; 0.0],1,4);
d.solarPanel.cellNormal = [ ...
     1, -1,  0,  0; ...
     0,  0,  1, -1; ...
     0,  0,  0,  0];

% -------------------------------------------------------------------------
% 6. Thermal model parameters
% -------------------------------------------------------------------------
d.thermal.mass_kg       = 9.0;             % Report-defined

d.cP                    = 900;             % [J/kg-K] Report-defined
d.alpha                 = 0.35*ones(1,size(d.uSurface,2));
d.epsilon               = 0.80*ones(1,size(d.uSurface,2));
d.thermal.Aproj_m2      = 0.012;           % Report-defined
d.thermal.Ar_m2         = 0.03;            % Report-defined
d.thermal.Qgen_W        = 8.0;             % Report-defined

d.thermal.S0_Wm2        = 1367;            % Report-defined solar constant

d.thermal.sigma         = 5.670374419e-8;  % Stefan-Boltzmann constant

d.thermal.TeqSun_K      = 317.0;           % Report-defined

d.thermal.TeqEclipse_K  = 276.9;           % Report-defined

d.thermal.T0_K          = 293.15;          % 20 degC, consistent with report simulation trend

d.thermal.hotComponent  = 'VPU';
d.thermal.hotComponentPower_W = 10.0;      % Report-defined payload support statement

d.thermal.radiatorFace  = '-Y';

% -------------------------------------------------------------------------
% 7. Electrical power subsystem
% -------------------------------------------------------------------------
d.power = struct();
d.power.primarySource           = 'Triple-junction GaAs solar array';
d.power.secondarySource         = 'Li-ion battery';
d.power.architecture            = 'DET';
d.power.solarCellEff            = 0.29*ones(1,4);   % Reasonable preliminary value for triple-junction GaAs

d.power.effPowerConversion      = 0.90;             % Consistent with report battery/path assumptions

d.power.solarCellArea           = 0.01*ones(1,4);   % [m^2] each deployed panel 100 mm x 100 mm

d.power.solarCellNormal         = d.solarPanel.cellNormal;
d.power.batteryType             = 'Li-ion';
d.power.batteryCapacity         = 40*3600;          % [Wh -> W*s] Report-defined

d.power.batteryCapacity_Wh      = 40.0;             % For convenience

d.power.batteryEnergy0          = 0.85*d.power.batteryCapacity; % Start near full charge

d.power.dOD                     = 0.30;             % Report-defined

d.power.etaBattery              = 0.90;             % Report-defined

d.power.Xe                      = 0.65;             % Report-defined

d.power.Xd                      = 0.85;             % Report-defined

d.power.consumptionDay          = 20.0;             % [W] Report-defined

d.power.consumptionEclipse      = 8.0;              % [W] Report-defined

d.power.PsaRequired_W           = 34.48;            % Report-defined

d.power.mass_battery_kg         = 0.45;             % Report-defined

d.power.mass_array_kg           = 1.60;             % Report-defined

d.power.mass_pcu_kg             = 0.15;             % Report-defined

d.power.notes                   = 'Array sizing kept consistent with 34.48 W required daytime average generation';

% -------------------------------------------------------------------------
% 8. Payload
% -------------------------------------------------------------------------
d.payload.name                  = 'Stereo camera suite + VPU';
d.payload.camera.mass_kg        = 0.8;              % Report-defined

d.payload.camera.dim_m          = [0.08; 0.04; 0.04];
d.payload.camera.power_W        = 2.0;              % Report-defined

d.payload.vpu.mass_kg           = 1.0;              % Report-defined

d.payload.vpu.dim_m             = [0.08; 0.04; 0.02];
d.payload.vpu.power_W           = 10.0;             % Report-defined

d.payload.totalMass_kg          = 1.8;              % Report-defined

d.payload.peakPower_W           = 12.0;             % Report-defined

d.payload.mountFace             = '+Z';             % Report-defined

d.payload.vpuMountFace          = '-Y internal radiator panel';
d.payload.dataMode              = 'Processed visual navigation / vSLAM products';

% -------------------------------------------------------------------------
% 9. ADCS sensors, actuators and controller parameters
% -------------------------------------------------------------------------
d.adcs = struct();

% Sensors
%d.adcs.sensors
 d.adcs.sensors.starTracker.accuracy_deg     = 30/3600;  % 30 arcsec = 0.0083 deg, plausible precision tracker
 d.adcs.sensors.starTracker.updateRate_Hz    = 2.0;
 d.adcs.sensors.starTracker.power_W          = 1.5;
 d.adcs.sensors.starTracker.mass_kg          = 0.25;

 d.adcs.sensors.gyro.bias_degps              = 0.01;     % conservative MEMS/fibre-hybrid preliminary value
 d.adcs.sensors.gyro.noise_degps             = 0.002;
 d.adcs.sensors.gyro.updateRate_Hz           = 50.0;
 d.adcs.sensors.gyro.power_W                 = 0.30;
 d.adcs.sensors.gyro.mass_kg                 = 0.08;

 d.adcs.sensors.magnetometer.noise_nT        = 200;      % reasonable coarse attitude support value
 d.adcs.sensors.magnetometer.updateRate_Hz   = 10.0;
 d.adcs.sensors.magnetometer.power_W         = 0.10;
 d.adcs.sensors.magnetometer.mass_kg         = 0.05;

 d.adcs.sensors.sunSensor.accuracy_deg       = 0.10;     % coarse sun sensor
 d.adcs.sensors.sunSensor.updateRate_Hz      = 5.0;
 d.adcs.sensors.sunSensor.power_W            = 0.10;
 d.adcs.sensors.sunSensor.mass_kg            = 0.05;

% Actuators
% Four-wheel pyramid: choose conservative but realistic 6U-class values.
maxRwMomentum_Nms = 0.03;                                   % 30 mNms each
maxRwSpeed_rpm    = 6000;
maxRwOmega_rads   = maxRwSpeed_rpm*2*pi/60;
rwInertia_kgm2    = maxRwMomentum_Nms/maxRwOmega_rads;

 d.adcs.actuators.rw.count                = 4;
 d.adcs.actuators.rw.maxTorque_Nm         = 2.0e-3;        % 2 mNm each
 d.adcs.actuators.rw.maxMomentum_Nms      = maxRwMomentum_Nms;
 d.adcs.actuators.rw.maxSpeed_rpm         = maxRwSpeed_rpm;
 d.adcs.actuators.rw.inertia_kgm2         = rwInertia_kgm2;
 d.adcs.actuators.rw.powerPerWheel_W      = 0.80;          % average active power
 d.adcs.actuators.rw.massPerWheel_kg      = 0.12;
 d.adcs.actuators.rw.mountMatrix          = localRwPyramidAxes(35.26438968);  % tetrahedral / pyramid geometry

 d.adcs.actuators.mtq.count               = 3;
 d.adcs.actuators.mtq.maxDipole_Am2       = 0.20;          % 0.2 A m^2 each axis, plausible 6U-class assumption
 d.adcs.actuators.mtq.powerPerAxis_W      = 0.50;
 d.adcs.actuators.mtq.massPerAxis_kg      = 0.05;

% Pointing and knowledge requirements
 d.adcs.pointingReq_deg                   = 1.0;           % Report-defined preliminary requirement
 d.adcs.knowledgeGoal_deg                 = 0.10;          % engineering target for payload support
 d.adcs.modeNominal                       = 'PAYLOAD';
 d.adcs.modeSafe                          = 'SUNPOINT';
 d.adcs.notes                             = 'Reaction wheels for fine pointing; magnetorquers for detumble and wheel unloading';

% Disturbance toggles / rough environment model
 d.disturbances.includeAerodynamic        = true;
 d.disturbances.includeSolarPressure      = true;
 d.disturbances.includeGravityGradient    = true;
 d.disturbances.includeMagnetic           = true;
 d.disturbances.Cd                        = 2.2;
 d.disturbances.Cr                        = 1.3;
 d.disturbances.residualDipole_Am2        = [0.01; 0.01; 0.01];

% Controller gains (preliminary; tune in simulation if required)
ctrl = struct();
ctrl.type                = 'Quaternion PD + magnetic unloading';
ctrl.kP                  = 1.5e-3;
ctrl.kD                  = 3.5e-2;
ctrl.kI                  = 0.0;
ctrl.qRef                = [1;0;0;0];     % LVLH-aligned reference placeholder
ctrl.wRef_radps          = [0;0;0];
ctrl.maxWheelTorque_Nm   = d.adcs.actuators.rw.maxTorque_Nm;
ctrl.maxWheelMomentum    = d.adcs.actuators.rw.maxMomentum_Nms;
ctrl.mtqMax_Am2          = d.adcs.actuators.mtq.maxDipole_Am2;
ctrl.dumpingThreshold    = 0.75*d.adcs.actuators.rw.maxMomentum_Nms;
ctrl.detumbleGain        = 5e4;           % preliminary B-dot-like gain placeholder

% Mirror some controller fields into d when convenient for RHS scripts
 d.ctrl = ctrl;

% -------------------------------------------------------------------------
% 10. Communications and CDH parameters
% -------------------------------------------------------------------------
comm = struct();
comm.band                    = 'S-band';
comm.freq_GHz                = 2.20;       % plausible TT&C / modest payload downlink choice
comm.lambda_m                = 3e8/(comm.freq_GHz*1e9);
comm.txPower_W               = 2.0;        % consistent with 3 W comm daytime budget including electronics overhead
comm.txGain_dBi              = 5.0;        % small patch / low-gain directional antenna assumption
comm.rxGain_dBi              = 25.0;       % modest ground terminal assumption
comm.requiredDataRate_bps    = 1.0e6;      % 1 Mbps preliminary mission target
comm.modulation              = 'QPSK';
comm.linkMargin_dB           = 3.0;
comm.groundStation.name      = 'Sydney';
comm.groundStation.lat_deg   = -33.917;
comm.groundStation.lon_deg   = 151.231;
comm.groundStation.alt_m     = 50;
comm.storage_GB              = 32;         % conservative onboard data storage assumption
comm.payloadDataRate_bps     = 2.5e5;      % processed payload products rather than raw stereo video
comm.downlinkPassesPerDay    = 4;          % engineering assumption for a single Australian station + SSO
comm.avgPassDuration_s       = 480;        % 8 min/pass
comm.mass_radio_kg           = 0.20;
comm.powerDay_W              = 3.0;        % Report-defined
comm.powerEclipse_W          = 2.0;        % Report-defined

% Also store in d for monolithic workflows
 d.comm = comm;

% -------------------------------------------------------------------------
% 11. Mode power schedule / operational concept
% -------------------------------------------------------------------------
d.modes = struct();
d.modes.SUNPOINT.duration_s  = 15*60;
d.modes.PAYLOAD.duration_s   = 10*60;
d.modes.DOWNLINK.duration_s  = 8*60;
d.modes.ECLIPSE.duration_s   = orbit.eclipse_s;

d.modes.SUNPOINT.power_W     = 12.0;   % charge-favouring mode with payload off but ADCS active

d.modes.PAYLOAD.power_W      = 20.0;   % Report-defined daylight/RPO load

d.modes.DOWNLINK.power_W     = 11.0;   % payload off, comms on, moderate ADCS + EPS

d.modes.ECLIPSE.power_W      = 8.0;    % Report-defined eclipse/standby load

% Detailed subsystem loads from report where already fixed
 d.loads.payload_day_W       = 12.0;
 d.loads.payload_eclipse_W   = 0.0;
 d.loads.adcs_day_W          = 4.0;
 d.loads.adcs_eclipse_W      = 2.0;
 d.loads.comms_day_W         = 3.0;
 d.loads.comms_eclipse_W     = 2.0;
 d.loads.eps_day_W           = 1.0;
 d.loads.eps_eclipse_W       = 4.0;

% -------------------------------------------------------------------------
% 12. Initial state vector
% -------------------------------------------------------------------------
% State order assumed here:
% [r(3); v(3); q(4); wBody(3); rwOmega(4); batteryEnergy(1)]
q0 = [1;0;0;0];
w0 = deg2rad([0.80; -0.60; 0.40]);   % small initial body-rate disturbance
rwOmega0 = zeros(4,1);
Eb0 = d.power.batteryEnergy0;

x0 = [r0_km(:); v0_kms(:); q0; w0; rwOmega0; Eb0];

% -------------------------------------------------------------------------
% 13. Convenience summary values
% -------------------------------------------------------------------------
d.summary.orbitPeriod_min    = orbit.period_min;
d.summary.eclipse_min        = orbit.eclipse_s/60;
d.summary.daylight_min       = orbit.daylight_s/60;
d.summary.totalMass_kg       = d.mass;
d.summary.totalPayload_kg    = d.payload.totalMass_kg;
d.summary.battery_Wh         = d.power.batteryCapacity_Wh;
d.summary.arrayRequired_W    = d.power.PsaRequired_W;
d.summary.ADCS_day_W         = d.loads.adcs_day_W;
d.summary.ADCS_eclipse_W     = d.loads.adcs_eclipse_W;

end

% ========================================================================
% Local helper functions
% ========================================================================
function [r_km, v_kms] = localEl2RV(a_km, e, inc_deg, raan_deg, argp_deg, nu_deg, mu)
% Classical orbital elements to ECI state vector
inc  = deg2rad(inc_deg);
raan = deg2rad(raan_deg);
argp = deg2rad(argp_deg);
nu   = deg2rad(nu_deg);

p = a_km*(1 - e^2);
r_pf = (p/(1 + e*cos(nu))) * [cos(nu); sin(nu); 0];
v_pf = sqrt(mu/p) * [-sin(nu); e + cos(nu); 0];

R3_W = [ cos(raan) sin(raan) 0; -sin(raan) cos(raan) 0; 0 0 1];
R1_i = [1 0 0; 0 cos(inc) sin(inc); 0 -sin(inc) cos(inc)];
R3_w = [ cos(argp) sin(argp) 0; -sin(argp) cos(argp) 0; 0 0 1];
Q_pX = (R3_w*R1_i*R3_W)';

r_km = Q_pX*r_pf;
v_kms = Q_pX*v_pf;
end

function I = localBoxInertia(m, a, b, c)
I = diag([ (1/12)*m*(b^2 + c^2), ...
           (1/12)*m*(a^2 + c^2), ...
           (1/12)*m*(a^2 + b^2) ]);
end

function I = localPointMassInertia(m, r)
I = m*((r.'*r)*eye(3) - (r*r.'));
end

function M = localRwPyramidAxes(alphaDeg)
% Returns 3x4 wheel-axis unit vectors for a symmetric 4-wheel pyramid.
a = deg2rad(alphaDeg);
M = [ cos(a) -cos(a)  0       0; ...
      0       0      cos(a) -cos(a); ...
      sin(a)  sin(a) sin(a)  sin(a) ];
for k = 1:4
    M(:,k) = M(:,k)/norm(M(:,k));
end
end

function [area, nFace, rFace, uSurface] = localDefaultCubeFaces()
% Simple 6-face box fallback if SCT face generator is unavailable.
Lx = 0.10; Ly = 0.20; Lz = 0.30;
area = [Ly*Lz; Ly*Lz; Lx*Lz; Lx*Lz; Lx*Ly; Lx*Ly].';
nFace = [ 1 -1  0  0  0  0; ...
          0  0  1 -1  0  0; ...
          0  0  0  0  1 -1 ];
rFace = [ Lx/2 -Lx/2  0      0      0      0; ...
          0      0    Ly/2  -Ly/2   0      0; ...
          0      0    0      0      Lz/2  -Lz/2 ];
uSurface = nFace;
end
