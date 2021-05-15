/**
Estimate optimal number of trajectories using the traj procedure

@author - Aniketh Manjunath
@version - 3.0
@start_date - 01/06/2021
@end_date - 05/11/2021
**/

/*
NOTE: Run gen_sparse_hui.do first
*/

* list of all events
local event = "age65 chf1 copd dementia fall mp_icu mp_2hosp65 nurshome surgery" 

* initial condition variables
local init_var = "init_age init_stroke init_hearte init_lunge init_cancre init_diabe init_hibpe"

* risk variables
local risk_var = "n_init_age ragender race"

local size : word count `event'
mat A = J(1, `size', 1)
local i 1

foreach var in `event' { 
	
	local orders 3
	
	use /schhome/users/anikethm/Trajectories/NewData/`var'.dta, clear
	
	* null hypothesis
	traj, model(cnorm) var(hui3ou*) indep(obsint*) order(`orders') refgroup(1) min(-0.36) max(1.0)
	
	local h0 = e(BIC_N_data)
	
	* find optimal polynomial upto degree 9
	forvalues n = 1 / 9 {
	
		local orders `orders' 3
		
		traj, model(cnorm) var(hui3ou*) indep(obsint*) order(`orders') refgroup(1) min(-0.36) max(1.0) risk(`risk_var')
		
		local num_groups = e(numGroups1)
		mat group_mem = e(groupSize1)
		
		* cf. https://www.andrew.cmu.edu/user/bjones/refpdf/ref1.pdf (390)
		local h1 = e(BIC_N_data)
		
		
		local delta = 2 * (`h1' - `h0')
		
		if (`delta' <= 10) continue, break
		
		local h0 = `h1'
		mat A[1, `i'] = A[1, `i'] + 1
	}
	local i = `i' + 1
}

local i 1

* Display Optimal # of groups for each event
foreach var in `event' {
	local a =  A[1, `i']
	di "`var' == `a'"
	local i = `i' + 1
}
