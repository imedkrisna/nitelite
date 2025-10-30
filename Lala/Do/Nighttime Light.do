/*==============================================================================
|                             Nighttime Light and GDRP                         |
|------------------------------------------------------------------------------|
|  Written by : Meizahra Afidatie                                              |
|  Created    : October 2025                                                   |
|------------------------------------------------------------------------------|
|  Source     :                                                                |
==============================================================================*/

***********
*DATA PATH*
***********

gl user = c(username)
*path lala*	
if "$user" == "meizahra"{
	gl path "/Users/meizahra/Documents/work/National Economic Council (NEC)"
	}

gl folder	"$path/Nighttime Light"
gl data 	"$folder/raw"
gl output 	"$folder/dat"
gl reg		"$folder/reg"		
gl do	 	"$folder/Do"		

set more off

*-------------------------------------------------------------------------------
* Cleaning GDRP
*-------------------------------------------------------------------------------

*----- Nominal GDRP Data -----*
import excel "$data/PDRB Seluruh Provinsi ADHK 2010-2025.xlsx", sheet("Level") firstrow clear

reshape long year_, i(prov) j(period, string)
ren year_ pdrb
gen year = substr(period, 1,4)
gen quarter = substr(period, 6, 7)
destring year quarter, replace
encode period, gen(period_num)


gen yr = real(substr(period,1,4))
gen mon = real(substr(period,6,.))      // 3,6,9,12
gen qnum = mon/3                         // 1,2,3,4
gen period2 = yq(yr, qnum)
format period2 %tq

tempfile nominal
save `nominal'

*----- Growth GDRP Data -----*
import excel "$data/PDRB Seluruh Provinsi ADHK 2010-2025.xlsx", sheet("Growth") firstrow clear
reshape long year_, i(prov) j(period, string)
ren year_ growth_qoq
gen year = substr(period, 1,4)
gen quarter = substr(period, 6, 7)
destring year quarter, replace

drop if prov==.
tempfile growth
save `growth'
 
merge 1:1 prov year quarter using `nominal'
drop _m

tempfile pdrb
save `pdrb'

*-------------------------------------------------------------------------------
* Cleaning NTL
*-------------------------------------------------------------------------------
import excel "$data/ntl_monthly_long.xlsx", sheet("Sheet1") firstrow clear	

gen quarter=.
replace quarter=3 if inrange(month, 1, 3)
replace quarter=6 if inrange(month, 4,6)
replace quarter=9 if inrange(month, 7,9)
replace quarter=12 if inrange(month, 10, 12)

collapse (mean) ntl_radiance, by(prov year quarter)

merge 1:1 prov year quarter using `pdrb' //Merging NTL with GDRP

*----- Additional Vars -----*
g		q1=0
replace	q1=1 if quarter==3 

gen		q2=0
replace	q2=1 if quarter==6

gen 	q3=0
replace	q3=1 if quarter==9 //Quarter dummy

g		covid=0
replace	covid=1 if inrange(year, 2020, 2022) //Covid dummy

g		scarring=0
replace scarring=1 if inrange(year, 2022, 2025) //Scarring dummy

g 		ln_ntl = ln(ntl_radiance)
g 		ln_pdrb = ln(pdrb) //ln variables

gen pulau = .
    replace pulau = 1 if inrange(prov,11,21)
    replace pulau = 2 if inrange(prov,31,36)
    replace pulau = 3 if inrange(prov,51,53)
    replace pulau = 4 if inrange(prov,61,65)
    replace pulau = 5 if inrange(prov,71,76)
    replace pulau = 6 if inrange(prov,81,82)
    replace pulau = 7 if inrange(prov,91,97) //Island Variables

    label define pulau_lbl  1 "SUMATERA" 2 "JAWA" 3 "BALI & NUSA TENGGARA" ///
                            4 "KALIMANTAN" 5 "SULAWESI" 6 "MALUKU" 7 "PAPUA"
    label values pulau pulau_lbl
	

*-------------------------------------------------------------------------------
* Analysis
*-------------------------------------------------------------------------------
gl x "ntl_radiance"
gl x2 "ln_ntl"

gl y "pdrb" 
gl y2 "ln_pdrb"
gl co "covid"
gl sc "scarring"

*----- OLS -----* 
	** Generate Residual
reg $x2 $y2, r 
predict e, resid
reg $x2 $y2
predict e_std, rstandard

reg $x2 $y2, r 
outreg2 using "$reg/ntl_analysis.xls", replace addtext(OLS, plain) label
reg $x2 $y2 $co, r 
outreg2 using "$reg/ntl_analysis.xls", append addtext(OLS, Covid) label
reg $x2 $y2 $sc, r 
outreg2 using "$reg/ntl_analysis.xls", append addtext(OLS, Scarring) label

*----- FE -----*
xtset prov period_num
xtreg $y2 $x2 covid, fe cluster(prov)
predict e_fe, e
outreg2 using "$reg/ntl_analysis.xls", append addtext(FE, plain) label
xtreg $x2 $y2 $co, fe cluster(prov)
outreg2 using "$reg/ntl_analysis.xls", append addtext(FE, Covid) label
xtreg $x2 $y2 $sc, fe cluster(prov)
outreg2 using "$reg/ntl_analysis.xls", append addtext(FE, Scarring) label

*----- TWFE -----* 
xtreg $x2 $y2  i.year, fe cluster(prov) 
outreg2 using "$reg/ntl_analysis.xls", append addtext(TWFE, plain) label
xtreg $x2 $y $co i.year, fe cluster(prov) 
outreg2 using "$reg/ntl_analysis.xls", append addtext(TWFE, Covid) label
xtreg $x2 $y $sc i.year, fe cluster(prov) 
outreg2 using "$reg/ntl_analysis.xls", append addtext(TWFE, Scarring) label

sa "$output/ntl_gdrp.dta", replace
export excel "$output/ntl_gdrp.xls",  firstrow(variables) replace

