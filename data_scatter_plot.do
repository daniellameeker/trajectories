/**
Plot Real-Trajectories given an event or list of events

@author - Aniketh Manjunath
@version - 3.0
@start_date - 12/26/2020
@end_date - Ongoing
**/

// age65 chf1 copd dementia fall mp_icu mp_2hosp65 nurshome surgery

set more off

* list of all events
local event = "age65 chf1 copd dementia fall mp_icu mp_2hosp65 nurshome surgery"

foreach var in `event' {
	
	* load DEID dataset
	use /schhome/users/anikethm/Trajectories/DEID/`var'_analytic_file.dta, clear

	* HUI3 imputed scores are only available after year 2000
	keep if year(obsint_beg) >= 2000

	* claims variables are only available through 2008
	keep if year(obsint_end) <= 2008

	* recenter data
	bysort hhidpn (obsint): replace obsint = _n - 1
	
	* drop if # follow-up < 8
	// bysort hhidpn (obsint): egen num_followup = sum(iwend != .)
	// drop if num_followup < 8 & death == .
	replace hui3ou = 0 if death == 1

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

	merge m:m hhidpn using "/schhome/users/anikethm/Trajectories/DEID/hrslong.dta", keepusing(ragender race rabmonth rabyear)
	keep if _merge==3 | _merge==1
	
	* compute missing init_age from DOB
	gen rabday = 15
	gen birthday = mdy(rabmonth,rabday,rabyear) 

	bysort hhidpn (obsint): gen n_init_age = (obsint_beg - birthday) / 365.25 if obsint==0
	bysort hhidpn (obsint): replace n_init_age = n_init_age[1] if missing(n_init_age)

	keep if !missing(n_init_age) & n_init_age >= 65
	
	* --> quietly suppresses all terminal output for the duration of command
	bysort hhidpn obsint: gen dup = cond(_N==1, 0,_n)
	drop if dup != 0
	drop dup
	
	keep hhidpn hui3ou obsint

	gen obsint_tmp = obsint
	replace obsint = obsint_tmp * 90 / 365
	sort hhidpn obsint
	
	egen group = group(hhidpn)
	su group, meanonly
	
	scatter hui3ou obsint, msymbol(circle_hollow) mcolor(blue%10)
	graph export "/schhome/users/anikethm/Trajectories/Output/Scatter_Plots/`var'.png",replace
}
