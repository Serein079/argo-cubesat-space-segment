%% ARGO 6U CubeSat Active ADCS Simulation using Reaction Wheels
% Modified from CubeSatRWASimulation.m
% Mission-consistent parameters:
% - 6U CubeSat (10 x 20 x 30 cm)
% - mass = 9 kg
% - 500 km Sun-synchronous orbit
% - reaction-wheel 3-axis active control
% - nadir-pointing equivalent for imaging mission

clear g; clear u; clear p; clear d;

%% Constants
radToDeg        = 180/pi;
mu              = 398600.4418;   % km^3/s^2
rEarth          = 6378.165;      % km
densitySilicon  = 2600;          % kg/m^3
densityTungsten = 19300;         % kg/m^3

%% Simulation parameters
days  = 0.20;                    % keep same duration as example
tEnd  = days*86400;
dT    = 1;
nSim  = ceil(tEnd/dT);

%% CubeSat model
d = RHSCubeSat;

% 6U spacecraft geometry and mass
model = '6U';
[area,nFace,rFace] = CubeSatFaces(model,1);

d.mass = 9.0;                    % kg, from ARGO draft

% Use manual cuboid inertia for consistency with 6U = 0.1 x 0.2 x 0.3 m
xDim = 0.10; yDim = 0.20; zDim = 0.30;   % m
Ix = (1/12)*d.mass*(yDim^2 + zDim^2);
Iy = (1/12)*d.mass*(xDim^2 + zDim^2);
Iz = (1/12)*d.mass*(xDim^2 + yDim^2);
d.inertia = diag([Ix Iy Iz]);

% Surface model
d.surfData.area     = area;
d.surfData.nFace    = nFace;
d.surfData.rFace    = rFace;
d.surfData.att.type = 'eci';

%% Reaction wheel design (3-wheel nominal control model)
% Keep 3 orthogonal wheels so the state order stays identical to the demo.
d.kWheels    = 14:16;

radius       = 0.030;            % m
thickness    = 0.004;            % m
volRWA       = pi*radius^2*thickness;
massRWA      = volRWA*densityTungsten;
d.inertiaRWA = 0.5*massRWA*radius^2;

%% Simplified power model for ADCS demonstrator
% Keep same structure/output as the demo.
thicknessSolarPanel            = 0.004;
d.power.solarCellNormal        = [ 1  1 -1 -1  0  0  0  0;
                                   0  0  0  0  1  1 -1 -1;
                                   0  0  0  0  0  0  0  0];
d.power.solarCellEff           = 0.295;
d.power.effPowerConversion     = 0.90;
d.power.solarCellArea          = 0.1*0.116*ones(1,8);

% For this stand-alone ADCS demo use the ADCS daytime load from your draft
d.power.consumption            = 4.0;          % W
d.power.batteryCapacity        = 40*3600;      % J = 40 Wh

volSolarPanel                  = d.power.solarCellArea(1,1)*thicknessSolarPanel;
massSolarPanel                 = volSolarPanel*densitySilicon;

DrawCubeSatSolarAreas(d.power)

%% Initial orbit: 500 km SSO
altitude   = 500;                           % km
inc        = 97.4*pi/180;                   % rad
rMag       = rEarth + altitude;             % km
vMag       = sqrt(mu/rMag);                 % circular speed

r0         = [rMag;0;0];                    % km
v0         = [0;
              vMag*cos(inc);
              vMag*sin(inc)];               % km/s

%% Initial attitude and rates
% Start with a disturbed attitude so that convergence can be observed.
q0         = [1;0;0;0];                     % unit quaternion
w0         = [0.002;-0.002;0.0015];         % rad/s
c0         = [0;0;0];                       % wheel rates
b0         = 20*3600;                       % J (start at 20 Wh)

% State = [r;v;q;w;wheel_rates;battery]
x          = [r0;v0;q0;w0;c0;b0];

%% Start Julian date
d.jD0      = Date2JD([2026 4 1 0 0 0]);

%% PID controller
p                    = PID3Axis;
[p.a,p.b,p.c,p.d]   = PIDMIMO(1,1,0.015,260,0.15,dT);

p.inertia            = d.inertia;
p.max_angle          = 1.0*pi/180;          % 1 deg target class
p.accel_sat          = [20;20;20];          % realistic for 6U
p.mode               = 1;
p.q_target_last      = q0;
p.q_desired_state    = [0;0;0;1];
p.body_vector        = [0;0;1];             % payload boresight = +Z body

%% Atmosphere model
d.atm = [];

%% Initialize plotting array
qECIToBody   = x(7:10);

% Recommended mission-consistent target: nadir vector in ECI
rHat         = Unit(x(1:3));
p.eci_vector = -rHat;

% If you want to match the original demo more closely, replace the two lines above with:
% bField       = QForm(qECIToBody, BDipole(x(1:3), d.jD0));
% p.eci_vector = Unit(bField);

angleError   = acos(Dot(p.eci_vector,QTForm(qECIToBody,p.body_vector)))*radToDeg;
bField       = QForm(qECIToBody,BDipole(x(1:3),d.jD0));

