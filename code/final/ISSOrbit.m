function [el, jD0] = ISSOrbit(varargin)
% Local offline replacement for SCT ISSOrbit

rEarth = 6378.137;       % km
h      = 500;            % km
a      = rEarth + h;
e      = 0.001;
inc    = 97.6*pi/180;
raan   = 0;
omega  = 0;
nu     = 0;

el = [a; e; inc; raan; omega; nu];
jD0 = JD2000 + 9500;
end