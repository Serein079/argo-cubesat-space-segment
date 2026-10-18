

deg = pi/180;

Re  = 6378.137;         
mu  = 398600.4418;       

altitude = 500;          
a        = Re + altitude;
inc      = 97.4*deg;     
nOrbit = sqrt(mu/a^3);  
Torb   = 2*pi/nOrbit;   

sim.nOrbits = 2;                        
sim.dT      = 1;                         
t           = 0:sim.dT:sim.nOrbits*Torb;
tMin        = t/60;
N           = length(t);


I = diag([0.105 0.083 0.047]);   
Ivec = diag(I);


rw.nWheels   = 4;
rw.axes = (1/sqrt(3))*[ ...
     1   1  -1  -1; ...
     1  -1   1  -1; ...
     1  -1  -1   1 ];

rw.maxTorque   = 2.0e-3;      
rw.maxMomentum = 0.020;       


zeta = 1.0;                         
wn   = [0.020; 0.020; 0.022];      

Kp = diag(Ivec .* wn.^2);                   
Kd = diag(2*zeta .* Ivec .* wn);             
Ki = diag(0.08 .* Ivec .* wn.^3);           


eIntMax = [1.0; 1.0; 1.0];         


q = quatFromEuler321([6; -4; 3]*deg);    
w = [0.20; -0.15; 0.10]*deg;              % Initial body rate 
eInt = zeros(3,1);                         

hWheel = zeros(rw.nWheels,1);


for k = 1:N

    q = q / norm(q);

    e = quatErrorVector(q);

    tauCmd = -(Kp*e + Kd*w + Ki*eInt);

    wheelTorqueCmd = -pinv(rw.axes)*tauCmd;

    wheelTorque = clamp(wheelTorqueCmd, -rw.maxTorque, rw.maxTorque);

    tauCtrl = -rw.axes*wheelTorque;

    tauDist = disturbanceTorque(t(k), nOrbit, q, I);

    wDot = I \ (tauCtrl + tauDist - cross(w, I*w));

    qDot = 0.5*omegaMatrix(w)*q;

    errHistDeg(k) = 2*acos(min(1,abs(q(1))))/deg;

    if k < N
        w = w + sim.dT*wDot;
        q = q + sim.dT*qDot;
        q = q / norm(q);

        eInt = eInt + e*sim.dT;
        eInt = min(max(eInt, -eIntMax), eIntMax);

        hWheel = hWheel + wheelTorque*sim.dT;
        hWheel = clamp(hWheel, -rw.maxMomentum, rw.maxMomentum);
    end
end




figure('Name','ARGO PID Attitude Pointing Error');
plot(tMin, errHistDeg, 'LineWidth', 1.5); hold on;
yline(1.0, '--', '1 deg requirement');
grid on;
xlabel('Time [min]');
ylabel('Pointing Error [deg]');
title('ARGO PID Attitude Pointing Error');

% Local functions

function q = quatFromEuler321(eul)
% eul = [roll; pitch; yaw], rad
    phi   = eul(1);
    theta = eul(2);
    psi   = eul(3);

    cr = cos(phi/2);   sr = sin(phi/2);
    cp = cos(theta/2); sp = sin(theta/2);
    cy = cos(psi/2);   sy = sin(psi/2);

    q = [ cr*cp*cy + sr*sp*sy;
          sr*cp*cy - cr*sp*sy;
          cr*sp*cy + sr*cp*sy;
          cr*cp*sy - sr*sp*cy ];
    q = q / norm(q);
end

function e = quatErrorVector(q)
    if q(1) < 0
        q = -q;
    end
    e = 2*q(2:4);
end

function Om = omegaMatrix(w)
    wx = w(1); wy = w(2); wz = w(3);

    Om = [ 0   -wx  -wy  -wz;
           wx   0    wz  -wy;
           wy  -wz   0    wx;
           wz   wy  -wx   0 ];
end

function C = quatToDCM(q)
    q = q / norm(q);
    q0 = q(1); q1 = q(2); q2 = q(3); q3 = q(4);

    C = [1-2*(q2^2+q3^2), 2*(q1*q2+q0*q3), 2*(q1*q3-q0*q2);
         2*(q1*q2-q0*q3), 1-2*(q1^2+q3^2), 2*(q2*q3+q0*q1);
         2*(q1*q3+q0*q2), 2*(q2*q3-q0*q1), 1-2*(q1^2+q2^2)];
end

function tauDist = disturbanceTorque(t, nOrbit, q, I)

    C_B_L = quatToDCM(q);

    rHatLVLH = [0; 0; 1];
    rHatBody = C_B_L*rHatLVLH;

 
    tauGG = 3*nOrbit^2 * cross(rHatBody, I*rHatBody);


    tauAero = [ 3.0e-7*sin(nOrbit*t + 0.3);
               -2.0e-7*cos(nOrbit*t);
                1.5e-7*sin(2*nOrbit*t) ];

  
    tauSRP = [ 4.0e-8*cos(nOrbit*t);
               3.0e-8*sin(nOrbit*t);
              -2.0e-8*cos(2*nOrbit*t) ];

    tauDist = tauGG + tauAero + tauSRP;
end

function y = clamp(x, lower, upper)
    y = min(max(x, lower), upper);
end