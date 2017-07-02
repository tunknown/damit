if	db_id ( 'damit' )	is	not	null	-- ����� ������������ ������� ����
	use	damit
go
----------
if	object_id ( 'damit.ToListFromString' , 'tf' )	is	null
	exec	( 'create	function	damit.ToListFromString()	returns	@t	table	( f	int )	as	begin	return	end' )
go
alter	function	damit.ToListFromString	-- �������������� ������ ���������� � �������
(	@s		nvarchar ( max )	-- ������
	,@sDelimeter	varchar ( 32 )=	','	-- ����������� ���������� � ������, ������ �� ���������� ������������� �����
	,@bRefine	bit=		1 )	-- 1=������� ��������� ��������� �� ���������� ��������, ������ ������ ���������; ����� ������� ��� @bRefine=0 ����� ����� ������������ � ������+1
returns	@table	table
(	Sequence	int			-- ������������ ������ ������ �����, smallint �� ��������
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
'					-- ������� ������ �� �������
----------
	/*if	right ( @s , @iDelimeterLen )<>	@sDelimeter */set	@s=	@s+	@sDelimeter	-- ��� ��������� �������� ���������� �������� � ������
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
			cte.Pos<=	@sLen+	1 )	-- ��� �������� ��������� ��������
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
		,Value										-- �������� �� ��������, ������ ���������� ������ ��������
	from
		cte
	where
			@bRefine=	1
		and	replace ( replace ( Value , ' ' , '' ) , @sCRLF , '' )<>	''	-- ���������� ������, �.�. ��������� ������ �� �������� �/��� CRLF
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