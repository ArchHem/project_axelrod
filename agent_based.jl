
module AxelRod
using Random, DataStructures, StatsBase, ProgressBars, Statistics

#all agents have perfect memory of their own actions, but not those of others: I.e. Pavlov will always correctly recall its actions

#this file implictly assumes that in terms of the payoffs, DC > CC >>> DD, i.e. its a prisoner's dilemma

#we represent the actions taken by an agent as a _boolean_ value: the list of actions taken by 
#agent is represented as a vector of bools.

#cooperation is true, defection is false

#TODO: Check if RNG seed can be fixed globally

#TODO: Theoretically, the support_type used by many internal functions can be infered from the dynamically generated structs. Implement!

#TODO: Re-check if teh current method of copy-decoupling is good enough! There may yet be some coupled operations. 

#TODO: Check type stability of internal functions

#READ ME BEFORE CONTRIBUTING:

#ALL agents must have:

#=fields of: 
score: The score achieved in the current game
pers_score (persistent score): used for model culling in ensemble simulations
actions (action history, as perceived by others, i.e. already 'corrupted'), 
true_actions: the true actions taken by the agent

A parametric type T which denotes the type of float they use for the score under the hood: type of the concrete type syntax, eg TFT{Float64}

GOOD TO HAVE: a sensible constructor function, esp. with regards the parametric type mentioned above.
=#

#=
specialized dispatch of the strategy(agent,cagent (as in counter-agent), index) function. 

By STANDARD the strategy functions may access: the actions of both agents and the index of iteration: 
they may not access any other 'meta' information or even the model's own scores.
 For pavlovian agents, we always implicutly assume that DC > CC >> DD in terms of payout. 
=#

abstract type PD_agent end 
abstract type depth_agent <: PD_agent end
abstract type simple_agent <: PD_agent end



function biased_random(p::T) where {T<:AbstractFloat}
    control = rand(T)
    outp = p > control ? true : false
    return outp
end

#p is the chance of corruption
function state_corruption(state::Bool, p::T) where {T<:AbstractFloat}
    control = rand(T)
    output = p > control ? !state : state
    return output
end

#examples

mutable struct TFT{T} <: simple_agent where {T<:AbstractFloat}
    score::T
    per_score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}
    function TFT(T::Type{<:Real} = Float64)
        new{T}(zero(T),zero(T),[],[])

    end
end

#p chance of coopeartion
mutable struct random_picker{T}<:simple_agent where {T<:AbstractFloat}
    score::T
    per_score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}   
    p::T
end

#p denotes the probability of cooperation
function random_picker(p::T) where {T<:AbstractFloat}
    random_picker{T}(zero(T),zero(T),[],[],p)
end

#pavlov
mutable struct pavlov{T}<:simple_agent where {T<:AbstractFloat}
    score::T
    per_score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}
    function pavlov(T::Type = Float64)
        new{T}(zero(T),zero(T),[],[])
    end
end

#caotious tft
mutable struct n_cautious_TFT{T} <: depth_agent where {T<:AbstractFloat}
    score::T
    per_score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}
    N_past::Int64
    function n_cautious_TFT(T::Type = Float64, Npast = 1)
        @assert Npast > 0
        new{T}(zero(T),zero(T),[],[], Npast)
    end
end

# n-averager pavlov
mutable struct n_averager_pavlov{T} <: depth_agent where {T<:AbstractFloat}
    score::T
    per_score::T
    actions::Vector{Bool}
    true_actions::Vector{Bool}
    N_past::Int
    function n_averager_pavlov(T::Type=Float64, N_past::Int=2)
        new{T}(zero(T), zero(T), [], [], N_past)
    end
end









strategy(agent::TFT, cagent::T, index::N) where {T<:PD_agent,N<:Integer} = begin 
    if length(cagent.actions) >= 1
        return cagent.actions[end]
    else
        return true
    end
end
    


