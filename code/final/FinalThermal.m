
aC = 0.80;    
eC = 0.82;    

% MLI
aG = 0.30;
eG = 0.04;

% Radiator surfaces
aR = 0.15;
eR = 0.80;

d = RHSIsothermalCubeSat;
d.mass = 9.0;

d.uSurface = [ ...
     1 -1  0  0  0  0   1 -1  0  0; ...
     0  0  1 -1  0  0   0  0  1 -1; ...
     0  0  0  0  1 -1   0  0  0  0];

d.alpha   = [aC aC aC aC aR aR aC aC aG aG];
d.epsilon = [eC eC eC eC eR eR eC eC eG eG];


d.area = [ ...
    0.020 0.020 0.020 0.020 ...   % body side faces
    0.020 0.020 ...               % radiator end faces 
    0.030 0.030 ...               % deployable panel active faces 
    0.025 0.025];                 % insulated equivalent surfaces 

d.cP = 900;

d.powerTotal = 10.0;


rEarth = 6378.137;                 
alt    = 500;                      
sma    = rEarth + alt;             

p = Period(sma);

nP = 3000;
time = linspace(0, 20*p, nP);

el = [sma deg2rad(97.4) 0 0 0.001 0];

[r,v] = RVFromKepler(el, time);
jD = Date2JD([2026 4 1 10 30 0]) + time/86400;
q  = QLVLH(r, v);

T = zeros(1, nP);
T(1) = 293.15;   
dT = (jD(2) - jD(1)) * 86400;
ecl = zeros(1, nP);

for k = 2:nP
    
    [uSun, rSun] = SunV1(jD(k));
    flux = QForm(q(:,k), 1367*uSun);

 
    ecl(k) = Eclipse(r(:,k), rSun*uSun, [0;0;0]);

    if ecl(k) > 0
        d.powerTotal = 10.0;   
    else
        d.powerTotal = 5.0;   
    end

    
    T(k) = RK4(@RHSIsothermalCubeSat, T(k-1), dT, 0, d, ecl(k)*flux);
end


sigmaSB = 5.67e-8;

alphaAvg = mean(d.alpha);
epsAvg   = mean(d.epsilon);

Aproj = 0.040;
Aemit = sum(d.area);


Plot2D(jD - jD(1), T, 'Days', 'T (K)', 'ARGO Isothermal Temperature Response');
Plot2D(jD - jD(1), ecl, 'Days', 'Sunlit=1 / Eclipse=0', 'ARGO Eclipse History');