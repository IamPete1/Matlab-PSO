clc
clear
close all

% load in a trianing file
%file_name = 'Workspace log 02-11-20 12-43-30';
%file_name = 'Workspace log 02-12-20 07-48-55';
%file_name = 'Workspace log 02-13-20 05-56-25';
%file_name = 'Workspace log 02-13-20 15-52-49';
%file_name = 'Workspace log 02-14-20 07-58-00';
%file_name = 'Workspace log 02-14-20 11-36-07';
%file_name = 'Workspace log 02-14-20 13-48-26';
%file_name = 'Workspace log 02-14-20 14-57-21';
%file_name = 'Workspace log 02-14-20 21-42-04';
%file_name = 'Workspace log 02-17-20 01-21-35';
%file_name = 'Workspace log 02-17-20 17-42-33';
%file_name = 'Workspace log 02-20-20 06-51-54';
%file_name = 'Workspace log 02-21-20 03-24-41';
%file_name = 'Workspace log 02-22-20 07-12-33';
%file_name = 'Workspace log 02-22-20 07-20-12';
%file_name = 'Workspace log 02-25-20 08-33-31';
%file_name = 'Workspace log 02-27-20 12-20-34';
%file_name = 'Workspace log 03-03-20 07-01-02';
%file_name = 'Workspace log 03-04-20 06-18-27';
%file_name = 'Workspace log 03-05-20 05-44-44';
%file_name = 'Workspace log 03-05-20 04-13-09';
%file_name = 'Workspace log 03-06-20 04-37-39';
%file_name = 'Workspace log 03-06-20 09-34-04';
%file_name = 'Workspace log 03-09-20 15-37-28';
%file_name = 'Workspace log 03-10-20 08-05-25';
%file_name = 'Workspace log 03-10-20 08-05-54';
%file_name = 'Workspace log 03-11-20 07-04-54';
%file_name = 'Workspace log 03-11-20 07-27-11';
%file_name = 'Workspace log 03-12-20 10-08-51';
%file_name = 'Workspace log 03-12-20 06-02-04';
%file_name = 'Workspace log 03-13-20 04-43-19';
%file_name = 'Workspace log 03-13-20 04-43-14';
file_name = 'Workspace log 05-08-20 15-50-38';

load(file_name)


colour = repmat(['b','r','m','g','k','c'],[1,10]);

if ~isa(state,'cell')
    figure
    hold all
    
    best = state.iteration_best;
    
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
    index = state.status == 1;
    c(index',1) = 1;
    c(index',2) = 0;
    c(index',3) = 0;
    
    % new global best
    index = state.status == 2;
    c(index',1) = 1;
    c(index',2) = 1;
    c(index',3) = 0;
    
    scatter(1:numel(best),state.iteration_best)
    scatter(1:numel(best),best,[],c,'filled')
    
    
    
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
    if numel(opts.inertia) > 1
        
        if mod(8,numel(opts.inertia)) ~= 0
            error('inertia canot be split evenly!')
        end
        inertia_index = zeros(numel(iter_best_all),1);
        for n = 1:numel(iter_best_all)
            index = state{n}.worker_ID;
            while index > numel(opts.inertia)
                index = index - numel(custom_opts.PSO.inertia);
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
