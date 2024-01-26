# input layer 3 
# hidden layer n 
# output sigmoid vagy heaviside  ==> move 
using ProgressBars
#from earlier project, resued with owner (my) permission
module NeuralNetworks

    function sigmoid(x::Vector{Float64})
        quant = @. 1.0 / (1.0 .+ exp.(.-x)) # @. makes the entire line pircewise interpeted.
        return quant
    end

    function sigmoid_der(x::Vector{Float64})
        quant = @. sigmoid(x) * (1.0 .- sigmoid(x))
        return quant
    end

    function RELU(x::Vector{Float64})
        quant = @. (abs(x) + x)/2
        return quant
    end

    function RELU_der(x::Vector{Float64})
        quant = @. 0.5 * (sign(x) + 1)
        return quant
    end

    function binary_crossentropy(ypredict::Vector{Float64},
        ylabel::Vector{Float64})
        quant = @. - ylabel * log(ypredict) - (1.0 - ylabel) * log(1.0 - ypredict)
        return sum(quant)
    end

    function binary_crossentropy_der(ypredict::Vector{Float64},
        ylabel::Vector{Float64})
        quant = @. -1.0 * (ylabel / ypredict - (1.0 -ylabel)/(1.0 - ypredict))
        return sum(quant)
    end

    struct NN_network
        #if one aims for HP, we would need to include the types of the layer functions in order not to use abstract types.
        N_neurons::Vector{Int64}
        layer_weights::Vector{Matrix{Float64}}
        layer_biases::Vector{Vector{Float64}}
        act_functions::Vector{Function}
        act_function_der::Vector{Function}
        loss_function::Function
        loss_function_der::Function
        function NN_network(N_neurons::Vector{Int64},act_functions::Vector{Function},act_function_der::Vector{Function},
            loss_function::Function,loss_function_der::Function)
            layer_weights = Vector{Matrix{Float64}}(undef,length(N_neurons)-1)
            layer_biases = Vector{Vector{Float64}}(undef,length(N_neurons)-1)
            for i in 1:length(N_neurons)-1
                layer_weights[i] = rand(Float64,(N_neurons[i+1],N_neurons[i])) .- 0.5
                layer_biases[i] = rand(Float64,(N_neurons[i+1],)) .- 0.5
            end
            new(N_neurons,layer_weights,layer_biases,act_functions,act_function_der,loss_function,loss_function_der)
        end
    end 

    function modify_layer(layer_index::Int64,new_weights::Matrix{Float64},new_biases::Vector{Float64},NN_instance::NN_network)
        NN_instance.layer_weights[layer_index] .= new_weights
        NN_instance.layer_biases[layer_index] .= new_biases
    end

    function apply_layer(input_vector::Vector{Float64},NN_instance::NN_network,index::Int64)
        l_weights = NN_instance.layer_weights[index,]
        l_bias = NN_instance.layer_biases[index,]
        l_afunc = NN_instance.act_functions[index,]
        zvec = l_weights * input_vector + l_bias
        output_vector = l_afunc(zvec)
        return output_vector, zvec
    end

    function network_predict(input_vector::Vector{Float64},NN_instance::NN_network)
        number_of_layers = length(NN_instance.N_neurons)
        output_vector = input_vector
        for indices in 1:number_of_layers-1
            output_vector, zvec = apply_layer(output_vector,NN_instance,indices)
        end
        return output_vector
    end

    function evaluate_loss(input_vector::Vector{Float64},label::Vector{Float64},NN_instance::NN_network)
        output = network_predict(input_vector,NN_instance)
        loss = NN_instance.loss_function(output,label)
        return loss
    end

    function calculate_activations(input_vector::Vector{Float64},NN_instance::NN_network)
        N = length(NN_instance.N_neurons)
        activations = Vector{Vector{Float64}}(undef,(N-1,))
        zvecs = Vector{Vector{Float64}}(undef,(N-1,))
        temp = input_vector
        for i in 1:N-1
            temp, lzvec = apply_layer(temp,NN_instance,i)
            activations[i] = temp
            zvecs[i] = lzvec
        end
        return activations, zvecs
    end 

    function backpropegate(input_vector::Vector{Float64},label::Vector{Float64},NN_instance::NN_network)
        activations, zvecs = calculate_activations(input_vector,NN_instance)
        N = length(NN_instance.N_neurons)
        deltas = Vector{Vector{Float64}}(undef,(N-1,))
        ldelta_w = NN_instance.loss_function_der(activations[N-1],label) .* NN_instance.act_function_der[N-1](zvecs[N-1])
        deltas[N-1] = ldelta_w
        for i in N-2:-1:1
            ldelta_w = NN_instance.act_function_der[i](zvecs[i]) .* NN_instance.layer_weights[i+1]' * ldelta_w 
            deltas[i] = ldelta_w
        end

        weight_updates = Vector{Matrix{Float64}}(undef,(N-1,))
        bias_updates = Vector{Vector{Float64}}(undef,(N-1,))

        for i in 2:N-1
            weight_updates[i] = deltas[i] .* activations[i-1]'
            bias_updates[i] = deltas[i]
        end
        weight_updates[1] = deltas[1] .* input_vector'
        bias_updates[1] = deltas[1]

        return weight_updates, bias_updates
    end

    function batch_update_network(input_vectors::Vector{Vector{Float64}},labels::Vector{Vector{Float64}},NN_instance::NN_network,
        learning_rate::Float64 = 1e-2)
        
        N = length(NN_instance.N_neurons)
        N_input_vecs = length(input_vectors)
        sum_d_weight, sum_bias_updates = backpropegate(input_vectors[1],labels[1],NN_instance)

        Threads.@threads for k in 2:N_input_vecs
            temp_weight, temp_bias = backpropegate(input_vectors[k],labels[k],NN_instance)
            sum_d_weight .= sum_d_weight .+ temp_weight
            sum_bias_updates .= sum_bias_updates .+ temp_bias
        end
        new_bias = NN_instance.layer_biases - learning_rate .* sum_bias_updates
        new_weights = NN_instance.layer_weights - learning_rate .* sum_d_weight

        for index in 1:N-1
            modify_layer(index,new_weights[index],new_bias[index],NN_instance)
        end
    end

    function train_network(input_vectors::Vector{Vector{Float64}},labels::Vector{Vector{Float64}},NN_instance::NN_network,
        learning_rate::Float64 = 1e-2,batch_length::Int64 = 10)

        N_input = length(input_vectors)

        last_batch_length = N_input % batch_length
        number_of_full_batches = N_input ÷ batch_length

        for j in 0:number_of_full_batches-1
            valid_indices = (j*batch_length+1):((j+1)*batch_length)
            batch_update_network(input_vectors[valid_indices],
            labels[valid_indices],NN_instance,learning_rate)
        end
        if last_batch_length !=0
            last_indices = ((number_of_full_batches) * batch_length +1):N_input
            batch_update_network(input_vectors[last_indices],
                labels[last_indices],NN_instance,learning_rate)
        end
    end

    function validate_model(test_vectors::Vector{Vector{Float64}},test_labels::Vector{Vector{Float64}},NN_instance::NN_network)
        N = length(test_labels)

        correct_guess::Int64 = 0
        
        for i in 1:N
            local_predict = network_predict(test_vectors[i],NN_instance)
            correct_answer = test_labels[i]

            if mapslices(argmax,local_predict,dims=1) == mapslices(argmax,correct_answer,dims=1)
                correct_guess = correct_guess + 1
            end
            
        end
        return correct_guess, N-correct_guess
    end

    function epoch_train_network!(input_vectors::Vector{Vector{Float64}},labels::Vector{Vector{Float64}},NN_instance::NN_network,
        test_vectors::Vector{Vector{Float64}},
        test_labels::Vector{Vector{Float64}},
        learning_rate::Float64 = 1e-3,batch_length::Int64 = 10, epoch_count::Int64 = 50, run_diagnostics::Bool = true)

        corrvec = zeros(Int64,(epoch_count))
        incorrvec = zeros(Int64,(epoch_count))

        for i in ProgressBar(1:epoch_count)
            train_network(input_vectors,labels,NN_instance,learning_rate,batch_length)
            if run_diagnostics
                corr, incorr = validate_model(test_vectors,test_labels,NN_instance)
                corrvec[i] = corr
                incorrvec[i] = incorr
            end
        end
        if run_diagnostics
            epoc_index = collect(1:epoch_count)
            
            return epoc_index, corrvec, incorrvec
        end
    
    end

    export sigmoid, sigmoid_der, RELU, RELU_der, binary_crossentropy, binary_crossentropy_der,network_predict, network_predict_der, NN_network

end

    
