use	damit
----------
if	object_id ( 'damit.ToDateTimeFromDateAndTimeInt' , 'fn' )	is	null
	exec	( 'create	function	damit.ToDateTimeFromDateAndTimeInt()	returns	datetime	as	begin	return	getdate()	end' )
go
alter	function	damit.ToDateTimeFromDateAndTimeInt	-- проверка ошибок
(	@iDate	int		-- дата в формате джоба
	,@iTime	int	)	-- время в формате джоба
returns	datetime
as
----------
begin
	return	( convert	( datetime,	convert	( char ( 17 ),	convert	( char ( 9 ),	@iDate )+	stuff ( stuff ( replace ( str ( @iTime , 6 ) , ' ' , '0' ) , 3 , 0 ,  ':' ) , 6 , 0 , ':' ) ) ) )

/*
	return	( convert ( datetime,	convert ( char ( 9 ),	@iDate )
					+	str ( @iTime%	1000000/	10000,	2 ) + ':' 
					+	str ( @iTime%	10000/		100,	2 ) + ':' 
					+	str ( @iTime%	100,			2 ) ) )
*/

end
go
select
	run_date
	,run_time
	,damit.ToDateTimeFromDateAndTimeInt	( run_date , run_time )
from
	msdb..sysjobhistory