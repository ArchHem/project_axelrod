include("./NeuralNetworks.jl")
include("./base_game.jl")

using .NeuralNetworks
using .base_game


const N_depth::Int64 = 10
neuron_arr = Vector{Int64}([3*N_depth,5,5,1])
funcs = Vector{Function}([sigmoid,sigmoid,sigmoid])
func_derivs = Vector{Function}([sigmoid_der,sigmoid_der,sigmoid_der])
player_strat = NN_network(neuron_arr,funcs,func_derivs,binary_crossentropy,binary_crossentropy_der)


testcase = [[1,0,0],[1,0,0],[0,0,1],[0,1,0]]
flattened = [(testcase...)...]

function NN_mutator!(network_instance::NN_network, sigma::Float64)
    for i in 1:length(network_instance.layer_weights)
        network_instance.layer_weights[i] .=+ sigma * randn(Float64,size(network_instance.layer_weights[i]))
        network_instance.layer_biases[i] .=+ sigma * randn(Float64,size(network_instance.layer_biases[i]))
    end
end

function clash_network_vs_strat(network_instance::NN_network,network_depth, competing_strategy, competing_depth,Number_of_rounds)

end

function one_round_competition!(networks::Array{NN_network},network_depth, competing_strategy, competing_depth, Number_of_rounds)
    
end 

