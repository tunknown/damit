use	damit
----------
if	object_id ( 'damit.GetFunctionResult' , 'fn' )	is	null
	exec	( 'create	function	damit.GetFunctionResult()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.GetFunctionResult	-- ���������� ������� �� ����� (� ����������� �����)
(	@iExecutionLog	TId
	,@sFunction	nvarchar ( 1024 )	-- �������� ������� �� ��������� �������
	,@sValue	nvarchar ( max ) )	-- �������� �������
returns	nvarchar ( max )
as
begin
	declare	@sResult	nvarchar ( max )
----------
	if	@sFunction	is	null
		set	@sResult=	@sValue
	else
		exec	@sResult=	@sFunction			-- �������� ������� � ������ ���������� � ����������� �����
						@iExecutionLog		-- ��������� � ������������� �������, � �� �� �����
						,@sValue
----------
	return	@sResult
end
go
select	damit.GetFunctionResult	( null,	null,	null )