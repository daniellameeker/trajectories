/**
Generate SparseHUI data for each event

@author - Aniketh Manjunath
@version - 2.0
@start_date - 02/06/2021
@end_date - 03/10/2021
**/

* list of all events
local event = "age65 chf1 copd dementia fall mp_icu mp_2hosp65 nurshome surgery"
local init_var = "init_age init_stroke init_hearte init_lunge init_cancre init_diabe init_hibpe"
local risk_var = "init_age ragender race"

foreach var in `event' {
	
	* load DEID dataset
	use /schhome/users/anikethm/TRAJ/DEID/`var'_analytic_file.dta, clear
	
	* drop if # follow-up < 8
	bysort hhidpn: egen num_followup = sum(iwend != .)
	drop if num_followup < 8 & death == .
	replace hui3ou = 0 if death == 1
	
	* HUI3 imputed scores are only available after year 2000
	keep if year(obsint_beg) >= 2000

	* claims variables are only available through 2008
	keep if year(obsint_end) <= 2008

	* for analysis of HUI3 and costs trajectory
	drop if missing(hui3ou) & missing(sum_payments)
	
	quietly bys obsint: sum sum_payments hui3ou hmoenroll hasclaims
	bys hhidpn: egen clmints = total(hasclaims)
	bys hhidpn: gen constclms = clmints == _N
	
	drop if clmints == 0
	
	* exclude anyone who ever enrolled in HMO
	bys hhidpn: egen hmoints = total(hmoenroll)

	* tab hmoints, m
	drop if hmoints > 0
	
	*** Daniella's code for sparse hui
	gen iwblock = iwend
	
	* define blocks by most recent observation
	bys hhidpn (obsint): replace iwblock=iwblock[_n-1] if missing(iwblock)

	* restart counter at each new block
	bys hhidpn iwblock (obsint): gen obssince = obsint - obsint[1]

	* because blocks are at 90 day intervals, flag every 8 observations
	gen modobs = mod(obssince, 8)

	* original hui that includes
	gen sparse_hui = hui3ou

	* if people are dead replace missing observations
	replace sparse_hui = . if modobs > 0 & hui3ou == 0
	***
	
	rename hui3ou hui3ou_old
	rename sparse_hui hui3ou
	
	merge m:m hhidpn using "/schhome/users/anikethm/TRAJ/DEID/hrslong.dta"
	keep if _merge==3 | _merge==1
	
	keep if init_age >= 65
	
	* --> quietly suppresses all terminal output for the duration of command
	bysort hhidpn obsint: gen dup = cond(_N==1, 0,_n)
	drop if dup != 0
	drop dup

	drop if hui3ou == .
	by hhidpn: gen count = _n
	by hhidpn: gen deadfirst = 1 if count == 1 & hui3ou == 0
	bysort hhidpn (deadfirst): drop if deadfirst[1]==1
	
	keep hhidpn hui3ou obsint `risk_var' `init_var'

	gen obsint_tmp = obsint
	replace obsint = obsint_tmp * 90 / 365
	sort hhidpn obsint

	reshape wide obsint hui3ou, i(hhidpn) j(obsint_tmp)
	drop if hui3ou0==0
	
	save "/schhome/users/anikethm/Trajectories/Data/`var'.dta",replace
}
