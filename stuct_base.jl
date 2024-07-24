# Define a type to represent a player
struct Player
    name::String
    strategy::Function
end


# Define a type to represent the game
struct Turnament
    players::Vector{Player}
    reward_matrix::Dict{Tuple{String, String}, Tuple{Int, Int}}
    rounds::Int
end

# Function to play a single round of the game
function play_round(player1::Player, player2::Player, reward_matrix::Dict{Tuple{String, String}, Tuple{Int, Int}})
    action1 = player1.strategy()
    action2 = player2.strategy()
    
    reward1, reward2 = reward_matrix[(action1, action2)]
    
    return (reward1, reward2)
end

# Function to play the entire game
function play_game(game::Turnament)
    scores = zeros(Int, length(game.players))
    
    for round in 1:game.rounds
        for i in 1:length(game.players)
            for j in i+1:length(game.players)
                reward1, reward2 = play_round(game.players[i], game.players[j], game.reward_matrix)
                scores[i] += reward1
                scores[j] += reward2
            end
        end
    end
    
    return scores
end


# Define a strategy for cooperation
function cooperate()
    return "cooperate"  # "cooperate" represents cooperation
end

# Define a strategy for defection
function defect()
    return "defect"  # "defect" represents defection
end

# Define a strategy for tit for tat
function tit_for_tat(last_opponent_action::String)
    if last_opponent_action == ""
        return "cooperate"  # Start by cooperating
    else
        return last_opponent_action  # Then mimic the opponent's last action
    end
end

# Define the reward matrix as a dictionary
reward_matrix = Dict(
    ("cooperate", "cooperate") => (3, 3),
    ("cooperate", "defect")    => (0, 5),
    ("defect", "cooperate")    => (5, 0),
    ("defect", "defect")       => (1, 1)
)

# Create players with different strategies
player1 = Player("Cooperator", cooperate)
player2 = Player("Defector", defect)
player3 = Player("Tit for Tat", tit_for_tat)

# Create the game
game = Turnament([player1, player2, player3], reward_matrix, 10)

# Play the game
scores = play_game(game)

# Display the results
println("Scores after $(game.rounds) rounds:")
for i in 1:length(game.players)
    println("$(game.players[i].name): $(scores[i])")
end