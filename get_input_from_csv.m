function [train_angles, train_velo, train_acel] = get_input_from_csv(dir, file_name, varargin)

calc_velo = false;
calc_acel = false;
if nargout >= 2
    calc_velo = true;
end
if nargout == 3
    calc_acel = true;
end

delta_t = 1 / 400;

old_dir = cd(dir);
if isempty(varargin)
    train_in = dlmread(file_name,' ');
else
    temp = dlmread(file_name,' ');
    cd(old_dir);
    cd(varargin{1});
    train_in = [temp; dlmread(file_name,' ')];
end
cd(old_dir);
    
red = train_in(:,[2,1])*0.2;
green = train_in(:,[4,3])*0.2;
blue = train_in(:,[6,5])*0.2;

% caculate the link angles
train_angles(:,1) = atan2d(red(:,2) - green(:,2), red(:,1) - green(:,1));
train_angles(:,2) = atan2d(green(:,2) - blue(:,2), green(:,1) - blue(:,1));

%     figure
%     subplot(3,1,1)
%     hold all
%     plot( train_angles{i}(:,1),'b')
%     plot( train_angles{i}(:,2),'r')


%     subplot(3,1,2)
%     hold all
%     plot( change_angle1,'b')
%     plot( change_angle2,'r')
%
%     subplot(3,1,3)
%     hold all
%     plot( sind(train_angles{i}(:,1)),'b')
%     plot( cosd(train_angles{i}(:,1)),'r')

train_angles = unwrap(train_angles,180);

if ~calc_velo
    return
end

%     figure
%     subplot(3,1,1)
%     hold all
%     plot( train_angles{i}(:,1),'b')
%     plot( train_angles{i}(:,2),'r')
%     subplot(3,1,2)
%     hold all

change_angle1 = diff(train_angles(:,1));
change_angle2 = diff(train_angles(:,2));

% X_val = (1:4) * delta_t;
% x_point = 2 * delta_t;
% %X1 = 1:0.01:4;
% for jj = 1:size(train_angles,1) - 4
%     Y_val = train_angles(jj:jj+3,1);
%     p = polyfit(X_val',Y_val,3);
%     %y1 = polyval(p,X1);
%     %y2 = p(1)*X1.^3 + p(2)*X1.^2 + p(3)*X1 + p(4);
%     %figure
%     %plot(X_val,Y_val,'o')
%     %hold all
%     %plot(X1,y1)
%     %plot(X1,y2,'--')
%     
%     train_velo(jj,1) = 3*p(1)*x_point^2 + 2*p(2)*x_point + p(3);
%     
%     Y_val = train_angles(jj:jj+3,2);
%     p = polyfit(X_val',Y_val,3);
%     
%     train_velo(jj,2) = 3*p(1)*x_point^2 + 2*p(2)*x_point + p(3);
%     
% end

%     plot( change_angle1,'b')
%     plot( change_angle2,'r')
%
%     subplot(3,1,3)
%     hold all
%     plot( sind(train_angles{i}(:,1)),'b')
%     plot( cosd(train_angles{i}(:,1)),'r')


% insure between +- 180
%     index = change_angle1 > 180;
%     change_angle1(index) = change_angle1(index) - 360;
%     index = change_angle1 < -180;
%     change_angle1(index) = change_angle1(index) + 360;
%
%     index = change_angle2 > 180;
%     change_angle2(index) = change_angle2(index) - 360;
%     index = change_angle2 < -180;
%     change_angle2(index) = change_angle2(index) + 360;

% link velocitys
train_velo(:,1) = change_angle1 ./ delta_t;
train_velo(:,2) = change_angle2 ./ delta_t;


% discard first angle as it has no acosiated velocity
train_angles(1,:) = [];

%train_angles(end-2:end,:) = [];

if calc_acel
    train_acel(:,1) = diff(train_velo(:,1)) ./ delta_t;
    train_acel(:,2) = diff(train_velo(:,2)) ./ delta_t;
    
    train_angles(1,:) = [];
    train_velo(1,:) = [];
end

end











