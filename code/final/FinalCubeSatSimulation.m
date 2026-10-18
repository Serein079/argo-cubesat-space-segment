
cube = '6U';
[aFace,nFace,rFace] = CubeSatFaces(cube,1);


d      = RHSCubeSat;
d.jD0  = Date2JD([2026 4 1 10 30 0]);   
d.mass = 9.0;                           
d.inertia = InertiaCubeSat(cube,d.mass);


rEarth = 6378.137;     


altitude = 500;                 
a0       = rEarth + altitude;   
i0       = deg2rad(97.4);       
RAAN0    = deg2rad(0.0);       
argPer0  = deg2rad(0.0);       
e0       = 0.001;              
M0       = deg2rad(0.0);        


el = [a0 i0 RAAN0 argPer0 e0 M0];

[r0,v0] = El2RV(el);


q0 = QLVLH(r0,v0);


w0 = [0; -OrbRate(a0); 0];


batteryCapacityJ = 60 * 3600;   
b0 = 0.8 * batteryCapacityJ;    


x = [r0; v0; q0; w0; b0];


PltOrbit(el,d.jD0);


d.surfData.cD       = 2.7;      
d.surfData.nFace    = nFace;     
d.surfData.rFace    = rFace;     
d.surfData.cM       = [0;0;0];   
d.surfData.area     = aFace;    
d.surfData.sigma    = [1 1 1 1 1 1; zeros(2,6)]; 
d.surfData.att.type = 'eci';     



d.aeroModel      = @CubeSatAero;
d.opticalModel   = @CubeSatRadiationPressure;
d.skewOmegaEarth = Skew([0;0;7.291e-5]);


d.power.solarCellNormal    = nFace;
d.power.solarCellEff       = 0.295;     % triple-junction GaAs efficiency / 三结GaAs效率
d.power.effPowerConversion = 0.90;      % EPS conversion efficiency / 电源转换效率


d.power.solarCellArea      = 0.70 * aFace;


d.power.consumption        = 8.0;            % [W]


d.power.batteryCapacity    = batteryCapacityJ;


[aP, f, fHat, fHat400] = SolarFluxPrediction(d.jD0,'nominal');
d.atm.aP      = aP(1);
d.atm.f       = f(1);
d.atm.fHat    = fHat(1);
d.atm.fHat400 = fHat400(1);


d.planet = 'earth';
d.rP     = 6378.165;


d.dipole = [0;0;0];

tic
orbits = 2.5;               % > 2 orbital periods / 超过两个轨道周期
tEnd   = orbits * Period(a0);
dT     = 2;                 % [s] time step / 时间步长
nSim   = floor(tEnd/dT);


xPlot     = [x zeros(14,nSim)];
[~, dist, power] = RHSCubeSat(x,0,d);

dragPlot  = [dist.fAerodyn zeros(3,nSim)];
radPlot   = [dist.fOptical zeros(3,nSim)];
tRadPlot  = [dist.tOptical zeros(3,nSim)];
tAeroPlot = [dist.tAerodyn zeros(3,nSim)];
tMagPlot  = [dist.tMag zeros(3,nSim)];
tGGPlot   = [dist.tGG zeros(3,nSim)];
powerPlot = [power zeros(1,nSim)];
bPlot     = zeros(3,nSim+1);
qPlot     = zeros(4,nSim+1);


t = 0;
h = waitbar(0,'ARGO CubeSat Simulation Running...');
upF = ceil(nSim/20);
kW  = 1;

for k = 1:nSim

    bField = BDipole(x(1:3), d.jD0 + t/86400);
    bBody  = QForm(x(7:10), bField); 
    
    
    d.dipole = [0;0;0];
    
    
    x = RK4(@RHSCubeSat, x, dT, t, d);
    
   
    [~, dist, power] = RHSCubeSat(x,t,d);
    
    dragPlot(:,k+1)  = dist.fAerodyn;
    tAeroPlot(:,k+1) = dist.tAerodyn;
    radPlot(:,k+1)   = dist.fOptical;
    tRadPlot(:,k+1)  = dist.tOptical;
    tMagPlot(:,k+1)  = dist.tMag;
    tGGPlot(:,k+1)   = dist.tGG;
    powerPlot(:,k+1) = power;
    bPlot(:,k+1)     = bField;
    
    
    qLVLH = QLVLH(x(1:3),x(4:6));
    qPlot(:,k+1) = QMult(QPose(qLVLH),x(7:10));
    

    xPlot(:,k+1) = x;
    t = t + dT;
    
    if k/upF >= kW
        waitbar(k/nSim,h);
        kW = kW + 1;
    end
end
close(h);


time = (0:nSim)*dT;
[tP,tL] = TimeLabl(time);


yL = {'r_x (km)' 'r_y (km)' 'r_z (km)' ...
      'v_x (km/s)' 'v_y (km/s)' 'v_z (km/s)' ...
      'q_s' 'q_x' 'q_y' 'q_z' ...
      '\omega_x (rad/s)' '\omega_y (rad/s)' '\omega_z (rad/s)' ...
      'b (Wh)'};


GroundTrack(xPlot(1:3,:), time, d.jD0);


rMag = Mag(xPlot(1:3,:));
Plot2D(tP, rMag-rMag(1), tL, '\Delta h (km)', 'ARGO Change in Altitude');


Plot2D(tP, xPlot(7:10,:), tL, {yL{7:10}}, 'ARGO ECI to Body Quaternion');
Plot2D(tP, qPlot,         tL, {yL{7:10}}, 'ARGO LVLH to Body Quaternion');
Plot2D(tP, xPlot(11:13,:),tL, {yL{11:13}}, 'ARGO Body Angular Rates (rad/s)');


Plot2D(tP, [xPlot(14,:)/3600; powerPlot], tL, ...
      {yL{14}, 'Power (W)'}, 'ARGO Power System');


Plot2D(tP, dragPlot*1e3,   tL, {'F_x (mN)','F_y (mN)','F_z (mN)'}, ...
      'ARGO Aerodynamic Force (mN)');

Plot2D(tP, tAeroPlot*1e6,  tL, {'T_x (\muNm)','T_y (\muNm)','T_z (\muNm)'}, ...
      'ARGO Aerodynamic Torque');

Plot2D(tP, tMagPlot*1e6,   tL, {'T_x (\muNm)','T_y (\muNm)','T_z (\muNm)'}, ...
      'ARGO Magnetic Torque');

Plot2D(tP, tGGPlot*1e6,    tL, {'T_x (\muNm)','T_y (\muNm)','T_z (\muNm)'}, ...
      'ARGO Gravity Gradient Torque');

Plot2D(tP, radPlot*1e3,    tL, {'F_x (mN)','F_y (mN)','F_z (mN)'}, ...
      'ARGO Radiation Force (mN)');


Plot2D(tP, tRadPlot*1e6,   tL, {'T_x (\muNm)','T_y (\muNm)','T_z (\muNm)'}, ...
      'ARGO Radiation Torque');


Plot2D(tP, bPlot,          tL, {'B_x (T)','B_y (T)','B_z (T)'}, ...
      'Magnetic Field (ECI Frame)');

Figui;


AnimQ(qPlot(:,1:min(800,size(qPlot,2))));

toc