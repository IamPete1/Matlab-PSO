
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evaluate network perfomance, using ODE
function perf = evaluate_pend_fast(x,targets,initial,Net_Size,nn_Input,nn_Output)


net = mat_to_net(x,Net_Size,nn_Input,nn_Output);

num_sims = numel(targets);
error_val = zeros(num_sims,1);

IW = net.IW;
b = net.b;
LW = net.LW;

for m = 1:num_sims
    
    steps = size(targets{m},1);
        
    output = ode1_max(IW,b,LW,initial{m},steps);

    % this is the mex file we generated in setup
    %output = ode1_max_mex(IW,b,LW,initial{m},steps);
    
    sim_angles = unwrap([atan2d(output(1:steps,3),output(1:steps,1)) , atan2d(output(1:steps,4),output(1:steps,2))],180);    
    
    error_val(m) = sum(sum( (targets{m} - sim_angles).^2) );

end


% Sum the error for all of the test sims
perf = sum(error_val);
%perf = mean(error_val);

end
