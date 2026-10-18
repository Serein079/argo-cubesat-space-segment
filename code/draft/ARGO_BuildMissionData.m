function [d, x0, ctrl, sim, comm] = ARGO_BuildMissionData()



sim = struct;

sim.days           = 0.2;

sim.dT             = 1;

sim.makePlots      = true;

sim.modeCycleSec   = 5400;


d = RHSCubeSatIntegral;

model = '6U';
% ARGO is modelled as a 6U CubeSat

[area, nFace, rFace] = CubeSatFaces(model, 1);

d.mass    = 9.0;
% Preliminary total spacecraft mass [kg]

d.inertia = InertiaCubeSat(model, d.mass);

d.surfData.area     = area;
d.surfData.nFace    = nFace;
d.surfData.rFace    = rFace;
d.surfData.att.type = 'eci';

d.kWheels    = 14:16;

d.inertiaRWA = 2.0e-5;

d.tRWA       = [0;0;0];

d.power.solarCellNormal = [ 1  1 -1 -1  0  0  0  0; ...
                            0  0  0  0  1  1 -1 -1; ...
                            0  0  0  0  0  0  0  0 ];

d.power.solarCellEff       = 0.295;

d.power.effPowerConversion = 0.9;

d.power.solarCellArea      = 0.1 * 0.116 * ones(1,8);

d.power.consumption        = 4;

d.power.batteryCapacity    = 40 * 3600;



aC = 0.8;   eC = 0.82;   % solar cells 
aG = 0.3;   eG = 0.04;   % goldized Kapton 
aR = 0.15;  eR = 0.8;    % radiator 


d.uSurface = [1  1  1 -1 -1 -1  0  0  0  0  0  0  0  0; ...
              0  0  0  0  0  0  1  1  1 -1 -1 -1  0  0; ...
              0  0  0  0  0  0  0  0  0  0  0  0  1 -1];

% Surface absorptivity 
d.alpha    = [aC aG aC aC aG aC aC aG aC aC aG aC aR aR];

% Surface emissivity 
d.epsilon  = [eC eG eC eC eG eC eC eG eC eC eG eC eR eR];

% Surface area of each thermal face 
d.area     = 0.1 * 0.1 * ones(1,14);

% Average specific heat 
d.cP       = 900;
%% Thermal parameters
d.powerTotal          = 8;       % W, representative internal heat load 
d.thermal.AprojEff    = 0.012;   % m^2, effective projected absorbing area 
d.thermal.Arad        = 0.03;    % m^2, dedicated radiator area 
d.thermal.alphaEff    = 0.35;    % effective absorptivity 
d.thermal.epsilonRad  = 0.80;    % radiator emissivity 

d.thicknessWall = 4;


d.thicknessRail = 8.5;

d.densityWall   = 2700;

d.massComponents = 3;

d.cMComponents   = [0;0;0];

d.sigma          = [zeros(2,6); ones(1,6)];

d.cD             = 2.7;

d.solarPanel.dim        = [100 100 10];

d.solarPanel.nPanels    = 1;


% Panel locations 
d.solarPanel.rPanel     = [ 50  -50    0    0; ...
                             0    0   50  -50; ...
                           150  150  150  150 ];

% Panel span/deployment directions
d.solarPanel.sPanel     = [ 1   -1    0    0; ...
                             0    0    1   -1; ...
                             0    0    0    0 ];

% Cell-surface normals
d.solarPanel.cellNormal = [ 0    0    0    0; ...
                             0    0    0    0; ...
                             1    1    1    1 ];

d.solarPanel.sigmaCell  = [1;0;0];

d.solarPanel.sigmaBack  = [0;0;1];

d.solarPanel.mass       = 0.1;

x0 = d.x0;

rEarth = 6378.137;          % km
h      = 500;               % km
a      = rEarth + h;        % km
e      = 0.001;             % near-circular orbit 
inc    = 97.6*pi/180;       % rad, SSO inclination 
raan   = 0;                 % rad
omega  = 0;                 % rad
nu     = 0;                 % rad

el = [a; e; inc; raan; omega; nu];
%  Classical orbital elements


jD0 = JD2000 + 9500;


[r, v] = El2RV(el);
% Convert orbital elements to position and velocity


x0(1:3) = r;
x0(4:6) = v;

x0(7:10)  = [cos(pi/4); 0; sin(pi/4); 0];


x0(11:13) = [0.03; -0.02; 0.015];

d.jD0 = jD0;


d.atm = [];


comm = struct;

radToDeg = 180/pi;

comm.rGS = LatLonToR(33.9191667/radToDeg, -118.4155556/radToDeg);

comm.dLink = DataRateOrbit;



ctrl = struct;

ctrl.inertia       = d.inertia;

ctrl.max_angle     = 1*pi/180;

ctrl.accel_sat     = [0.05;0.05;0.05];

ctrl.mode          = 2;

end