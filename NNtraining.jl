include("./NeuralNetworks.jl")
include("./base_game.jl")

using .NeuralNetworks
using .base_game

copy(x::T) where T = T([getfield(x, k) for k ∈ fieldnames(T)]...)


const N_depth::Int64 = 10
neuron_arr = Vector{Int64}([3*N_depth,5,5,1])
funcs = Vector{Function}([sigmoid,sigmoid,sigmoid])
func_derivs = Vector{Function}([sigmoid_der,sigmoid_der,sigmoid_der])
player_strat = NN_network(neuron_arr,funcs,func_derivs,binary_crossentropy,binary_crossentropy_der)

function copy_networks(networks::Vector{NN_network}, number_of_copies::Int64 = 3)
    #assumes all NNs have the same layer dimensions and act functions
    N_networks = length(networks)
    for i in 1:N_networks
        for j in 1:number_of_copies
            local_network = copy(networks[i])
            append!(networks,local_network)
    end
    return networks
end

function NN_mutator!(network_instance::NN_network, sigma::Float64)
    for i in 1:length(network_instance.layer_weights)
        network_instance.layer_weights[i] .=+ sigma * randn(Float64,size(network_instance.layer_weights[i]))
        network_instance.layer_biases[i] .=+ sigma * randn(Float64,size(network_instance.layer_biases[i]))
    end
end

function clash_network_vs_strat(network_instance::NN_network, network_depth, competing_strategy, competing_depth, Number_of_rounds)
    hot1 = [[0,0,1] for i in 1:N_past2+1]
    hot2 = [[0,0,1] for i in 1:N_past1+1]

    next_hot_1 = strat1(hot2)
    next_hot_2 = strat2(hot1)

    hot1[N_past2+1] = next_hot_1
    hot1[N_past1+1] = next_hot_2

    score = Array{Float64}([0.0,0.0])

    for i in 1:number_of_steps-1
        p1 = convert_hot_to_prob(next_hot_1)
        p2 = convert_hot_to_prob(next_hot_2)
        rewards = evaluate_game(p1,p2)
        score += rewards
        
        next_hot_1 = strat1(hot2)
        next_hot_2 = strat2(hot1)

        for index1 in 1:N_past2
            hot1[index1] =  hot1[index1+1]         
        end

        for index2 in 1:N_past1
            hot1[index2] =  hot2[index2+1]         
        end
        
        hot1[N_past2 + 1] = next_hot_1
        hot2[N_past1 + 1] = next_hot_2

    end 

    return score
end

function one_round_competition!(networks::Array{NN_network},network_depth, competing_strategy, competing_depth, Number_of_rounds)
    
end 

