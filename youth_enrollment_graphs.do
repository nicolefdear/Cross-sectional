/***********************************************************
Project: AFRICOS
Program summary: Youth enrollment graphs
Author: Nicole Dear
Date: 11 June 2021
Last modified: 10 Feb 2022
***********************************************************/
*set working directory
cd "C:\Users\ndear\Box Sync\Shared Files- Reed and Esber\Youth\youth enrollment"

*load data
use "C:\Users\ndear\Box Sync\Shared Files- Reed and Esber\Youth\youth_1DEC2021.dta", clear

*recode misdiagnoses
replace hivflag=2 if subjid=="A01-0026"
replace hivflag=2 if subjid=="A01-0159"
replace hivflag=2 if subjid=="A01-0232"
replace hivflag=2 if subjid=="A01-0343"
replace hivflag=2 if subjid=="A01-0402"
replace hivflag=2 if subjid=="A01-0527"
replace hivflag=2 if subjid=="A01-0587"
replace hivflag=2 if subjid=="A01-0603"
replace hivflag=2 if subjid=="B04-0054"

*drop acute and missed visits
drop if visit>50
drop if misvis==1

*check for duplicates
duplicates tag subjid visit, gen(dup_id)
tab dup_id

list subjid visit visitdt fdanna gender hivflag sequence vl drawper_vl if dup_id==1
drop if sequence==2 & dup_id==1

duplicates tag subjid visit, gen(dup_id2)
tab dup_id2
duplicates drop subjid visit, force

*keep those with known HIV status
list subjid if hivflag==. & visit==1
keep if hivflag!=.

*********cumulative and % enrolled by month*********
gen year=year(visitdt)
gen month=month(visitdt)
gen yearmo=ym(year,month)
format yearmo %tm

replace agev=(visitdt-dobdtn)/365.25 if agev==. & dobdtn!=.
gen agec=1 if agev<25 & agev!=.
replace agec=2 if agev>=25 & agev!=.
tab visit agec
drop if agec==.

keep if visit==1
tab yearmo agec

*calc cumulative enrollment for entire cohort by month
// bysort yearmo: egen all_enroll=count(subjid)
// bysort yearmo: gen nvals = _n == 1
// keep if nvals==1
// keep yearmo all_enroll
// gen cum_enroll_all = sum(all_enroll)
// save cum_enroll_all.dta, replace

bysort yearmo agec: egen enroll=count(subjid)
bysort yearmo agec: gen nvals = _n == 1

keep if nvals==1
keep yearmo agec enroll

gsort agec yearmo
bysort agec: gen cum_enroll = sum(enroll)

keep yearmo agec cum_enroll
reshape wide cum_enroll, i(yearmo) j(agec)

merge 1:1 yearmo using cum_enroll_all.dta

gen perc1524=100*(cum_enroll1/cum_enroll_all)
label var cum_enroll1 "15-24 years"
label var cum_enroll_all "All ages"
label var perc1524 "Percent of total enrolled in 15-24 age group"

tsset yearmo
graph twoway tsline cum_enroll1 cum_enroll_all, tline(2020m2) ytitle("Cumulative enrollment") ttitle("Date (year, month)")
graph twoway tsline perc1524, tline(2020m2) ttitle("Date (year, month)")

*********cumulative and % enrolled by year*********
gen year=year(visitdt)
gen month=month(visitdt)
gen yearmo=ym(year,month)
format yearmo %tm

replace agev=(visitdt-dobdtn)/365.25 if agev==. & dobdtn!=.
gen agec=1 if agev<25 & agev!=.
replace agec=2 if agev>=25 & agev!=.
tab visit agec, missing
drop if agec==.

keep if visit==1
tab agec

*calc cumulative enrollment for entire cohort by year
// bysort year: egen all_enroll=count(subjid)
// bysort year: gen nvals = _n == 1
// keep if nvals==1
// keep year all_enroll
// gen cum_enroll_all = sum(all_enroll)
// save cum_enroll_all_byyear.dta, replace

bysort year agec: egen enroll=count(subjid)
bysort year agec: gen nvals = _n == 1

