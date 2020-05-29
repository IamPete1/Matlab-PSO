clc
clear
close all

% delete any jobs left over from last run
myCluster = parcluster('local');
delete(myCluster.Jobs);

% load in the training data
data = dlmread('data.pso',',');
inputs = data(:,[1,2]);
output = data(:,3);

nn_Input = 2;
nn_Output = 1;

Net_Size = (15);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Caculate the number of varables required for network size
n_bias = sum(Net_Size) + nn_Output;

% input to layer one and last layer to output
n_weights = nn_Input * Net_Size(1) + nn_Output * Net_Size(end);
% for hidden layers
for i = 1:length(Net_Size) - 1
    n_weights = n_weights + Net_Size(i) * Net_Size(i + 1);
end

% train on varables such that first are bias's and remaing are
% weights starting at hidden layer one to last
n_vars = n_bias + n_weights;

% create a network to test with
net_in = randn(1,n_vars);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Backprop training
%{
net = feedforwardnet(Net_Size);
%net.layers{1}.transferFcn = 'softmax';

net.divideFcn = 'dividetrain';

% Remove normalization
net.input.processFcns = {};
net.output.processFcns = {}; 
net.trainParam.time = 60 * 60 * 0.5;

net.trainParam.epochs = 1000000000;
net.trainParam.min_grad = 0;
net.trainParam.max_fail = 1000000000;

%[net, back_prop_perf] = train(net,backprop_inputs',backprop_outputs');
%[net, back_prop_perf] = train(net,inputs',output','useParallel','yes');
%[net, back_prop_perf] = train(net,inputs',output');
[net, back_prop_perf] = train(net,inputs',output','useGPU','yes');

test_outputs = net(inputs');

figure
hold all
scatter3(inputs(:,1),inputs(:,2),output)
scatter3(inputs(:,1),inputs(:,2),test_outputs)
view(3)
drawnow

return

%delete(gcp('nocreate'))

%save(sprintf('Backprop training test %s', datestr(now,'mm-dd-yy HH-MM-SS')),'-v7.3')

backprop = net_to_mat(net);
net_save2 =  mat_to_net(backprop,Net_Size,nn_Input,nn_Output);

net_temp.IW = net.IW{1};
net_temp.b = net.b;
net_temp.LW = net.LW(2:end,1);

identical = true;
for i = 1:numel(net_temp.b)
    identical = identical & all(net_temp.b{i} == net_save2.b{i});
end
identical = identical & all(net_temp.IW(:) == net_save2.IW(:));
for i = 1:numel(net_temp.LW)
    identical = identical & all(net_temp.LW{i}(:) == net_save2.LW{i}(:));
end
if ~identical
   errror('Net error') 
end
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the PSO config

perf_func = @(x)evaluate_example(x,inputs,output,Net_Size,nn_Input,nn_Output);

% test it!
perf_func(net_in);

% for particle swarm
opts.SwarmSize = 100;
opts.MaxIterations = 5000000000000000; % tend to set this high and use a timeout
opts.inertia = 0.6;%[0.1,0.4,0.6,0.8]; % 0.4 to 0.9, PSO partical propertys, for a single swarm the first value will be used, for parallel swarms the range is used
opts.inertia_damping = 0.99999;
opts.personal_best_velo_coef = 0.7;
opts.global_best_velo_coef = 0.7;
opts.random_regen = 0.1; % percentage of swarm to 'teliported'
opts.max_stall = 1000; % PSO will stop is if it cant improve for this long and hold off steps has passed
opts.min_sigma = 0.00001; % Sigma is a measure of improment, if it is lower than this for the last x steps the PSO will stop
opts.sigma_rolling_average_size = 1000; % rolling average for sigma to stop the PSO
opts.hold_off_steps = 10000; % number of steps to take before re-allowing regenation or global best swap
opts.initial_velo = 10; % standard devation of intial particle velocity
opts.live_Plot = @(best_net)live_plot_example(best_net,inputs,output,Net_Size,nn_Input,nn_Output); % you can use this to plot stuff as you go with a single swarm 
opts.parallel = false; % use Parfor in evaluation, might be faster but code needs to be compatable
opts.parallel_cluster = false; % Run parallel swarms, see PSO train fun, note they will keep running even if you ctrl+c, use job moniter
opts.spit_inertia.mult = 0.2; % multiply the main inertia by this value for some percentage of the swarm
opts.spit_inertia.pct = 0.2; % this percentage of the swarm will use the inerta * spit_inertia.mult
opts.QDPSO.enable = false;
opts.QDPSO.g = 2000;
opts.num_workers = 0;

opts.timeout = 10; % time out in hours

% Run!
start_time = tic;
[out, perf, state] = PSO_train_fun(perf_func,n_vars,opts);
toc(start_time)

% turn back into a network and save
net_save = mat_to_net(out,Net_Size,nn_Input,nn_Output);

delete(gcp('nocreate'))

% save comand window and workspace for headless operation
% add date and time so we can run without over writing previous
save(sprintf('Workspace log %s', datestr(now,'mm-dd-yy HH-MM-SS')),'-v7.3')













