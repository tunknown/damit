if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
----------
if	object_id ( 'damit.ToListFromStringAuto' , 'if' )	is	null
	exec	( 'create	function	damit.ToListFromStringAuto()	returns	table	as	return	( select	ObjectNotCreated=	1/	0 )' )
go
alter	function	damit.ToListFromStringAuto	-- преобразование строки параметров в датасет
(	@s	nvarchar ( max ) )			-- первый символ(в т.ч. CRLF)=разделитель
returns	table
as
return	( with	cte	as
	(	select	Delimeter=	case	left ( @s , 2 )
						when	'
'	then	'
'
						else	left ( @s , 1 )
					end )
	select
		t.Sequence
		,t.Value
	from
		cte
		cross	apply	damit.ToListFromString ( @s , cte.Delimeter , 1 )	t )
go
use	tempdb
select * from damit.damit.ToListFromStringAuto ( ',1,2,3,4,' )
select * from damit.damit.ToListFromStringAuto ( ',1,,3
3,4,')