strategy(agent::n_cautious_TFT, cagent::T, index::N) where {T<:PD_agent, N<:Integer} = begin
    # Ensure there are at least `n` rounds of history to check
    if index > agent.N_past
        # Check if the last N actions of the opponent were cooperation (true)
        for i in 1:agent.N_past
            if cagent.actions[end-i+1] == false
                return false  # If any action was a defection (false), defect
            end
        end
        return true  # If all last N actions were cooperation, cooperate
    else
        # If less than N rounds have been played, default to cooperation
        return true 
    end
end




strategy(agent::random_picker, cagent::T, index::N) where {T<:PD_agent,N<:Integer} = biased_random(agent.p)

strategy(agent::pavlov, cagent::T, index::N) where {T<:PD_agent,N<:Integer} = begin 
    if length(cagent.actions) >= 1
        state = is_favourable(agent.true_actions[end],cagent.actions[end])
        outcome = state ? agent.true_actions[end] : !agent.true_actions[end]
        return outcome
    else
        return true
    end
end



function strategy(agent::n_averager_pavlov, cagent::T, index::N) where {T<:PD_agent,N<:Integer}

    if length(agent.true_actions) >= agent.N_past
        # Get the last n actions from both the agent and the opponent
        @views agent_actions_window = agent.true_actions[end-agent.N_past+1]
        @views cagent_actions_window = cagent.actions[end-agent.N_past+1]

        # Check if the interaction history over the last n rounds was favorable
        was_favorable = is_favourable.(agent_actions_window,cagent_actions_window)

        overall_payoff = mean(was_favorable)
        
        avg_move_pavlov = round(Int64, mean(agent_actions_window))
        
        if overall_payoff > 0.5
            return Bool(avg_move_pavlov)
        else
            return !Bool(avg_move_pavlov)
        end

            
        if was_favorable
            # If favorable, use the average action
            return Bool(avg_action)
        else
            # If unfavorable, switch to the opposite action
            return !Bool(avg_action)
        end
    else
        # If there aren't enough actions to evaluate, cooperate by default
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

function total_reset_agent!(agent::T) where T<:PD_agent
    agent.actions = Vector{Bool}([])
    agent.true_actions = Vector{Bool}([])
    agent.score = zero(agent.score)
    agent.per_score = zero(agent.per_score)
    return agent
end

const axelrod_payout = Dict((true, true) => (3,3),(true, false) => (0,5), (false, true) => (5,0), (false, false)=>(1,1))

function clash_models!(agent1::PD_agent, agent2::PD_agent, payout::Dict = axelrod_payout; N_turns::Integer = 200, p_corrupt::T) where T<:AbstractFloat
    #=
    This function has inputs:
        agent1:: The first agent, which has associated dispatch of 'strategy'
        agent2:: The second agent, which has associated dispatch of 'strategy'. 
            For type stability, the two agents should have the same internal real-number represenation of scores
        payout:: Dictionary that maps the boolean tuples (true, false), (false, true), (false, false), (true, true) to some FLOAT tuples
        N_turns:: Number of turns played, before the agents are 'reset'
        p_corrupt:: chance of a random action in true_history being flipped to the opposite, as stored in actions
            
            This function will 'reset' or wipe the memory of the agents at the end of it, but keeps their persistent scores
    =#
    @assert p_corrupt <= one(T)
    for index in 1:N_turns
        #amnesiac agents - past is corrupted every time, in a non-unique manner.
        action_1 = strategy(agent1,agent2, index)
        action_2 = strategy(agent2,agent1, index)

        action_tuple = (action_1, action_2)

        point1, point2 = payout[action_tuple]

        agent1.score += point1
        agent2.score += point2 

        agent1.per_score += point1
        agent2.per_score += point2 

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

abstract type AbstractEnsemble end

