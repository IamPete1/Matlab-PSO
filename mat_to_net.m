%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matlab network structure from matrix
function net = mat_to_net(x,Net_Size,nn_Input,nn_Output)

% intiate cells
bias = cell(numel(Net_Size)+1,1);

LW = cell(length(Net_Size));

num_layers = length(Net_Size);

hidden_weights = cell(1,num_layers);
bias_calc = cell(1,num_layers+1);


% Convert to bias and remove from varable lenght
index1 = 1;
for i = 1:num_layers
    index2 = index1 + Net_Size(i) - 1;
    bias_calc{1,i} = x(index1:index2)';
    
    index1 = index2 + 1;
end
index2 = index1 + nn_Output - 1;
bias_calc{1,i+1} = x(index1:index2)';
index1 = index2 + 1;

% Input Layer weights
n_weights = nn_Input * Net_Size(1);
index2 = index1 + n_weights - 1;
input_weights = reshape(x(index1:index2),Net_Size(1),nn_Input);
index1 = index2 + 1;

% Hidden layer weights
for i = 1:num_layers - 1
    n_weights = Net_Size(i) * Net_Size(i + 1);
    index2 = index1 + n_weights - 1;
    hidden_weights{1,i} = reshape(x(index1:index2),Net_Size(i+1),Net_Size(i));
    index1 = index2 + 1;
end
n_weights = nn_Output * Net_Size(end);
index2 = index1 + n_weights - 1;
i = num_layers;
hidden_weights{1,i} = reshape(x(index1:index2),nn_Output,Net_Size(i));

% Append to matrixs
for i = 1:num_layers + 1
    bias{i,1} = bias_calc{1,i};
end
IW = input_weights;
for i = 1:num_layers
    LW{i,i} = hidden_weights{1,i};
end

net.b = bias;
net.IW = IW;
net.LW = LW;
end
