/*
(	a=	1
and	(	b=	2
	or	c=	3 ) )


Id	Parent	FieldName	Operator	Value
0	null	()		and		null
1	0	a		=		1
2	0	()		or		null
3	2	b		=		2
4	2	c		=		3
*/

/*
begin	tran

declare	@p1	int
	,@p2	int

insert	damit.Condition	( Parent,	FieldName,	Operator,	Value,	Sequence )
select	/*0,*/	null,	null,	'and',	null,	null
set	@p1=	@@identity

insert	damit.Condition	( Parent,	FieldName,	Operator,	Value,	Sequence )
select	/*1,*/	@p1/*0*/,	'a',	'=',	'1',	1
insert	damit.Condition	( Parent,	FieldName,	Operator,	Value,	Sequence )
select	/*2,*/	@p1/*0*/,	null,	'or',	null,	2
set	@p2=	@@identity

insert	damit.Condition	( Parent,	FieldName,	Operator,	Value,	Sequence )
select	/*3,*/	@p2/*2*/,	'b',	'=',	'2',	1
insert	damit.Condition	( Parent,	FieldName,	Operator,	Value,	Sequence )
select	/*4,*/	@p2/*2*/,	'c',	'=',	'3',	2

insert	damit.Condition	( Parent,	FieldName,	Operator,	Value,	Sequence )
select	/*5,*/	@p1/*1*/,	'd',	'=',	'4',	3

select * from damit.Condition

rollback
*/

/*
(	a=	1
and	(	b=	2
	or	c=	3 )
and	d=	4 )
*/


