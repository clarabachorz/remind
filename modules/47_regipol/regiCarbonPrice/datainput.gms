*** |  (C) 2006-2022 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/47_regipol/regiCarbonPrice/datainput.gms

*** initialize regipol target deviation parameter
pm_emiMktTarget_dev(ttot,ttot2,ext_regi,emiMktExt) = 0;

***--------------------------------------------------
*** Emission markets (EU Emission trading system and Effort Sharing)
***--------------------------------------------------
$IFTHEN.emiMkt not "%cm_emiMktTarget%" == "off" 

*** initialize emiMkt Target parameters
  p47_targetConverged(ttot2,ext_regi) = 0;

*** initialize carbon taxes before start year 
if ( (cm_startyear gt 2005),
  Execute_Loadpoint 'input_ref' p47_taxCO2eq_ref = pm_taxCO2eq;
  Execute_Loadpoint 'input_ref' p47_taxemiMkt_init = pm_taxemiMkt;

*** copying taxCO2eq value to emiMkt tax parameter for fixed years that contain no pm_taxemiMkt value
  p47_taxemiMkt_init(ttot,regi,emiMkt)$((p47_taxCO2eq_ref(ttot,regi)) and (ttot.val le cm_startyear) and (NOT(p47_taxemiMkt_init(ttot,regi,emiMkt)))) = p47_taxCO2eq_ref(ttot,regi);

*** Initializing European ETS historical and reference prices
  loop(regi$regi_groupExt("EUR_regi",regi),
    p47_taxemiMkt_init("2005",regi,"ETS")$(cm_startyear le 2005) = 0;
    p47_taxemiMkt_init("2010",regi,"ETS")$(cm_startyear le 2010)  = 15*sm_DptCO2_2_TDpGtC;
    p47_taxemiMkt_init("2015",regi,"ETS")$(cm_startyear le 2015)  = 8*sm_DptCO2_2_TDpGtC;
***  p47_taxemiMkt_init("2020",regi,"ETS")$(cm_startyear le 2020)  = 41.28*sm_DptCO2_2_TDpGtC; !! 2018 =~ 16.5€/tCO2, 2019 =~ 25€/tCO2, 2020 =~ 25€/tCO2, 2021 =~ 53.65€/tCO2, 2022 =~ 80€/tCO2 -> average 2020 = 40€/tCO2 -> 40*1.032 $/tCO2 = 41.28 $/t CO2
    p47_taxemiMkt_init("2020",regi,"ETS")$(cm_startyear le 2020)  = 30*sm_DptCO2_2_TDpGtC;

*** Initializing European ESR historical and reference prices
    p47_taxemiMkt_init("2020",regi,"ES")$(cm_startyear le 2020)  = 30*sm_DptCO2_2_TDpGtC;
    p47_taxemiMkt_init("2020",regi,"other")$(cm_startyear le 2020)  = 30*sm_DptCO2_2_TDpGtC;
  );

*** intialize price trajectory after 2020 based on historical year prices for non policy scenarios 
  if ( (cm_startyear le 2020),
    p47_taxemiMkt_init(t,regi,emiMkt)$(t.val gt 2020)  = p47_taxemiMkt_init("2020",regi,emiMkt) + (cm_postTargetIncrease*sm_DptCO2_2_TDpGtC)*(t.val-2020);
  );

);

*** Auxiliar parameters based on emission targets information 
  loop((ttot,ttot2,ext_regi,emiMktExt,target_type_47,emi_type_47)$pm_emiMktTarget(ttot,ttot2,ext_regi,emiMktExt,target_type_47,emi_type_47), !!calculated sets that depends on data parameter
    regiEmiMktTarget(ext_regi) = yes;
    regiANDperiodEmiMktTarget_47(ttot2,ext_regi) = yes;
  );

  loop((ttot,ttot2,ext_regi,emiMktExt,target_type_47,emi_type_47)$pm_emiMktTarget(ttot,ttot2,ext_regi,emiMktExt,target_type_47,emi_type_47),
    p47_lastTargetYear(ext_regi) = ttot2.val;
  );

  loop(ext_regi,
    loop(ttot$regiANDperiodEmiMktTarget_47(ttot,ext_regi),
      p47_firstTargetYear(ext_regi) = ttot.val;
      break$(p47_firstTargetYear(ext_regi));
    );
  );

