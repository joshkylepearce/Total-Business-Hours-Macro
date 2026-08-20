/************************************************************************************
Example 1:
Complaints & Closures

Purpose:
Calculate the number of business hours between the time that a
complaint was submitted and the time that the complaint was closed.
************************************************************************************/

/************************************************************************************
Example 1: Data Setup
************************************************************************************/

/*Create a fictious dataset of customer complaint & closure dates*/
data complaint_dates;
input complaint_date :date9. closure_date :date9.;
format complaint_date closure_date date9.;
datalines;
01JUN2023 01JUN2023
02JUN2023 07JUN2023
03JUN2023 06JUN2023
04JUN2023 06JUN2023
05JUN2023 08JUN2023
06JUN2023 12JUN2023
07JUN2023 09JUN2023
08JUN2023 12JUN2023
09JUN2023 13JUN2023
10JUN2023 15JUN2023
;
run;

/*Add times to ficticous complaint & closure dates*/
data complaint_datetime;
	set complaint_dates;
	/*Seed the random stream so this bundle's output is reproducible*/
	call streaminit(20240817);
	/*Create randomly generated times for complaints & closures*/
	complaint_timepart=rand("uniform",'09:00:00't, '12:00:00't);
	closure_timepart=rand("uniform",'12:00:00't, '17:00:00't);
	/*Join the date & times to a combined complaint datetime variable*/
	complaint_datetime=dhms(complaint_date,0,0,complaint_timepart);
	/*Join the date & times to a combined closure datetime variable*/
	closure_datetime=dhms(closure_date,0,0,closure_timepart);
	/*Reformat variables to datetime format*/
	format complaint_datetime closure_datetime datetime.;
	/*Drop variables not required for macro usage*/
	drop complaint_date closure_date complaint_timepart closure_timepart;
run;

/************************************************************************************
Example 1: Macro Usage
************************************************************************************/

/*Call the macro and enter the input parameters*/
%total_work_hours(
input_data 		= complaint_datetime,
output_data		= total_hours_complaints,
start_date 		= complaint_datetime,
end_date 		= closure_datetime,
business_start 	= 9,
business_end 	= 17
);

proc print data=total_hours_complaints noobs;
run;