function EnsembleBuilder(name::Symbol,model_types::AbstractVector,field_names::AbstractVector{Symbol},T::Type{<:Real})
    #=
    This function creates a storing struct dynamically, as specified by the inputs.
        name:: Symbol, will put the 'name' into the local namespace as a constructor: otherwise, 
        the function itself returns the constructor which might be bound to another name but will gnereate structs of this name.
        model_types:: A vector filled with NON _concrete_ agent types: their concrete type is determined via the Type T
        field_names:: Name of the fields dynamically generated, vector of Symbolss
        T:: Concrete float representation of internal points, type, eg Float64, NOT an instance
    =#

    #model_types should be a vector-of-types
    @assert length(model_types) == length(field_names)
    N = length(model_types)
    interm_types = [:($(elem{T})) for elem in model_types]
    interm_types = [:(Vector{$(elem)}) for elem in interm_types]

    fields_interm = [:( $(field_names[i]) ) for i in 1:N]

    fields = [:($(fields_interm[i])::$(interm_types[i])) for i in 1:N]
    
    
    container = quote
        mutable struct $name <:AbstractEnsemble 
            $(fields...)
        end
    end
    eval(container)

    return eval(name)
end

#might be better in returning vector-of-vectors
function get_pers_scores(ensemble::AbstractEnsemble,T::Type{<:Real})
    #=This function gets the 'persistent score' of each model in the ensemble: 
    the function is dynamic and should operate on all instnces of abstractensembles defined via the above dynamic generator
        T::Type of internal float repr. of scores. TODO: can be infered in theory via some other dynamic approach
    =#
    fields = fieldnames(typeof(ensemble))
    score_vector = Vector{Vector{T}}([])

    for field in fields
        local_models = getfield(ensemble,field)
        local_scores = getfield.(local_models,:per_score)
        push!(score_vector,local_scores)
    end
    return score_vector
end

function delete_worst_performers!(ensemble::AbstractEnsemble,min_score::T) where T<:Real
    #=
    This function deteles all models dynamically from the ensemble that do not have some minimum score min_score.
    =#
    fields = fieldnames(typeof(ensemble))
    
    #look into ways to do this in-place instead of this monstrosity!
    for field in fields
        #THIS ALLOCATES LOOK INTO FIXES
        local_models = getfield(ensemble,field)
        local_scores = getfield.(local_models,:per_score)
        bool_mask = local_scores .< min_score
        deleteat!(local_models,findall(bool_mask))
        setfield!(ensemble,field,local_models)
    end
    return ensemble
end



function r_repopulate_model!(ensemble::AbstractEnsemble,N_new_models::T) where T<:Integer
    #this works by taking a random, non deleted model, and duplicating it, adding it back into the ensemble
    #first we iterature thru the struct fields, to see how likely is a new model to belong to either field-vector
    #i.e. first we sample the fields with probability prop. to length(field...) then select a random model within that field, and duplicate it
    fields = fieldnames(typeof(ensemble))
    field_vals = @views [getfield(ensemble,field) for field in fields]

    field_lengths = [length(val) for val in field_vals]
    field_ids = collect(1:length(fields))

    number_of_models = sum(field_lengths)

    probs = field_lengths/number_of_models

    chosen = wsample(field_ids,probs,N_new_models,replace=true)

    for c in chosen
        #performance bloat... maybe implement copy for all agents?
        push!(field_vals[c],deepcopy(sample(field_vals[c])))
    end

    for (i, field) in enumerate(fields)
        setfield!(ensemble,field,field_vals[i])
    end

    return ensemble

end

function ensemble_shape(ensenble::AbstractEnsemble)
    #returns a vector ints that stores which field has how many elements
    fields = fieldnames(typeof(ensenble))
    shape = @views [length(getfield(ensenble,field)) for field in fields]
    return shape

end

function to_shape(index::T, shape::Vector{T}) where T<:Integer
    #=given an index of a model, this function will output the 
    prim_index:: index of the field
    secondary_index:: Index of the model inside the field specified by primary_index
    =#
    csummed = cumsum(shape)
    @assert csummed[end] >= index
    prim_index = searchsortedfirst(csummed,index)
    secondary_index = prim_index == 1 ? index : index - csummed[prim_index-1]
    return (prim_index, secondary_index)
end

function NumberOfAgents(ensemble::AbstractEnsemble)
    #returns the current number of agents inside an ensemble
    vec = ensemble_shape(ensemble)

    number_of_models = sum(vec)

    return number_of_models
end

