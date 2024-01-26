"""
Implemetation of iterated prisoner's dilemma game

Bendeguz Szabo, Mate Koszta 
"""

include("./base_game.jl")

using .base_game

# hot encoding: 
# [1, 0, 0] = cooperated
# [0, 1, 0] = defected
# [0, 0, 1] = no games played yet. ==> first move hard coded 
function Tit4Tat(prev_move::Vector)
    if prev_move == [0,0,1]
        return [1,0,0]
    else
        return prev_move
    end
end

function AllDefect(prev_move::Vector)
    return [0, 1, 0]
end

function AllCooperate(prev_move::Vector)
    return [1, 0, 0]
end


function RandomMove(prev_move::Vector)

    moves = [[1, 0, 0], [0, 1, 0]]

    return rand(moves)
    
end 



function PastAveragerPositive(past_moves::Vector{Vector{Int64}})
    
    average_move = [0, 0, 0]

    for move in past_moves
        average_move += move
    end 
    average_move = average_move / length(past_moves)

    if average_move[3] ≈ 1.0
        return [1, 0, 0]
    elseif average_move[1] > average_move[2]
        return [1, 0, 0]
    else
        return [0, 1, 0]
    end 
end 

function PastAveragerNegative(past_moves::Vector{Vector{Int64}})
    
    average_move = [0, 0, 0]

    for move in past_moves
        average_move += move
    end 
    average_move = average_move / length(past_moves)

    if average_move[3] ≈ 1.0
        return [0, 1, 0]
    elseif average_move[1] > average_move[2]
        return [1, 0, 0]
    else
        return [0, 1, 0]
    end 
end 





println(clash_strategies_deep_past(PastAveragerPositive, PastAveragerNegative))




