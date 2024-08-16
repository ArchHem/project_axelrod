include("./agent_based.jl")

using Random, .AxelRod, Plots


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


StandardRun!(test_ensemble2,50,200,10,0.05,axelrod_payout,0.05,Float64)
s2 = get_pers_scores(test_ensemble2,Float64)


#first 'proper' use case


plot_builder = EnsembleBuilder(:TFTvsAD,[TFT,random_picker],[:TFT,:AD],Float64)

const N_init = 500
const p_corr = 0.05
const dtype = Float64
const cull_freq = 5
const rounds = 50
const reruns = 5000
const cull_amount = 0.05


const TFTs = [TFT() for i in 1:N_init]
const ADs = [random_picker(0.0) for i in 1:N_init]

const N_p = 5
const pvec = LinRange(0.0,0.5,N_p)
const histories = Vector{Matrix{Float64}}([])

for p in pvec
    model = plot_builder(copy(TFTs),copy(ADs))

    shape_history = StandardRun!(model,rounds,reruns,cull_freq,cull_amount,axelrod_payout,p,dtype)
    push!(histories,shape_history)
end

function colorer1(index::T, N_max::T) where T<:Integer
    return RGB(0.2,index/N_max,1.0)
end

function colorer2(index::T, N_max::T) where T<:Integer
    return RGB(index/N_max,1.0, 0.2)
end
const fontsiz = 5
x = @views plot(histories[1][1,:], label = "Number of TFT agents for p = $(pvec[1])", xlabel = "Iteration of 'culling'", ylabel = "Number of Agents",
color = colorer1(1,N_p), title = "1000 Agent sim", dpi = 1500, legendfontsize = fontsiz)
@views plot!(x,histories[1][2,:], label = "Number of AD agents for p = $(pvec[1])", color = colorer2(1,N_p), legendfontsize = fontsiz)

for i in 2:N_p
    @views plot!(x,histories[i][1,:], label = "Number of TFT agents for p = $(round(pvec[i],digits = 2))", color = colorer1(i,N_p), legendfontsize = fontsiz)
    @views plot!(x,histories[i][2,:], label = "Number of AD agents for p = $(round(pvec[i],digits = 2))", color = colorer2(i,N_p), legendfontsize = fontsiz)
end

display(x)

