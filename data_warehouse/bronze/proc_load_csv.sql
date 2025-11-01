/*
===============================================================================
stored procedure: load csv data into bronze table
===============================================================================
purpose:
    - truncates the table before loading data.
    - uses the `COPY INTO` command to bulk load data from external CSV files.
parameters:
	- none
output:
	- void
usage:
    - call bronze.load_csv;
===============================================================================
*/

create or replace procedure bronze.load_csv(tableName text, csvFile text)
language plpgsql
as $body$

declare
	starttime	timestamp;
	endtime		timestamp;
	rowCounter	bigint;
	command1	text;
	command2	text;
	command3	text;

begin
	raise notice '------------------------------------------------';
	raise notice 'Load csv data into bronze table';
	raise notice '------------------------------------------------';

	command1 := 'truncate table ' || tableName || ';';
	command2 := 'copy '
	|| tableName
	|| ' from '
	|| quote_literal(csvFile)
	|| ' with csv header delimiter as '
	|| quote_literal(',')
	|| ';';
	command3 := 'select count(*) from ' || tableName || ';';

	starttime := clock_timestamp();
	execute command1;
	execute command2;
	execute command3 into rowCounter;
	endtime := clock_timestamp();

	raise notice '>> Truncate table: %', tableName;
	raise notice '>> Insert data into: %', tableName;
	raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
	raise notice '>> Total rows after insert: % [#]', rowCounter;
	raise notice '------------------------------------------------';
end;

$body$;
