# project_axelrod
Analysing iterated prisoner's dilemma with (ambiguous) communication. 

In Robert Axelrod's original tournament and subsequent ones, agents were assumed to have both perfect memory and perfect access to information: to put it into the original framework of the iterated prisoner's dilemma, this meant that that the 'guards' have always correctly informed the prisoner's of each other's actions.

Reality often does not have access to perfect communication channels: information other than what is observable in an agent's local vicinity may be assumed to be 'corrupted' with a certain probability $p$. While agents retain perfect memory of their own actions, they receive incorrect and conflicting recounts of the actions of others.

In this project, we examine the simplest case of this hypotethical scenario: agent with perfect memeory of their own actions, but who rely entirely on external sources to receive information on the actions of others. If they encounter conflicting information, they will accept the latest informations batch as ground truth. 

The project aims to examine how ensemble simulations evolve as a function of $p$, while introducing simple learning agents that may instead develop strategies on their own. 

## Mathematical background and defintions

TBA: reward matrix, usage of markov process for estimation, etc.

### Agents and Strategies

All agents have an associated strategy: such a strategy is a function of their own actions (which they always remember and can access perfectly), the _perceived_ action of the enemy agent (in which each action is reversed by some probability _p_ at _every iteration_, which we call as the corruption/noise level) and the current index of the game. We emphasize that this means that an agent _may not retain a consistent history of perceived, enemy actions_. 

An agent itself describes all auxillary parameters that its strategy might entail: an example is a stochastic agent with parameter 0<_q_<1 that will cooperate with probability _q_, regardless of enemy action. Agents may be arbiteraly complex, but they may not _directly_ remember enemy, perceived actions between iterations: they however may use auxillary parameters generated from 'snapshots' of enemy actions. An example would be an agent that tries to estimate the enemy agent's cooperation probability. 

### 1-depth strategies

1-depth strategies refer to strategis that may only access the most recent enemy actions. An example would be the tit-for-that agent (TFT), the Pavlov agent (cooperates if the previous action with the enemy was favourable, i.e. defection-cooperation or cooperation-cooperation) and a generalized stochastic agent (cooperates with probability q: two special cases are the All-defector and All-Cooperator agents). 

Example result: 

![TFTvsAD](https://github.com/ArchHem/project_axelrod/blob/main/examp_plot.png)



