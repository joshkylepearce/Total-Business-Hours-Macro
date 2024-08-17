/************************************************************************************
***** Program: 	Total Work Hours Macro	*****
***** Author:	joshkylepearce	        *****
************************************************************************************/

/************************************************************************************
Public Holiday Setup

Purpose:
Public holidays are subject to change each year. 
Define public holidays in New Zealand between 2022-2024.
Provided as an example to be used in the macro.

Format:
To ensure compatibility with the macro, the public holiday dataset must be:
- 	Saved with the name 'public_holidays'.
-	Contain one variable named 'holiday' in date9. format.
************************************************************************************/

/*Define New Zealand public holidays 2022-2024*/
data public_holidays;
input holiday :date9.;
format holiday date9.;
datalines;
01JAN2022
02JAN2022
06FEB2022
15APR2022
18APR2022
25APR2022
06JUN2022
24JUN2022
26SEP2022
24OCT2022
25DEC2022
26DEC2022
01JAN2023
02JAN2023
03JAN2023
30JAN2023
06FEB2023
07APR2023
10APR2023
25APR2023
05JUN2023
14JUL2023
23OCT2023
25DEC2023
26DEC2023
01JAN2024
02JAN2024
06FEB2024
29MAR2024
01APR2024
25APR2024
03JUN2024
28JUN2024
28OCT2024
25DEC2024
26DEC2024
;
run;

/*Create a macro named 'hol' that contains all public holiday dates defined above*/
proc sql noprint;
select cat("'",put(holiday,date9.),"'d") into: hol separated by "," 
from public_holidays;
quit;
%put &hol.;

/************************************************************************************
Total Work Hours Macro

Purpose:
Calculate the number of work hours between two datetime variables.
Excludes weekends, public holidays, and non-business hours.

Input Parameters:
1.	input_data	- Input dataset that should be queried.
2.	output_data	- Name of the output dataset.
2. 	start_date	- Specify the start datetime variable.
3.	end_date	- Specify the end datetime variable.
4.	business_start	- The first hour of the business day (e.g. 9=9am).
5.	business_end	- The last hour of the business day (e.g. 17=5pm)

Output Parameters:
1. 	total_hours	- The total hours between the user-inputted start & end datetimes.

Macro Usage:
1. 	Create the public holiday table. See section above for details.
2. 	Run the total_work_hours macro code.
3. 	Call the total_work_hours macro and enter the input parameters.
	e.g. 
	%total_work_hours(
	input_data	= work.library,
	output_data	= total_hours,
	start_date	= begin_timestamp,
	end_date	= end_timestamp,
	business_start	= 9,
	business_end	= 17
	);

Notes:
-	start_date & end_date must be datetime variables since hours are required.
-	business_start & business_end can be entered with/without quotations. 
	This is handled within the macro so that both options are applicable.
************************************************************************************/

%macro total_work_hours(input_data,output_data,start_date,end_date,business_start,business_end);

/*
The business_start & business_end input parameters are only compatible 
with macro if not in quotes.
Account for single & double quotations.
*/
/*Remove double quotes*/
%let business_start = %sysfunc(compress(&business_start., '"'));
%let business_end = %sysfunc(compress(&business_end., '"'));
/*Remove single quotes*/
%let business_start = %sysfunc(compress(&business_start., "'"));
%let business_end = %sysfunc(compress(&business_end., "'"));

/*Calculate the total number of hours between user-inputted business start & end*/
%let hours_per_day=%sysevalf(&business_end.-&business_start.);

/*Set created table name as user-inputted parameter*/
data &output_data.;
/*Set input dataset as user-inputted paramter*/
set &input_data.;

/*Extract datepart values from datetime variables*/
start_datepart=datepart(&start_date.);
end_datepart=datepart(&end_date.);

/*Extract timepart values from datetime variables*/
start_timepart=timepart(&start_date.);
end_timepart=timepart(&end_date.);

/*Allocate start time as the start of the working day if the time is earlier*/
/*Since the time is before the working day begins, these hours should not be counted*/
if hour(start_timepart) < &business_start. then do;
	start_time=&business_start.;
end;
else do;
	start_time=hour(start_timepart);
end;

/*Initialize*/
business_days=0;

/*Count the number of business days between the start & end date*/
/*Specify the day after start date & day before end date and count between*/
do date = (start_datepart+1) to (end_datepart-1);
	/*Count all days between that are not weekends or public holidays*/
	if weekday(date) not in (1,7) and date not in (&hol.) then do;
		business_days+1;
	end;
end;
drop date;

