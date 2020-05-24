clc
clear
close all

% delete any jobs left over from last run
myCluster = parcluster('local');
delete(myCluster.Jobs);

% load in the training data
old_dir = cd('Data/train_and_test_split/dpc_dataset_traintest_4_200_csv/train');

input_file_names = dir('30.csv');

cd(old_dir);

num_train = numel(input_file_names);
fprintf('%i input sims\n',num_train)

train_in = cell(num_train,1);
train_angles = cell(num_train,1);
train_velo = cell(num_train,1);

max_velo = 0;
max_acell = 0;
index = 1;
for i = 1:num_train
    %[train_angles{i},  train_velo{i}] = get_input_from_csv('Data/train_and_test_split/dpc_dataset_traintest_4_200_csv/train', input_file_names(i).name);
    [temp_train_angles,  temp_train_velo] = get_input_from_csv('Data/train_and_test_split/dpc_dataset_traintest_4_200_csv/train', input_file_names(i).name);
    
    % keep track of the max velocity for scailing
    max_velo = max([max(max(abs(temp_train_velo))),max_velo]);
    max_acell = max([      max(max(abs(diff(temp_train_velo))))          ,max_acell]);
    
    % Split into smaller time serise chunks, use aprox 200 steps to match
    % test data
    len = size(temp_train_angles,1);
    %dev = divisors(len);
    %dev = dev(dev>200);
    %dev = dev(1);
    %split = len/dev;
    %fprintf('Spliting into %i of %i\n',split,dev)
    %dev = repmat(dev,split,1);
    
    split = floor(len/200);
    dev = floor(len / split);
    rem = len - dev * split;
    
    fprintf('Spliting into %i of %i and 1 of %i\n',split-1,dev,dev+rem)
    dev = repmat(dev,split,1);
    dev(end) = dev(end) + rem;
    
    if sum(dev) ~= len
        error('did not split correctly')
    end
    
    train_angles(index:index+split-1,:) = mat2cell(temp_train_angles,dev,size(temp_train_angles,2));
    train_velo(index:index+split-1,:) = mat2cell(temp_train_velo,dev,size(temp_train_velo,2));
    
    index = index + split;
    
end
num_train = size(train_angles,1);
fprintf('%i training sims\n\n',num_train)

% normalise inputs, scale to -1 to 1
targets = cell(num_train,1);
inputs_cell = cell(num_train,1);
outputs_cell = cell(num_train,1);
input_frames = 4;
for i = 1:num_train
    targets{i} = train_angles{i};
    %targets{i} = [cosd(train_angles{i}), sind(train_angles{i})];
    %targets{i} = [train_angles{i}, train_velo{i}];
    %targets{i} = [train_angles{i}, train_velo{i} ./ max_velo];
    %targets{i} = [train_angles{i} ./ 180, train_velo{i} ./ max_velo];
    %targets{i} = [train_angles{i} ./ 180, train_velo{i} ./ 180];
    %targets{i} = [cosd(train_angles{i}), sind(train_angles{i}), train_velo{i}./ max_velo];
    
    %inputs_cell{i} = [sind(targets{i}(1:end-1,[1,2])),cosd(targets{i}(1:end-1,[1,2])),targets{i}(1:end-1,[3,4])./1.3548e+03];
    %outputs_cell{i} = diff(train_velo{i}) / (1/400);
    
end
inputs = cell2mat(inputs_cell);
outputs = cell2mat(outputs_cell);

% train on only the angles, discard the velo to speed up passing data
% recorde for the firs time step
%intial = zeros(num_train,4);
intial = cell(num_train,1);
targets_full = targets;
for i = 1:num_train
    %intial(i,:) = targets{i}(1:input_frames,:);
    %intial{i} = targets{i}(1:input_frames,:);
    intial{i} = [cosd(targets{i}(1:input_frames,:)), sind(targets{i}(1:input_frames,:))];
    %targets{i}(1:input_frames,:) = [];
end

% inputs of: link 1 angle, link 2 angle, link 1 velocity, link 2 velocity
nn_Input = 4 * input_frames;
%nn_Input = 6;

% ouputs of: link 1 aceleration, link2 aceleration
%nn_Output = 2;
nn_Output = 4;

Net_Size = (15);
%Net_Size{1} = [25,15];

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
%  Generate MEX files for each simulation
%{
% create a network to test with
net = mat_to_net(net_in,Net_Size,nn_Input,nn_Output);

IW = net.IW;
b = net.b;
LW = net.LW;

sim_initial = intial{1};

steps = size(targets{1},1);

% create a cell of the input types
input_types{1} = coder.typeof(IW);
input_types{2} = coder.typeof(b);
input_types{3} = coder.typeof(LW);
input_types{4} = coder.typeof(sim_initial);
input_types{5} = coder.typeof(steps);

cfg = coder.config('mex');
cfg.IntegrityChecks = false;
cfg.ExtrinsicCalls = false;
cfg.ResponsivenessChecks = false;

codegen("ode1_max","-args",input_types,"-config",cfg);

for i = 1:num_train
    
    sim_initial = intial{i};
    steps = size(targets{i},1);
    
    expected_output = ode1_max(IW,b,LW,sim_initial,steps);
    test_output = ode1_max_mex(IW,b,LW,sim_initial,steps);
    
    if any(any(abs(expected_output - test_output) > 10^-4))
        warning('MEX file did not give expected ouput, max error of %g',max(max(abs(expected_output - test_output))))
    end
    
    test_runs = 1;
    tic
    for o = 1:test_runs
        ode1_max(IW,b,LW,sim_initial,steps);
    end
    test_time = toc;
    
    tic
    for o = 1:test_runs
        ode1_max_mex(IW,b,LW,sim_initial,steps);
    end
    mex_time = toc;
    
    fprintf('train sim %d - Original: %gs MEX: %gs speedup of : %g\n',i,test_time,mex_time,test_time/mex_time)
        
end
fprintf('\n');
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the PSO config

perf_func = @(x)evaluate_pend_fast(x,targets,intial,Net_Size,nn_Input,nn_Output);

% test it!
perf_func(net_in);

% for particle swarm
opts.SwarmSize = 100;
opts.MaxIterations = 5000000000000000; % tend to set this high and use a timeout
opts.inertia = [0.1,0.4,0.6,0.8]; % 0.4 to 0.9, PSO partical propertys, for a single swarm the first value will be used, for parallel swarms the range is used
opts.inertia_damping = 0.99999;
opts.personal_best_velo_coef = 0.7;
opts.global_best_velo_coef = 0.7;
opts.random_regen = 0.1; % percentage of swarm to 'teliported'
opts.max_stall = 1000; % PSO will stop is if it cant improve for this long and hold off steps has passed
opts.min_sigma = 0.00001; % Sigma is a measure of improment, if it is lower than this for the last x steps the PSO will stop
opts.sigma_rolling_average_size = 1000; % rolling average for sigma to stop the PSO
opts.hold_off_steps = 10000; % number of steps to take before re-allowing regenation or global best swap
opts.initial_velo = 10; % standard devation of intial particle velocity
opts.live_Plot = @(best_net)live_plot(best_net,targets_full,intial); % you can use this to plot stuff as you go with a single swarm, also needs to be enabled in the PSO 
opts.parallel = false; % use Parfor in evaluation, might be faster but code needs to be compatable
opts.parallel_cluster = false; % Run parallel swarms, see PSO train fun, note they will keep running even if you ctrl+c, use job moniter

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













