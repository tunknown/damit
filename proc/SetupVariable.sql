use	damit
----------
if	object_id ( 'damit.SetupVariable' , 'p' )	is	null
	exec	( 'create	proc	damit.SetupVariable	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.SetupVariable
--	@gId		TGUID=		null	output
	@gExecutionLog	TGUID
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

	,@gExecution	TGUID
	,@iSequenceEx	TInteger
	,@dtStart	TDateTime
----------
select
	@gExecution=	Execution
	,@iSequenceEx=	Sequence
	,@dtStart=	Start
from
	damit.ExecutionLog
where
	Id=		@gExecutionLog
----------
if	exists	( select
			1
		from
			damit.ExecutionLog
		where
				Execution=	@gExecution
			and	@iSequenceEx<=	Sequence
			and	Id<>		@gExecutionLog		-- исключаем себя, т.к. применяем <= для Sequence
			and	Execution<>	@gExecutionLog		-- можно менять только "общие" переменные корневого шага
		union	all
		select
			1
		from
			damit.ExecutionLog
		where
				Execution=	@gExecution
			and	@dtStart<=	Start
			and	Id<>		@gExecutionLog
			and	Execution<>	@gExecutionLog )	-- исключаем себя, т.к. применяем <= для Start
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
		and	( ExecutionLog=	@gExecutionLog	or	@gExecutionLog	is	null	and	ExecutionLog	is	null )
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
							( ExecutionLog=	@gExecutionLog	or	@gExecutionLog	is	null	and	ExecutionLog	is	null )
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
			ExecutionLog=	@gExecutionLog
		and	Alias=		@sAlias
		and	Sequence=	@iSequence
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
	insert	damit.Variable	( Id,	ExecutionLog,	Alias,	Value,	ValueBLOB,	Sequence )
	select			newid(),@gExecutionLog,	@sAlias,@oValue,@mValue,	@iSequence
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