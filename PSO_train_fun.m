function [x, perf, state_out] = PSO_train_fun(perf_func,n_vars,opts)

if ~isfield(opts,'timeout')
    opts.timeout = inf;
else
    % convert to seconds
    opts.timeout = opts.timeout * 60 * 60;
end

start_time = tic;
if ~isfield(opts,'starting_point')
    init_data.start = 'new';
else
    init_data.start = 'starting_point';
end

% single swarm
if ~opts.parallel_cluster
    [x, perf, state_out] = PSO(perf_func,n_vars,opts,opts,false,1,init_data,start_time);
    return
end

% Parallel swarm
c = parcluster;
if ~opts.parallel
    num_PSO = c.NumWorkers;
    pool_size = 0;
    fprintf('Running %i parallel swarms\n',num_PSO)
else
    % Parallel swarms each with a number of workers
    num_PSO = 4;
    pool_size = (c.NumWorkers / num_PSO) - 1;
    if rem(pool_size,1) ~= 0
        error('Pool size per worker incorect')
    end
    fprintf('Running %i parallel swarms each with %i workers\n',num_PSO,pool_size+1)
end

done = ones(num_PSO,1);
text_index = ones(num_PSO,1);
job = cell(num_PSO,1);
num_runs = 1;


warning('off','all');
for j = 1:num_PSO
    job{j} = batch(c,'PSO',3,{perf_func,n_vars,opts,opts,true,j,init_data,start_time},'Pool',pool_size);
end

while true
    for j = 1:num_PSO
        if done(j) ~= 2
            done(j) = strcmp(job{j}.State,'finished');
        end
        
        try
            out_text = job{j}.Tasks(1).Diary;
            if ~isempty(out_text)
                fprintf('%s',out_text(text_index(j):end))
                text_index(j) = numel(out_text)+1;
            end
        catch
        end
        
        if done(j) == 1
            text_index(j) = 1;
            output = fetchOutputs(job{j});
            
            x_par = output{1};
            fval_par = output{2};
            state_par = output{3};
            init_data = state_par;
            
            % add to the global best pool
            if num_runs == 1
                global_best_pool = x_par;
                global_score_pool = fval_par;
            else
                global_best_pool = [global_best_pool; x_par;]; %#ok<AGROW>
                global_score_pool = [global_score_pool; fval_par;]; %#ok<AGROW>
            end
            
            state{num_runs} = state_par; %#ok<AGROW>
            num_runs = num_runs + 1;
            
            % if we are the best in the global pool we should keep trying so
            % dont regen
            if min(global_score_pool) ~= fval_par && numel(global_score_pool) > 1
                
                % pick a global best that is better than current
                %index = find(particle.Best_group_cost < particle.Global_Best_cost);
                
                % pick the best global best
                index = find(global_score_pool == min(global_score_pool));
                
                %                             if ~isempty(index) && ~all(index == regen_index_old)
                %                                 % pick a new global best difrent to the one we used before
                %                                 regen_index = randi(numel(index));
                %                                 while regen_index == regen_index_old
                %                                     regen_index = randi(numel(index));
                %                                 end
                %                             else
                %                                 regen_index = 0;
                %                             end
                
                %inertia = inertia_in;
                
                
                if rand > 0.25 && 0
                    % randomly select a prevoise best as new global best
                    state_par.Global_Best = global_best_pool(index,:); %#ok<FNDSB>
                    
                    fprintf('%i- swaped global best\n',j)
                    
                    init_data.start = 'continue swap';
                else
                    fprintf('%i- restarting\n',j)
                    init_data.start = 'new';
                    
                    
                end
            else
                fprintf('%i- global best, continuing\n',j)
                init_data.start = 'continue best';
            end
            if toc(start_time) < opts.timeout
                delete(job{j})
                job{j} = batch(c,'PSO',3,{perf_func,n_vars,opts,opts,true,j,init_data,start_time},'Pool',pool_size);
            else
                done(j) = 2;
            end
        end
    end
    if all(done)
        break
    end
end

fprintf('\n%i runs\n',num_runs-1)

% find the best, but keep all states
[perf, index] = min(global_score_pool);
x = global_best_pool(index,:);

state_out = state;

fprintf('performance of %6.8f in %g seconds\n',perf,toc(start_time))

end