use	damit
----------
if	object_id ( 'damit.DoEval' , 'p' )	is	null
	exec	( 'create	proc	damit.DoEval	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoEval	-- ���������� ������� �� �� ����� 10 ������ ����������
	@iExecutionLog		TId
as						-- return=0->������� �� �����������, return=1->������� �����������
-- ������� �� SQL injection
declare	@sMessage		TMessage
	,@iError		TInteger
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=�������� ���������� ���������
	,@sTransaction		TSysName
	,@bAlien		TBoolean

	,@iTask			TId
	,@iExecution		TId
	,@iDistribution		TId

	,@sExec			TScript

	,@iBegin		bigint
	,@iEnd			bigint
	,@iStep			smallint
	,@iCurrent		bigint

	,@gVariableForEach	TGUID

	,@sAliasForEach		TName
	,@iExecutionForEach	TId
	,@iSequenceForEach0	TIntegerNeg
	,@iSequenceForEach1	TIntegerNeg
----------
select
	@iTask=			d.Task
	,@iExecution=		el.Execution
	,@iDistribution=	el.Distribution
from
	damit.ExecutionLog	el
	,damit.Distribution	d
where
		el.Id=		@iExecutionLog
	and	d.Id=		el.Distribution
if	@@RowCount<>	1
begin
	select	@sMessage=	'�������� ������ ��������',
		@iError=	-3
	goto	error
end
----------
select	top	( 1 )	-- �������, �� ���� �������� ��-�� ��������� ������������� ������� 'ForEach'
	@iBegin=		convert ( bigint,	t.Value0 )
	,@iEnd=			convert ( bigint,	t.Value1 )
	,@iStep=		isnull ( convert ( smallint,	t.Value2 ),	1 )	-- ��������������� ��� ����������� �������������� �����
	,@iCurrent=		convert ( bigint,	t.Value3 )
	,@gVariableForEach=	t.Variable4
from
	damit.GetVariables	( @iExecutionLog,	'Begin',	'End',	'Step',	'Current',	'ForEach',	default,	default,	default,	default,	default )	t
--where
--	t.Sequence=	1					-- �������� ������ ���� ����� ����, � �� ������ �� ����������
if	@@Error<>	0	or	1<	@@RowCount
begin
	select	@sMessage=	'�������� ������ ��������� ��� For',
		@iError=	-3
	goto	error
end
----------
if	@iEnd	is	not	null				-- ��� ���� �� ��������
begin
	if	@iCurrent	is	null
		select	@iCurrent=	@iBegin			-- ������ ���� � ����
			,@sMessage=	'�������������'
	else
		select	@iCurrent=	@iCurrent+	@iStep
			,@sMessage=	'�����������'
----------
	exec	@iError=	damit.SetupVariable
					@iExecutionLog=	@iExecutionLog
					,@sAlias=	'Current'
					,@oValue=	@iCurrent
					,@iSequence=	1	-- insert or update
	if	@@Error<>	0	or	@iError<	0
	begin
		select	@sMessage=	'������ '+	isnull ( @sMessage,	'' )+	' �����',
			@iError=	-3
		goto	error
	end
end
----------
if	@gVariableForEach	is	not	null
begin
	-- ������� � ������� ForEach ��������� IsCurrent � ������� ���������� ��� ���������� Squence �������� sign('Step')
	if	0<	@iStep
		select
			@sAliasForEach=		p1.Alias
			,@iExecutionForEach=	p1.ExecutionLog
			,@iSequenceForEach0=	max ( c1.Sequence )
			,@iSequenceForEach1=	min ( p1.Sequence )
		from
			damit.Variable	p0
			inner	join	damit.Variable	p1	on
				p1.ExecutionLog=p0.ExecutionLog
			and	p1.Alias=	p0.Alias
			and	isnull ( p1.IsCurrent,	0 )=	0	-- ��������� � ��� ����������������� ����� � ��� ���������, �.�. ��������� ��� ������; ��� ��������� ������� � ��� damit.GetVariables('ForEach') ������ ���������� ��� IsCurrent=1 ��-�� ���������� ������
			left	join	damit.Variable	c1	on
				c1.ExecutionLog=p0.ExecutionLog
			and	c1.Alias=	p0.Alias
			and	c1.IsCurrent=	1
		where
				p0.Id=		@gVariableForEach
		group	by
			p1.Alias
			,p1.ExecutionLog
		having
			max ( c1.Sequence )<	min ( p1.Sequence )
	else
		select
			@sAliasForEach=		p1.Alias
			,@iExecutionForEach=	p1.ExecutionLog
			,@iSequenceForEach0=	min ( c1.Sequence )
			,@iSequenceForEach1=	max ( p1.Sequence )
		from
			damit.Variable	p0
			inner	join	damit.Variable	p1	on
				p1.ExecutionLog=p0.ExecutionLog
			and	p1.Alias=	p0.Alias
			and	isnull ( p1.IsCurrent,	0 )=	0	-- ��������� � ��� ����������������� ����� � ��� ���������, �.�. ��������� ��� ������; ��� ��������� ������� � ��� damit.GetVariables('ForEach') ������ ���������� ��� IsCurrent=1 ��-�� ���������� ������
			left	join	damit.Variable	c1	on
				c1.ExecutionLog=p0.ExecutionLog
			and	c1.Alias=	p0.Alias
			and	c1.IsCurrent=	1
		where
				p0.Id=		@gVariableForEach
		group	by
			p1.Alias
			,p1.ExecutionLog
		having
			max ( p1.Sequence )<	min ( c1.Sequence )
----------
	-- ����������� � ������� ForEach �� ��������� IsCurrent
	update
		damit.Variable
	set
		IsCurrent=	case	Sequence
					when	@iSequenceForEach0	then	null
					when	@iSequenceForEach1	then	1
				end
	where
			Alias=		@sAliasForEach
		and	ExecutionLog=	@iExecutionForEach
		and	Sequence	in	( @iSequenceForEach0,	@iSequenceForEach1 )
	if	@@Error<>	0	or	@@RowCount	not	in	( 1,	2 )
	begin
		select	@sMessage=	'������ ������������� �����',
			@iError=	-3
		goto	error
	end
end
----------
;with	cte0	as
(	select
		Id
		,Parent
		,FieldName
		,Operator
		,Value
		,Stack=		convert ( varchar ( 8000 ),	case
									when	Operator	in	( 'and',	'or' )	then	convert ( char ( 3 ),	Operator )
									else								''
								end )
		,Sequence2=	isnull ( Sequence,	0 )
		,SequenceBin=	convert ( varbinary ( 8000 ),	convert ( binary ( 2 ),	 isnull ( Sequence,	0 ) ) )
	from
		damit.Condition
	where
		Id=	@iTask
	union	all
	select
		Id=		0x7FFFFFFF
		,Parent=	null
		,FieldName=	null
		,Operator=	null
		,Value=		null
		,Stack=		convert ( varchar ( 8000 ),	'' )
		,Sequence2=	0x7FFF
		,SequenceBin=	convert ( varbinary ( 8000 ),	0x7FFF )	-- �������������� ������ ��� ��������� ����������� ������
	from
		damit.Condition
	where
		Id=	@iTask
	union	all
	select
		c.Id
		,c.Parent
		,c.FieldName
		,c.Operator
		,c.Value
		,Stack=		p.Stack+	case
							when	c.Operator	in	( 'and',	'or' )	then	convert ( char ( 3 ),	c.Operator )
							else								''
						end
		,Sequence2=	convert ( smallint,	row_number()	over	( partition	by	c.Parent	order	by	c.Sequence ) )
		,SequenceBin=	p.SequenceBin+	convert ( binary ( 2 ),	 convert ( smallint,	row_number()	over	( partition	by	c.Parent	order	by	c.Sequence ) ) )
	from
		damit.Condition	c
		,cte0		p
	where
		c.Parent=	p.Id )
,	cte1	as
(	select
		Parent
		,FieldName
		,Operator
		,Value
		,Stack
		,Sequence2
		,SequenceBin

		,basetype=	case
					when	Value	is	null	then	'varbinary'
					else					convert ( sysname,		SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )
				end
		,Precision=	convert ( varchar ( 2 ),	SQL_VARIANT_PROPERTY ( Value,	'Precision' ) )
		,Scale=		convert ( varchar ( 2 ),	SQL_VARIANT_PROPERTY ( Value,	'Scale' ) )
		,MaxLength=	case
					when	Value	is	null	then	-1
					else					SQL_VARIANT_PROPERTY ( Value,	'MaxLength' )
				end
	from
		cte0 )
,	cte	as
(	select
		Parent
		,FieldName
		,Operator
		,Value
		,Stack
		,Sequence2
		,SequenceAll=	row_number()	over	( order		by
								SequenceBin )
		,SequenceField=	dense_rank()	over	( partition	by	-- dense_rank ��� ���������� ������ ���� ��������� ��� � ���� ����� ���� �����
								case
									when	FieldName	is	null	then	0
									else						1
								end
							order		by
								SequenceBin )
		,DataType=	convert ( varchar ( 256 ),	case
									when	basetype	like	'%binary'				then	basetype+	'('+	case	MaxLength	when	-1	then	'max'	else	convert ( varchar ( 4 ),	MaxLength )	end+	')'
									when	basetype	like	'n%char'				then	basetype+	'('+	convert ( varchar ( 4 ),	convert ( smallint,	MaxLength )/	2 )+	')'
									when	basetype	like	'%char'/*%char ������ ����� n%char*/	then	basetype+	'('+	convert ( varchar ( 4 ),	MaxLength )+					')'
									when	basetype	in	( 'decimal',	'numeric' )		then	basetype+	'('+	Precision+	','+	Scale+							')'
									else										basetype
								end )
	from
		cte1 )
--select	*	from	cte	order	by	SequenceAll
select	@sExec=	'
select
	@iRowCount=	sign ( count ( * ) )
from
	damit.GetVariables ( @iExecutionLog'
	+	( select	distinct			-- distinct ��� ������������� ����� � �������
			[data()]=	',	/*'
				+	convert ( varchar ( 1 ),	cur.SequenceField-	1 )
				+	'*/'''
				+	cur.FieldName+	''''
		from
			cte	cur
			,cte	next
		where
			next.SequenceAll=	cur.SequenceAll+	1
		order	by
			1--cur.SequenceField
		for
			xml	path ( '' ),	TYPE ).value ( '.',	'nvarchar(max)' )
	+	replicate ( ',	default',	10-	( select	max ( SequenceField )	from	cte	where	FieldName	is	not	null ) )	-- � damit.GetVariables �� ����� 10 ���������� ����������
	+' )	t
where
	'+	( select
			[data()]=	case
						when		cur.FieldName	is		null
							and	3<	len ( cur.Stack )		then	rtrim ( left ( right ( cur.Stack,	6 ),	3 ) )
						else								''
					end
				+	case
						when		cur.FieldName	is		null
							or	cur.SequenceAll=	1		then	'('	-- ������ ����������� ������ ������� �������� ������
						else								''
					end
				+	case
						when		cur.FieldName	is	not	null
							and	1<	cur.Sequence2			then	rtrim ( right ( cur.Stack,	3 ) )
						else								''
					end
				+	case
						when		cur.FieldName	is		null	then	''
						else								' (/*1*/convert ( '+	cur.DataType+	',	t.Value'+	convert ( varchar ( 1 ),	cur.SequenceField-	1 )+	' )'
					end
				+	case
						when		cur.FieldName	is	not	null	then	case
															when	cur.Value	is	null	then	'	is	'
																				+	case	cur.Operator
																						when	'='	then	''
																						when	'<>'	then	'not'
																						else			null	-- ������ ���������� dbo.Condition?
																					end
																				+	'	null	'
																				+	case	cur.Operator
																						when	'='	then	'and'
																						when	'<>'	then	'or'
																						else			null	-- ������ ���������� dbo.Condition?
																					end
																				+	'	damit.GetVariableBLOB ( @iExecutionLog,	t.Variable'
																				+	convert ( varchar ( 1 ),	cur.SequenceField-	1 )
																				+	' )	is	'
																				+	case	cur.Operator
																						when	'='	then	''
																						when	'<>'	then	'not'
																						else			null	-- ������ ���������� dbo.Condition?
																					end
																				+	'	null'	-- ���� ��� ������ �� ����������� � varchar(8000), �� ����� ��������� �� null
															else						cur.Operator+	convert ( nvarchar ( 4000 ),	cur.Value )
														end
													+	'/*1*/)'
						else								''
					end
				+	case
						when		cur.FieldName	is	not	null
							and	(	cur.Parent<>	next.Parent
								or	next.Parent	is	null )	then	')'	-- ��������� ����������� ������ ������� �������� ������
						else								''
					end
		from
			cte	cur
			,cte	next
		where
			next.SequenceAll=	cur.SequenceAll+	1
		order	by
			cur.SequenceAll
		for
			xml	path ( '' ),	TYPE ).value ( '.',	'nvarchar(max)' )
----------
if	@bDebug=	1
	print	@sExec
----------
exec	@iError=	sp_executesql
				@statement=	@sExec
				,@params=	N'@iExecutionLog	bigint,	@iRowCount	int	out'
				,@iExecutionLog=@iExecutionLog
				,@iRowCount=	@iRowCount	out
if	@@Error<>	0	or	@iError<>	0
begin
	select	@sMessage=	'������ �������� �������, ��������, �������� ������',
		@iError=	-3
	goto	error
end
----------
set	@iError=	@iRowCount	-- 1=true, ������� ���������
----------
if	@iRowCount=	0
begin
	if	@iEnd	is	not	null
	begin
		---��� ��������� ����� � ���� ������� 'Current', ����� ��� ��������� ������������� ����� � ��� �� ��������(��-�� goto �� ����������� � ���������� �����) �� �������
		exec	@iError=	damit.SetupVariable
						@iExecutionLog=	@iExecutionLog
						,@sAlias=	'Current'
						,@oValue=	null
						,@iSequence=	1	-- insert or update
		if	@@Error<>	0	or	@iError<	0
		begin
			select	@sMessage=	'������ ������������� �����',
				@iError=	-3
			goto	error
		end
	end
----------
	if	@gVariableForEach	is	not	null
	begin
		---��� ��������� ����� � ���� ������� 'ForEach.IsCurrent', ����� ��� ��������� ������������� ����� � ��� �� ��������(��-�� goto �� ����������� � ���������� �����) �� �������
		update
			v1
		set
			IsCurrent=	null
		from
			damit.Variable	v0
			,damit.Variable	v1
		where
				v0.Id=		@gVariableForEach	-- �� �������, ��� ��� damit.GetVariables('ForEach') ������ ���������� ��� IsCurrent=1
			and	v1.ExecutionLog=v0.ExecutionLog
			and	v1.Alias=	v0.Alias
		if	@@Error<>	0	or	@@RowCount=	0
		begin
			select	@sMessage=	'������ ��������������� �����',
				@iError=	-3
			goto	error
		end
	end
end
----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go
use	tempdb