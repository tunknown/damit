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
alter	proc	damit.DoEval	-- вычисление условия из не более 10 разных переменных
	@gExecutionLog		damit.TGUID
as						-- return=0->условие НЕ выполняется, return=1->условие выполняется
-- следить за SQL injection
declare	@sMessage		TMessage
	,@iError		TInteger
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	0	-- 1=включить отладочные сообщения
	,@sTransaction		TSysName
	,@bAlien		TBoolean

	,@gTask			TGUID
	,@gExecution		TGUID
	,@gDistribution		TGUID

	,@sExec			TScript

	,@iBegin		bigint
	,@iEnd			bigint
	,@iStep			smallint
	,@iCurrent		bigint

	,@gVariableForEach	TGUID

	,@sAliasForEach		TName
	,@gExecutionForEach	TGUID
	,@iSequenceForEach0	TIntegerNeg
	,@iSequenceForEach1	TIntegerNeg
----------
select
	@gTask=			d.Task
	,@gExecution=		el.Execution
	,@gDistribution=	el.Distribution
from
	damit.ExecutionLog	el
	,damit.Distribution	d
where
		el.Id=		@gExecutionLog
	and	d.Id=		el.Distribution
if	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибочно задана выгрузка',
		@iError=	-3
	goto	error
end
----------
select	top	( 1 )	-- неверно, но пока пришлось из-за возможных множественных записей 'ForEach'
	@iBegin=		convert ( bigint,	t.Value0 )
	,@iEnd=			convert ( bigint,	t.Value1 )
	,@iStep=		isnull ( convert ( smallint,	t.Value2 ),	1 )	-- преимущественно для возможности отрицательного счёта
	,@iCurrent=		convert ( bigint,	t.Value3 )
	,@gVariableForEach=	t.Variable4
from
	damit.GetVariables	( @gExecutionLog,	'Begin',	'End',	'Step',	'Current',	'ForEach',	default,	default,	default,	default,	default )	t
--where
--	t.Sequence=	1	-- параметр должен быть всего один, а не первый из нескольких
if	@@Error<>	0	or	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибочно заданы параметры для For',
		@iError=	-3
	goto	error
end
----------
if	@iEnd	is	not	null	-- это цикл по счётчику
begin
	if	@iCurrent	is	null	-- первый вход в цикл
	begin
		exec	@iError=	damit.SetupVariable
						@gExecutionLog=	@gExecutionLog
						,@sAlias=	'Current'
						,@oValue=	@iBegin
						,@iSequence=	1	-- insert or update
		if	@@Error<>	0	or	@iError<	0
		begin
			select	@sMessage=	'Ошибка инициализации цикла',
				@iError=	-3
			goto	error
		end
	end
	else
	begin
		set	@iCurrent=	@iCurrent+	@iStep
----------
		exec	@iError=	damit.SetupVariable
						@gExecutionLog=	@gExecutionLog
						,@sAlias=	'Current'
						,@oValue=	@iCurrent
						,@iSequence=	1	-- insert or update
		if	@@Error<>	0	or	@iError<	0
		begin
			select	@sMessage=	'Ошибка инициализации цикла',
				@iError=	-3
			goto	error
		end
	end
