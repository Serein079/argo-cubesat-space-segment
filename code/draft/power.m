


[d, x0, ctrl, sim, comm] = ARGO_BuildMissionData(); 


S0 = 1367;                
mu = 398600.4418;         
r0     = norm(x0(1:3));            
Torb_s = 2*pi*sqrt(r0^3/mu);      
Torb_h = Torb_s/3600;               

Tecl_h = 0.593;                   
Tday_h = Torb_h - Tecl_h;        

etaCell = d.power.solarCellEff;          % solar-cell efficiency 
etaConv = d.power.effPowerConversion;    % conversion efficiency 
Ai      = d.power.solarCellArea;         % [m^2] solar-cell areas 

% increase effective solar-cell area by 25% 
Ai_opt  = 1.25 * Ai;

Atot    = sum(Ai_opt);                   % Total active cell area [m^2] 

EbatMax_J  = d.power.batteryCapacity;    % Battery capacity [J] 
EbatMax_Wh = EbatMax_J / 3600;           % Battery capacity [Wh] 

P_day   = 20;   
P_night = 8;    

DoDmax = 0.30;  

Eecl_Wh     = P_night * Tecl_h;         % Eclipse energy demand [Wh] 
Cbat_min_Wh = Eecl_Wh / DoDmax;         % Minimum battery size [Wh] 

Pgen_max = S0 * etaCell * etaConv * Atot;   % Max solar array power [W] 
% Print analytical results
fprintf('===== ARGO EPS Optimized Sizing Summary =====\n');
fprintf('Orbital period            = %.2f min\n', Torb_s/60);
fprintf('Daylight duration         = %.2f min\n', Tday_h*60);
fprintf('Eclipse duration          = %.2f min\n', Tecl_h*60);
fprintf('Total active cell area    = %.4f m^2\n', Atot);
fprintf('Max solar array power     = %.2f W\n', Pgen_max);
fprintf('Night energy required     = %.2f Wh\n', Eecl_Wh);
fprintf('Selected battery capacity = %.2f Wh\n', EbatMax_Wh);


nOrbit = 5;               % simulate 5 orbits 
dt_min = 1;               % time step = 1 min 
t_min  = 0:dt_min:(nOrbit*Torb_s/60);   % time vector [min] 
t_h    = t_min/60;                        % time vector [h] 
Pgen   = zeros(size(t_min));   % Generated power
Pload  = zeros(size(t_min));   % Load demand
Ebat   = zeros(size(t_min));   % Battery stored energy 
% Start from 90% charged, more realistic
Ebat(1) = 0.90 * EbatMax_Wh;

for k = 1:length(t_min)

    tOrb_min = mod(t_min(k), Torb_s/60);

    if tOrb_min <= Tday_h*60
        % Daylight phase 
        Pload(k) = P_day;   % operational load 


        theta = pi * (tOrb_min / (Tday_h*60));
        sunFactor = sin(theta);

        Pgen(k) = max(0, Pgen_max * (0.15 + 0.85*sunFactor));

    else
        % Eclipse phase 
        Pload(k) = P_night;   % survival load 
        Pgen(k)  = 0;         % no solar power in eclipse 
    end

    if k > 1
       
  
        dE_Wh = (Pgen(k-1) - Pload(k-1)) * (dt_min/60);
        Ebat(k) = Ebat(k-1) + dE_Wh;

        Ebat(k) = max(0, min(EbatMax_Wh, Ebat(k)));
    end
end

%% ------------------------------------------------------------------------
% Figure 1: Power generation vs demand

fig1 = figure('Color','w');
plot(t_h, Pgen, 'b-', 'LineWidth', 2); hold on; grid on;
plot(t_h, Pload, 'r--', 'LineWidth', 2);

xlabel('Mission Time (hours)');
ylabel('Power (W)');
title('ARGO Power Generation vs Demand');
legend('Generated Power','Consumed Power','Location','best');

% Figure 2: Battery energy

fig2 = figure('Color','w');
plot(t_h, Ebat, 'g-', 'LineWidth', 2); hold on; grid on;
yline(EbatMax_Wh, 'k--', 'Battery Capacity', 'LineWidth', 1.2);
yline((1-DoDmax)*EbatMax_Wh, 'r--', '30% DoD Limit', 'LineWidth', 1.2);

xlabel('Mission Time (hours)');
ylabel('Battery Energy (Wh)');
title('ARGO Battery Energy');
legend('Battery Energy','Location','best');