$ENDIF.emiMkt

***---------------------------------------------------------------------------
*** Implicit tax/subsidy necessary to achieve primary, secondary and/or final energy targets
***---------------------------------------------------------------------------

*** intialize energy type bound implicit target parameters
$ifthen.cm_implicitEnergyBound not "%cm_implicitEnergyBound%" == "off"
	p47_implEnergyBoundTax0(t,all_regi) = 0;
$endIf.cm_implicitEnergyBound

***---------------------------------------------------------------------------
*** implicit tax/subsidy necessary to final energy price targets
***---------------------------------------------------------------------------

$ifthen.cm_implicitPriceTarget not "%cm_implicitPriceTarget%" == "off"

  p47_implicitPriceTax0(t,regi,entyFe,entySe,sector)=0;

*** load exogenously defined FE price targets
table f47_implicitPriceTarget(fePriceScenario,ext_regi,all_enty,entySe,sector,ttot)        "exogenously defined FE price targets [2005 Dollar per GJoule]"
$ondelim
$include "./modules/47_regipol/regiCarbonPrice/input/exogenousFEprices.cs3r"
$offdelim
;

  loop((t,ext_regi,entyFe,entySe,sector)$f47_implicitPriceTarget("%cm_implicitPriceTarget%",ext_regi,entyFe,entySe,sector,t),
    loop(regi$regi_groupExt(ext_regi,regi),
      pm_implicitPriceTarget(t,regi,entyFe,entySe,sector)=f47_implicitPriceTarget("%cm_implicitPriceTarget%",ext_regi,entyFe,entySe,sector,t)*sm_DpGJ_2_TDpTWa;
    );
  );

*** initialize first and terminal years auxiliary parameters for price targets 
  loop(ttot,
    p47_implicitPriceTarget_terminalYear(regi,entyFe,entySe,sector)$pm_implicitPriceTarget(ttot,regi,entyFe,entySe,sector) = 2005;
    p47_implicitPriceTarget_initialYear(regi,entyFe,entySe,sector) $pm_implicitPriceTarget(ttot,regi,entyFe,entySe,sector) = 2150;
  );

$endIf.cm_implicitPriceTarget

***---------------------------------------------------------------------------
*** implicit tax/subsidy necessary to primary energy price targets
***---------------------------------------------------------------------------

$ifthen.cm_implicitPePriceTarget not "%cm_implicitPePriceTarget%" == "off"

  p47_implicitPePriceTax0(t,regi,entyPe)=0;

*** load exogenously defined FE price targets
table f47_implicitPePriceTarget(pePriceScenario,ext_regi,all_enty,ttot)        "exogenously defined Pe price targets [2005 Dollar per GJoule]"
$ondelim
$include "./modules/47_regipol/regiCarbonPrice/input/exogenousPEprices.cs3r"
$offdelim
;

  loop((t,ext_regi,entyPe)$f47_implicitPePriceTarget("%cm_implicitPePriceTarget%",ext_regi,entyPe,t),
    loop(regi$regi_groupExt(ext_regi,regi),
      pm_implicitPePriceTarget(t,regi,entyPe)=f47_implicitPePriceTarget("%cm_implicitPePriceTarget%",ext_regi,entyPe,t)*sm_DpGJ_2_TDpTWa;
    );
  );

