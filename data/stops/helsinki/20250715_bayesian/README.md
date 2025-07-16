Instead of the intuitive weighting, a bayesian clustering was applies to determine the best weights maximizing the silhouette score.

The intuitive formula:
$$0.7 * \text{geographic\_distance} + 0.3 *(1 - \text{name\_similarity})$$

Based on the bayesian optimization the new formula for the stop clustering is:
$$0.00013 * \text{geographic\_distance} + 0.99987 *(1 - \text{name\_similarity})$$

I other words, the name similarity should dominate the clustering.
