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

#test ensemble struct 

model_types = [TFT,pavlov]
field_names = [:TFTs,:Pavlovs]
struct_name = :TFTvsPavlov


examp_builder = EnsembleBuilder(struct_name,model_types,field_names,Float64)


TFT_vec = [TFT() for i in 1:5]
pav_vec = [pavlov() for i in 1:5]
#always use cplict copies!!!!
test_ensemble = examp_builder(copy(TFT_vec),copy(pav_vec))
test_ensemble2 = examp_builder(copy(TFT_vec),copy(pav_vec))

s1 = get_pers_scores(test_ensemble,Float64)
delete_worst_performers!(test_ensemble,1.0)
#should delete all models..


#should add on average equal amounts of models

r_repopulate_model!(test_ensemble2,10)

println(get_pers_scores(test_ensemble2,Float64))
StandardRun!(test_ensemble2,50,200,10,0.05,axelrod_payout,0.05,Float64)
s2 = get_pers_scores(test_ensemble2,Float64)
println(s2)


