
module AxelRod
using Random, SimpleChains, DataStructures

#all agents have perfect memory of their own actions, but not those of others: I.e. Pavlov will always correctly recall its actions

#this file implictly assumes that in terms of the payoffs, DC > CC >>> DD, i.e. its a prisoner's dilemma

#we represent the actions taken by an agent as a _boolean_ value: the list of actions taken by 
#agent is represented as a vector of bools.

#cooperation is true, defection is false

#TODO: Looki into state_corruption. Better to rewrite as non-mutating func based on true_actions?: DONE

#TODO: Check if RNG seed can be fixed

abstract type PD_agent end 
abstract type depth_agent <: PD_agent end
abstract type simple_agent <: PD_agent end

#examples

mutable struct TFT{T} <: simple_agent where {T<:AbstractFloat}
    score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}
    function TFT(T::Type = Float64)
        new{T}(zero(T),[],[])

    end
end

#p chance of coopeartion
mutable struct random_picker{T}<:simple_agent where {T<:AbstractFloat}
    score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}   
    p::T
end

#p denotes the probability of cooperation
function random_picker(p::T) where {T<:AbstractFloat}
    random_picker{T}(zero(T),[],[],p)
end

#pavlov
mutable struct pavlov{T}<:simple_agent where {T<:AbstractFloat}
    score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}
    function pavlov(T::Type = Float64)
        new{T}(zero(T),[],[])
    end
end

#__________________________________________________________________________________










#__________________________________________________________________________________

function biased_random(p::T) where T<:AbstractFloat
    control = rand(T)
    outp = p > control ? true : false
    return outp
end

#p is the chance of corruption
function state_corruption(state::Bool, p::T) where T<:AbstractFloat
    control = rand(T)
    output = p > control ? !state : state
    return output
end

strategy(agent::TFT, cagent::T, index::N) where {T<:PD_agent,N<:Integer} = begin 
    if length(cagent.actions) >= 1
        return cagent.actions[end]
    else
        return true
    end
end
    
strategy(agent::random_picker, cagent::T, index::N) where {T<:PD_agent,N<:Integer} = biased_random(agent.p)

strategy(agent::pavlov, cagent::T, index::N) where {T<:PD_agent,N<:Integer} = begin 
    if length(cagent.actions) >= 1
        @views return is_favourable(agent.true_actions[end],cagent.actions[end])
    else
        return true
    end
end

function is_favourable(own_action::Bool, enemy_action::Bool)::Bool
    
    action_tuple = (own_action, enemy_action)
    output = (action_tuple == (true,true)) || (action_tuple == (false,true)) ? true : false
    return output
end


#TODO: this may require a multiple dispatch implementation for more advanced agents, i.e. ones that may have a local cache
function reset_agent!(agent::T) where T<:PD_agent
    agent.actions = Vector{Bool}([])
    agent.true_actions = Vector{Bool}([])
    agent.score = zero(agent.score)
    return agent
end

const axelrod_payout = Dict((true, true) => (3,3),(true, false) => (0,5), (false, true) => (5,0), (false, false)=>(1,1))

function clash_models!(agent1::PD_agent, agent2::PD_agent, payout::Dict = axelrod_payout; N_turns::Integer = 200, p_corrupt::T) where T<:AbstractFloat
    @assert p_corrupt <= one(T)
    for index in 1:N_turns
        #amnesiac agents - past is corrupted every time, in a non-unique manner.
        action_1 = strategy(agent1,agent2, index)
        action_2 = strategy(agent2,agent1, index)

        action_tuple = (action_1, action_2)

        point1, point2 = payout[action_tuple]

        agent1.score += point1
        agent2.score += point2 

        push!(agent1.actions,action_1)
        push!(agent1.true_actions,action_1)

        push!(agent2.actions,action_2)
        push!(agent2.true_actions,action_2)

        agent1.actions .= state_corruption.(agent1.true_actions, p_corrupt)
        agent2.actions .= state_corruption.(agent2.true_actions, p_corrupt)
    end

    #at the end of each state, we extract the scores and wipe the model's memory's
    s1 = copy(agent1.score)
    s2 = copy(agent2.score)
    reset_agent!(agent1)
    reset_agent!(agent2)
    return s1, s2
end

mutable struct EnsembleRepr{T<:AbstractFloat}
    model_types::Vector{Type{<:PD_agent}}
    model_container::Vector{Vector{<:PD_agent}}

    #TODO: somehow check if all sub-vectors are of a concrete type! (we dont wanna mix diffent floats for instance!
    #TODO: make this a bit cleaner, check type stability!
    function EnsembleRepr(models::Vector{Vector{<:PD_agent}})
        model_types = [eltype(vect) for vect in models]
        new{score_type}(model_types,models)
    end
end

function get_model(X::EnsembleRepr, index<:Integer)
    lengths = length.(X.model_container)
    @assert sum(lengths) <= index
    support_indeces = cumsum(lengths)
    index_of_models = searchsortedfirst(support_indeces,index)
    

end



export TFT, random_picker, pavlov, clash_models!, EnsembleRepr
end