*** initialize first and terminal years auxiliary parameters for price targets 
  loop(ttot,
    p47_implicitPePriceTarget_terminalYear(regi,entyPe)$pm_implicitPePriceTarget(ttot,regi,entyPe) = 2005;
    p47_implicitPePriceTarget_initialYear(regi,entyPe) $pm_implicitPePriceTarget(ttot,regi,entyPe) = 2150;
  );

$endIf.cm_implicitPePriceTarget

***---------------------------------------------------------------------------
*** Region-specific datainput (with hard-coded regions)
***---------------------------------------------------------------------------

$IFTHEN.CCScostMarkup not "%cm_CCS_markup%" == "off" 
	pm_inco0_t(ttot,regi,teCCS)$(regi_group("EUR_regi",regi)) = pm_inco0_t(ttot,regi,teCCS)*%cm_CCS_markup%;
$ENDIF.CCScostMarkup

$IFTHEN.renewablesFloorCost not "%cm_renewables_floor_cost%" == "off" 
	parameter p_new_renewables_floor_cost(all_te) / %cm_renewables_floor_cost% /;
	pm_data(regi,"floorcost",te)$((regi_group("EUR_regi",regi)) AND (p_new_renewables_floor_cost(te))) = pm_data(regi,"floorcost",te)  + p_new_renewables_floor_cost(te);
$ENDIF.renewablesFloorCost


$ifthen.altFeEmiFac not "%cm_altFeEmiFac%" == "off" 
*** Changing refineries emission factors in regions that belong to cm_altFeEmiFac to avoid negative emissions on pe2se (changing from 18.4 to 20 zeta joule = 20/31.7098 = 0.630719841 Twa = 0.630719841 * 3.66666666666666 * 1000 * 0.03171  GtC/TWa = 73.33 GtC/TWa)
loop(ext_regi$altFeEmiFac_regi(ext_regi), 
  pm_emifac(ttot,regi,"peoil","seliqfos","refliq","co2")$(regi_group(ext_regi,regi)) = 0.630719841;
);
*** Changing Germany and UKI solids emissions factors to be in line with CRF numbers (changing from 26.1 to 29.27 zeta joule = 0.922937989 TWa = 107.31 GtC/TWa)
  pm_emifac(ttot,regi,"pecoal","sesofos","coaltr","co2")$(sameas(regi,"DEU") OR sameas(regi,"UKI")) = 0.922937989;
$endif.altFeEmiFac

*** VRE capacity factor adjustments for Germany in line with ARIADNE assumptions
$ifthen.GerVRECapFac not "%cm_ariadne_VRECapFac_adj%" == "off" 
loop(te$sameas(te,"wind"),
  loop(regi$sameas(regi,"DEU"),
    pm_cf("2025",regi,te) =  1.04 * pm_cf("2025",regi,te);
    pm_cf("2030",regi,te) =  1.08 * pm_cf("2030",regi,te);
    pm_cf("2035",regi,te) =  1.12 * pm_cf("2035",regi,te);
    pm_cf("2040",regi,te) =  1.16 * pm_cf("2040",regi,te);
    pm_cf("2045",regi,te) =  1.2  * pm_cf("2045",regi,te);
    pm_cf(t,regi,te)$(t.val gt 2045) =  pm_cf("2045",regi,te);
  );
);

loop(te$sameas(te,"spv"),
  loop(regi$sameas(regi,"DEU"),
    pm_cf("2025",regi,te) =  1.02 * pm_cf("2025",regi,te);
    pm_cf("2030",regi,te) =  1.04 * pm_cf("2030",regi,te);
    pm_cf("2035",regi,te) =  1.06 * pm_cf("2035",regi,te);
    pm_cf("2040",regi,te) =  1.08 * pm_cf("2040",regi,te);
    pm_cf("2045",regi,te) =  1.10 * pm_cf("2045",regi,te);
    pm_cf(t,regi,te)$(t.val gt 2045) =  pm_cf("2045",regi,te);
  );
);
$endif.GerVRECapFac

