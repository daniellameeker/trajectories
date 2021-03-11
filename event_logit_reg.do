/**
Predictive model using Logistic Regression 
Original code sourced from Terry's programs folder

@author - Aniketh Manjunath
@version - 1.0
@start_date - 02/12/2020
@end_date - 02/12/2021
**/


/*
NOTE: Run find_opt_grp.do first

-----------------------------------------
| EVENT		|	OPTIMAL GRP #	|
-----------------------------------------
| age65		|		4	|
| chf1		|		4	|
| copd		|		3	|
| dementia	|		4	|
| fall		|		4	|
| mp_icu	|		4	|
| mp_2hosp65	|		2	|
| nurshome	|		3	|
| surgery	|		4	|
-----------------------------------------
*/

set more off

local event = "surgery"
local orders 3 3 3 3
local ref_grp = "4"
local init_var = "init_age init_stroke init_hearte init_lunge init_cancre init_diabe init_hibpe"
local risk_var = "init_age ragender race"

use /schhome/users/anikethm/Trajectories/Data/`event'.dta, clear
traj, model(cnorm) var(hui3ou*) indep(obsint*) order(`orders') refgroup(1) min(-0.36) max(1.0) risk(`risk_var')
mlogit _traj_Group init_age ragender race, b(`ref_grp')
