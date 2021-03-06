%--------------------------------------------------------------------------
%
% READ ME
% 
% 1. Pick three points on screen, the first one being the origin
% 2. Pick any number of points in, e.g., diagram
% 3. Press enter when ready
%--------------------------------------------------------------------------
clc
clear all
%--------------------------------------------------------------------------
% read image
%--------------------------------------------------------------------------
[X,map]=imread('kalidindi1992.png','png');
%--------------------------------------------------------------------------
figure(1)
clf
image(X)
%--------------------------------------------------------------------------
% reaf image data
%--------------------------------------------------------------------------
[x_1,x_2] = ginput
a(:,1) = x_1;
a(:,2) = x_2;
a(:,1) = a(:,1)-a(1,1);
a(:,2) = a(:,2)-a(1,2);
%--------------------------------------------------------------------------
% scale data points w.r.t. image axes
%--------------------------------------------------------------------------
picked_x_1 = input('Enter picked x_1 axis value: ');
picked_x_2 = input('Enter picked y_2 axis value: ');
scale_x_1 = a(2,1)/picked_x_1;
scale_x_2 = a(3,2)/picked_x_2;
a(:,1) = a(:,1)/scale_x_1;
a(:,2) = a(:,2)/scale_x_2;
%--------------------------------------------------------------------------
% plot result
%--------------------------------------------------------------------------
xx = a(4:end,1);
yy = a(4:end,2);
% pp = interp1(a(4:end,1),a(4:end,2),'cubic','pp');
% yy = ppval(pp,xx);
plot(a(4:end,1),a(4:end,2),'o',xx,yy);
