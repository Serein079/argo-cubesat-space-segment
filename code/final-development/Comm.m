%% ARGO_CommsCDH_AssignmentFull.m
% Full Communication & CDH assignment script
% 通信与CDH作业完整脚本
%
% Outputs / 输出:
% 1) Ground visibility plot / 地面可见性图
% 2) Slant range plot / 斜距图
% 3) Elevation angle plot / 仰角图
% 4) Data rate plot / 数据率图
% 5) BEP plot / 误码率图
% 6) Antenna gains / 天线增益
% 7) Pass-by-pass summary / 分过站统计
% 8) Total downloadable data / 总下传量
%
% Main course functions used / 主要课件函数:
% Date2JD, RVFromKepler, LatLonAltToEF, DataRateOrbit,
% LinkOrbitAnalysis, FrequencyToWavelength, ECIToEF, JD2T
%
% -------------------------------------------------------------------------

clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. Orbit definition / 轨道定义
% -------------------------------------------------------------------------
% Use a robust course-style case that guarantees visible passes.
% 采用稳妥的课件风格工况，保证出现可见过站。

mu = 398600.4418;          % Earth gravitational parameter [km^3/s^2]
Re = 6378.137;             % Earth radius [km]

alt = 500;                 % Orbit altitude [km]
a   = Re + alt;            % Semi-major axis [km]
e   = 0.001;               % Near-circular orbit / 近圆轨道
inc = 90*pi/180;           % Polar orbit / 极轨
RAAN = 0;
omega = 0;
nu0 = 0;

% Use the same style as course examples for RVFromKepler
% 按课件示例风格构造轨道根数
el = [a inc 0 0 0 0];

% Simulate 4 orbital periods (>= 2 required)
% 仿真4个轨道周期（满足至少2轨要求）
Torb = 2*pi*sqrt(a^3/mu);
nOrb = 4;
nPts = 3000;
t    = linspace(0, nOrb*Torb, nPts);

% Epoch / 历元
jD0 = Date2JD([2026 4 22 12 0 0]);
jD  = jD0 + t/86400;

% Orbit in ECI / ECI轨道位置
[r, ~, ~] = RVFromKepler(el, t);

%% ------------------------------------------------------------------------
% 2. Ground station definition / 地面站定义
% -------------------------------------------------------------------------
% Use a high-latitude ground station for reliable pass generation
% 使用高纬地面站保证稳定过站

latGS_deg = 65.0;
lonGS_deg = -147.5;
altGS_km  = 0.10;

latGS = latGS_deg*pi/180;
lonGS = lonGS_deg*pi/180;

% Ground station in Earth-fixed frame
% 地面站地固坐标
rGS_EF = LatLonAltToEF([latGS; lonGS; altGS_km], [], []);

%% ------------------------------------------------------------------------
% 3. Communication data structure / 通信参数结构体
% -------------------------------------------------------------------------
% Mission-consistent first-pass values
% 与任务一致的一阶参数

d = struct;

% RF settings / 射频设置
d.fGHz = 2.2;               % S-band [GHz]
d.bitRate = 5e5;            % 0.5 Mbps
d.modulation = 'BPSK';

% Spacecraft transmitter / 星上发射端
d.powerTransmit = 1.0;      % RF power [W]
d.gainTransmit  = 6.0;      % TX antenna gain [dB]

% Ground receiver / 地面接收端
d.diameterReceive    = 3.0; % dish diameter [m]
d.apertureEfficiency = 0.60;

% Link losses / 链路损耗
d.ampAntennaLoss    = 1.0;  % [dB]
d.beamEdgeLoss      = 2.0;  % [dB]
d.lossFeeder        = 0.5;  % [dB]
d.polarizationAngle = 3.0;  % [deg]
d.attError          = 1.0;  % [deg]

% Receiver temperatures / 接收温度
d.temperatureERX    = 75;   % [K]
d.temperatureFeeder = 290;  % [K]

% Ground station coordinates / 地面站坐标
d.latitude  = latGS;
d.longitude = lonGS;
d.altitude  = altGS_km;

% Minimum elevation cutoff / 最低仰角
d.horizonAngle = 5*pi/180;  % 5 deg

%% ------------------------------------------------------------------------
% 4. Visibility, range, elevation / 可见性、斜距、仰角
% -------------------------------------------------------------------------
visible  = zeros(1,nPts);
range_km = zeros(1,nPts);
elev_deg = zeros(1,nPts);

