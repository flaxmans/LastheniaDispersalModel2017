#Packages
library(statmod)

# Parameters etc.
meta_cols <- 3 
meta_col_names <- c('generation','individual_ID','location')  
ploidy <- 2
disp_a_loci <- 5
disp_b_loci <- 5
env_loci <- 5
neut_loci <- 5
total_genome_length <- ploidy*(disp_a_loci+disp_b_loci+env_loci+neut_loci)
Rmax_good <- 50 
Rmax_bad <- 0
nstar <- 100
p_mut <- 0.00001 
sigma_mut <- 0.001 
nbhd_width <- 1 
env_length <- 10 
t_max <- 100
env_change_speed <- 0.1
init_loc_mean <- 0
k <- 1
disp_a_allele <- 1 
disp_b_allele <- 2
env_allele <- 0

parameters <- paste("meta_cols: ", meta_cols, ", ploidy: ", ploidy, ", disp_a_loci: ", disp_a_loci, ", disp_b_loci: ", disp_b_loci, ", env_loci: ", env_loci, ", neut_loci: ", neut_loci, ", Rmax_good: ", Rmax_good, ", Rmax_bad: ", Rmax_bad, ", nstar: ", nstar, ", p_mut: ", p_mut, ", sigma_mut: ", sigma_mut, ", nbhd_width: ", nbhd_width, ", env_length: ", env_length, ", t_max: ", t_max, ", init_loc_mean: ", init_loc_mean, ", k: ", k, ", disp_a_allele: ", disp_a_allele, ", disp_b_allele: ", disp_b_allele, ", env_allele: ", env_allele)
write(parameters, file = "/Users/Courtney/Documents/Rotation 3 - Melbourne & Flaxman Labs/Simulation Practice Files/parameters_from_sim.txt")

# Derived Constants
disp_a_locus_1 <- meta_cols+1
disp_a_locus_last <- disp_a_locus_1 + disp_a_loci*ploidy - 1
disp_b_locus_1 <- disp_a_locus_last + 1
disp_b_locus_last <- disp_b_locus_1 + disp_b_loci*ploidy - 1
env_locus_1 <- disp_b_locus_last + 1
env_locus_last <- env_locus_1 + env_loci*ploidy - 1
neut_locus_1 <- env_locus_last + 1
neut_locus_last <- neut_locus_1 + neut_loci*ploidy - 1

# ---------------------------------------------------------
# Now Simulate!

current_population <- make_pop(0, nstar, init_loc_mean, nbhd_width, disp_a_allele, disp_b_allele, env_allele, meta_cols, meta_col_names, ploidy, disp_a_loci, disp_b_loci, env_loci, neut_loci)
write_name <- paste("/Users/Courtney/Documents/Rotation 3 - Melbourne & Flaxman Labs/Simulation Practice Files/sim_dispevoonly_gen_", 0, ".csv", sep="")
write.csv(current_population, write_name)

for (t in 1:t_max){
	# (1) Reproduction
	# (2) Parental Death
	# (3) Dispersal (but this is density independent)
	# (3) F1 Reproduction
	
	# (1) & (2) - offspring dispersal is built into the make_offspring function. 
	print(paste("generation: ",t))
	
	next_generation <- make_popn_dataframe(t, meta_cols, meta_col_names, ploidy, disp_a_loci, disp_b_loci, env_loci, neut_loci)
	next_generation[c(1:(nstar*10)),] <- 0
	next_gen_ID_tracker <- 1
	
	for (i in 1:nrow(current_population)){
		mom <- current_population[i,]
		Rmax <- environment(mom$location, Rmax_good, Rmax_bad, t, env_length, env_change_length)
		mates <- current_population[-i,]
		n_offspring <- reproduce(mom, nstar, Rmax, k, mates)
		dads_list <- matefinder1D(n_offspring, mom, mates, nbhd_width)
		dads_list_reformat <- convert_dads_list(dads_list)
		
		if (n_offspring > 0) {
			for (n in 1:n_offspring){
				dad <- dads_list_reformat[n]
				offspring <- make_offspring(mom, dad, t, next_gen_ID_tracker)
				next_generation[next_gen_ID_tracker,] <- offspring
				next_gen_ID_tracker <- next_gen_ID_tracker + 1
			}
		}
	}

	next_generation <- next_generation[next_generation[,2]>0,]
	print(paste("pop size: ",dim(next_generation)))
	current_population <- next_generation

	# write the parental generation to file before erasing them (annuals)
	write_name <- paste("/Users/Courtney/Documents/Rotation 3 - Melbourne & Flaxman Labs/Simulation Practice Files/Disp_",t,".csv", sep="")
	write.csv(current_population, write_name)
	
	if (nrow(current_population) == 0){
		print("extinction!")
		break
	}
}