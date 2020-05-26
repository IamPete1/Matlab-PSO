function [x, fval, state] = PSO(perf_func,n_vars,options,parallel,worker_ID,init_data,start_time)

% reset random number generators, importand for batch parallel
rng('shuffle');

if parallel
    % Pick a inertia to use
    num_inertial = numel(options.inertia);
    if num_inertial ~= 1
        if rem(8,num_inertial) ~= 0
            error('inertia canot be split evenly!')
        end
        index = worker_ID;
        while index > num_inertial
            index = index - num_inertial;
        end
        inertia = options.inertia(index);
    else
        inertia = options.inertia;
    end
else
    inertia = options.inertia(1);
end
inertia_in = inertia;

if strcmp(init_data.start,'starting_point') 
    % Initialize Population Members
    particle.Position = repmat(options.starting_point,options.SwarmSize,1);
    
    % Update the Personal Best
    particle.Best_Cost = inf(options.SwarmSize,1);
    particle.Global_Best_cost = inf;

elseif strcmp(init_data.start,'new')
    % Start a new swarm
    
    % Initialize Population Members
    particle.Position = rand_pop(options.SwarmSize, n_vars);
    
    % Update the Personal Best
    particle.Best_Cost = inf(options.SwarmSize,1);
    particle.Global_Best_cost = inf;
    
elseif strcmp(init_data.start,'continue swap') || strcmp(init_data.start,'continue best')
    % Use a prevous swam
    particle = init_data;
else
    error('unknown start!')
end

inertia_mult = ones(options.SwarmSize,1);
if isfield(options,'spit_inertia')
    inertia_mult(1:round(options.SwarmSize*options.spit_inertia.pct),1) = options.spit_inertia.mult;
end

% Initialize Velocity
particle.Velocity = randn(options.SwarmSize,n_vars) * options.initial_velo;


% Main Loop of PSO
tic;
stall = 0;

rate = ones(1,options.sigma_rolling_average_size) * 100;
particle.worker_ID = worker_ID;

