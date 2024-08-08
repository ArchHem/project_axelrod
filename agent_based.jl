
module AxelRod
using Random, SimpleChains, DataStructures

#all agents have perfect memory of their own actions, but not those of others: I.e. Pavlov will always correctly recall its actions

#this file implictly assumes that in terms of the payoffs, DC > CC >>> DD, i.e. its a prisoner's dilemma

#we represent the actions taken by an agent as a _boolean_ value: the list of actions taken by 
#agent is represented as a vector of bools.

#cooperation is true, defection is false

#TODO: Looki into state_corruption. Better to rewrite as non-mutating func based on true_actions?

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

function biased_random(p::T) where T<:AbstractFloat
    control = rand(T)
    outp = p > control ? true : false
    return outp
end

#p is the chance of corruption
function state_corruption(state::Bool, p::T) where T<:AbstractFloat
    control = rand(T)
    output = p > control ? state : !state
    return output
end

strategy(agent::TFT, cagent::T) where T<:PD_agent = begin 
    if length(cagent.actions) >= 1
        @views return cagent.actions[end] ? true : false
    else
        return true
    end
end
    
strategy(agent::random_picker, cagent::T) where T<:PD_agent = biased_random(agent.p)

strategy(agent::pavlov, cagent::T) where T<:PD_agent = begin 
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

function reset_agent!(agent::T) where T<:PD_agent
    agent.actions = Vector{Bool}([])
    agent.true_actions = Vector{Bool}([])
    agent.score = zero(agent.score)
    return agent
end

const axelrod_payout = Dict((true, true) => (3,3),(true, false) => (0,5), (false, true) => (5,0), (false, false)=>(1,1))

function clash_models!(agent1::PD_agent, agent2::PD_agent, payout::Dict = axelrod_payout; N_turns::Integer = 200, p_corrupt::T) where T<:AbstractFloat
    @assert p_corrupt <= one(T)
    for _ in 1:N_turns
        #amnesiac agents - past is corrupted every time, in a non-unique manner.
        action_1 = strategy(agent1,agent2)
        action_2 = strategy(agent2,agent1)

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

export TFT, random_picker, pavlov, clash_models!
end

using .AxelRod

#example working 

all_defector = random_picker(0.0)
titfortat = TFT()
pavlov_agent = pavlov()

const p_corruption = 0.2
score1, score2 = clash_models!(all_defector,titfortat,p_corrupt = p_corruption, N_turns = 100)
score3, score4 = clash_models!(titfortat,pavlov_agent,p_corrupt = p_corruption, N_turns = 100)

# we expect the all-defector/TFT matchup to end up with 1 cooperation/defection followed by all-defection: I.e. the defector should have 5 points more, 
#and the TFT model should have N_turn-1 points. 
# pavlov and TFT should cooperate till the end

println(score1)
println(score2)

println(score3)
println(score4)

