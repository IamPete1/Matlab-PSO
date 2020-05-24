function pop = rand_pop(num_pop, num_vars)

% create random intial population of values between -5 and 5
%pop = 10 * (rand([num_pop,num_vars]) - 0.5);

% Random arrays from continuous uniform distribution.
%pop =  unifrnd(-5, 5, num_pop,num_vars);

% gasuan distrbusion about zero
pop = randn([num_pop,num_vars]) * 10;
%pop = zeros(num_pop,num_vars);

end