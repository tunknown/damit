if	db_id ( 'damit' )	is	not	null	-- ����� ������������ ������� ����
	use	damit
go
----------
if	object_id ( 'damit.GetVariable' , 'fn' )	is	null
	exec	( 'create	function	damit.GetVariable()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.GetVariable	-- ��������� ������� �������� ����������, ���� ��� ���� ������ ���������
(	@iExecution	TId	-- �������� ��� ���������� ��� ��������
	,@sAlias	varchar ( 256 ) )
returns	sql_variant				-- ���� ���������� null, �� ������ ������, ������ �� ��� �������� ��� ���������� ����������
as
begin
	declare	@oValue	sql_variant
----------
	select	top	1
		@oValue=	Value
	from
		damit.Variable
	where
			ExecutionLog=	@iExecution
		and	Alias=		@sAlias
	order	by
		Sequence
	if	@@RowCount=	0
	begin
		select
			@iExecution=	Execution
		from
			damit.ExecutionLog
		where
			Id=		@iExecution
----------
		select	top	1
			@oValue=	Value
		from
			damit.Variable
		where
				ExecutionLog=	@iExecution
			and	Alias=		@sAlias
		order	by
			Sequence
	end
----------
	return	@oValue
end
go
use	tempdb
/*
select * from damit.damit.GetVariable ( ',1,2,3,4,' , ',' , 0 )
select * from damit.damit.GetVariable ( ',1,,3
3,4,' , ',' , 1 )
*/