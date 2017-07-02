use	damit
----------
if	object_id ( 'damit.DoSave' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSave	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSave
	@gExecutionLog		TGUID
as
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=включить отладочные сообщения

	,@gData			TGUID
	,@sLogTable		TSystemName
	,@sFieldsSortQuoted	TSystemName=	''
	,@bCanBlank		TBool
	,@sSaveProc		TSystemName

	,@sExec			nvarchar ( max )=	''
	,@sExec1		varchar ( max )=	''
	,@sExec2		varchar ( max )=	''

	,@sFileName		nvarchar ( 4000 )

	,@gExecution		TGUID
	,@gExecutionLogData	TGUID
	,@gDistribution		TGUID
----------
select
	@gExecution=	dl.Execution
	,@gDistribution=dl.Distribution
from
	damit.ExecutionLog	dl
where
	dl.Id=		@gExecutionLog
if	@@rowcount<>	1
begin
	select	@sMessage=	'Ошибка передачи параметров',
		@iError=	-3
	goto	error
end
----------
select
	@bCanBlank=	f.CanBlank
	,@sSaveProc=	s.Saver
from
	damit.Distribution	d
	,damit.Format		f
	,damit.Storage		s
where
		d.Id=		@gDistribution
	and	f.Id=		d.Task
	and	s.Id=		f.Storage
if	@@error<>	0	or	@@rowcount<>	1
begin
	select	@sMessage=	'Ошибка передачи параметров',
		@iError=	-3
	goto	error
end
----------
select	@gExecutionLogData=	convert ( uniqueidentifier , Value0 )	from	damit.GetVariables ( @gExecutionLog,	'Data:ExecutionLog',	default,	default,	default,	default,	default,	default,	default,	default,	default )
if	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибочно',
		@iError=	-3
	goto	error
end
----------
select
	@gData=		da.Id
	,@sLogTable=	da.DataLog
from
	damit.ExecutionLog	el
	,damit.Distribution	d
	,damit.Data		da
where
		el.Id=		@gExecutionLogData
	and	d.Id=		el.Distribution
	and	da.Id=		d.Task
if	@@rowcount<>	1
begin
	select	@sMessage=	'Ошибка передачи параметров',
		@iError=	-3
	goto	error
end
----------
select
	@sExec=	'select
	@iRowCount=	count ( * )
from
	'+	@sLogTable+	'	with	( tablock , holdlock )
where
	ExecutionLog=	'''+	convert ( varchar ( 36 ) , @gExecutionLogData )+	''''
----------
exec	sp_executesql
		@statement=	@sExec
		,@params=	N'@iRowCount	int	output'
		,@iRowCount=	@iRowCount	output
----------
if	@iRowCount<>	0	or	@bCanBlank=	1
begin
	select	@sExec1=	''
		,@sExec2=	''
----------
	select
		@sExec1=	@sExec1+	''''+	replace ( FieldName,	'''',	'''''' )+	''','	-- последнюю запятую нужно отрезать; если в имени поля есть одинарная кавычка
		,@sExec2=	@sExec2+	quotename ( FieldName )+	','			-- последнюю запятую нужно отрезать
	from
		damit.DataField
	where
			IsResultset=	1
		and	Data=		@gData
	order	by
		Sequence
		,FieldName
----------
	select
		@sFieldsSortQuoted=	@sFieldsSortQuoted+	',	'+	quotename ( FieldName )+	case
															when	Sort<	0	then	'	desc'
															else				''
														end
	from
		damit.DataField
	where
			Data=		@gData
		and	Sort	is	not	null
	order	by
		abs ( Sort )
		,Sequence
		,FieldName
----------
	if	len ( @sFieldsSortQuoted )>	0
	begin
		set	@sFieldsSortQuoted=	right ( @sFieldsSortQuoted , len ( @sFieldsSortQuoted )-	2 )
	--	if	@bDebug=	1	select	( @sFieldsSortQuoted )
	end
	else
		set	@sFieldsSortQuoted=	null
----------
	if	@bDebug=	1
	begin
		print	@sExec1
		print	@sExec2
	end
----------
	select	@sExec1=	'select	'+	left ( @sExec1,	len ( @sExec1 )-	1 )		-- с этим условием пишем только мы, поэтому можно использовать hint=nolock, чтобы bcp не зависло на ожидании, если есть транзакция
		,@sExec2=	'select	'+	left ( @sExec2,	len ( @sExec2 )-	1 )+	'	from	'+	@sLogTable+	'	with	( nolock )	where	ExecutionLog=	'''+	convert ( char ( 36 ) , @gExecutionLogData )+	''''+	isnull ( '	order	by	'+	@sFieldsSortQuoted , '' )
----------
	if	@bDebug=	1
	begin
		print	( @sExec2 )
		--select	*	from	damit.damit.ExecutionLog	where	Execution=	@gExecution
	end
----------
	exec	@iError=	@sSaveProc
					@gExecutionLog=	@gExecutionLog
					,@sQueryHeader=	@sExec1
					,@sQueryData=	@sExec2
					,@sFileName=	@sFileName	output
	if	@@Error<>	0	or	@iError<	0
	begin
		select	@sMessage=	'Ошибка записи данных',
			@iError=	-3
		goto	error
	end
----------
	exec	@iError=	damit.SetupVariable
					@gExecutionLog=	@gExecutionLog
					,@sAlias=	'FileName'
					,@oValue=	@sFileName
	if	@@Error<>	0	or	@iError<	0
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
use	tempdb