*** p_EmiLULUCFCountryAcc contains historic LULUCF emissions from UNFCCC, 
*** used for rescaling land-use change emissions for emissions targets based on national accounting
parameter p47_EmiLULUCFCountryAcc(tall,all_regi)                "historic co2 emissions from landuse change based on country accounting [Mt CO2/yr]"
/
$ondelim
$include "./modules/47_regipol/regiCarbonPrice/input/p_EmiLULUCFCountryAcc.cs4r"
$offdelim
/
;

*** difference between 2015 land-use change emissions from Magpie and UNFCCC 2015 land-use change emissions
p47_LULUCFEmi_GrassiShift(t,regi)$(p47_EmiLULUCFCountryAcc("2015",regi)) = (pm_macBaseMagpie("2015",regi,"co2luc") - p47_EmiLULUCFCountryAcc("2015",regi)* 1e-3/sm_c_2_co2);


*** -------------------------Primary Energy Tax--------------------------

*PW* charge tax on PE gas,oil,coal in energy security scenario for Germany (in trUSD/TWa) to hit Ariadne energy security price trajectories
$ifThen.cm_EnSecScen "%cm_EnSecScen%" == "on"
  pm_tau_pe_tax("2025",regi,"pegas")$(sameAs(regi,"DEU")) = 0.4;
  pm_tau_pe_tax("2030",regi,"pegas")$(sameAs(regi,"DEU")) = 0.3;
  pm_tau_pe_tax("2035",regi,"pegas")$(sameAs(regi,"DEU")) = 0.25;
  pm_tau_pe_tax("2040",regi,"pegas")$(sameAs(regi,"DEU")) = 0.2;
  pm_tau_pe_tax("2045",regi,"pegas")$(sameAs(regi,"DEU")) = 0.2;
  pm_tau_pe_tax("2050",regi,"pegas")$(sameAs(regi,"DEU")) = 0.2;
  pm_tau_pe_tax("2055",regi,"pegas")$(sameAs(regi,"DEU")) = 0.15;
  pm_tau_pe_tax("2060",regi,"pegas")$(sameAs(regi,"DEU")) = 0.1;

  pm_tau_pe_tax("2025",regi,"peoil")$(sameAs(regi,"DEU")) = 0.1;
  pm_tau_pe_tax("2030",regi,"peoil")$(sameAs(regi,"DEU")) = 0.1;
  pm_tau_pe_tax("2035",regi,"peoil")$(sameAs(regi,"DEU")) = 0.15;
  pm_tau_pe_tax("2040",regi,"peoil")$(sameAs(regi,"DEU")) = 0.2;
  pm_tau_pe_tax("2045",regi,"peoil")$(sameAs(regi,"DEU")) = 0.2;
  pm_tau_pe_tax("2050",regi,"peoil")$(sameAs(regi,"DEU")) = 0.2;
  pm_tau_pe_tax("2055",regi,"peoil")$(sameAs(regi,"DEU")) = 0.15;
  pm_tau_pe_tax("2060",regi,"peoil")$(sameAs(regi,"DEU")) = 0.1;

  pm_tau_pe_tax("2025",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.03;
  pm_tau_pe_tax("2030",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.02;
  pm_tau_pe_tax("2035",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.02;
  pm_tau_pe_tax("2040",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.02;
  pm_tau_pe_tax("2045",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.02;
  pm_tau_pe_tax("2050",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.02;
  pm_tau_pe_tax("2055",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.01;
  pm_tau_pe_tax("2060",regi,"pecoal")$(sameAs(regi,"DEU")) = 0.01;
$endIf.cm_EnSecScen

*** intermediate solution for code check until ces tax gets implemented
pm_tau_ces_tax("2025",regi,"ue_steel_primary")$(sameAs(regi,"DEU")) = 0.0;


*** EOF ./modules/47_regipol/regiCarbonPrice/datainput.gms
