use	damit
----------
if	object_id ( 'damit.DoQuery' , 'p' )	is	null
	exec	( 'create	proc	damit.DoQuery	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoQuery
	@iExecutionLog		TId
as
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=включить отладочные сообщения

	,@sExec			TScript
	,@sParamName		TsysName=		''

	,@oValue		sql_variant

	,@iExecution		TId

	,@sQuery		TSystemName

	,@sExecAtServer		TSystemName
	,@sExecShort		TScript
	,@sTargetDatabaseQuoted	TSysName
	,@sTargetServerQuoted	TSysName
	,@sTargetProc		TSystemName
	,@sTargetProc1		TSystemName

	,@iTargetObject		TInteger
	,@sTargetType		varchar ( 2 )

	,@sParamsDeclare	TScript
	,@sParamsProc		TScript
	,@sParamsConvert	TScript
	,@sParamsSave		TScript

	,@bIsOutParam		bit
	,@bIsDate		bit
	,@oParamValue		sql_variant
	,@sDataType		varchar ( 128 )
----------
select
	name
	,colid
	,isoutparam
	,IsDate=	convert ( bit,			null )
	,DataType=	convert ( varchar ( 128 ),	null )
into
	#syscolumns_Params		-- полагаем, что чаще вызывается без ошибок, чтобы рекомпиляция завершилась раньше
from
	syscolumns
where
	0=	1
----------
select
	@iExecution=	dl.Execution
	,@sTargetProc=	f.Alias
from
	damit.ExecutionLog	dl
	,damit.Distribution	d
	,damit.Query		f
where
		dl.Id=	@iExecutionLog
	and	d.Id=	dl.Distribution
	and	f.Id=	d.Task
if	@@error<>	0	or	@@rowcount<>	1
begin
	select	@sMessage=	'Ошибка передачи параметров',
		@iError=	-3
	goto	error
end
----------
select
	@sTargetServerQuoted=	quotename ( Server )
	,@sTargetDatabaseQuoted=quotename ( Db )
	,@sTargetProc=		LocalName
	,@sTargetProc1=		SmartName
from
	damit.GetParseObjectName ( @sTargetProc )
----------
exec	@iError=	damit.DoGetObjectId
				@sObject=	@sTargetProc1
				,@iObject=	@iTargetObject	out
				,@sType=	@sTargetType	out
if	@@Error<>	0	or	@iError<	0	or	@iTargetObject	is	null
begin
	select	@sMessage=	'Целевой объект не найден или найдено несколько временных таблиц с похожим именем',
		@iError=	-3
	goto	error
end
----------
select
	@sExecAtServer=	SmartName
	,@sExecShort=	'
select
	sc.name
	,sc.colid
	,sc.isoutparam
	,IsDate=	case
				when	st.xtype	in	( 40 , 41 , 42 , 43 , 58 , 61 )	then	1
				else									0
			end
	,DataType=	convert ( varchar ( 128 ),	case
								when		st.name	like	''%char''
									or	st.name	like	''%binary''		then	st.name+	'' ( ''+	case	sc.prec
																				when	-1	then	''max''
																				else			convert ( varchar ( 128 ),	sc.prec )
																			end+	'' )''
								when	st.name	in	( ''numeric'',	''decimal'' )	then	st.name+	'' ( ''+	convert ( varchar ( 128 ),	sc.prec )+	'',	''+	convert ( varchar ( 128 ),	sc.scale )+	'' )''
								else								st.name
							end )
from
	'+	@sTargetDatabaseQuoted+	'.dbo.syscolumns	sc
	inner	join	'+	@sTargetDatabaseQuoted+	'.dbo.systypes	st	on
		st.xusertype=	sc.xtype						-- берём системный тип, а не пользовательский; чтобы не поддерживать соответствие типов между базами
where
		sc.id=	@iTargetObject'
from
	damit.GetParseObjectName ( @sTargetServerQuoted+	'...sp_executesql' )
----------
insert	#syscolumns_Params
exec	@sExecAtServer
		@statement=	@sExecShort
		,@params=	N'@iTargetObject	int'
		,@iTargetObject=@iTargetObject
if	@@Error<>	0	--or	@@RowCount=	0
begin
	select	@sMessage=	'Не удалось получить параметры целевой процедуры',
		@iError=	-3
	goto	error
end
----------
if	0<	( select	count ( 1 )	from	#syscolumns_Params )
begin
	select	@sParamsProc=		''
		,@sParamsDeclare=	''
		,@sParamsConvert=	''
		,@sParamsSave=		''
		,@sExec=		''
----------
	declare	c	cursor	local	fast_forward	for
		select
			name
			,isoutparam
			,IsDate
			,DataType
		from				-- внести сюда damit.GetVariables и убрать курсор
			#syscolumns_Params
		order	by
			colid
----------
	open	c
----------
	while	1=	1
	begin
		fetch	next	from	c	into	@sParamName,	@bIsOutParam,	@bIsDate,	@sDataType
		if	@@fetch_status<>	0	break
----------
		set	@oParamValue=	null
----------
		select
			@oParamValue=	Value0
		from
			damit.GetVariables ( @iExecutionLog,	@sParamName,	default,	default,	default,	default,	default,	default,	default,	default,	default )
		if	1<	@@RowCount
		begin
			select	@sMessage=	'Найдено более одного значения для параметра '+	@sParamName+	' процедуры '+	@sTargetProc
				,@iError=	-3
			goto	error
		end
----------
		select	@sParamsProc=		@sParamsProc
					+	'
		'
					+	case	isnull ( @sParamsProc,	'' )
							when	''	then	''
							else			','
						end
					+	@sParamName
					+	'=	'
					+	case
							when	@bIsOutParam=	1			then	@sParamName+	'	output'
							when	@sParamName	like	'%Execution%'	then	''''+	convert ( varchar ( 36 ),	@iExecutionLog )+	''''
							when	@oParamValue	is	null		then	'null'									-- неизвестно, это значение или отсутствие значения; нельзя опускать передачу null, т.к. default параметра процедуры может быть другой
							when	@bIsDate=	1			then	''''+	convert ( varchar ( 23 ),	@oParamValue,	121 )+	''''
							else							''''+	convert ( varchar ( 8000 ),	@oParamValue )+		''''	-- считаем, что из текстового значения автосконвертируется в тип параметра
						end
			,@sParamsDeclare=	@sParamsDeclare
					+	case	@bIsOutParam
							when	1	then		case
												when	isnull ( @sParamsDeclare,	'' )=	''	then	'
----------
declare	'
												else								'
	,'
											end
										+	@sParamName+	'	'+	@sDataType
										+	case
												when		@sDataType	like	'%(%max%)'
													or	@sDataType	in	( 'image',	'text',	'ntext',	'xml' )	then	'
	,@@'+	@sParamName+	'	varbinary ( max )'
												else												''
											end
							else			''
						end
			,@sParamsConvert=	case
							when		@bIsOutParam=	1
								and	(	@sDataType	like	'%(%max%)'
									or	@sDataType	in	( 'image',	'text',	'ntext',	'xml' ) )
							then	case	isnull ( @sParamsConvert,	'' )
									when	''	then	'
----------
select	'
									else			'
	,'
								end
							+	'@@'+	@sParamName+	'=	convert ( varbinary ( max ),	'+	@sParamName+	' )'	-- добавляем две @@ вместо одной, чтобы случайно не пересечься со @@spid
							else	''
						end
			,@sParamsSave=		@sParamsSave
					+	case	@bIsOutParam
							when	1	then		'
----------
exec	damit.SetupVariable
		@iExecutionLog=	'''
										+	convert ( varchar ( 36 ),	@iExecutionLog )
										+	'''
		,@sAlias=	'''
										+	@sParamName
										+	'''
		,'
										+	case
												when		@sDataType	like	'%(%max%)'
													or	@sDataType	in	( 'image',	'text',	'ntext',	'xml' )	then	'@mValue=	@@'
												else												'@oValue=	'
											end
										+	@sParamName+	'
'
							else				''
						end
	end
----------
	deallocate	c
end
----------
set	@sExec=		@sParamsDeclare
		+	'
----------
exec	'
		+	@sTargetProc
		+	@sParamsProc
		+	@sParamsConvert
		+	@sParamsSave
----------
if	@bDebug=	1
	print	( @sExec )
----------
exec	( @sExec )
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка',
		@iError=	-3
	goto	error
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