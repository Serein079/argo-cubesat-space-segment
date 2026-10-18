

d = struct;

model = '6U';  


d.mass    = 9.0;                        
d.inertia = InertiaCubeSat(model, d.mass);

d.thicknessWall = 4;      
d.thicknessRail = 8.5;   
d.densityWall   = 2700;   


d.massComponents = 3;     
d.cMComponents   = [0;0;0];

d.sigma = [zeros(2,6); ones(1,6)];
d.cD    = 2.7;                   


d.solarPanel.dim        = [100 100 10];   
d.solarPanel.nPanels    = 1;              


d.solarPanel.rPanel     = [ 50  -50    0    0;...
                             0    0   50  -50;...
                           150  150  150  150];


d.solarPanel.sPanel     = [ 1   -1    0    0;...
                             0    0    1   -1;...
                             0    0    0    0];

d.solarPanel.cellNormal = [ 0    0    0    0;...
                             0    0    0    0;...
                             1    1    1    1];


d.solarPanel.sigmaCell  = [1;0;0];  
d.solarPanel.sigmaBack  = [0;0;1];  

d.solarPanel.mass       = 0.1;     



[v, f, data] = CubeSatModel(model, d);


fig1 = figure('Color','w');
DrawCubeSat(v, f, data);
title('ARGO 6U CubeSat Structure');



fig2 = figure('Color','w');
DrawCubeSatSolarAreas(data);
title('ARGO Solar Panel Configuration');

