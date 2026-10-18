

% Load mission data
[d, x0, ctrl, sim, comm] = ARGO_BuildMissionData();

% Time definition
tEnd = sim.days * 24 * 3600;   % [s] total simulation time
t    = 0:sim.dT:tEnd;          % [s] time vector 
tMin = t/60;                   % [min] time in minutes 

% Figure 1: Orbit profile

% Initial position and velocity from mission data
r0 = x0(1:3);
v0 = x0(4:6);

% Convert Cartesian state to orbital elements
el0 = RV2El(r0, v0);

% Extract classical orbital elements

a     = el0(1);   
e     = el0(2);   
inc   = el0(3);   
raan  = el0(4);   
omega = el0(5);   
nu0   = el0(6);  
mu = 398600.4418;      %  Earth gravitational parameter 
n  = sqrt(mu/a^3);     %  mean motion

% Preallocate orbit history
rHist = zeros(3, numel(t));

% Propagate orbit by advancing true anomaly
for k = 1:numel(t)
    nu = nu0 + n*t(k);            % propagated anomaly 
    el = [a; e; inc; raan; omega; nu];
    [r, ~] = El2RV(el);           % convert back to position 
    rHist(:,k) = r;
end

% Plot orbit
figure('Name','Figure 1 - Orbit','Color','w');
hold on; grid on; axis equal;

% Draw Earth as a sphere
Re = 6378.137;                    % [km] Earth radius 
[Xe, Ye, Ze] = sphere(80);
surf(Re*Xe, Re*Ye, Re*Ze, 'FaceAlpha',0.35, 'EdgeColor','none');

% Draw equatorial reference line
th = linspace(0,2*pi,500);
plot3(Re*cos(th), Re*sin(th), zeros(size(th)), 'k--', 'LineWidth', 1.2);

% Draw spacecraft orbit trajectory
plot3(rHist(1,:), rHist(2,:), rHist(3,:), 'r-', 'LineWidth', 2);

xlabel('X (km)');
ylabel('Y (km)');
zlabel('Z (km)');
title('ARGO Pathfinder - 500 km Sun-Synchronous Orbit');
legend('Earth Reference','Equator','ARGO 500 km Orbit Trajectory','Location','best');
view(35,25);

% Figure 2: Pointing Error Convergence
theta0 = 90;      % [deg] initial pointing error
tau1   = 25;      % [min] time constant 
thetaErrDeg = theta0 * exp(-tMin/tau1);

figure('Name','Figure 2 - Pointing Error','Color','w');
plot(tMin, thetaErrDeg, 'b-', 'LineWidth', 2); hold on; grid on;

% Plot 1-degree pointing requirement
yline(1, 'r--', '1^{\circ} Pointing', 'LineWidth', 1.5);

xlabel('Time (min)');
ylabel('Pointing Error (deg)');
title('Pointing Error Convergence');
xlim([0 max(tMin)]);


% Figure 3: Angular Velocity

% Convert initial angular velocity from rad/s to deg/s
w0 = x0(11:13) * 180/pi;

% Simplified exponential decay model for angular velocity
tau2 = 18;                 % [min] decay time constant
omegaX = w0(1) * exp(-tMin/tau2);
omegaY = w0(2) * exp(-tMin/tau2);
omegaZ = w0(3) * exp(-tMin/tau2);

figure('Name','Figure 3 - Angular Velocity','Color','w');
plot(tMin, omegaX, 'LineWidth', 2); hold on; grid on;
plot(tMin, omegaY, 'LineWidth', 2);
plot(tMin, omegaZ, 'LineWidth', 2);

xlabel('Time (min)');
ylabel('Angular Velocity (deg/s)');
title('Spacecraft Angular Velocity');
legend('\omega_x','\omega_y','\omega_z','Location','best');
xlim([0 max(tMin)]);

