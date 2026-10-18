
d = CubeSatModel('struct');

d.massComponents = 5.0;

d.solarPanel.dim = [100 200 10];

d.solarPanel.nPanels = 1;

d.solarPanel.rPanel = [ ...
     50  -50    0    0; ...
      0    0   50  -50; ...
    150  150  150  150];


d.solarPanel.sPanel = [ ...
     1  -1   0   0; ...
     0   0   1  -1; ...
     0   0   0   0];

d.solarPanel.cellNormal = Unit([ ...
    0   0   0   0; ...
    0   0   0   0; ...
    1   1   1   1]);

d.solarPanel.sigmaCell = [1;0;0];


d.solarPanel.sigmaBack = [0;0;1];


d.solarPanel.mass = 0.15;


[v, f, data] = CubeSatModel('6U', d);

StructToText(data);

DrawCubeSat(v, f, data);
DrawCubeSatSolarAreas(data);



