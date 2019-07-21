use	damit
----------
if	object_id ( 'damit.GetReplacement' , 'fn' )	is	null
	exec	( 'create	function	damit.GetReplacement()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.GetReplacement	-- ���������� ���������� ��� ��������� � ��������� ��������� ����������
(	@iExecutionLog	TId
	,@sValue	nvarchar ( max )=	null	)	-- ��� ���������� ��� ����� � ��������� ��� �����������
returns	nvarchar ( max )	-- ''=������
as
begin
	declare	@bIsProcessed	TBool
		,@sResult	nvarchar ( max )
		,@c		cursor
		,@sAlias	TName
----------
	if	@sValue	like	'%(*%*)%'
		set	@sResult=	@sValue
	else
		select
			@sResult=	damit.GetFunctionResult ( @iExecutionLog,	Expression0,	Value0 )
		from
			( select
				Expression0
				,Value0=	convert ( nvarchar ( 4000 ),	Value0 )
			from
				damit.GetVariables ( @iExecutionLog,	@sValue,	default,	default,	default,	default,	default,	default,	default,	default,	default ) )	t
----------
	if	@sResult	like	'%(*%*)%'	-- '%(*%[^*()]%*)%' �� �������, �.�. ����� ���� ��������� ����������
	begin
		set	@c=	cursor	local	fast_forward	for
					select	distinct					-- ��������� ��������� ������������� ��������� ��-�� �������������
						Name
					from
						damit.GetVariablesList ( @iExecutionLog )
					order	by
						Name
----------
		set	@bIsProcessed=	1
----------
		while	@bIsProcessed=	1	-- ���������, ���� ���� ��������� ���������� �� ����� ��������
		begin
			open	@c
----------
			set	@bIsProcessed=	0
----------
			while	1=	1
			begin
				fetch	next	from	@c	into	@sAlias
				if	@@fetch_status<>	0	break
----------
				if	@sResult	like	'%(*'+	@sAlias+	'*)%'
					select
						@sResult=	replace ( @sResult,	'(*'+	@sAlias+	'*)',	case	isnull ( Sequence,	1 )
																when	1	then	''
																else			'(*'+	@sAlias+	'*)'	-- ���� ����� �������� �������� ���������� ���������� �������, �� ����� ��������� ������ �� ��������� ������
															end+	damit.GetFunctionResult ( @iExecutionLog,	Expression0,	Value0 ) )
						,@bIsProcessed=	1
					from
						( select
							Expression0
							,Value0=	convert ( nvarchar ( 4000 ),	Value0 )
							,Sequence
						from
							damit.GetVariables ( @iExecutionLog,	@sAlias,	default,	default,	default,	default,	default,	default,	default,	default,	default ) )	t
					order	by
						Sequence	desc
			end
----------
			close	@c
		end
----------
		deallocate	@c
----------
		if	@sResult	like	'%(*%*)%'
			set	@sResult=	''	--������: ����������� ������� � ������� ������� ��� ����� �����
	end
----------
	return	@sResult
end
go
select	damit.GetReplacement	(null,	null)