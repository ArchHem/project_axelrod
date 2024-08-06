# Define a type to represent a player
struct Player
    name::String
    strategy::Function
    action_history::Vector{String}  # Store the entire action history
end

# Define a type to represent the game
struct IteratedPrisonersDilemma
    players::Vector{Player}
    reward_matrix::Dict{Tuple{String, String}, Tuple{Int, Int}}
    rounds::Int
    p::Float64
end

# # Function to play a single round of the game
# function play_round(player1::Player, player2::Player, reward_matrix::Dict{Tuple{String, String}, Tuple{Int, Int}})
#     action1 = player1.strategy(player2.action_history)
#     action2 = player2.strategy(player1.action_history)
    
#     push!(player1.action_history, action1)
#     push!(player2.action_history, action2)
    
#     reward1, reward2 = reward_matrix[(action1, action2)]
    
#     return (reward1, reward2)
# end


# Function to play a single round of the game with noisy communication
function play_round(player1::Player, player2::Player, reward_matrix::Dict{Tuple{String, String}, Tuple{Int, Int}}, p::Float64)
    action1 = player1.strategy(player2.action_history)
    action2 = player2.strategy(player1.action_history)
    
    # Apply noisy communication
    if rand() < p
        action1 = action1 == "cooperate" ? "defect" : "cooperate"
    end
    if rand() < p
        action2 = action2 == "cooperate" ? "defect" : "cooperate"
    end
    
    push!(player1.action_history, action1)
    push!(player2.action_history, action2)
    
    reward1, reward2 = reward_matrix[(action1, action2)]
    
    return (reward1, reward2)
end

# Function to play the entire game
function play_game(game::IteratedPrisonersDilemma)
    scores = zeros(Int, length(game.players))
    
    for round in 1:game.rounds
        for i in 1:length(game.players)
            for j in i+1:length(game.players)
                reward1, reward2 = play_round(game.players[i], game.players[j], game.reward_matrix, game.p)
                scores[i] += reward1
                scores[j] += reward2
            end
        end
    end
    
    return scores
end

# Define a strategy for cooperation
function cooperate(action_history::Vector{String})
    return "cooperate"  # "cooperate" represents cooperation
end

# Define a strategy for defection
function defect(action_history::Vector{String})
    return "defect"  # "defect" represents defection
end

# Define a strategy for tit for tat
function tit_for_tat(opponent_action_history::Vector{String})
    if isempty(opponent_action_history)
        return "cooperate"  # Start by cooperating
    else
        return opponent_action_history[end]  # Then mimic the opponent's last action
    end
end

# Define the reward matrix as a dictionary
reward_matrix = Dict(
    ("cooperate", "cooperate") => (3, 3),
    ("cooperate", "defect")    => (0, 5),
    ("defect", "cooperate")    => (5, 0),
    ("defect", "defect")       => (-1, -1)
)

# Create players with different strategies
player1 = Player("Cooperator", cooperate, String[])
player2 = Player("Defector1", defect, String[])
player3 = Player("Tit for Tat", tit_for_tat, String[])
player4 = Player("Defector2", defect, String[])


# Create the game
game = IteratedPrisonersDilemma([player1, player2, player3, player4], reward_matrix, 10, 0.0)

# Play the game
scores = play_game(game)

# Display the results
println("Scores after $(game.rounds) rounds:")
for i in 1:length(game.players)
    println("$(game.players[i].name): $(scores[i])")
end


