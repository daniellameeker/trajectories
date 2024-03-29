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

-----------------------------------------------------------------
| EVENT		|	OPTIMAL GRP #	|	REF GRP #	|
-----------------------------------------------------------------
| age65		|		5	|		4	|
| chf1		|		3	|		3	|
| copd		|		4	|		4	|
| dementia	|		4	|		4	|
| fall		|		5	|		5	|
| mp_icu	|		4	|		4	|
| mp_2hosp65	|		5	|		5	|
| nurshome	|		2	|		2	|
| surgery	|		3	|		3	|
-----------------------------------------------------------------

-----------------------------------------------------------------
| EVENT		|   NEW OPTIMAL GRP #	| 	NEW REF GRP #	|
-----------------------------------------------------------------
| age65		|		8	|		5	|
| chf1		|		2	|		2	|
| copd		|		5	|		4	|
| dementia	|		2	|		2	|
| fall		|		3	|		3	|
| mp_icu	|		2	|		2	|
| mp_2hosp65	|		4	|		4	|
| nurshome	|		2	|		2	|
| surgery	|		4	|		4	|
-----------------------------------------------------------------
*/

set more off

local event = "age65"
local orders 3 3 3 3 3 3 3 3
local ref_grp = "5"
local init_var = "n_init_age init_stroke init_hearte init_lunge init_cancre init_diabe init_hibpe"
local risk_var = "n_init_age ragender race"

* Use Data subfolder for optimal group # that excludes data with hui=0 at t=0 
* Else use new optimal group # data in NewData subdirectory
use /schhome/users/anikethm/Trajectories/NewData/`event'.dta, clear
traj, model(cnorm) var(hui3ou*) indep(obsint*) order(`orders') refgroup(1) min(-0.36) max(1.0) risk(`risk_var')
mlogit _traj_Group init_age ragender race, b(`ref_grp')
