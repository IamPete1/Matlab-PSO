clc
clear
%close all

% load in a trianing file
file_name = 'Re-worked PSO';
file_name = 'QDPSO';

%old_dir = cd('..');
load(file_name)
%cd(old_dir);

colour = ['b','r','m','g','k','c'];
colour = repmat(colour,1,50);

if  numel(state) == 1
    figure
    hold all
    
    best = state{1}.iteration_best;
    
    % blue
    c = zeros(numel(best),3);
    %c(:,3) = 0;
    %c(:,3) = 0;
    c(:,3) = 1;
    
    % find stall generations
    index = false(numel(best),1);
    for i = 2:numel(index)
        if best(i-1) < best(i)
            best(i) = best(i-1);
            index(i) = true;
        end
    end
    
    % cyan
    %c(index,1) = 0;
    c(index,2) = 1;
    %c(index,3) = 1;
    
    % swarm regenerated
    index = state{1}.status == 1;
    c(index',1) = 1;
    c(index',2) = 0;
    c(index',3) = 0;
    
    % new global best
    index = state{1}.status == 2;
    c(index',1) = 1;
    c(index',2) = 1;
    c(index',3) = 0;
    
    scatter(1:numel(best),state{1}.iteration_best)
    scatter(1:numel(best),best,[],c,'filled')
    
    
    
elseif numel(state) < 10
    
    % parallel swarms!
    input_states = state{1};
    
    max_iter = 0;
    figure
    hold all
    legend_val = cell(numel(input_states),1);
    for n = 1:numel(input_states)
        
        plot(input_states{n}.iteration_best,colour(n))
        
        
        iterations = size(input_states{n}.iteration_best,2);
        max_iter = max(max_iter,iterations);
        %fprintf('Worker %i: %d iterations, %g best\n',n,iterations,input_states{n}.Global_Best_cost)
        
        legend_val{n} = sprintf('Worker %i',n);
        
        % compare to see if the global best was correctly shared
        %{
        if n == 1
            global_best_temp = input_states{n}.Best_group;
        else
            if  ~(sum(all(global_best_temp == input_states{n}.Best_group,2)) >= size(input_states{n}.Best_group,1) - 1)
                % all but the last should match, last is added as the
                % current best when the PSO exits, thus is not shared
                warning('Global bests not shared correctly!!')
            end
        end
        %}
    end
    xlim([1,max_iter])
    %ylim([perf{1}-0.1,15])
    %ylim([0,50])
    legend(legend_val,'location','eastoutside')
    fprintf('\n')
    
    
    % seperate plots
    num_plots = numel(input_states);
    
    plot_size = divisors(num_plots);
    if rem(numel(plot_size),2) == 0
        % is even
        plot_size = plot_size(numel(plot_size)*0.5 + [0,1]);
    else
        % is odd
        plot_size = plot_size(ceil(numel(plot_size)*0.5) + [0,0]);
    end
    
    figure
    for n = 1:numel(input_states)
        subplot(plot_size(1),plot_size(2),n)
        hold all
        title(sprintf('Worker %i',n))
        plot(input_states{n}.iteration_best,colour(n))
        
        % swarm regenerated
        index = find(input_states{n}.status == 1);
        if ~isempty(index)
            scatter(index,input_states{n}.iteration_best(index),'filled','*r')
        end
        
        % new global best
        index = find(input_states{n}.status == 2);
        if ~isempty(index)
            scatter(index,input_states{n}.iteration_best(index),'filled','dk')
        end
        
        
        xlim([1,max_iter])
        %ylim([perf{1}-0.1,15])
        %ylim([0,50])
    end
    
else
    % batch PSO
    
    % cant be more than 50 cores
    iter = zeros(50,1);
    best = inf(50,1);
    
    for n = 1:numel(state)
        worker_num = state{n}.worker_ID;
        
        worker_iter = numel(state{n}.iteration_best);
        iter(worker_num) = iter(worker_num) + worker_iter;
        
        
        best(worker_num) = min( best(worker_num),state{n}.Global_Best_cost);
    end
    
    index = iter == 0;
    iter(index) = [];
    best(index) = [];
    
    for n = 1:numel(iter)
        %fprintf('Worker %i: %d iterations, %g best\n',n,iter(n),best(n))
    end
    %fprintf('Total iterations %g\n',sum(iter))
    %fprintf('Total evaluations %g\n',sum(iter) * opts.SwarmSize)
    
    
    iter_best_all = cell(numel(state),1);
    final_best = zeros(numel(state),1);
    for n = 1:numel(state)
        iter_best_all{n} = state{n}.iteration_best;
        final_best(n) = min(state{n}.iteration_best);
    end
    
    % concatinate the continued runs
    scatter_point = cell(numel(state),1);
    for n = numel(iter_best_all):-1:1
        if strcmp(state{n}.start,'new')
            continue
        end
        
        % concatinate onto the previouse run of the same worker
        for i = n-1:-1:1
            if  state{n}.worker_ID == state{i}.worker_ID
                % add to scatter points for swaps of global best
                if strcmp(state{n}.start,'continue swap')
                    if isempty(scatter_point{n})
                        scatter_point{i} = [numel(iter_best_all{i}),min(iter_best_all{i})];
                    else
                        scatter_add = zeros(size(scatter_point{n}));
                        scatter_add(:,1) = numel(iter_best_all{i});
                        scatter_point{i} = [scatter_point{n} + scatter_add;[numel(iter_best_all{i}),min(iter_best_all{i})]];
                    end
                elseif ~strcmp(state{n}.start,'continue best') && ~strcmp(state{n}.start,'continue') % legacy 'continue'
                    warning('unknown start')
                end
                iter_best_all{i} = [iter_best_all{i}, iter_best_all{n}];
                iter_best_all(n) = [];
                scatter_point(n) = [];
                break;
            end
        end
    end
    
    % take min of each step so can never increse (tidys plot)
    max_iter = 0;
    for n = 1:numel(iter_best_all)
        iter = numel(iter_best_all{n});
        max_iter = max(max_iter, iter);
        for i = 2:iter
            iter_best_all{n}(i) = min(iter_best_all{n}(i),iter_best_all{n}(i-1));
        end
    end    
    
    figure
    hold all
    %ylim([0,100])
    xlim([0,max_iter])
    set(gca,'Xscale','log')
    
    for n = 1:numel(iter_best_all)
        plot(1:numel(iter_best_all{n}),iter_best_all{n})
    end
    scatter_point = cell2mat(scatter_point);
    if ~isempty(scatter_point)
        scatter(scatter_point(:,1),scatter_point(:,2),'filled','k');
    end
    
    % duplicate plot for each inertia value
    if numel(opts.inertia) > 1 && ~opts.QDPSO.enable
        
        if mod(8,numel(opts.inertia)) ~= 0
            error('inertia canot be split evenly!')
        end
        inertia_index = zeros(numel(iter_best_all),1);
        for n = 1:numel(iter_best_all)
            index = state{n}.worker_ID;
            while index > numel(opts.inertia)
                index = index - numel(opts.inertia);
            end
            inertia_index(n) = index;
        end
        
        figure
        for n = 1:numel(opts.inertia)
            subplot(2,2,n)
            hold all
            total_iter = 0;
            for i = 1:numel(iter_best_all)
                if inertia_index(i) == n
                    plot(1:numel(iter_best_all{i}),iter_best_all{i})
                    total_iter = total_iter + numel(iter_best_all{i});
                end
            end
            %total_iter
            %ylim([0,100])
            xlim([0,max_iter])
            ylabel({sprintf('inertia of %g',opts.inertia(n)),sprintf('%i starts',sum(inertia_index==n)),sprintf('%i iterations',total_iter)})
            set(gca,'Xscale','log')
        end
    end
    
    
    
end

% rebuild the network from the best training
if ~isstruct(net_save)
    best_net = mat_to_net(net_save,Net_Size{1},nn_Input,nn_Output);
else
    best_net = net_save;
end

net_plot(best_net,0,1,0);