for k = 1:nPts
    % Convert ground station from EF to ECI at current time
    % 将地面站从EF转到当前时刻ECI
    g       = ECIToEF(JD2T(jD(k)));
    rGS_ECI = g' * rGS_EF;

    % Slant range vector / 斜距向量
    rhoVec = r(:,k) - rGS_ECI;
    range_km(k) = Mag(rhoVec);

    % Local elevation angle / 当地仰角
    uZenith = Unit(rGS_ECI);
    uRho    = Unit(rhoVec);
    zenithAngle = acos(max(-1,min(1,uZenith'*uRho)));
    elev = pi/2 - zenithAngle;
    elev_deg(k) = elev*180/pi;

    % Visibility condition / 可见性条件
    visible(k) = elev > d.horizonAngle;
end

fprintf('Visible samples = %d / %d\n', sum(visible), nPts);
fprintf('Max elevation   = %.2f deg\n', max(elev_deg));
fprintf('Min range       = %.2f km\n', min(range_km));

%% ------------------------------------------------------------------------
% 5. Geometry plots / 几何结果图
% -------------------------------------------------------------------------
figure('Name','Ground Visibility and Geometry','Color','w');

subplot(3,1,1);
plot(t/60, visible, 'LineWidth', 1.5);
xlabel('Time [min]');
ylabel('Visibility');
title('Ground Station Visibility over Multiple Orbits');
ylim([-0.1 1.1]);
grid on;

subplot(3,1,2);
plot(t/60, range_km, 'LineWidth', 1.5);
xlabel('Time [min]');
ylabel('Slant Range [km]');
title('Slant Range between CubeSat and Ground Station');
grid on;

subplot(3,1,3);
plot(t/60, elev_deg, 'LineWidth', 1.5);
xlabel('Time [min]');
ylabel('Elevation [deg]');
title('Ground Station Elevation Angle');
grid on;
yline(d.horizonAngle*180/pi, '--r', 'Min Elevation');

%% ------------------------------------------------------------------------
% 6. Antenna gain calculation / 天线增益计算
% -------------------------------------------------------------------------
% Ground receive gain from aperture formula
% 用口径公式计算地面接收增益

fHz    = d.fGHz*1e9;
lambda = FrequencyToWavelength(fHz);

Gr_lin = d.apertureEfficiency * (pi*d.diameterReceive/lambda)^2;
Gr_dBi = 10*log10(Gr_lin);

fprintf('\n============= Antenna Gains =============\n');
fprintf('Spacecraft TX antenna gain = %.2f dBi\n', d.gainTransmit);
fprintf('Ground RX antenna gain     = %.2f dBi\n', Gr_dBi);
fprintf('=========================================\n');

%% ------------------------------------------------------------------------
% 7. Data rate analysis / 数据率分析
% -------------------------------------------------------------------------
% Use DataRateOrbit provided in the course material
% 使用课件给出的DataRateOrbit函数

% Start from the course default data-rate structure
% 先用课件默认的数据率结构体，避免缺字段
dRate = DataRateGain;

% Overwrite with ARGO mission-specific values
% 再覆盖成ARGO任务参数
dRate.fGHz         = d.fGHz;
dRate.gainTransmit = d.gainTransmit;
dRate.gainReceive  = Gr_dBi;          % dB
dRate.tempS        = d.temperatureERX;
dRate.modulation   = d.modulation;
dRate.sN           = 10;              % first-pass SNR assumption
dRate.lossOther    = 0;               % additional miscellaneous loss [dB], set to zero if neglected

% range is updated internally inside DataRateOrbit
% range会在DataRateOrbit内部自动更新，这里不用手动赋有意义的值
dRate.range        = 1000;

% Compute data rate
% 计算沿轨道数据率
dR = DataRateOrbit(r, rGS_EF, d.powerTransmit, jD, dRate);

figure('Name','Data Rate','Color','w');
plot(t/60, dR/1e6, 'LineWidth', 1.5);
xlabel('Time [min]');
ylabel('Data Rate [Mbps]');
title('Instantaneous Data Rate along the Orbit');
grid on;

%% ------------------------------------------------------------------------
% 8. BEP analysis / 误码率分析
% -------------------------------------------------------------------------
% Use course-provided LinkOrbitAnalysis directly
% 直接调用课件函数LinkOrbitAnalysis

bEP = LinkOrbitAnalysis(r, jD, d);

% Clean BEP plot for report / 报告用BEP干净图
bEP_plot = bEP;
bEP_plot(visible == 0) = NaN;

figure('Name','BEP Clean Plot','Color','w');
semilogy(t/60, bEP_plot, 'LineWidth', 1.5);
xlabel('Time [min]');
ylabel('Bit Error Probability');
title('Bit Error Probability along the Orbit');
grid on;

if any(bEP > 0)
    fprintf('Min nonzero BEP = %.3e\n', min(bEP(bEP>0)));
    fprintf('Max BEP         = %.3e\n', max(bEP));
else
    fprintf('Warning: no nonzero BEP values were found.\n');
end

%% ------------------------------------------------------------------------
% 9. Pass-by-pass summary / 分过站统计
% -------------------------------------------------------------------------
% Identify pass windows and compute downloadable data
% 识别过站窗口并计算可下传数据量

visDiff = diff([0 visible 0]);
passStart = find(visDiff == 1);
passEnd   = find(visDiff == -1) - 1;

nPass = length(passStart);
dt = mean(diff(t));

fprintf('\n================ Pass Summary ================\n');
fprintf('Number of visible passes = %d\n', nPass);

passTable = [];

for p = 1:nPass
    idx = passStart(p):passEnd(p);

    start_min = t(passStart(p))/60;
    end_min   = t(passEnd(p))/60;
    dur_min   = (t(passEnd(p)) - t(passStart(p)))/60;
    min_rng   = min(range_km(idx));
    max_elev  = max(elev_deg(idx));
    mean_rate_Mbps = mean(dR(idx))/1e6;
    data_MB   = sum(dR(idx))*dt/8/1e6;

    passTable = [passTable; p, start_min, end_min, dur_min, min_rng, max_elev, mean_rate_Mbps, data_MB]; %#ok<AGROW>

    fprintf(['Pass %d: start = %.2f min, end = %.2f min, duration = %.2f min, ', ...
             'min range = %.1f km, max elevation = %.1f deg, mean data rate = %.3f Mbps, ', ...
             'downloadable data = %.2f MB\n'], ...
             p, start_min, end_min, dur_min, min_rng, max_elev, mean_rate_Mbps, data_MB);
end
fprintf('==============================================\n');

%% ------------------------------------------------------------------------
% 10. Total downloadable data / 总下传量
% -------------------------------------------------------------------------
data_bits = sum(dR .* visible) * dt;
data_MB   = data_bits / 8 / 1e6;

fprintf('\n========== Total Downloadable Data ==========\n');
fprintf('Total downloadable data over %d orbits = %.2f MB\n', nOrb, data_MB);
fprintf('=============================================\n');

%% ------------------------------------------------------------------------
% 11. Short summary for report / 报告摘要输出
% -------------------------------------------------------------------------
fprintf('\n================ Summary ====================\n');
fprintf('Orbit altitude               = %.1f km\n', alt);
fprintf('Inclination                  = %.1f deg\n', inc*180/pi);
fprintf('Ground station latitude      = %.1f deg\n', latGS_deg);
fprintf('Ground station longitude     = %.1f deg\n', lonGS_deg);
fprintf('Frequency                    = %.2f GHz\n', d.fGHz);
fprintf('RF transmit power            = %.2f W\n', d.powerTransmit);
fprintf('Target bit rate              = %.2f Mbps\n', d.bitRate/1e6);
fprintf('Visible passes               = %d\n', nPass);
fprintf('Total downloadable data      = %.2f MB\n', data_MB);
fprintf('================================================\n');

%% ------------------------------------------------------------------------
% 12. Save results / 保存结果
% -------------------------------------------------------------------------
results = struct;
results.time_s = t;
results.visibility = visible;
results.range_km = range_km;
results.elevation_deg = elev_deg;
results.dataRate_bps = dR;
results.BEP = bEP;
results.passTable = passTable;
results.totalDownloadable_MB = data_MB;
results.groundStation = 'High-latitude station';
results.orbit_altitude_km = alt;
results.orbit_inclination_deg = inc*180/pi;

save('ARGO_CommsCDH_AssignmentFull_Results.mat','results');
fprintf('\nResults saved to ARGO_CommsCDH_AssignmentFull_Results.mat\n');