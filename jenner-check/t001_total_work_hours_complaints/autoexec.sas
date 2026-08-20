/* cap input rows for the captured run */
options obs=100;

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
