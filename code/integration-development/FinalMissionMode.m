function mode = MissionMode(t, x, d, sim)
% MISSIONMODE
% Mission operation schedule for the ARGO 6U CubeSat.
%
% ARGO mission logic:
%   1) SUNPOINT  : low-power charging / survival mode
%   2) PAYLOAD   : stereo imaging + onboard VPU processing
%   3) DOWNLINK  : transmit stored mission data to ground
%   4) SAFE      : battery-protection fallback mode
%
% 中文说明：
% 本函数根据当前仿真时刻和电池状态，定义ARGO卫星当前工作模式，
% 并输出该模式下的功耗、通信发射功率和载荷数据生成速率。

%% ------------------------------------------------------------------------
% Repeating mission cycle
%% ------------------------------------------------------------------------
cycle = sim.modeCycleSec;
if isempty(cycle) || cycle <= 0
    cycle = 5400;   % default ~ one LEO orbit scale
end

% Phase within one cycle [0,1)
phi = mod(t, cycle) / cycle;

%% ------------------------------------------------------------------------
% Default operating schedule for ARGO
%
% Suggested cycle:
%   0.00 - 0.35  SUNPOINT
%   0.35 - 0.75  PAYLOAD
%   0.75 - 1.00  DOWNLINK
%
% Reasoning:
% - SUNPOINT gives time to recharge battery and maintain thermal margin
% - PAYLOAD is the main observation / vision-navigation phase
% - DOWNLINK transmits stored data during scheduled contact windows
%% ------------------------------------------------------------------------
if phi < 0.35
    % ------------------------------------------------------------
    % Mode 1: SUNPOINT
    % ------------------------------------------------------------
    mode.id = 1;
    mode.name = 'SUNPOINT';

    % Low-to-moderate bus power:
    % ADCS survival + avionics + EPS housekeeping
    mode.powerConsumptionW = 8.0;

    % No active transmission
    mode.linkPowerW = 0.0;

    % Payload not producing science data
    mode.payloadDataRateBps = 0.0;

elseif phi < 0.75
    % ------------------------------------------------------------
    % Mode 2: PAYLOAD
    % ------------------------------------------------------------
    mode.id = 2;
    mode.name = 'PAYLOAD';

    % Optical payload + VPU + reaction-wheel ADCS + avionics
    % Close to the daylight observation/RPO power budget in your report
    mode.powerConsumptionW = 20.0;

    % No downlink while observing
    mode.linkPowerW = 0.0;

    % Payload data generation rate
    % Set to a meaningful high-data-rate value for vision payload
    % Example first-pass value: 2 Mbps
    mode.payloadDataRateBps = 2.0e6;

else
    % ------------------------------------------------------------
    % Mode 3: DOWNLINK
    % ------------------------------------------------------------
    mode.id = 3;
    mode.name = 'DOWNLINK';

    % Communications on, payload off, ADCS holds communication pointing
    mode.powerConsumptionW = 12.0;

    % RF transmitter power for link model
    % First-pass value for S-band / smallsat downlink simulation
    mode.linkPowerW = 3.0;

    % No new payload generation during downlink
    mode.payloadDataRateBps = 0.0;
end

%% ------------------------------------------------------------------------
% Battery-protection override
%% ------------------------------------------------------------------------
b = x(end);   % battery energy state [J]

if isfield(d, 'power') && isfield(d.power, 'batteryCapacity')
    % If remaining battery < 10% capacity, force safe charging mode
    if b < 0.10 * d.power.batteryCapacity
        mode.id = 4;
        mode.name = 'SAFE';

        % Survival-only load
        mode.powerConsumptionW = 5.0;
        mode.linkPowerW = 0.0;
        mode.payloadDataRateBps = 0.0;
    end
end

end