end
----------
if	@gVariableForEach	is	not	null
begin
	-- выбрать в массиве ForEach следующую IsCurrent в сторону увеличения или уменьшения Squence согласно sign('Step')
	if	0<	@iStep
		select
			@sAliasForEach=		p1.Alias
			,@gExecutionForEach=	p1.ExecutionLog
			,@iSequenceForEach0=	max ( c1.Sequence )
			,@iSequenceForEach1=	min ( p1.Sequence )
		from
			damit.Variable	p0
			inner	join	damit.Variable	p1	on
				p1.ExecutionLog=p0.ExecutionLog
			and	p1.Alias=	p0.Alias
			and	isnull ( p1.IsCurrent,	0 )=	0	-- сработает и при инициализационном входе и при следующих, т.к. проверяем всю группу; при следующих заходах в шаг damit.GetVariables('ForEach') выдаст переменную для IsCurrent=1 из-за внутренней логики
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
			,@gExecutionForEach=	p1.ExecutionLog
			,@iSequenceForEach0=	min ( c1.Sequence )
			,@iSequenceForEach1=	max ( p1.Sequence )
		from
			damit.Variable	p0
			inner	join	damit.Variable	p1	on
				p1.ExecutionLog=p0.ExecutionLog
			and	p1.Alias=	p0.Alias
			and	isnull ( p1.IsCurrent,	0 )=	0	-- сработает и при инициализационном входе и при следующих, т.к. проверяем всю группу; при следующих заходах в шаг damit.GetVariables('ForEach') выдаст переменную для IsCurrent=1 из-за внутренней логики
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
	-- переключить в массиве ForEach на следующую IsCurrent
	update
		damit.Variable
	set
		IsCurrent=	case	Sequence
					when	@iSequenceForEach0	then	null
					when	@iSequenceForEach1	then	1
				end
	where
			Alias=		@sAliasForEach
		and	ExecutionLog=	@gExecutionForEach
		and	Sequence	in	( @iSequenceForEach0,	@iSequenceForEach1 )
	if	@@Error<>	0	or	@@RowCount	not	in	( 1,	2 )
	begin
		select	@sMessage=	'Ошибка инициализации цикла',
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
		Id=	@gTask
	union	all
	select
		Id=		0x7FFFFFFF
		,Parent=	null
		,FieldName=	null
		,Operator=	null
		,Value=		null
		,Stack=		convert ( varchar ( 8000 ),	'' )
		,Sequence2=	0x7FFF
		,SequenceBin=	convert ( varbinary ( 8000 ),	0x7FFF )
	from
		damit.Condition
	where
		Id=	@gTask
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
		,SequenceField=	dense_rank()	over	( partition	by	-- dense_rank при упоминании одного поля несколько раз у него будет один номер
								case
									when	FieldName	is	null	then	0
									else						1
								end
							order		by
								SequenceBin )
		,DataType=	convert ( varchar ( 256 ),	case
									when	convert ( sysname,	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )	like	'%binary'			then	convert ( varchar ( 256 ),	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )+	'('+	convert ( varchar ( 4 ),	convert ( smallint,	SQL_VARIANT_PROPERTY ( Value,	'MaxLength' ) ) )+	')'
									when	convert ( sysname,	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )	like	'n%char'			then	convert ( varchar ( 256 ),	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )+	'('+	convert ( varchar ( 4 ),	convert ( smallint,	SQL_VARIANT_PROPERTY ( Value,	'MaxLength' ) )/	2 )+	')'
									-- %char строго позже n%char
									when	convert ( sysname,	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )	like	'%char'				then	convert ( varchar ( 256 ),	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )+	'('+	convert ( varchar ( 4 ),	convert ( smallint,	SQL_VARIANT_PROPERTY ( Value,	'MaxLength' ) ) )+	')'
									when	convert ( sysname,	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )	in	( 'decimal',	'numeric' )	then	convert ( varchar ( 256 ),	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )+	'('+	convert ( varchar ( 2 ),	convert ( tinyint,	SQL_VARIANT_PROPERTY ( Value,	'Precision' ) ) )+	','+	convert ( varchar ( 2 ),	convert ( tinyint,	SQL_VARIANT_PROPERTY ( Value,	'Scale' ) ) )+	')'
									else																convert ( varchar ( 256 ),	SQL_VARIANT_PROPERTY ( Value,	'basetype' ) )
								end )
	from
		cte0 )
--select	*	from	cte	order	by	SequenceAll
select	@sExec=	'
select
	@iRowCount=	sign ( count ( * ) )
