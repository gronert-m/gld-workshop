# AI Exposure and Complementarity Scores

This folder provides documentation and occupational mappings for linking artificial intelligence (AI) exposure and potential complementarity scores to Global Labor Database (GLD) data. These materials support the hands-on GLD workshop at the Jobs and Development Conference in Hong Kong on October 8, 2026.

The scores draw on the AI Occupational Exposure measure developed by **Felten, Raj, and Seamans (2021)** and the complementarity framework developed by **Pizzinelli, Panton, Tavares, Cazzaniga, and Li (2023)**. Please cite both papers when using these materials.

## Sources and interpretation

**AI Occupational Exposure (AIOE)** measures the relative exposure of occupations to AI. Felten et al. (2021) construct it by linking AI applications to occupational abilities described in the US Occupational Information Network (O*NET). Higher scores indicate greater exposure. Exposure alone does not distinguish whether AI is likely to substitute for workers or complement their work.

**Potential complementarity (θ)** captures occupational characteristics that may favor the use of AI alongside human workers. Pizzinelli et al. (2023) construct this measure using O*NET information on work contexts and occupational preparation requirements. Higher scores indicate greater potential complementarity.

**Complementarity-adjusted AI Occupational Exposure (C-AIOE)** combines exposure with potential complementarity. In the framework of Pizzinelli et al. (2023), greater complementarity reduces adjusted exposure. Higher C-AIOE values indicate greater relative potential for substitution, rather than a measured probability of job loss.

These measures describe relative differences across occupations. They are not estimates of the percentage of tasks that can be automated, the number of jobs that will disappear, or actual AI adoption.

## Provenance and permission

The AI exposure and complementarity mappings were shared with the GLD team by the authors of Pizzinelli et al. (2023).

The authors agreed to public inclusion of their classification alongside the Felten et al. classification in the workshop repository, subject to citation of both papers and inclusion of the disclaimer below.

### Disclaimer for the complementarity classification

> The authors of the paper are solely responsible for this data. This data should not be interpreted as the official view of the International Monetary Fund, its Management, or its Board.

## Linking the scores to GLD

The mappings are supplementary occupation-level data, provided separately from the standard GLD datasets.

Before linking them to a GLD survey:

1. **Check the occupational classification and level of detail.** The survey and mapping must use compatible classification versions and code lengths. Identical-looking codes from different classifications are not necessarily equivalent.
2. **Document any conversion or aggregation.** Pizzinelli et al. (2023) describe converting US SOC 2010 scores to ISCO-08 using a Bureau of Labor Statistics crosswalk and taking simple averages where multiple source occupations map to the same destination occupation. Any additional workshop transformations should be documented separately.
3. **Check the merge.** Confirm that the mapping has one observation per intended merge key, preserve occupational codes correctly, and report unmatched observations. Missing scores should not be treated as zero exposure.
4. **Use appropriate survey weights.** Estimates of employment shares or average exposure should reflect the survey’s weighting and design.

If constructing “high” and “low” exposure or complementarity groups, document the thresholds, reference population, and weighting used. These choices affect the resulting employment shares.

## Limitations

The underlying occupational characteristics are based on US O*NET data. Applying them across countries assumes that those characteristics provide a useful approximation of local occupations; tasks, technology use, and working conditions may differ.

The scores reflect the methodologies and technology coverage of the cited studies. They should not be interpreted as a continuously updated assessment of AI capabilities or as measures specific to the latest generative AI systems.

## Required citations

Felten, E., Raj, M., & Seamans, R. (2021). Occupational, industry, and geographic exposure to artificial intelligence: A novel dataset and its potential uses. *Strategic Management Journal, 42*(12), 2195–2217. [https://doi.org/10.1002/smj.3286](https://doi.org/10.1002/smj.3286).

Pizzinelli, C., Panton, A., Tavares, M. M., Cazzaniga, M., & Li, L. (2023). *Labor Market Exposure to AI: Cross-country Differences and Distributional Implications*. [IMF Working Paper No. 23/216. International Monetary Fund.](https://www.imf.org/-/media/files/publications/wp/2023/english/wpiea2023216-print-pdf.pdf)
