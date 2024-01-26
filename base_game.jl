
module base_game
    sample(items, weights) = items[findfirst(cumsum(weights) .> rand())]

    function evaluate_game(p1_defect::Float64,p2_defect::Float64,
        CC::Float64 = 3.0, DD::Float64 = 1.0, 
        CD::Float64 = 5.0, DC::Float64 = 0.0)

        value_table = Array{Float64}([CC CD;
                                    DC DD])

        #evalute stochacity
        p1_probs = Array{Float64}([1-p1_defect, p1_defect])
        p2_probs = Array{Float64}([1-p2_defect, p2_defect])
        indeces = Array{Int64}([1, 2])

        p1_strat = sample(indeces, p1_probs)
        p2_strat = sample(indeces, p2_probs)

        #get points

        p1_point = value_table[p2_strat, p1_strat]
        p2_point = value_table[p1_strat, p2_strat]

        return [p1_point, p2_point]
    end

    function convert_hot_to_prob(hotvector::Vector{Int64})
        prob = convert(Float64,hotvector[2])
        return prob 
    end

    function clash_strategies_shallow_past(strat1,strat2,number_of_steps::Int64 = 100)
        hot1 = strat1([0,0,1])
        hot2 = strat2([0,0,1])
        
        score = Array{Float64}([0.0,0.0])
        for i in 1:number_of_steps-1
            p1 = convert_hot_to_prob(hot1)
            p2 = convert_hot_to_prob(hot2)
            rewards = evaluate_game(p1,p2)
            score += rewards
            hot1 = strat1(hot2)
            hot2 = strat2(hot1)
        
        end
        return score
    end



    function clash_strategies_deep_past(strat1,strat2, number_of_steps::Int64 = 100, N_past1::Int64 = 20, N_past2::Int64 = 20)

        hot1 = [[0,0,1] for i in 1:N_past2+1]
        hot2 = [[0,0,1] for i in 1:N_past1+1]

        next_hot_1 = strat1(hot2)
        next_hot_2 = strat2(hot1)

        hot1[N_past2+1] = next_hot_1
        hot1[N_past1+1] = next_hot_2

        score = Array{Float64}([0.0,0.0])

        for i in 1:number_of_steps-1
            p1 = convert_hot_to_prob(next_hot_1)
            p2 = convert_hot_to_prob(next_hot_2)
            rewards = evaluate_game(p1,p2)
            score += rewards
            
            next_hot_1 = strat1(hot2)
            next_hot_2 = strat2(hot1)

            for index1 in 1:N_past2
                hot1[index1] =  hot1[index1+1]         
            end

            for index2 in 1:N_past1
                hot1[index2] =  hot2[index2+1]         
            end
            
            hot1[N_past2 + 1] = next_hot_1
            hot2[N_past1 + 1] = next_hot_2

        end 

        return score
    end  

    
 
end