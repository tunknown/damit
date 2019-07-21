use	damit
----------
if	object_id ( 'damit.SetupVariable' , 'p' )	is	null
	exec	( 'create	proc	damit.SetupVariable	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.SetupVariable
--	@gId		TGUID=		null	output
	@iExecutionLog	TId
	,@sAlias	TName
	,@oValue	sql_variant=	null
	,@mValue	image=		null
	,@iSequence	TIntegerNeg=	null
	,@bAdd		bit=		null
	,@bRemove	bit=		null
as
----------
set	nocount	on
----------
declare	@sMessage	TMessage
	,@iError	TInteger=	0
	,@iRowCount	TInteger
	,@bDebug	TBoolean=	1	-- 1=включить отладочные сообщения
	,@sTransaction	TSysName
	,@bAlien	TBoolean
	,@iError2	TInteger=	0

	,@iExecution	TId
	,@iSequenceEx	TInteger
	,@dtStart	TDateTime
----------
select
	@iExecution=	Execution
	,@iSequenceEx=	Sequence
	,@dtStart=	Start
from
	damit.ExecutionLog
where
	Id=		@iExecutionLog
----------
if	exists	( select
			1
		from
			damit.ExecutionLog
		where
				Execution=	@iExecution
			and	@iSequenceEx<=	Sequence
			and	Id<>		@iExecutionLog		-- исключаем себя, т.к. применяем <= для Sequence
			and	Execution<>	@iExecutionLog		-- можно менять только "общие" переменные корневого шага
		union	all
		select
			1
		from
			damit.ExecutionLog
		where
				Execution=	@iExecution
			and	@dtStart<=	Start
			and	Id<>		@iExecutionLog
			and	Execution<>	@iExecutionLog )	-- исключаем себя, т.к. применяем <= для Start
begin
	select	@sMessage=	'Нельзя менять переменные другого шага',
		@iError=	-3
	goto	error
end
----------
if		@oValue	is	not	null
	and	@mValue	is	not	null
begin
	select	@sMessage=	'Ошибка',
		@iError=	-3
	goto	error
end
----------
if	@bRemove=	1
begin
	if	@oValue	is	not	null
	begin
		select	@sMessage=	'Ошибка',
			@iError=	-3
		goto	error
	end
----------
	delete
		damit.Variable
	where
			Alias=		@sAlias
		and	( ExecutionLog=	@iExecutionLog	or	@iExecutionLog	is	null	and	ExecutionLog	is	null )
		and	( Sequence=	@iSequence	or	@iSequence	is	null )
	if	@@Error<>	0
	begin
		select	@sMessage=	'Ошибка',
			@iError=	-3
		goto	error
	end
end
----------
if	@bAdd=	1
begin
	if	@iSequence	is	not	null
	begin
		select	@sMessage=	'Ошибка',
			@iError=	-3
		goto	error
	end
----------
	set	@iSequence=	isnull ( ( select
						max ( Sequence )
					from
						damit.Variable
					where
							( ExecutionLog=	@iExecutionLog	or	@iExecutionLog	is	null	and	ExecutionLog	is	null )
						and	Alias=		@sAlias ) , 0 )+	1
end
else
begin
	update
		damit.Variable
	set
		Value=		@oValue
		,ValueBLOB=	@mValue
	where
			ExecutionLog=	@iExecutionLog
		and	Alias=		@sAlias
		and	(	Sequence=	@iSequence
			or	isnull ( Sequence,	@iSequence )	is	null )
	select	@iError=	@@Error
		,@iRowCount=	@@RowCount
	if	@iError<>	0	or	@iRowCount>	1
	begin
		select	@sMessage=	'Ошибка',
			@iError=	-3
		goto	error
	end
end
----------
if	@bAdd=	1	or	@iRowCount=	0
begin
	insert	damit.Variable	( ExecutionLog,	Alias,	Value,	ValueBLOB,	Sequence )
	select			@iExecutionLog,	@sAlias,@oValue,@mValue,	@iSequence
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'Ошибка',
			@iError=	-3
		goto	error
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