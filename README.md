# project_axelrod
Analysing iterated prisoner's dilemma with (ambiguous) communication. 

In Robert Axelrod's original tournament and subsequent ones, agents were assumed to have both perfect memory and perfect access to information: to put it into the original framework of the iterated prisoner's dilemma, this meant that that the 'guards' have always correctly informed the prisoner's of each other's actions.

Reality often does not have access to perfect communication channels: information other than what is observable in an agent's local vicinity may be assumed to be 'corrupted' with a certain probability $p$. While agents retain perfect memory of their own actions, they receive incorrect and conflicting recounts of the actions of others.

In this project, we examine the simplest case of this hypotethical scenario: agent with perfect memeory of their own actions, but who rely entirely on external sources to receive information on the actions of others. If they encounter conflicting information, they will accept the latest informations batch as ground truth. 

The project aims to examine how ensemble simulations evolve as a function of $p$, while introducing simple learning agents that may instead develop strategies on their own. 




