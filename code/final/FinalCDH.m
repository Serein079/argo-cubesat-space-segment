



rD = pi/180;

mu = 398600.4418;
Re = 6378.137;        

altitude = 500;     
sMA      = Re + altitude;
inc      = 97.4*rD;

Torb = 2*pi*sqrt(sMA^3/mu);

nOrbit  = 2;
nPoints = 800;
t       = linspace(0, nOrbit*Torb, nPoints);

jD0 = Date2JD([2026 4 1 10 30 0]);
jD  = jD0 + t/86400;


% Ground station

latGS = -33.9173*rD;
lonGS = 151.2313*rD;
altGS = 0.05;         

rGS = LatLonAltToEF([latGS; lonGS; altGS], [], []);


passCenterTime = 11*60;   

rGSECI_mid = ECIToEF(JD2T(jD0 + passCenterTime/86400))' * rGS;
rHat_mid   = rGSECI_mid / norm(rGSECI_mid);

x = rHat_mid(1);
y = rHat_mid(2);
z = rHat_mid(3);

C   = sqrt(x^2 + y^2);
rhs = -cos(inc)*z/sin(inc);
rhs = min(max(rhs/C, -1), 1);

phi  = atan2(y, x);
raan = phi + asin(rhs);

hHat = [ sin(inc)*sin(raan);
        -sin(inc)*cos(raan);
         cos(inc) ];

hHat = hHat / norm(hHat);

rMid = sMA*rHat_mid;
vMid = sqrt(mu/sMA)*cross(hHat, rHat_mid);

nMean = sqrt(mu/sMA^3);
r     = zeros(3, nPoints);

for k = 1:nPoints
    tau = t(k) - passCenterTime;
    r(:,k) = rMid*cos(nMean*tau) + (vMid/nMean)*sin(nMean*tau);
end


d = struct;

d.fGHz               = 2.26;       
d.diameterReceive    = 3.0;        
d.apertureEfficiency = 0.55;

d.polarizationAngle  = 3.0;        
d.attError           = 1.0;        
d.ampAntennaLoss     = 1.0;        
d.beamEdgeLoss       = 1.0;        
d.lossFeeder         = 0.5;

d.latitude           = latGS;
d.longitude          = lonGS;
d.altitude           = altGS;
d.horizonAngle       = 10*rD;     

d.bitRate            = 1.2e6;      
d.powerTransmit      = 2.0;        
d.modulation         = 'QPSK';
d.gainTransmit       = 6.0;       


d.temperatureERX     = 120;        % [K]
d.temperatureFeeder  = 290;        % [K]

dRate = DataRateGain;

lambda = 299792458/(d.fGHz*1e9);

gainReceiveDB = 10*log10( ...
    d.apertureEfficiency*(pi*d.diameterReceive/lambda)^2 );

dRate.fGHz         = d.fGHz;
dRate.gainTransmit = d.gainTransmit;
dRate.gainReceive  = gainReceiveDB;
dRate.tempS        = 500;
dRate.modulation   = d.modulation;

if ~isfield(dRate, 'sN')
    dRate.sN = 10;
end


LinkOrbitAnalysis(r, jD, d);

DataRateOrbit(r, rGS, d.powerTransmit, jD, dRate);

bEP = LinkOrbitAnalysis(r, jD, d);

visible = false(1, nPoints);

for k = 1:nPoints
    visible(k) = GroundStationVisibility(rGS, jD(k), r(:,k), d.horizonAngle);
end

bEPThreshold = 1e-5;
goodLink     = visible & (bEP < bEPThreshold);

dt = t(2) - t(1);

contactTime  = sum(visible)*dt;
goodLinkTime = sum(goodLink)*dt;



