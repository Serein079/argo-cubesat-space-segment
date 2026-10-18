
solarFlux   = 1367;             % Solar constant [W/m^2]
radiusEarth = 6378.137;         % Earth radius [km]


altitude = 500;                 
inc      = deg2rad(97.4);       
e        = 0.001;               
raan     = deg2rad(0.0);        
argPer   = deg2rad(0.0);        
M0       = deg2rad(0.0);        

sma      = radiusEarth + altitude;   
tOrb     = Period(sma);              


batteryCapacityWh = 60.0;            
batteryCapacityJ  = batteryCapacityWh * 3600;
dOD               = 0.30;            


jD0        = Date2JD([2026 4 1 10 30 0]);
t          = linspace(0, 6*tOrb, 600);     % simulate 6 orbits
julianDate = jD0 + t/86400;
m          = length(t);


[rs, vs, t] = RVFromKepler([sma inc raan argPer e M0], t);


PlotOrbit(rs, t, jD0);


d                       = CubeSatModel('struct');
d.massComponents        = 5.0;


d.solarPanel.dim        = [100 200 10];
d.solarPanel.nPanels    = 1;

d.solarPanel.rPanel     = [ ...
     50  -50    0    0; ...
      0    0   50  -50; ...
    150  150  150  150];

d.solarPanel.sPanel     = [ ...
     1  -1   0   0; ...
     0   0   1  -1; ...
     0   0   0   0];

d.solarPanel.cellNormal = [ ...
     0   0   0   0; ...
     0   0   0   0; ...
     1   1   1   1];

d.solarPanel.sigmaCell  = [1;0;0];
d.solarPanel.sigmaBack  = [0;0;1];
d.solarPanel.mass       = 0.15;     

[v, f, data] = CubeSatModel('6U', d);
DrawCubeSat(v, f, data);

data.power.solarCellNormal = [ ...
     1  -1   0   0   1  -1   0   0; ...
     0   0   1  -1   0   0   1  -1; ...
     0   0   0   0   0   0   0   0];

data.power.solarCellEff       = 0.295;
data.power.effPowerConversion = 0.90;
data.power.solarCellArea      = 0.020 * ones(1,8);   
data.power.consumption        = 8.0;                 
data.power.batteryCapacity    = batteryCapacityJ;

DrawCubeSatSolarAreas(data.power);


dT         = t(2) - t(1);
tE         = 0;                 
pGen       = zeros(1,m);        
pLoad      = zeros(1,m);        
pNet       = zeros(1,m);        
nEcl       = zeros(1,m);        
uSunBody   = zeros(3,m);
bEnergy    = zeros(1,m);        
bEnergy(1) = 0.8 * batteryCapacityJ;  
modeID     = zeros(1,m);        


qs     = QLVLH(rs, vs);
qPoint = Eul2Q([pi;0;0]);   


for k = 1:m

 
    [uSun, rSun] = SunV1(julianDate(k));

 
    nEcl(k) = Eclipse(rs(:,k), rSun*uSun);

    qECIToBody    = QMult(qs(:,k), qPoint);
    uSunBody(:,k) = QForm(qECIToBody, uSun);

    pSunBody = solarFlux * nEcl(k) * uSunBody(:,k);

    pGen(k) = SolarCellPower(data.power, pSunBody);

    
    phi = mod(t(k), tOrb) / tOrb;

    if nEcl(k) > 0
        if phi < 0.30
            pLoad(k) = 8.0;       
            modeID(k) = 1;
        elseif phi < 0.36
            pLoad(k) = 18.0;      
            modeID(k) = 2;
        elseif phi < 0.42
            pLoad(k) = 10.0;      
            modeID(k) = 3;
        else
            pLoad(k) = 8.0;       
            modeID(k) = 1;
        end
    else
        pLoad(k) = 5.0;           
        tE       = tE + dT;
        modeID(k)= 4;
    end


    pNet(k) = pGen(k) - pLoad(k);


    if k > 1
        bEnergy(k) = bEnergy(k-1) + pNet(k-1) * dT;
        bEnergy(k) = max(0, min(bEnergy(k), batteryCapacityJ));
    end
end


figure;
subplot(3,1,1)
plot(t/tOrb, pGen, 'LineWidth', 1.2)
ylabel('Generated Power (W)')
title('ARGO Power vs Time')
grid on

subplot(3,1,2)
plot(t/tOrb, pLoad, 'LineWidth', 1.2)
ylabel('Load Power (W)')
grid on

subplot(3,1,3)
plot(t/tOrb, pNet, 'LineWidth', 1.2)
ylabel('Net Power (W)')
xlabel('Time (orbits)')
grid on

figure;
plot(t/tOrb, bEnergy/3600, 'LineWidth', 1.2)
xlabel('Time (orbits)')
ylabel('Battery Energy (Wh)')
title('ARGO Battery State vs Time')
grid on

