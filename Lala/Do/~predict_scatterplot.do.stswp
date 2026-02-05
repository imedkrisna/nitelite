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
	gl path "/Users/meizahra/Documents/nitelite"
	}

gl folder	"$path/Lala"
gl data 	"$folder/raw"
gl output 	"$folder/dat"
gl reg		"$folder/reg"		
gl do	 	"$folder/Do"	
gl fig 		"$folder/fig"	

set more off

use "$output/ntl_gdrp.dta", clear

*-------------------------------------------------------------------------------
* Scatterplot
*-------------------------------------------------------------------------------

levelsof prov, local(provs)

local scat error_ols error_ols_co error_ols_sc error_fe error_fe_co error_fe_sc error_twfe error_twfe_co error_twfe_sc error_dfe error_dfe_co error_dfe_sc
		   

levelsof prov, local(provs)

foreach x of local scat {

    local plots
    
    foreach p of local provs {
        local plots `plots' ///
        (scatter `x' ln_ntl if year==2024 & prov==`p')
    }

    twoway `plots', ///
        title("`x' vs ln_ntl") ///
        legend(off) ///
		name(`x', replace)
		graph export "$fig/`x'.png", replace
}


graph combine error_ols error_ols_co error_ols_sc, ///
    cols(2) imargin(tiny) ///
    graphregion(color(white))
	graph export "$fig/combine_ols.png", replace

	graph combine error_fe error_fe_co error_fe_sc, ///
    cols(2) imargin(tiny) ///
    graphregion(color(white))
	graph export "$fig/combine_fe.png", replace
	
graph combine error_twfe error_twfe_co error_twfe_sc, ///
    cols(2) imargin(tiny) ///
    graphregion(color(white))
		graph export "$fig/combine_twfe.png", replace
		
graph combine error_dfe error_dfe_co error_dfe_sc, ///
    cols(2) imargin(tiny) ///
    graphregion(color(white))
		graph export "$fig/combine_dfe.png", replace		