from
	damit.GetVariables ( @gExecutionLog'
	+	( select	distinct			-- distinct для повторяющихся полей в условии
			[data()]=	',	/*'+	convert ( varchar ( 1 ),	cur.SequenceField-	1 )+	'*/'''+	cur.FieldName+	''''
		from
			cte	cur
			,cte	next
		where
			next.SequenceAll=	cur.SequenceAll+	1
		order	by
			1--cur.SequenceField
		for
			xml	path ( '' ) )
	+	replicate ( ',	default',	10-	( select	max ( SequenceField )	from	cte	where	FieldName	is	not	null ) )
	+' )	t
where
	'+	( select
			[data()]=	case
						when		cur.FieldName	is	null
							and	3<	len ( cur.Stack )		then	rtrim ( left ( right ( cur.Stack,	6 ),	3 ) )
						else								''
					end
				+	case
						when		cur.FieldName	is	null
							or	cur.SequenceAll=	1		then	'('	-- первая закрывающая скобка условия ставится всегда
						else								''
					end
				+	case
						when		1<	cur.Sequence2
							and	cur.FieldName	is	not	null	then	rtrim ( right ( cur.Stack,	3 ) )
						else								''
					end
				+	case
						when	cur.FieldName		is	null		then	''
						else								' convert ( '+	cur.DataType+	',	t.Value'+	convert ( varchar ( 2 ),	cur.SequenceField-	1 )+	' )'
					end
				+	case
						when	cur.FieldName	is	not	null		then	cur.Operator+	isnull ( convert ( nvarchar ( 4000 ),	cur.Value ),	'null' )	-- =null -> is null при других операторах ошибка
						else								''
					end
				+	case
						when		(	cur.Parent<>	next.Parent
								or	next.Parent	is	null )
							and	cur.FieldName	is	not	null	then	')'	-- последняя закрывающая скобка условия ставится всегда
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
			xml	path ( '' ) )	-- после xml нужно восстановить Predefined entities in XML
----------
set	@sExec=	replace (
		replace (
		replace (
		replace (
		replace (
		@sExec
		,'&amp;',	'&' )
		,'&apos;',	'''' )
		,'&quot;',	'"' )
		,'&lt;',	'<' )
		,'&gt;',	'>' )
----------
exec	sp_executesql
		@statement=	@sExec
		,@params=	N'@gExecutionLog	uniqueidentifier,	@iRowCount	int	out'
		,@gExecutionLog=@gExecutionLog
		,@iRowCount=	@iRowCount	out
if	@@Error<>	0	--or	@@RowCount=	0
begin
	select	@sMessage=	'Не удалось проверить фильтрацию',
		@iError=	-3
	goto	error
end
----------
set	@iError=	@iRowCount	-- 1=true, условие выполнено
----------
if	@iRowCount=	0
begin
	if	@iEnd	is	not	null
	begin
		---при последнем входе в цикл очищать 'Current', чтобы при следующей инициализации цикла в той же выгрузке(из-за goto не относящейся к завершению цикла) он работал
		exec	@iError=	damit.SetupVariable
						@gExecutionLog=	@gExecutionLog
						,@sAlias=	'Current'
						,@oValue=	null
						,@iSequence=	1	-- insert or update
		if	@@Error<>	0	or	@iError<	0
		begin
			select	@sMessage=	'Ошибка инициализации цикла',
				@iError=	-3
			goto	error
		end
	end
----------
	if	@gVariableForEach	is	not	null
	begin
		---при последнем входе в цикл очищать 'ForEach.IsCurrent', чтобы при следующей инициализации цикла в той же выгрузке(из-за goto не относящейся к завершению цикла) он работал
		update
			v1
		set
			IsCurrent=	null
		from
			damit.Variable	v0
			,damit.Variable	v1
		where
				v0.Id=		@gVariableForEach	-- не надеясь, что шаг damit.GetVariables('ForEach') выдаст переменную для IsCurrent=1
			and	v1.ExecutionLog=v0.ExecutionLog
			and	v1.Alias=	v0.Alias
		if	@@Error<>	0	or	@@RowCount=	0
		begin
			select	@sMessage=	'Ошибка деинициализации цикла',
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