#implement varitions of this func
function ensemble_round!(ensemble::AbstractEnsemble,T::Type{Z},N_turns::Z,payout::Dict,p_corrupt::AbstractFloat) where Z<:Integer
    #TODO: review, add docstring
    N = NumberOfAgents(ensemble)

    @assert iseven(N)

    shape = ensemble_shape(ensemble)
    
    indeces = collect(1:N)

    shuffle!(indeces)

    fields = fieldnames(typeof(ensemble))
    
    vert = T(N/2)
    random_index_pairs = reshape(indeces,(2,vert))

    model_indeces = to_shape.(random_index_pairs,Ref(shape))

    for j in 1:vert
        #allocates!!!
        prim1, sec1 = @views model_indeces[1,j]
        prim2, sec2 = @views model_indeces[2,j]

        models1 = getfield(ensemble,fields[prim1])
        models2 = getfield(ensemble,fields[prim2])

        model1 = @views models1[sec1]
        model2 = @views models2[sec2]

        clash_models!(model1, model2, payout; N_turns = N_turns, p_corrupt = p_corrupt)

        setfield!(ensemble,fields[prim1],models1)
        setfield!(ensemble,fields[prim2],models2)

    end

    return ensemble
end

function StandardRun!(ensemble::AbstractEnsemble,N_turns::T,N_iters::T,cull_freq::T,to_cull::Z, payout::Dict, p_corrupt::Z, support_type::Type{<:Real}) where {T<:Integer, Z<:AbstractFloat}

    #this function also has the 'convinince' function of returning the history of the shape of the array.
    
    shapos = Vector{Vector{Int64}}([ensemble_shape(ensemble)])

    for i in 1:N_iters
        is_multiple = i % cull_freq == 0
        ensemble_round!(ensemble,Int64,N_turns,payout,p_corrupt)

        if is_multiple
            N_old = NumberOfAgents(ensemble)
            scores = get_pers_scores(ensemble,support_type)
            scores = vcat(scores...)
            
            #get lowesr to_cull percentag
            #is this type stable?
            cutoff = round(Int64, N_old*to_cull)
            sort!(scores)
            min_score_local = scores[cutoff]
            delete_worst_performers!(ensemble,min_score_local)
            N_new = NumberOfAgents(ensemble)
            to_create = N_old - N_new
            r_repopulate_model!(ensemble,to_create)
            push!(shapos, ensemble_shape(ensemble))
        end


    end
    return hcat(shapos...)
end


function ensemble_resetter!(x)
    lfields = fieldnames(typeof(x))
    fieldvals = [getfield(x,elem) for elem in lfields]
    #now we have an array of vectors of agents...
    
    fieldvals = broadcast(f -> total_reset_agent!.(f), fieldvals)
    
    for (f, v) in zip(lfields,fieldvals)
        setfield!(x,f,v)
    end
end


macro mc_avg(func_call, reruns)
    func = func_call.args[1]  
    args = func_call.args[2:end]  

    quote
        let
            N = $(esc(reruns))  
            
            
            res0 = $(esc(func))($(map(arg -> :(deepcopy($(esc(arg)))), args)...))
            dims0 = size(res0)
            T = eltype(res0)
            
            
            storage = zeros(T, (dims0..., N))
            storage[:, :, 1] = res0

            
            test = zeros(N)
            test[1] = 1
           
            Threads.@threads :dynamic for i in ProgressBar(2:N)
                local j = i  # Ensure thread-safe loop index
                local lres = $(esc(func))($(map(arg -> :(deepcopy($(esc(arg)))), args)...))  # Deep copy args for each run
                storage[:, :, j] = lres
                test[j] = 1
            end
            
            
            results = mean(storage, dims=3)
            results = dropdims(results, dims=3) 
            results  
        end
    end
end


export TFT, random_picker, pavlov, axelrod_payout, clash_models!, EnsembleRepr, EnsembleBuilder, get_pers_scores, delete_worst_performers!, r_repopulate_model!
export ensemble_round!, StandardRun!, axelrod_payout, ensemble_shape, ensemble_resetter!, @mc_avg, n_cautious_TFT, n_averager_pavlov
end
