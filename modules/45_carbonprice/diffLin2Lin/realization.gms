*** |  (C) 2006-2023 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/45_carbonprice/diffLin2Lin/realization.gms

*#' @description: This realization implements linearly increasing carbon price - either until 2100 or until peak year (constant or linear thereafter). Optional carbon price differentiation and quadratic phase-in can be activated via switch cm_co2_tax_spread.

*####################### R SECTION START (PHASES) ##############################
$Ifi "%phase%" == "declarations" $include "./modules/45_carbonprice/diffLin2Lin/declarations.gms"
$Ifi "%phase%" == "datainput" $include "./modules/45_carbonprice/diffLin2Lin/datainput.gms"
$Ifi "%phase%" == "postsolve" $include "./modules/45_carbonprice/diffLin2Lin/postsolve.gms"
*######################## R SECTION END (PHASES) ###############################

*** EOF ./modules/45_carbonprice/diffLin2Lin/realization.gms