Instead of the intuitive weighting, a bayesian clustering was applies to determine the best weights maximizing the silhouette score.

The intuitive formula:

$$0.8 * \text{geographic distance} + 0.2 *(1 - \text{name similarity})$$

Based on the bayesian optimization the new formula for the stop clustering is:

$$0.0996 * \text{geographic distance} + 0.9004 *(1 - \text{name similarity})$$

I other words, the name similarity should dominate the clustering for Helsinki.
