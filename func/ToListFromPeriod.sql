use	damit
----------
if	object_id ( 'damit.ToListFromPeriod' , 'tf' )	is	null
	exec	( 'create	function	damit.ToListFromPeriod()	returns	@t	table	( f	int )	as	begin	return	end' )
go
alter	function	damit.ToListFromPeriod
(	@iLcid		int=	1049
	,@sType		varchar ( 16 )
	,@dtStart	datetime
	,@dtFinish	datetime )
returns	@table	table
(	Value		datetime
	,ValueStr1	nvarchar ( 256 )
	,ValueStr2	nvarchar ( 256 ) )
as
begin
	declare	@s	nvarchar ( 4000 )
----------
	select
		@s=	case	@sType
				when	'month'		then	months
				when	'weekday'	then	days
				else				null
			end
	from
		sys.syslanguages
	where
		lcid=	@iLcid
----------
	;with	cte	as
	(	select	Value=	@dtStart
		union	all
		select
			Value=	case	@sType
					when	'year'		then	dateadd ( year,		1,	cte.Value )
					when	'quarter'	then	dateadd ( quarter,	1,	cte.Value )
					when	'month'		then	dateadd ( month,	1,	cte.Value )
					when	'day'		then	dateadd ( day,		1,	cte.Value )
					when	'week'		then	dateadd ( week,		1,	cte.Value )
					when	'weekday'	then	dateadd ( weekday,	1,	cte.Value )
					when	'hour'		then	dateadd ( hour,		1,	cte.Value )
					when	'minute'	then	dateadd ( minute,	1,	cte.Value )
				end
		from
			cte
		where
			case	@sType
				when	'year'		then	dateadd ( year,		1,	cte.Value )
				when	'quarter'	then	dateadd ( quarter,	1,	cte.Value )
				when	'month'		then	dateadd ( month,	1,	cte.Value )
				when	'day'		then	dateadd ( day,		1,	cte.Value )
				when	'week'		then	dateadd ( week,		1,	cte.Value )
				when	'weekday'	then	dateadd ( weekday,	1,	cte.Value )
				when	'hour'		then	dateadd ( hour,		1,	cte.Value )
				when	'minute'	then	dateadd ( minute,	1,	cte.Value )
			end<=	@dtFinish	)
	insert
		@table	( Value,	ValueStr1,	ValueStr2 )
	select
		cte.Value
		,isnull ( t.Value+	' ' , '' )+	convert ( varchar ( 256 ) , datepart ( year , cte.Value ) )
		,t.Value
	from
		cte
		left	join	damit.ToListFromString ( @s , ',' , 1 )	t	on
			t.Sequence=	case	@sType
						when	'month'		then	datepart ( month,	cte.Value )
						when	'weekday'	then	datepart ( weekday,	cte.Value )
					end
	OPTION
		( MAXRECURSION	0 )
----------
	return
end
go
use	tempdb
select	*	from	damit.damit.ToListFromPeriod
(	default--1054
	,'month'--'weekday'
	,'20110101'
	,'20121231' )