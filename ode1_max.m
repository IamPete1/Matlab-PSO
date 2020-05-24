% ODE1 eulers method solver
function yout = ode1_max(IW,b,LW,intitial,steps)
                       
%if numel(intitial) ~= 1
%    coder.varsize('Y');
%end
%{
yout = zeros(steps,length(intitial));

yout(1,:) = intitial;
len = length(LW);

% in this case timestep is always 1
delta_t = 1 / 400;
   
%threshold = 10^6;
%angle = zeros(1,2);
%ang_lim = 180;
for n = 1:steps -1

    
    %y_temp = reshape(yout(n,:)',3,[]);
    %y_temp2 = y_temp .* delta_t;
    %y = reshape([y_temp;y_temp2],[],1);    
    %s = F(n,y)';
    %s = ODE_novector(n,y,IW,b,LW,Input_scale,Output_scale,var_num,press)';
    %s = ODE(n,y,IW,b,LW,Input_scale,Output_scale,var_num,press)';
    
    %s = F(time(n),yout(n,:)')';
    
%        y = [yout(n,:)'; yout(n,:)' * delta_t];

    %s = evaluate_net([press(n); yout(n,:)'; yout(n,:)' * delta_t]',IW,b,LW,Input_scale,Output_scale);
    
    
    % Scale input
    %X = (([press(n); yout(n,:)'; yout(n,:)' * delta_t]'./ Input_scale(2,:)) - Input_scale(1,:));
    
    %X = , yout(n,:) * delta_t]';
    
    % Input to hiden layer one
    % multiply input by weights and add biases, then aplly transfer function
    %Y = 2./(1+exp(-2*  (b{1}+IW*X')   ))-1 ;
    
    input = [sind(yout(n,[1,2])),cosd(yout(n,[1,2])),yout(n,[3,4])./1.3548e+03];
    Y = max(0,  (b{1}+IW*input')   );
    
    %Y = max(0,  (b{1}+IW*yout(n,:)')   );
    
    % Hiden layers
    for i = 1:len-1
        %Y = tansig(b{n}+LW{n,n-1}*Y);
        %Y = 2./(1+exp(-2* (b{i+1}+LW{i,i}*Y) ))-1;
        Y = max(0,  (b{i+1}+LW{i,i}*Y) );
    end
    
    % hidden layers to output
    Y = b{len+1}+LW{len,len}*Y;
    
    % output, no bias
    %Y = LW{len,len-1}*Y;
    
    % Scale output
    %s = ((Y' + Output_scale(1,:)) .* Output_scale(2,:));
     
    velo = yout(n,[3,4]) + (delta_t *  Y');% .* 1.3548e+03 ; % abitary scailing
    
    %angle(1) = atan2d(yout(n,1),yout(n,3)) + (yout(n,5) + velo(1)) * 0.5 * delta_t;
    %angle(2) = atan2d(yout(n,2),yout(n,4)) + (yout(n,5) + velo(2)) * 0.5 * delta_t;
    %yout(n+1,:) = [cosd(angle), sind(angle), velo];
    
    
    mean_velo = (yout(n,[3,4]) + velo) * 0.5; 
    % Hard Constrain velocity to +- 20 deg per step
    %max_velo = 10 * delta_t;
    %mean_velo = max([mean_velo; -max_velo,-max_velo]);
    %mean_velo = min([mean_velo; max_velo, max_velo]);
    
    
    yout(n+1,:) = [yout(n,[1,2]) + mean_velo * delta_t, velo];
    
    %yout(n+1,:) = yout(n,:) + Y' * delta_t;
    
%     while yout(n+1,1) > ang_lim
%         yout(n+1,1) = yout(n+1,1) - ang_lim * 2;
%     end
%     while yout(n+1,1) < -ang_lim
%         yout(n+1,1) = yout(n+1,1) + ang_lim * 2;
%     end    
%     while yout(n+1,2) > ang_lim
%         yout(n+1,2) = yout(n+1,2) - ang_lim * 2;
%     end
%     while yout(n+1,2) < -ang_lim
%         yout(n+1,2) = yout(n+1,2) + ang_lim * 2;
%     end        
    
    %if any( abs(yout(n+1,:)) > threshold)
    %    break;
    %end
    
end
%}

inital_size = size(intitial);

yout = zeros(steps,inital_size(2));


yout(1:inital_size(1),:) = intitial;
len = length(LW);

for n = inital_size(1) + 1:steps

  
    input = yout(n-inital_size(1):n-1,:);

    Y = max(0,  (b{1}+IW*input(:))   );
       
    % Hiden layers
    for i = 1:len-1
        %Y = tansig(b{n}+LW{n,n-1}*Y);
        %Y = 2./(1+exp(-2* (b{i+1}+LW{i,i}*Y) ))-1;
        Y = max(0,  (b{i+1}+LW{i,i}*Y) );
    end
    
    % hidden layers to output
    %yout(n,:) = b{len+1}+LW{len,len}*Y;
    
    output = b{len+1}+LW{len,len}*Y;
    
    angles = [atan2(output(3),output(1)) , atan2(output(4),output(2))];
     
    yout(n,:) = [cos(angles), sin(angles)];
end

end

