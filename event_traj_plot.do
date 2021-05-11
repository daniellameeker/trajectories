/**
Estimate trajectory model using the traj procedure modified from Duncan's code
Original code sourced from Terry's programs folder

@author - Aniketh Manjunath
@version - 5.0
@start_date - 12/12/2020
@end_date - 03/10/2021
**/


/*
NOTE: Run find_opt_grp.do first

-----------------------------------------
| EVENT		|	OPTIMAL GRP #	|
-----------------------------------------
| age65		|		5	|
| chf1		|		3	|
| copd		|		4	|
| dementia	|		4	|
| fall		|		5	|
| mp_icu	|		4	|
| mp_2hosp65	|		5	|
| nurshome	|		2	|
| surgery	|		3	|
-----------------------------------------
*/

set more off

local event = "mp_2hosp65"
local num_grp = "5"
local orders 3 3 3 3 3
local init_var = "n_init_age init_stroke init_hearte init_lunge init_cancre init_diabe init_hibpe"
local risk_var = "n_init_age ragender race"

use /schhome/users/anikethm/Trajectories/Data/`event'.dta, clear

traj, model(cnorm) var(hui3ou*) indep(obsint*) order(`orders') refgroup(1) min(-0.36) max(1.0) risk(`risk_var')
trajplot, model(1) ytitle("`event' HUI3OU") xtitle("Time from event (year)") ci

local num_groups = e(numGroups1)
mat group_mem = e(groupSize1)

local ref_grp = -1
local max_auc = -1

egen auc = rowtotal(hui3ou*)

* plot edits
forvalues i = 1(1)`num_groups' {

	quietly sum auc if _traj_Group == `i'
	
	if (r(mean) > `max_auc') {
		local max_auc = r(mean)
		local ref_grp = `i'
	}
	local x = group_mem[1, `i'] / 25
	gr_edit .plotregion1.plot`i'.style.editstyle line(width(+`x')) editcopy
}

di "All Groups"
sum `init_var' if !missing(_traj_Group)
tab ragender if !missing(_traj_Group), nolabel
tab race if !missing(_traj_Group), nolabel

* compute stats
forvalues i = 1(1)`num_groups' {
	
	di "Group # `i'"
	
	sum `init_var' if _traj_Group == `i'
	
	tab ragender if _traj_Group == `i', nolabel
	tab race if _traj_Group == `i', nolabel
}

di "Max AUC = Group # `ref_grp'"
traj, model(cnorm) var(hui3ou*) indep(obsint*) order(`orders') refgroup(`ref_grp') min(-0.36) max(1.0) risk(`risk_var')


graph save Graph "/schhome/users/anikethm/Trajectories/Output/Traj_Plot/`event'.gph",replace
graph export "/schhome/users/anikethm/Trajectories/Output/Traj_Plot/`event'.png",replace
