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
	/*Seed the random stream so this bundle's output is reproducible*/
	call streaminit(20240817);
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

proc print data=total_hours_fincrime noobs;
run;