for n = 1:options.MaxIterations
    
    % evaluate the population
    if options.parallel
        pos = particle.Position;
        cost = zeros(options.SwarmSize,1);
        parfor i = 1:options.SwarmSize
            cost(i,1) = perf_func(pos(i,:)); %#ok<PFBNS>
        end
        particle.Cost = cost;
    else
        for i = 1:options.SwarmSize
            particle.Cost(i,1) = perf_func(particle.Position(i,:));
        end
    end
    
    % update particle best
    if n == 1
        index = true(options.SwarmSize,1);
    else
        index = particle.Cost < particle.Best_Cost;
    end
    particle.Best_Cost(index) = particle.Cost(index);
    particle.Best(index,:) = particle.Position(index,:);
    
    % update global best
    [iteration_best, interation_best_index] = min(particle.Cost);
    if (iteration_best < particle.Global_Best_cost)
        particle.Global_Best_cost = particle.Cost(interation_best_index);
        particle.Global_Best = particle.Position(interation_best_index,:);
        
        stall = 0;
    else
        stall = stall + 1;
    end
    
    % rate is sort of the gradient of the of the optimisation, high
    % numbers are better!
    if ~isinf(particle.Global_Best_cost) && ~isnan(particle.Global_Best_cost)
        % shift out rate
        rate(2:end) = rate(1:end-1);
        
        % caculate new rate
        rate(1) = abs(particle.Cost(interation_best_index) - particle.Global_Best_cost) / (stall+1);
    end
    sigma = mean(rate);
    
    particle.status(n) = 0;
    if (stall > options.max_stall || sigma < options.min_sigma*(1/100)*particle.Global_Best_cost) && n > options.hold_off_steps
        break; % Stalled, or low sigma give up
    end
    
    
    % keep a history of progress
    particle.iteration_best(n) = iteration_best;
    
    % if our global best is inf or nan we should regenerate pop and try
    % again, hopefully this never happens, but for some probvlems it might
    % at the start
    if isnan(particle.Global_Best_cost) || isinf(particle.Global_Best_cost)
        particle.Position = rand_pop(options.SwarmSize, n_vars);
        particle.Best_Cost = inf(options.SwarmSize,1);
        particle.Global_Best_cost = inf;
        fprintf('%i: swarm regenerated due to nan/inf global best\n',worker_ID)
        continue % advance to go, do not collect £200
    end
    
    % if any members of the swam are bad then respwan
    msg = '';
    %{
    bad_swarm = isnan(particle.Cost) | isinf(particle.Cost);
    if any(bad_swarm)
        %particle.Position(bad_swarm,:) = rand_pop(sum(bad_swarm), n_vars);
        %particle.Velocity(bad_swarm,:) = randn(sum(bad_swarm),n_vars);
        %msg = sprintf(' regenerated %.0f%% of swarm',(sum(bad_swarm)/options.SwarmSize)*100);
        msg = sprintf(' %.0f%% of swarm inf or nan',(sum(bad_swarm)/options.SwarmSize)*100);
    end
    %}
    
    
    
    % randomly teliport some of the swam
    rand_regen_no = round(options.SwarmSize*options.random_regen);
    if rand_regen_no > 0
        index = randi(options.SwarmSize,rand_regen_no,1);
        particle.Position(index,:) = particle.Position(index,:) + rand_pop(rand_regen_no,n_vars);
    end
    
    % update each partical position
    
    % Update Velocity
    temp_global_best_mat = zeros(options.SwarmSize,n_vars);
    for i = 1:n_vars
        temp_global_best_mat(:,i) = particle.Global_Best(1,i);
    end
    
    % index all true = standard PSO
    %index = rand(options.SwarmSize,1) > 0.95;
    index = true(options.SwarmSize,1);
    index_size = sum(index);
    if index_size ~= 0
        % Random scailing for personal best and global best for each
        % partical
        particle.Velocity(index,:) = inertia_mult(index,:) * inertia .* particle.Velocity(index,:) ...
            + options.personal_best_velo_coef .* rand(index_size,n_vars) .* (particle.Best(index,:) - particle.Position(index,:)) ...
            + options.global_best_velo_coef   .* rand(index_size,n_vars) .* (temp_global_best_mat(index,:) - particle.Position(index,:));
    end
    if index_size ~= options.SwarmSize
        % Random scailing for personal best and global best for all particales
        particle.Velocity(~index,:) = inertia_mult(~index,:) * inertia .* particle.Velocity(~index,:) ...
            + options.personal_best_velo_coef .* rand .* (particle.Best(~index,:) - particle.Position(~index,:)) ...
            + options.global_best_velo_coef   .* rand .* (temp_global_best_mat(~index,:) - particle.Position(~index,:));
    end
   
    % Update Position
    particle.Position = particle.Position + particle.Velocity;
    
    
    % Display Iteration Information
    if ~parallel
        if rem(n,1) == 0
            fprintf('Generation %d - %.5fs - %g%s\n',n,toc,particle.Global_Best_cost,msg)
            tic
        end
        %if rem(n,5000) == 0
        %   options.live_Plot(net)
        %end
    else
        % only ouput every 250 generations, or if somthing has happend
        if rem(n,250) == 0
            fprintf('%i - Generation %d - %.5fs - %g%s\n',worker_ID,n,toc,particle.Global_Best_cost,msg)
            tic;
        elseif ~isempty(msg)
            fprintf('%i -Generation %d - %g%s\n',worker_ID,n,particle.Global_Best_cost,msg)
        end
    end
    
    
    % Damping Inertia Coefficient
    inertia = inertia * options.inertia_damping;
    
    if toc(start_time) > options.timeout
        fprintf('Timed out after %g seconds\n',options.timeout)
        break;
    end
    
end

if isfield(particle,'Best_group')
    particle.Best_group(end+1,:) = particle.Global_Best;
    particle.Best_group_cost(end+1,1) = particle.Global_Best_cost;
else
    particle.Best_group = particle.Global_Best;
    particle.Best_group_cost = particle.Global_Best_cost;
end

[fval, index] = min(particle.Best_group_cost);

x = particle.Best_group(index,:);
state = particle;

state.inertia = inertia;
state.start_inertia = inertia_in;
state.start = init_data.start;

end