xPlot        = [[x;0;0;0;0;angleError;bField;0;0;0] zeros(length(x)+11,nSim)];

%% Initialize time display
TimeDisplay('initialize','ARGO 6U RWA Sim',nSim);

%% Run simulation
t = 0;

for k = 1:nSim

    TimeDisplay('update');

    qECIToBody = x(7:10);

    % Magnetic field (kept for plotting and future momentum dumping logic)
    bField     = QForm(qECIToBody,BDipole(x(1:3),d.jD0 + t/86400));

    % No active magnetorquer torque in this run
    d.dipole   = [0;0;0];

    % Nadir-pointing target
    rHat         = Unit(x(1:3));
    p.eci_vector = -rHat;

    angleError   = acos(Dot(p.eci_vector,QTForm(qECIToBody,p.body_vector)))*radToDeg;

    [torque,p]   = PID3Axis(qECIToBody,p);
    d.tRWA       = -torque;

    % Integrate one step
    x            = RK4(@RHSCubeSat,x,dT,t,d);

    % Get instantaneous power
    [xDot,dist,power] = RHSCubeSat(x,t,d); %#ok<NASGU,ASGLU>

    % Wheel momentum
    hRWA         = x(14:16)*d.inertiaRWA;

    % Save
    xPlot(:,k+1) = [x;power;torque;angleError;bField;hRWA];
    t            = t + dT;
end

TimeDisplay('close');

%% Plotting
kP = 1:k+1;
[tPlot,tL] = TimeLabl((0:k)*dT);

yL = {'r_x (km)' 'r_y (km)' 'r_z (km)' 'v_x (km/s)' 'v_y (km/s)' 'v_z (km/s)'...
      'q_s' 'q_x' 'q_y' 'q_z' '\omega_x (rad/s)' '\omega_y (rad/s)' '\omega_z (rad/s)' ...
      '\omega_{w1} (rad/s)' '\omega_{w2} (rad/s)' '\omega_{w3} (rad/s)' 'b (Wh)' 'Power (W)' ...
      'T_x (Nm)' 'T_y (Nm)' 'T_z (Nm)' 'Angle Error (deg)' 'B_x' 'B_y' 'B_z'...
      'H_x (Nms)' 'H_y (Nms)' 'H_z (Nms)'};

Plot2D(tPlot,xPlot(1:3,kP),tL,yL(1:3),'ARGO Orbit');
Plot2D(tPlot,xPlot(7:10,kP),tL,yL(7:10),'ARGO ECI To Body Quaternion');
Plot2D(tPlot,xPlot(11:13,kP),tL,yL(11:13),'ARGO Attitude Rate');
Plot2D(tPlot,xPlot(14:16,kP),tL,yL(14:16),'ARGO Reaction Wheel Rate');
Plot2D(tPlot,[xPlot(17,kP)/3600; xPlot(18,kP)],tL,yL(17:18),'ARGO Power');
Plot2D(tPlot,xPlot(19:22,kP),tL,yL(19:22),'ARGO Control Torque');
Plot2D(tPlot,xPlot(23:25,kP),tL,yL(23:25),'ARGO Magnetic Field');
Plot2D(tPlot,xPlot(26:28,kP),tL,yL(26:28),'ARGO RWA Momentum');

%% Output summary
maximumTorque   = max(max(abs(xPlot(19:21,kP))));
maximumMomentum = max(max(abs(xPlot(26:28,kP))));
maximumSpeed    = max(max(abs(xPlot(14:16,kP))));

g{1,1} = 'Reaction Wheel Inertia';
g{1,2} = LatexScientificNotation(d.inertiaRWA,3);
g{1,3} = 'kg-m$^2$';

g{2,1} = 'Reaction Wheel Radius';
g{2,2} = sprintf('%8.2f',radius*1000);
g{2,3} = 'mm';

g{3,1} = 'Reaction Wheel Thickness';
g{3,2} = sprintf('%8.2f',thickness*1000);
g{3,3} = 'mm';

g{4,1} = 'Maximum RWA torque';
g{4,2} = LatexScientificNotation(maximumTorque,4);
g{4,3} = 'Nm';

g{5,1} = 'Maximum RWA momentum';
g{5,2} = LatexScientificNotation(maximumMomentum,4);
g{5,3} = 'Nms';

g{6,1} = 'Maximum RWA rate';
g{6,2} = sprintf('%12.2f',maximumSpeed*30/pi);
g{6,3} = 'RPM';

g{7,1} = 'Spacecraft mass';
g{7,2} = sprintf('%8.2f',d.mass);
g{7,3} = 'kg';

g{8,1} = 'Battery Capacity';
g{8,2} = sprintf('%8.1f',d.power.batteryCapacity/3600);
g{8,3} = 'Wh';

CreateTable(g,'ARGO_RWASummary');

%% Save for budget usage
u.rwa.mass          = massRWA;
u.rwa.volume        = volRWA;
u.solarPanel.mass   = massSolarPanel;
u.solarPanel.volume = volSolarPanel;

SaveStructure(u,'ARGO_ADCS_BudgetData.mat');