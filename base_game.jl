""" Basic Functions for interated Prisoner's Dilemma Game """

function play_prisoners_dilemma(player1_strategy, player2_strategy, num_rounds)

    """
    Simulates a repeated Prisoner's Dilemma game for a specified number of rounds.

    # Arguments
    - `player1_strategy::Function`: A function representing Player 1's strategy. The function takes two arguments, the current payoffs of Player 1 and Player 2.
    - `player2_strategy::Function`: A function representing Player 2's strategy. The function takes two arguments, the current payoffs of Player 2 and Player 1.
    - `num_rounds::Int`: The number of rounds to simulate the game.

    # Returns
    - A tuple `(player1_payoff, player2_payoff)` representing the total payoffs for Player 1 and Player 2 after all rounds.

    # Example
    ```julia
    result = play_prisoners_dilemma(always_cooperate, always_defect, 10)
    println("Player 1 payoff: ", result[1])
    println("Player 2 payoff: ", result[2])
    """
    player1_payoff = 0
    player2_payoff = 0

    for round in 1:num_rounds
        # Players make decisions
        player1_decision = player1_strategy(player1_payoff, player2_payoff)
        player2_decision = player2_strategy(player2_payoff, player1_payoff)

        # Update payoffs based on decisions
        player1_payoff += payoff(player1_decision, player2_decision)[1]
        player2_payoff += payoff(player2_decision, player1_decision)[2]
    end

    return player1_payoff, player2_payoff
end

function payoff(decision1, decision2)
    if decision1 == "cooperate" && decision2 == "cooperate"
        return (3, 3)  # Both players cooperate, mutual cooperation
    elseif decision1 == "cooperate" && decision2 == "defect"
        return (0, 5)  # Player 1 cooperates, player 2 defects
    elseif decision1 == "defect" && decision2 == "cooperate"
        return (5, 0)  # Player 1 defects, player 2 cooperates
    elseif decision1 == "defect" && decision2 == "defect"
        return (1, 1)  # Both players defect, mutual defection
    end
end

# Example of strategies
function always_cooperate(payoff1, payoff2)
    return "cooperate"
end

function always_defect(payoff1, payoff2)
    return "defect"
end

# Example: Play the game with two strategies
num_rounds = 100
result = play_prisoners_dilemma(always_defect, always_defect, num_rounds)

println("Player 1 payoff: ", result[1])
println("Player 2 payoff: ", result[2])
