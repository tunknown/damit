if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
----------
if	object_id ( 'damit.ToListFromString' , 'tf' )	is	null
	exec	( 'create	function	damit.ToListFromString()	returns	@t	table	( f	int )	as	begin	return	end' )
go
alter	function	damit.ToListFromString	-- преобразование строки параметров в датасет
(	@s		nvarchar ( max )	-- строка
	,@sDelimeter	varchar ( 32 )=	','	-- разделитель параметров в строке, вплоть до текстового представления гуида
	,@bRefine	bit=		1 )	-- 1=очищать отдельные параметры от незначащих символов, пустые записи исключать; число записей при @bRefine=0 равно числу разделителей в строке+1
returns	@table	table
(	Sequence	int			-- сверхбольшие списки иногда нужны, smallint не подходит
	,Value		nvarchar ( max ) )
as
begin
	declare	@iDelimeterLen	tinyint
		,@sLen		int
		,@sCRLF		char ( 2 )
----------
	select	@iDelimeterLen=	len ( @sDelimeter )
		,@sLen=		len ( @s )
		,@sCRLF=	'
'					-- перевод строки не трогать
----------
	/*if	right ( @s , @iDelimeterLen )<>	@sDelimeter */set	@s=	@s+	@sDelimeter	-- для упрощения проверки последнего значения в списке
----------
	;with	cte	( Pos,	Value,	Sequence )	as
	(	select	Pos=		charindex ( @sDelimeter , @s )+	@iDelimeterLen
			,Value=		substring ( @s , 1 , charindex ( @sDelimeter , @s )-	1 )
			,Sequence=	1
		union	all
		select
			Pos=		charindex ( @sDelimeter , @s , cte.pos )+	@iDelimeterLen
			,Value=		substring ( @s , cte.Pos , charindex ( @sDelimeter , @s , cte.Pos )-	cte.Pos )
			,Sequence=	cte.Sequence+	1
		from
			cte
		where
			cte.Pos<=	@sLen+	1 )	-- эта проверка несколько тормозит
	insert
		@table ( Sequence,	Value )
	select
		Sequence
		,Value
	from
		cte
	where
			@bRefine=	0
	union	all
	select
		Sequence=	ROW_NUMBER()	over	( order	by	Sequence )
		,Value										-- значение не изменяем, только выкидываем пустые значение
	from
		cte
	where
			@bRefine=	1
		and	replace ( replace ( Value , ' ' , '' ) , @sCRLF , '' )<>	''	-- пропускаем пустые, т.е. состоящие только из пробелов и/или CRLF
	OPTION
		( MAXRECURSION	0 )
----------
	return
end
go
use	tempdb
select * from damit.damit.ToListFromString ( ',1,2,3,4,' , ',' , 0 )
select * from damit.damit.ToListFromString ( ',1,,3
3,4,' , ',' , 1 )