keep if nvals==1
keep year agec enroll

gsort agec year
bysort agec: gen cum_enroll = sum(enroll)

keep year agec cum_enroll
reshape wide cum_enroll, i(year) j(agec)

merge 1:1 year using cum_enroll_all_byyear.dta

gen perc1524=100*(cum_enroll1/cum_enroll_all)
label var cum_enroll1 "15-24 years"
label var cum_enroll_all "All ages"
label var perc1524 "Percent of total enrolled in 15-24 age group"

tsset year
graph twoway tsline cum_enroll1 cum_enroll_all, ytitle("Cumulative enrollment") ttitle("Year") tline(2020)
graph twoway tsline perc1524, ttitle("Year") tline(2020)

*********other youth numbers*********
replace agev=(visitdt-dobdtn)/365.25 if agev==. & dobdtn!=.
gen agec=1 if agev<25 & agev!=.
replace agec=2 if agev>=25 & agev!=.

gen youth=1 if agev<25

tab visit agec, row missing
tab progid hivflag if agec==1 & visit==1
tab hivflag if agec==1 & visit==1
tab gender if agec==1 & visit==1
tabstat agev if agec==1 & visit==1, stats(p25 p50 p75)

*code route of HIV transmission
replace hivinfct=8 if strpos(hivintxt,"BIRTH")|strpos(hivintxt,"BORN")|strpos(hivintxt,"BREAST MILK")|strpos(hivintxt,"DELIVERY")|strpos(hivintxt,"MOTHER TO CHILD")|strpos(hivintxt,"PARENTS")|strpos(hivintxt,"MOTHER TOCHILD")|strpos(hivintxt,"MTCT")|strpos(hivintxt,"VERTICAL")|strpos(hivintxt,"MOTHER")
replace hivinfct=97 if strpos(hivintxt,"DO NOT KNOW")|strpos(hivintxt,"DON'T KNOW")|strpos(hivintxt,"DONT KNOW")|strpos(hivintxt,"NOT SURE")|strpos(hivintxt,"UNKNOWN")

gen route=1 if hivinfct==1|hivinfct==2|hivinfct==3
replace route=2 if hivinfct==8
replace route=3 if hivinfct==4|hivinfct==5|hivinfct==6|hivinfct==7|hivinfct==90
replace route=4 if hivinfct==97|hivinfct==98|hivinfct==.
label def route 1 "Sexual contact" 2 "Vertical transmission" 3 "Other" 4 "Unknown"
label val route route

tab route if agec==1 & visit==1 & hivflag==1, missing

*duration on ART
bysort subjid: carryforward diagdtn, replace
bysort subjid: carryforward art_sdtn, replace

replace dur_hiv=(visitdt-diagdtn)/365.25 if dur_hiv==. & diagdtn!=.
gen art6mo=1 if dur_art>=0.5 & dur_art!=.

*viral suppression
gen vf=0 if vl>=1000 & vl!=. & dur_art>=0.5 & dur_art!=.
replace vf=1 if vl<1000 & dur_art>=0.5 & dur_art!=.
label def vf 0 "Failing" 1 "Suppressed"
label val vf vf

tab art6mo if agec==1 & visit==1 & hivflag==1, missing
tab vf if art6mo==1 & agec==1 & visit==1 & hivflag==1, missing

*other variables for table 1
gen transmit=0
replace transmit=1 if route==2
label def transmit 0 "Other" 1 "Vertical"
label val transmit transmit
label var transmit "Route of transmission"

label var progid "Study site"
label define progid3 1  "Kayunga, Uganda" 2 "South Rift Valley, Kenya" 3 "Kisumu West, Kenya" 4 "Mbeya, Tanzania" 5 "Abuja & Lagos Nigeria"
label val progid progid3

label var gender "Sex"
label def gender 1 "Male" 2 "Female"
label val gender gender

label var hivflag "HIV status"
label def hivflag 1 "PLWH" 2 "PLWoH"
label val hivflag hivflag

*on art
replace art_sdtn=astartdtcn if art_sdtn==.
replace art_sdtn=startdtcn if art_sdtn==.

