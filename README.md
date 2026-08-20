# SURP_2026
Fractional Anisotropy Differences in Youth With Psychosis Spectrum Symptoms in the Toronto Adolescent and Youth (TAY) Cohort Study

Student: Kelei Xiao, Supervisors: Erin Dickie, Stephanie Ameis

Background:
Psychosis spectrum symptoms (PSS) are subclinical psychotic experiences which may be a risk factor for the development of clinical psychosis. Studies have demonstrated that adults with schizophrenia spectrum disorders may have age-related differences in fractional anisotropy (FA), a measure of white matter microstructure. However, it is unclear whether similar patterns of FA deviations exist in youth with PSS.

Hypothesis:
Youth with PSS will have lower global FA values compared to non-PSS youth. 

Methods: 
Diffusion magnetic resonance imaging scans were collected in the ongoing Toronto Adolescent and Youth (TAY) CAMH Cohort study on help-seeking youth aged 11-24. 635 TAY participants (age=18.26±3.62; Female=408; PSS=325) were preprocessed using QSIPrep. A linear regression model compared FA in PSS and non-PSS participants using age, sex and motion as covariates.

Results:
There was no significant difference in PSS vs non-PSS youth for average FA (d=-0.09; t(630)=-1.17; p=0.24). However, in exploratory tract-level analyses, we observed a sex-by-PSS interaction in the external capsule (t(629)=2.30; p=0.022), indicating that PSS was associated with increased FA in males (d=0.22; t(223)=1.68; p=0.095), but not in females (d=−0.16; t(404)=-1.57; p=0.118).

Conclusions:
Though there was no significant effect of PSS status on global FA values in our analyses, a significant sex-by-PSS effect was found. Future research should aim to further explore the role of sex as a potential moderator in tract-level FA differences among youth with PSS.

-----------------------------------------------------------------------------------

Date Processed: 06-01-2026 to 08-20-2026

Dataset: The .csv files utilized in this project are available in /projects/kexiao/SURP_2026.


Contact People:

Principal Investigator: Erin Dickie, Stephanie Ameis

Primary: Kelei Xiao - kelei131415@gmail.com

Others: Jiya Shah - jiya.shah@mail.utoronto.ca, Shane Cleary - Shane.cleary@camh.ca

Citation: 

System:

Dependencies: None

RanFrom: SCC

Commands/Scripts:

Model: Primary outcomes of study; outputs effect sizes for PSS effects on global FA, adjusted by age, sex, and motion during baseline scan.

exploratory_outcomes: Exploratory outcomes of study; outputs tract-level sex-by-PSS effect sizes.

ggseg: plots sex-by-PSS effect sizes using ggseg on a visual.

plots/EC_boxplot: makes a boxplot for the exploratory outcomes for external capsule only, as it was the only statistically significant effect size.

plots/scatter_plot: makes a scatter plot for the primary outcomes of the study.

Quality Control:

Primary: Kelei Xiao - kelei131415@gmail.com, John Lio - johnliosb@gmail.com

QCfile: ./projects/kexiao/QC_output

Data Requests/Publications: N/A
