function live_plot_example(x,input,output,Net_Size,nn_Input,nn_Output)


net = mat_to_net(x,Net_Size,nn_Input,nn_Output);

IW = net.IW;
b = net.b;
LW = net.LW;
len = length(LW);

net_output = zeros(size(output));
for j = 1:size(input,1)
    Y = max(0,  (b{1}+IW*input(j,:)')   );

    % Hiden layers
    for i = 1:len-1
        %Y = tansig(b{n}+LW{n,n-1}*Y);
        %Y = 2./(1+exp(-2* (b{i+1}+LW{i,i}*Y) ))-1;
        Y = max(0,  (b{i+1}+LW{i,i}*Y) );
    end

    % hidden layers to output
    net_output(j) = b{len+1}+LW{len,len}*Y;
end

%net_plot(best_net,0,1,0);
figure
hold all
scatter3(input(:,1),input(:,2),output)
scatter3(input(:,1),input(:,2),net_output)
view(3)
drawnow

end