/*Check if first day is a business day*/
if weekday(start_datepart) in (1,7) or start_datepart in (&hol.) then do;
	/*If the first day is a non-business day, set the first day hours to zero*/
	first_day_hours=0;
	/*Calculate the number of hours between the start of business hours & end time*/
	last_day_hours=intck('hour',dhms(end_datepart,&business_start.,0,0),&end_date.);
	/*Calculate the number of days between and multiply by business hours per day */
	inbetween_hours= (business_days*&hours_per_day.);
end;
/*Check whether the time of the first day is after business hours*/
else if hour(start_timepart) > &business_end. then do;
	/*If the time is after business hours, set first day hours to zero*/
	first_day_hours=0;
	/*Calculate the number of hours between the start of business hours & end time*/
	last_day_hours=intck('hour',dhms(end_datepart,&business_start.,0,0),&end_date.);
	/*Calculate the number of days between and multiply by business hours per day */
	inbetween_hours= (business_days*&hours_per_day.);
end;
/*Set last day & days between hours to zero if the start & end date are the same day*/
else if start_datepart=end_datepart then do;
	first_day_hours=intck('hour',dhms(start_datepart,start_time,0,0),&end_date.);
	/*If there are not multiple days between the two days, set last day hours to zero*/
	last_day_hours=0;
	/*If there are not multiple days between the two days, set inbetween hours to zero*/
	inbetween_hours=0;
end;
/*If not the same day*/
/*Calculate hours for inbetween days & last day*/
else do;
	/*Calculate the number of hours between the start time & end of business hours*/
	first_day_hours=intck('hour',dhms(start_datepart,start_time,0,0),dhms(start_datepart,&business_end.,0,0));
	/*Calculate the number of hours between the start of business hours & end time*/
	last_day_hours=intck('hour',dhms(end_datepart,&business_start.,0,0),&end_date.);
	/*Calculate the number of days between and multiply by business hours per day */
	inbetween_hours= (business_days*&hours_per_day.);
end;
/*Drop variables that are no longer required*/
drop start_datepart end_datepart start_timepart end_timepart start_time business_days;

/*Calculate the total number of hours*/
total_hours=sum(first_day_hours,last_day_hours,inbetween_hours);
/*Drop variables that are no longer required*/
drop first_day_hours last_day_hours inbetween_hours;

run;

%mend;

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

/************************************************************************************
Example 2:	
Financial Crime Suspicious Transactions

Purpose:	
Calculate the number of business hours between the time that a 
suspicous transaction was flagged and the time that the transaction
was reviewed. 
************************************************************************************/

/************************************************************************************
Example 2: Data Setup
************************************************************************************/

/*Create a ficticious dataset of dates that suspicious transactions were flagged*/
data flagged;
	/*Integer representing datetime 25MAY22:22:55:59*/
	/*Random selection that provides a suitable date range for this example*/
	date=1969138559;
	/*Create 20 random dates to test usage of the macros*/
	do i=1 to 20;
		flagged_date=date+(i*100000);
		output;
	end;
	/*Set variables as datetime. format for ease of interpretation*/
	format flagged_date datetime.;
	/*Drop variables not required for macro usage*/
	drop date i;
run;

/*Create a ficticious dataset of dates that suspicious transactions were reviewed*/
data reviewed;
	set flagged;
	/*Create a randomly generated date between 0 and 7 days after the flagged date*/
	datepart=datepart(flagged_date) + rand("integer",0,7);
	/*Reviews should not take place outside of working hours*/
	/*Reallocate review date to a weekday if the random allocation is a weekend*/
	if weekday(datepart)=1 then datepart+1;
	else if weekday(datepart)=7 then datepart+2;
	/*Reallocate review date to a business day if the random allocation is a holiday*/
	if datepart in (&hol.) then datepart+1;
	/*Randomly allocate time between 9am-5pm*/
	timepart= rand("uniform",'09:00:00't, '17:00:00't);
	/*Join the randomly allocated date & time to a datetime variable*/
	reviewed_date=dhms(datepart,0,0,timepart);
	/*Set the format of the datetime variable*/
	format reviewed_date datetime.;
	/*Drop the individual components that are no longer required*/
	drop datepart timepart;
run;

/************************************************************************************
Example 2: Macro Usage
************************************************************************************/

/*Call the macro and enter the input parameters*/
%total_work_hours(
input_data 	= reviewed,
output_data	= total_hours_fincrime,
start_date 	= flagged_date,
end_date 	= reviewed_date,
business_start 	= 8,
business_end 	= 16
);