replace dur_hiv=(visitdt-diagdtn)/365.25 if dur_hiv==.
replace dur_art=(visitdt-art_sdtn)/365.25 if dur_art==.

replace takearv=1 if art_sdtn!=.
label def takearv 0 "Not on ART" 1 "On ART"
label val takearv takearv

gen art=0 if tenofovir==1 & (lamivudine==1 |emtricitabine==1) & efavirenz==1
replace art=1 if zidovudine==1 & nevirapine==1 & lamivudine==1
replace art=2 if zidovudine==1 & efavirenz==1 & lamivudine==1
replace art=3 if tenofovir==1 & lamivudine==1 & nevirapine==1
replace art=4 if art_sdtn==.
replace art=5 if lopinavir==1 | atazanavir==1
replace art=6 if tenofovir==1 & (lamivudine==1 | emtricitabine==1) & dolutegravir==1
replace art=7 if abacavir==1 & lamivudine==1 & (efavirenz==1 | nevirapine==1)
replace art=8 if hivflag==2
replace art=7 if art==. & hivflag==1
label def art 0 "TLE" 1 "AZT/NVP/3TC" 2 "AZT/EFV/3TC" 3 "TDF/NVP/3TC" 4 "NAIVE" 5 "PI" 7 "other" 6 "TLD" 8 "HIV-uninfected"
label val art art
label var art "ART regimen"

*year
gen year=year(visitdt) if visit==1
bysort subjid: carryforward year, replace
label var year "Year of enrollment"

*calc age at dx
gen age_dx=(diagdtn-dobdtn)/365.25
label var age_dx "Age at diagnosis (years)"

*vs
gen vs=0 if takearv==0
replace vs=1 if vl<1000 & vl!=. & takearv==1
replace vs=2 if vl>=1000 & vl!=. & takearv==1
label def vs 0 "Not on ART" 1 "On ART, suppressed" 2 "On ART, not suppressed"
label val vs vs
label var vs "Viral suppression <1000 copies/mL"

*Viral suppression
label def vl 1 "undetectable" 17 "<34" 10 "<20" 20 "<40"
label val vl vl

*CD4_cat
gen cd4_cat=0 if cd3_4_n<200
replace cd4_cat=1 if cd3_4_n>=200 & cd3_4_n<350
replace cd4_cat=2 if cd3_4_n>=350 & cd3_4_n<500
replace cd4_cat=3 if cd3_4_n>=500 & cd3_4_n !=.
label define cd4_cat 0"<200" 1 "200-349" 2 "350-499" 3 "500+" 
label val cd4_cat cd4_cat
label var cd4_cat "CD4 count (cells/mm3)"
label var cd3_4_n "CD4 count (cells/mm3)"

label var vl "Viral load"
label var dur_hiv "Time since HIV diagnosis"
label var dur_art "Duration on ART"

*ART adherence
gen adherent=1 if missarv==0
replace adherent=0 if missarv>=1 & missarv!=.
label define adherent 1 "No missed doses ART" 0 "Missed 1+ doses ART"
label val adherent adherent
label var adherent "ART adherence (past 30 days)"

gen adherent2=0 if takearv==0
replace adherent2=1 if missarv==0 & takearv==1
replace adherent2=2 if missarv>=1 & missarv!=. & takearv==1
label define adherent2  0 "not on ART" 1 "No missed doses ART" 2 "Missed 1+ doses ART"
label val adherent2 adherent2
label var adherent2 "ART adherence (past 30 days)"

*table 1
table1_mc if visit==1 & youth==1 & hivflag==1, by(transmit) vars(agev conts \ gender cat \ progid cat \ dur_hiv conts \ age_dx conts \ cd4_cat cat \ takearv cat\ dur_art conts\ vs cat) total(b) onecol missing format(%2.1f) sav("table1.xlsx")

*ART regimen pre/post 2020
tab art if visit==1 & youth==1 & hivflag==1 & visitdt<date("20200101","YMD")
tab art if visit==1 & youth==1 & hivflag==1 &visitdt>date("20200101","YMD")