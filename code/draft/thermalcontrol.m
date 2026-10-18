
[d, x0, ctrl, sim, comm] = ARGO_BuildMissionData(); 


sigma = 5.67e-8;     % Stefan-Boltzmann constant 
S0    = 1367;        % Solar flux [W/m^2]
T0    = 293.15;      % Initial temperature 

mu     = 398600.4418;       
r0     = norm(x0(1:3));      % km
Torb   = 2*pi*sqrt(r0^3/mu); % s

Tecl   = 35.6 * 60;          % s
Tday   = Torb - Tecl;        % s

% Thermal parameters from BuildMissionData
m       = d.mass;                   % kg
cp      = d.cP;                     % J/(kg*K)
Qgen    = d.powerTotal;             % W
Aproj   = d.thermal.AprojEff;       % m^2
Arad    = d.thermal.Arad;           % m^2
alphaEf = d.thermal.alphaEff;       
epsRad  = d.thermal.epsilonRad;     

% Time grid

nOrbit = 6;
dt     = sim.dT;
tEnd   = nOrbit * Torb;
t      = 0:dt:tEnd;

T      = zeros(size(t));
T(1)   = T0;


% Isothermal integration

for k = 2:length(t)

    tOrb = mod(t(k), Torb);

    % Sunlight / eclipse logic
    if tOrb <= Tday
        Qin_solar = alphaEf * Aproj * S0;
    else
        Qin_solar = 0;
    end

    % Energy balance
    dTdt = (Qin_solar + Qgen - sigma*epsRad*Arad*T(k-1)^4) / (m*cp);

    T(k) = T(k-1) + dTdt * dt;
end


% Convert to degC

T_C = T - 273.15;

% Plot

figT = figure('Color','w');
plot(t/3600, T_C, 'LineWidth', 2); grid on; hold on;

yline(50,  'r--', 'Example Electronics Limit (+50°C)', 'LineWidth', 1.2);
yline(-20, 'b--', 'Battery Min Limit (-20°C)', 'LineWidth', 1.2);

xlabel('Mission Time (hours)');
ylabel('Spacecraft Bulk Temperature (°C)');
title('ARGO 6U Isothermal Thermal Response');

