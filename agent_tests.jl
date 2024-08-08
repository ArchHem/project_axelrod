include("./agent_based.jl")

using Random, .AxelRod


all_defector = random_picker(0.0)
titfortat = TFT()
pavlov_agent = pavlov()

const p_corruption = 0.0
score1, score2 = clash_models!(all_defector,titfortat,p_corrupt = p_corruption, N_turns = 100)
score3, score4 = clash_models!(titfortat,pavlov_agent,p_corrupt = p_corruption, N_turns = 100)

#for p = 0.0
# we expect the all-defector/TFT matchup to end up with 1 cooperation/defection followed by all-defection: I.e. the defector should have 5 points more, 
#and the TFT model should have N_turn-1 points. 
# pavlov and TFT should cooperate till the end

println(score1)
println(score2)

println(score3)
println(score4)
