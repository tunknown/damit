use	damit
----------
if	object_id ( 'damit.DoGet' , 'p' )	is	null
	exec	( 'create	proc	damit.DoGet	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoGet	-- выгрузка данных с сервера
	@gExecutionLog		TGUID
as
-- следить за SQL injection
-- сначала лучше применять выгрузку по изменению содержимого, после уточнения бизнес-процесса можно перейти к выгрузке по дате изменения
-- эту процедуру нельзя вызывать из транзакции, т.к. bcp не будет иметь доступа к свежевставленным данным до commit tran	
declare	@sMessage		TMessage
	,@iError		TInteger
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	0	-- 1=включить отладочные сообщения
	,@sTransaction		TSysName
	,@bAlien		TBoolean

	,@sExec			TScript
	,@sExec1		TScript
	,@sExec2		TScript
	,@sExec3		TScript
	,@sExec5		TScript
	,@sSelectable		TScript
	,@sExec4		TScript
	,@sExec501		TScript
	,@sExec502		TScript
	,@sExec500		TScript
	,@sExecIds		TScript
	,@sExecIds2		TScript
	,@sExecForChk1		TScript
	,@sExecForChk2		TScript
	,@sExec6		TScript
	,@sExec7		TScript
	,@sExecData1		TScript
	,@sExecData2		TScript

	,@sExecShort		TScript

	,@sTargetTable		TSystemName
	,@sLogTable		TSystemName
--	,@dtStart		TDateTime
	,@sFilterTable		TSystemName
	,@sFieldsObject		TSystemName
	,@sFieldsLocalObject	TSystemName
	,@sFieldsObjectType	TSystemName

	,@sFilterStart		varchar ( 256 )
	,@sFilterFinish		varchar ( 256 )
	,@sExecutionLog		char ( 38 )
	,@sData			char ( 38 )

	,@sFilterObject		TSystemName		-- из этого параметра информация о таблице попадает в эти переменные
	,@sFilterSchema		TSysName
	,@sFilterDatabase	TSysName
	,@sFilterDatabaseQuoted	TSysName
	,@sFilterServerQuoted	TSysName

	,@sTargetTable1		TSystemName

	,@sTargetObject		TSystemName
	,@sTargetSchema		TSysName
	,@sTargetDatabase	TSysName
	,@sTargetDatabaseQuoted	TSysName
	,@sTargetServerQuoted	TSysName
	,@sTargetType		varchar ( 2 )
	,@sDataLogType		varchar ( 2 )

	,@iFilterObject		TInteger
	,@iTargetObject		TInteger
	,@iDataLogObject	TInteger

	,@sFieldDate		TSysName
	,@sFieldList		TSysName

	,@sFieldRelationshipQuoted	TSysName
	,@sFieldDateQuoted	TSysName
	,@sFieldListQuoted	TSysName
	,@sFieldsSortQuoted	TScript

	,@sPurifier		TSystemName

	,@bComparison		bit
	,@bIsDate		bit
	,@bHasValue		bit
	,@bStartSkip		bit
	,@dtMoment		TDateTime

	,@bCanCreated		bit
	,@bCanChanged		bit
	,@bCanRemoved		bit
	,@bCanFixed		bit

	,@bCanRenew		bit

	,@bIsParameterized	bit
	,@bCreateDataLog	bit

	,@gData			TGUID
	,@gDataNew		TGUID
	,@sExecAtServer		TSystemName
	,@sLogTableLocal	TSystemName
	,@sLogTableT		TSystemName

	,@iFilterJoinFields	TInteger

	,@gExecution		TGUID

	,@dtFilterStart		TDateTime		-- фильтрация по дате изменения обновления/актуальности, в т.ч. и при неизменных данных
	,@dtFilterFinish	TDateTime		-- фильтрация по дате изменения обновления/актуальности, в т.ч. и при неизменных данных
	,@sFilterList		varchar ( max )		-- список идентификаторов для передачи в фильтровочную функцию, по полям которой происходит выборка(AND) из целевого объекта(view,таблица,процедура)
	,@sParamValue		varchar ( max )
	,@oParamValue		sql_variant
----------
select	@sExecutionLog=	''''+	convert ( char ( 36 ) , @gExecutionLog )+	''''
	,@sFilterList=	''
----------
set	@sTransaction=	convert ( varchar ( 256 ) , @@procid )+	'_'+	convert ( char ( 36 ) , @gExecutionLog )
----------
select
	@gData=		d.Task
	,@sData=	''''+	convert ( char ( 36 ) , d.Task )+	''''
	,@gExecution=	el.Execution
from
	damit.ExecutionLog	el
	,damit.Distribution	d
where
		el.Id=	@gExecutionLog
	and	d.Id=	el.Distribution
----------
select
	@sTargetTable=	Target
	,@sFilterTable=	Filter
	,@sLogTable=	DataLog

	,@sPurifier=	Refiner

	,@bCanCreated=	CanCreated
	,@bCanChanged=	CanChanged
	,@bCanRemoved=	CanRemoved
	,@bCanFixed=	CanFixed
from
	damit.Data
where
	Id=		@gData
if	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибочно задана выгрузка',
		@iError=	-3
	goto	error
end
----------
if		@bCanChanged=	1	--чтобы upd не исключать из слежения за del
	and	@bCanCreated=	0
begin
	select	top	1
		@gDataNew=	d.Id
	from
		damit.GetCompatibleData ( @gData )	gcd
		,damit.Data				d
	where
			d.Id=		gcd.Data
		and	d.CanCreated=	1
----------
	if	exists	( select
				1
			from
				damit.GetCompatibleData ( @gDataNew )	gcd
				,damit.Data				d
			where
					d.Id=		gcd.Data
				and	d.CanRemoved=	1 )
		set	@bCanRenew=	0				-- если new следит за del, то возобновлённые попадают в new, даже если upd тоже следит за del
end
else
	if	1	in	( @bCanCreated,	@bCanChanged )
		select
			@bCanRenew=	sign ( count ( * ) )
		from
			damit.GetCompatibleData ( @gData )	gcd
			,damit.Data				d
		where
				d.Id=		gcd.Data
			and	d.CanRemoved=	1
----------
select
	@dtFilterStart=		convert ( datetime,	Value0 )
	,@dtFilterFinish=	convert ( datetime,	Value1 )
from
	damit.GetVariables ( @gExecutionLog,	'FilterStart',	'FilterFinish',	default,	default,	default,	default,	default,	default,	default,	default )
if	@@RowCount>	1
begin
	select	@sMessage=	'Ошибочно заданы параметры выгрузки',
		@iError=	-3
	goto	error
end
----------
select
	@sFilterList=		@sFilterList+	','+	convert ( varchar ( max ),	Value0 )	-- ***авторазделитель может оказаться в самом списке значений, переделать далее в месте использования на Variables вместо ToListFromStringAuto
from
	damit.GetVariables ( @gExecutionLog,	'FilterList',	default,	default,	default,	default,	default,	default,	default,	default,	default )
order	by
	Sequence
----------
select	@sFilterStart=		''''+	convert ( varchar ( 256 ) , @dtFilterStart,	121 )+	''''
	,@sFilterFinish=	''''+	convert ( varchar ( 256 ) , @dtFilterFinish,	121 )+	''''
----------
select
	@sLogTableLocal=	SmartName
	,@sLogTableT=		SmartNameT
from
	damit.GetParseObjectName ( @sLogTable )
----------
select	top	1								-- если дополнительно ограничить поля PK/UQ=not null, то поддержка нескольких полей в PK/UQ всё ещё возможна
	@sFieldRelationshipQuoted=	quotename ( FieldName )
from
	damit.DataField
where
		Data=		@gData
	and	IsRelationship=	1
order	by
	Sequence
----------
select	top	1
	@sFieldDate=		FieldName
	,@sFieldDateQuoted=	quotename ( FieldName )
from
	damit.DataField
where
		Data=		@gData
	and	IsDate=		1
order	by
	Sequence
----------
select	top	1
	@sFieldList=		FieldName
	,@sFieldListQuoted=	quotename ( FieldName )
from
	damit.DataField
where
		Data=		@gData
	and	IsList=		1
order	by
	Sequence
----------
set	@sFieldsSortQuoted=	''
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
----------
select
	@bHasValue=	sign ( count ( * ) )
from
	damit.DataField
where
		Data=		@gData
	and	Value	is	not	null
----------
if	len ( @sFieldsSortQuoted )>	0
begin
	set	@sFieldsSortQuoted=	right ( @sFieldsSortQuoted , len ( @sFieldsSortQuoted )-	2 )
--	if	@bDebug=	1	select	( @sFieldsSortQuoted )
end
else
	set	@sFieldsSortQuoted=	null
----------
select
	@sFilterServerQuoted=	quotename ( Server )
	,@sFilterDatabase=	Db
	,@sFilterDatabaseQuoted=quotename ( Db )
	,@sFilterSchema=	Owner
	,@sFilterObject=	Object
	,@sFilterTable=		SmartName	-- для единобразия заменяем исходные переменные/параметры на уточнённые
from
	damit.GetParseObjectName ( @sFilterTable )
----------
select
	@sTargetServerQuoted=	quotename ( Server )
	,@sTargetDatabase=	Db
	,@sTargetDatabaseQuoted=quotename ( Db )
	,@sTargetSchema=	Owner
	,@sTargetObject=	Object
	,@sTargetTable=		LocalName	-- нужно имя внутри сервера, т.к. далее используется в OpenQuery
	,@sTargetTable1=	SmartName
from
	damit.GetParseObjectName ( @sTargetTable )
----------
if	@sFilterTable	is	not	null
begin
	exec	@iError=	damit.DoGetObjectId
					@sObject=	@sFilterTable
					,@iObject=	@iFilterObject	out
	if	@@Error<>	0	or	@iError<	0	or	@iFilterObject	is	null
	begin
		select	@sMessage=	'Таблица фильтрации не найдена или найдено несколько временных таблиц с похожим именем',
			@iError=	-3
		goto	error
	end
end
----------
exec	@iError=	damit.DoGetObjectId
				@sObject=	@sTargetTable1
				,@iObject=	@iTargetObject	out
				,@sType=	@sTargetType	out
if	@@Error<>	0	or	@iError<	0	or	@iTargetObject	is	null
begin
	select	@sMessage=	'Целевой объект не найден или найдено несколько временных таблиц с похожим именем',
		@iError=	-3
	goto	error
end
----------
exec	@iError=	damit.DoGetObjectId
				@sObject=	@sLogTableLocal
				,@iObject=	@iDataLogObject	out
				,@sType=	@sDataLogType	out
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'Ошибка получения DataLog',
		@iError=	-3
	goto	error
end
----------
select
	FieldName=	convert ( sysname , sc.name )	-- дальше будем стирать пустые
	,TypeName=	st.name
into
	#syscolumns_Target
from
	syscolumns	sc				-- если берётся таблица через linked sql server другой версии, возможны отличия в полях syscolumns
	,systypes	st
where
	0=	1
----------
select
	name
	,colid
	,IsParam=	convert ( bit , null )		-- ? неплохо ещё подставлять параметры по типам и порядку следования если их несколько
into
	#syscolumns_Filter
from
	syscolumns
where
	0=	1
----------
select
	name
	,colid
	,IsDate=	convert ( bit , null )
into
	#syscolumns_Params
from
	syscolumns
where
	0=	1
----------
if	@sTargetType	in	( 'P',	'TF' )		-- получим параметры хранимой процедуры или табличной функции
begin
	select
		@sExecAtServer=	SmartName
		,@sExecShort=	'
select
	sc.name
	,sc.colid
	,IsDate=	case
				when	st.xtype	in	( 40 , 41 , 42 , 43 , 58 , 61 )	then	1
				else									0
			end
from
	'+	@sTargetDatabaseQuoted+	'.dbo.syscolumns	sc
	inner	join	'+	@sTargetDatabaseQuoted+	'.dbo.systypes	st	on
		st.xusertype=	sc.xtype
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
end
----------
if	@iFilterObject	is	not	null
begin
	select
		@sExecAtServer=	SmartName
		,@sExecShort=	'
select
	name
	,colid
	,IsParam=	case	left ( name , 1 )
				when	''@''	then	1
				else			0
			end
from
	'+	@sFilterDatabaseQuoted+	'.dbo.syscolumns
where
	id=	@iFilterObject'
	from
		damit.GetParseObjectName ( @sFilterServerQuoted+	'...sp_executesql' )
----------
	insert	#syscolumns_Filter
	exec	@sExecAtServer
			@statement=	@sExecShort
			,@params=	N'@iFilterObject	int'
			,@iFilterObject=@iFilterObject
	if	@@Error<>	0	--or	@@RowCount=	0
	begin
		select	@sMessage=	'Не удалось получить параметры объекта фильтрации',
			@iError=	-3
		goto	error
	end
end
----------
if	exists	( select
			1
		from
			damit.GetParseObjectName ( @sLogTable )
		where
			Object	like	'#%' )
begin
	if	@iDataLogObject	is	not	null
	begin
		select	@sExecShort=		'
if	object_id ( '''+	@sLogTableT+	''',	''u'' )	is	not	null
	drop	table	'+	@sLogTableLocal
			,@iDataLogObject=	null		-- правильнее учесть условие ExecutionLog=parameter(@gExecutionLog) в new части генерируемого запроса
			,@sDataLogType=		null
----------
		if	@bDebug=	1
			print	@sExecShort
----------
		exec	( @sExecShort )
	end
----------
	select	@bCreateDataLog=	case
						when	@iDataLogObject	is	null	then	1
						else						0
					end
		,@sDataLogType=		'U'			-- select into создаёт только таблицу
end
else
	set	@bCreateDataLog=	0
----------
if		@bCreateDataLog=	0
	or	@sTargetType	in	( 'V' , 'U' )
begin
	if	@bCreateDataLog=	0
		select	@sFieldsLocalObject=	@sLogTableLocal
			,@sFieldsObject=	@sLogTable
			,@sFieldsObjectType=	@sDataLogType	-- только 'u', считаем, что insertable view не применяется?
	else
		if	@sTargetType	in	( 'V' , 'U' )
			select	@sFieldsLocalObject=	@sTargetTable
				,@sFieldsObject=	@sTargetTable1
				,@sFieldsObjectType=	@sTargetType
----------
	select
		@sExecAtServer=	e.SmartNameT
		,@sExecShort=	'
select
	sc.name
	,st.name
from
	'+	quotename ( l.Db )+	'.dbo.syscolumns	sc
	inner	join	'+	quotename ( l.Db )+	'.dbo.systypes	st	on
		st.xusertype=	sc.xtype
where
		sc.id=		object_id ( @sLogTableLocal,	@sFieldsObjectType )
	and	sc.name	not	in	( ''ExecutionLog'',	''IsCreated'',	''IsChanged'',	''IsRemoved'',	''IsFixed'' )'	-- считаем, что object_id можно использовать, т.к. логи всегда лежат на локальной базе
	from
		damit.GetParseObjectName ( @sFieldsObject )	l		-- берём поля таблицы лога damit.Distribution.DataLog, а не исходной таблицы данных, считая, что они должны быть одинаковы
		cross	apply	damit.GetParseObjectName ( quotename ( l.Server )+	'.'+	quotename ( l.DB )+	'..sp_executesql' )	e	-- DB для поддержки #tempdb
----------
	if	@bDebug=	1
	begin
		print	( @sExecAtServer )
		print	( @sLogTableLocal )
		print	( @sExecShort )
	end
----------
----------
	insert	#syscolumns_Target
	exec	@sExecAtServer
			@statement=		@sExecShort
			,@params=		N'@sLogTableLocal	nvarchar ( 1024 ),	@sFieldsObjectType	varchar ( 2 )'
			,@sLogTableLocal=	@sFieldsLocalObject	-- здесь нужен SmartName
			,@sFieldsObjectType=	@sFieldsObjectType
	select	@iError=	@@Error
		,@iRowCount=	@@RowCount
	if	@iError<>	0	or	@iRowCount=	0
	begin
		select	@sMessage=	'Ошибка получения полей целевой таблицы лога данных ExecutionLog='+	convert ( char ( 36 ),	@gExecutionLog )+	' @@Error='+	convert ( varchar ( 256 ),	@iError )+	' @@RowCount='+	convert ( varchar ( 256 ),	@iRowCount ),
			@iError=	-3
		goto	error
	end
----------
--if	@bDebug=	1	select	*	from	#syscolumns_Target
end
----------
--if	@bDebug=	1	select	*	from	#syscolumns_Filter
----------
set	@sExec1=	''
----------
select
	@sExec1=	@sExec1+	'
	and	t.'+	quotename ( f.Name )+	case	@bCanRemoved
							when	1	then	'	in	( new.'+	quotename ( f.Name )+	' , old.'+	quotename ( f.Name )+	' )'	-- хотя бы один из них должен подпадать под фильтр
							else			'=	new.'+	quotename ( f.Name )
						end
from
	#syscolumns_Filter	f
	,damit.DataField	df
where
		df.FieldName=	f.name		-- не ясно, по каким полям жоинить- правильно
	and	f.IsParam=	0
	and	df.Data=	@gData
set	@iFilterJoinFields=	@@RowCount
----------
if		@sFilterTable	is	not	null
	and	@iFilterJoinFields=	0
begin
	select	@sMessage=	'Таблица фильтрации не содержит подходящих полей',
		@iError=	-3
	goto	error
end
----------
if	@sTargetType=	'P'
begin
	if	0<	( select	count ( 1 )	from	#syscolumns_Params )
	begin
		set	@sSelectable=	'	'
----------
		if	exists	( select	1	from	#syscolumns_Params	where	name=	'@bIsParameterized' )
			set	@bIsParameterized=	1
----------
		declare	c	cursor	fast_forward	for
			select
				name
				,IsDate
			from
				#syscolumns_Params
			order	by
				colid
----------
		open	c
----------
		while	1=	1
		begin
			fetch	next	from	c	into	@sExec1,	@bIsDate
			if	@@fetch_status<>	0	break
----------
			if	@bIsParameterized=	1	-- для сохранения совместимости с процедурами параметризованными по старому методу
			begin
				set	@oParamValue=	null
----------
				select
					@oParamValue=	Value0
				from
					damit.GetVariables ( @gExecutionLog,	@sExec1,	default,	default,	default,	default,	default,	default,	default,	default,	default )
				if	1<	@@RowCount
				begin
					select	@sMessage=	'Найдено более одного значения для параметра '+	@sExec1+	' процедуры '+	@sTargetTable
						,@iError=	-3
					goto	error
				end
----------
				select	@sParamValue=	convert ( varchar ( 8000 ),	@oParamValue )
					,@sSelectable=	@sSelectable
						+	@sExec1
						+	'=	'
						+	case
								when	@sParamValue	is	null	then	'null'		-- неизвестно, это значение или отсутствие значения; нельзя опускать передачу null, т.к. default может быть другой
								when	@bIsDate=	1		then	''''''+	convert ( varchar ( 256 ),	@oParamValue,	121 )+	''''''
								else						''''''+	@sParamValue+	''''''	-- считаем, что из текстового значения автосконвертируется в тип параметра
							end
			end
			else
				if	@bIsDate=	1
					select	@dtMoment=	case	@bStartSkip
									when	1	then	@dtFilterFinish
									else			@dtFilterStart
								end
						,@sSelectable=	@sSelectable+	@sExec1+	'=	'+	case
															when	@dtMoment	is	null	then	'null'	-- нельзя опускать передачу null, т.к. default может быть другой
															else						''''''+	convert ( varchar ( 256 ) , @dtMoment , 121 )+	''''''
														end
						,@bStartSkip=	1
				else
					set	@sSelectable=	@sSelectable+	@sExec1+	'=	'+	isnull ( ''''+	case
																	when	@sExec1	like	'@%ExecutionLog%'	then	@sExecutionLog
																	else							''''+	@sFilterList+	''''
																end+	'''',	'null' )	-- нельзя опускать передачу null, т.к. default может быть другой
----------
			set	@sSelectable=	@sSelectable+	',	'
		end
----------
		deallocate	c
----------
		set	@sSelectable=	left ( @sSelectable,	len ( @sSelectable )-	2 )	-- отрезаем 2 лишних символа сзади
	end
	else
		set	@sSelectable=	''
----------
	set	@sSelectable=	'openquery ( '+	@sTargetServerQuoted+	' , ''set	nocount	on;declare	@bAlien	bit;set	@bAlien=	sign ( @@TranCount );if	@bAlien=	1	rollback;exec	'+	@sTargetTable+	@sSelectable+	';if	@bAlien=	1	begin	tran'' )'
end
else
	if	@sTargetType=	'TF'
	begin
		if	0<	( select	count ( 1 )	from	#syscolumns_Params )
		begin
			set	@sSelectable=	'	'
----------
			declare	c	cursor	fast_forward	for
				select
					name
				from
					#syscolumns_Params
				order	by
					colid
----------
			open	c
----------
			while	1=	1
			begin
				fetch	next	from	c	into	@sExec1
				if	@@fetch_status<>	0	break
----------
				if	@sExec1	like	'%ExecutionLog%'
					set	@sExec5=	@sExecutionLog
				else
					set	@sExec5=	'null'			-- полноценная передача параметров пока не поддерживается
----------
				set	@sSelectable=	@sSelectable+	@sExec5+	',	'
			end
----------
			deallocate	c
----------
			set	@sSelectable=	left ( @sSelectable,	len ( @sSelectable )-	2 )	-- отрезаем 2 лишних символа сзади
		end
----------
		set	@sSelectable=	@sTargetTable1+	' ( '+	@sSelectable+	' )'
	end
	else
		set	@sSelectable=	@sTargetTable1
----------
set	@sSelectable=	@sSelectable+	'	a'
----------
if		@iFilterJoinFields=	0
	and	@sFieldListQuoted	is	not	null
	and	isnull ( @sFilterList , '' )<>''			-- ???SQL injection
	and	( select	count ( 1 )	from	#syscolumns_Params )=	0
	set	@sSelectable=	'damit.ToListFromStringAuto ( '''+	@sFilterList+	''' )	t
			inner	'+	case	@sTargetServerQuoted
						when	quotename ( @@ServerName )	then	''
						else						'remote	'	-- для linked сервера обычный join может вызвать курсор по каждой записи таблицы
					end+	'join	'+	@sSelectable+	'	on
				a.'+	@sFieldListQuoted+	'=	t.Value'
----------
select	@sExec=		''
	,@sExec1=	''
	,@sExec2=	''
	,@sExec4=	''
	,@sExec501=	''
	,@sExec502=	''
	,@sExec500=	''
	,@sExecIds=	''
	,@sExecIds2=	''
	,@sExecForChk1=	''
	,@sExecForChk2=	''
	,@sExec6=	''
	,@sExec7=	''
----------
select
	@sExec1=	@sExec1+	quotename ( df.FieldName )+	',	'
	,@sExec2=	@sExec2+	case
						when		df.Value	is	null
							or	df.IsComparison=	1	then	'
			,'+	case
					when	@sPurifier	is	null	or	sc.TypeName	not	like	'%char'	then	'a.'
					else												''
				end+	quotename ( df.FieldName )+	case
										when	@sPurifier	is	null	or	sc.TypeName	not	like	'%char'	then	''
										else												'=	'+	@sPurifier+	' ( a.'+	quotename ( df.FieldName )+	' )'
									end
						else							''
					end
	,@sExec4=	@sExec4+	case	df.IsComparison
						when	1	then	quotename ( df.FieldName )+	',	'
						else			''
					end
	,@sExec501=	@sExec501+	case	df.IsRelationship
						when	1	then	'
	and	old.'+	quotename ( df.FieldName )+	'=	new.'+	quotename ( df.FieldName )
						else			''
					end
	,@sExec502=	@sExec502+	case	df.IsRelationship
						when	1	then	'
				and	D.'+	quotename ( df.FieldName )+	'=	t.'+	quotename ( df.FieldName )
						else			''
					end
	,@sExec500=	@sExec500+	case	df.IsRelationship
						when	1	then	'	,D.'+	quotename ( df.FieldName )
						else			''
					end
	,@sExecIds=	@sExecIds+	case	df.IsRelationship
						when	1	then	'
					,'+	quotename ( df.FieldName )
						else			''
					end
	,@sExecIds2=	@sExecIds2+	case	df.IsRelationship
						when	1	then	'
					D.'+	quotename ( df.FieldName )+	','
						else			''
					end
	,@sExecForChk1=	@sExecForChk1+	case	df.IsComparison
						when	1	then	quotename ( df.FieldName )+	',	'
						else			''
					end
	,@sExecForChk2=	@sExecForChk2+	case	df.IsComparison
						when	1	then	'D.'+	quotename ( df.FieldName )+	',	'
						else			''
					end
	,@sExec6=	@sExec6+	'
	,'+	quotename ( df.FieldName )+	'=	'+	case
									when	df.Value	is	not	null	then	df.Value	-- пока из других условий не убираю df.Value
									when	@bCanRemoved=	1			then	'case	when	new.'+	@sFieldRelationshipQuoted+	'	is	null	then	old.'+	quotename ( df.FieldName )+	'	else	'+	isnull ( df.Value , 'new.'+	quotename ( df.FieldName ) )+	'	end'	-- такое получение предыдущих значений заставляет ставить зависимость del от upd, а не от new. Иначе, после изменения при стирании в IsResultset в del попадут поля из new, а не из upd
									else							isnull ( df.Value , 'new.'+	quotename ( df.FieldName ) )
								end
	,@sExec7=	@sExec7+	case
						when	1	in	( df.IsRelationship , @bCanRemoved , @bHasValue )	then	'
				,D.'+	quotename ( df.FieldName )
						else											''
					end
from
	damit.DataField	df
	left	join	#syscolumns_Target	sc	on
		sc.FieldName=	df.FieldName
where
		df.Data=	@gData
order	by
	df.Sequence
	,df.FieldName
----------
select
	@bComparison=	sign ( count ( 1 ) )
from
	damit.DataField
where
		Data=		@gData
	and	IsComparison=	1
----------
if	@bComparison=	1							-- выгрузка только изменившихся данных
begin
	select	@sExecData1=	''
		,@sExecData2=	''
----------
	select
		@sExecData1=	@sExecData1+	'select
						ExecutionLog'+	@sExecIds+	'
						,IsRemoved
					from
						'+	d.DataLog+	'
					union	all
					'
		,@sExecData2=	@sExecData2+	'select
					ExecutionLog'+	@sExecIds+	'
					,'+	@sExecForChk1+	'
					IsRemoved
				from
					'+	d.DataLog+	'
				union	all
				'
	from
		damit.GetCompatibleData	( @gData )	GCD
		,damit.Data				d
	where
		d.Id=		GCD.Data
	group	by
		d.DataLog	-- на всякий случай
	order	by
		d.DataLog
----------
	if	@@RowCount=	1
		select	@sExecData1=	@sLogTable
			,@sExecData2=	@sLogTable
	else									-- ***не согласуется с заполнением @sExec7
		select	@sExecData1=	'( '
				+	left ( @sExecData1,	len ( @sExecData1 )-	23 )
				+	' )'
			,@sExecData2=	'( '
				+	left ( @sExecData2,	len ( @sExecData2 )-	21 )
				+	' )'
----------
	select	@sExecForChk2=	left ( @sExecForChk2,	len ( @sExecForChk2 )-	2 )	-- отрезаем 2 лишних символа сзади
		,@sExec500=	right ( @sExec500,	len ( @sExec500 )-	2 )	-- отрезаем 2 лишних символа спереди
		,@sExec7=	stuff ( @sExec7 , 1 , charindex ( ',' , @sExec7 ) , '' )
		,@sExec=	@sExec+	'
	full	join	( select
				'+	@sExec7+	'
				,D.IsRemoved'+	case
							when	1	in	( @bCanChanged,	@bCanFixed )	then	'
				,chk=		checksum ( '+	@sExecForChk2+	' )'
							else								''
						end+	'
			from
				( select'+	@sExecIds2+	'
					D.ExecutionLog
					,D.IsRemoved
					,Sequence667591256E81453BB647594E2D982308=	row_number()	over	( partition	by	'+	@sExec500+	'	order	by	L.Start	desc )
				from
					damit.ExecutionLog	L
					,damit.Distribution	i
					,damit.GetCompatibleData	( @gData )	cd
					,'+	@sExecData1+	'	D'+	case
											when		@bCanRemoved=		1	-- @bComparison здесь не подходит
												and	@iFilterJoinFields=	0
												and	@sFieldListQuoted	is	not	null
												and	isnull ( @sFilterList , '' )<>''			-- ???SQL injection
												and	( select	count ( 1 )	from	#syscolumns_Params )=	0	then	'
                                        inner	join	damit.ToListFromStringAuto ( '''+	@sFilterList+	''' )	tt	on
						tt.Value=	D.'+	@sFieldListQuoted
											else												''
										end+	'
				where
						i.Id=		L.Distribution
					and	cd.Data=	i.Task
					and	D.ExecutionLog=	L.Id			--???????????????????????????????L.Execution
					and	damit.CheckError ( L.ErrorCode )=	0 )	t	-- ошибочные пропускаем
				,'+	@sExecData2+	'	D
			where
					t.Sequence667591256E81453BB647594E2D982308=	1
				and	D.ExecutionLog=	t.ExecutionLog'+	@sExec502+	' )	old	on
		1=	1'+	@sExec501			-- full join=предыдущие и последующие выгрузки могут не пересекаться по Id
end
----------
select	@sExec1=	left ( @sExec1,	len ( @sExec1 )-	2 )	-- отрезаем 2 лишних символа сзади
	,@sExec2=	right ( @sExec2,len ( @sExec2 )-	6 )	-- отрезаем 5 лишних символов спереди
----------
if	2<	len ( @sExec4 )
	set	@sExec4=	left ( @sExec4,	len ( @sExec4 )-	2 )	-- отрезаем 2 лишних символа сзади
----------
/*create	table	#Error
(	IsError	tinyint	)
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка создания таблицы ошибок',
		@iError=	-3
	goto	error
end*/
----------
set	@sExec=	'
----------
declare	@gExecutionLog	uniqueidentifier
	,@gData		uniqueidentifier
----------
select	@gExecutionLog=	'+	@sExecutionLog+	'
	,@gData=	'+	@sData+	'
----------'+	case	@bCreateDataLog
			when	0	then	'
insert
	'+	@sLogTable+	'	( ExecutionLog,	IsCreated,	IsChanged,	IsRemoved,	IsFixed,	'+	@sExec1+	' )
'	/*case	sign ( 0+	@bCanRemoved+	@bCanChanged )
		when	1	then	'output
	case	0+	inserted.IsChanged+	inserted.IsRemoved
		when	2	then	1
		else			0
	end	as	IsError
into
	#Error
'
		else			''
	end+*/
			else			''
		end+	'
select
	ExecutionLog=	@gExecutionLog
	,IsCreated=	'+	case	@bCanCreated		-- если нет сравнения, то нет и данных о записи
					when	1	then	'case	when	new.'
							+	@sFieldRelationshipQuoted
							+	'	is	not	null	and	'
							+	case	@bCanRenew
									when	0	then	'old.'+	@sFieldRelationshipQuoted+	'	is	null'					-- возобновлённые и возобновлённые+изменённые записи НЕ ДОЛЖНЫ появляться как "новые"
									else			'( old.'+	@sFieldRelationshipQuoted+	'	is	null	or	old.IsRemoved=	1 )'	-- возобновлённые и возобновлённые+изменённые записи могут появляться как "новые"
								end+	'	then	1	else	0	end'
					else			'0'
				end+	'
	,IsChanged=	'+	case	@bCanChanged
					when	1	then	'case	when	new.chk'
							+	case	@bCanRenew
									when	0	then	'<>	old.chk	and	old.IsRemoved=	0'							-- возобновлённые записи НЕ должны появляться как "изменённые"
									else			'	is	not	null	and	( old.chk<>	new.chk	or	old.IsRemoved=	1 )'	-- возобновлённые записи могут появляться как "изменённые"
								end+	'	then	1	else	0	end'
					else			'0'
				end+	'
	,IsRemoved=	'+	case	@bCanRemoved	--sign ( 0+	@bCanRemoved+	@bCanChanged )		-- добавляем избыточное условие для нахождения ошибок= когда идентификатор появился в новых после его стирания
					when	1	then	'case	when	new.'+	@sFieldRelationshipQuoted+	'	is	null	and	old.IsRemoved=	0	then	1	else	0	end'	-- однажды удалённую запись исключать при повторном запросе удалённых
					else			'0'
				end+	'
	,IsFixed=	'+	case	@bCanFixed
					when	1	then	'case	when	old.chk=	new.chk	and	old.IsRemoved=	0	then	1	else	0	end'
					else			'0'
				end+	@sExec6
			+	case	@bCreateDataLog
					when	1	then	'
into
	'+	@sLogTableLocal											-- linked сервер не поддерживается
					else			''
				end
			+	'
from
	( select
		*'+	case
				when		1	in	( @bCanChanged,	@bCanFixed )
					and	0<	len ( @sExec4 )	then	'
		,chk=	checksum ( '+	@sExec4+	' )'
				else						''
			end+	'
	from
		( select
			'+	@sExec2+	'
		from
			'+	@sSelectable+	'	)	a	)	new'+	@sExec	-- проверять checksum только после Purifier
----------
if	@iFilterJoinFields>	0
	select
		@sExec=	@sExec+	'
	inner	join	'+	@sFilterTable+	'	( @gExecutionLog,	'+
							case
								when	@sFilterStart	is	null	then	'null'
								else						@sFilterStart
							end+	',	'+
							case
								when	@sFilterFinish	is	null	then	'null'
								else						@sFilterFinish
							end+	',	'+
							case
								when	@sFilterList	is	null	then	'null'
								else						''''+	@sFilterList+	''''
							end+	' )	t	on
		1=	1'+	@sExec1
----------
/*
if		@iFilterJoinFields=	0
	and	@sFieldListQuoted	is	not	null
	and	isnull ( @sFilterList , '' )<>''			-- ???SQL injection
	and	( select	count ( 1 )	from	#syscolumns_Params )=	0
	select
		@sExec=	@sExec+	'
	inner	'+	case	@sTargetServerQuoted
				when	quotename ( @@ServerName )	then	''
				else						'loop	'	-- для linked сервера обычный join порождает курсор по каждой записи таблицы
			end+	'join	damit.ToListFromString	( '''+	@sFilterList+	''',	'','',	1 )	t	on
		t.Value'+	case	@bCanRemoved			-- @bComparison здесь не подходит
					when	1	then	'	in	( new.'+	@sFieldListQuoted+	' , old.'+	@sFieldListQuoted+	' )'	-- хотя бы один из них должен подпадать под фильтр
					else			'=	new.'+	@sFieldListQuoted
				end
*/
----------
set	@sExec=	@sExec+	'
where
		1=	1'						-- для упрощения генерации запроса
----------
if	@bComparison=	1
begin
	set	@sExec1=	''
----------
	select
		@sExec1=	@sExec1+	Script			-- порядок следования не важен
	from
		( select
			Script=	'
		or	new.'+	@sFieldRelationshipQuoted+	'	is	not	null	and	'
		+	case	@bCanRenew
				when	0	then	'old.'+	@sFieldRelationshipQuoted+	'	is	null'					-- возобновлённые и возобновлённые+изменённые записи НЕ ДОЛЖНЫ появляться как "новые"
				else			'( old.'+	@sFieldRelationshipQuoted+	'	is	null	or	old.IsRemoved=	1 )'	-- возобновлённые и возобновлённые+изменённые записи могут появляться как "новые"
			end
		where
			@bCanCreated=	1
		union	all
		select
			script=	'
		or	new.chk'
		+	case	@bCanRenew
				when	0	then	'<>	old.chk	and	old.IsRemoved=	0'							-- возобновлённые записи НЕ должны появляться как "изменённые"
				else			'	is	not	null	and	( old.chk<>	new.chk	or	old.IsRemoved=	1 )'	-- возобновлённые записи могут появляться как "изменённые"
			end
		where
			@bCanChanged=	1
		union	all
		select
			script=	'
		or	new.'+	@sFieldRelationshipQuoted+	'	is		null	and	old.IsRemoved=	0'	-- однажды удалённую запись исключать при повторном запросе удалённых
		where
			@bCanRemoved=	1
		union	all
		select
			script=	'
		or	old.chk=	new.chk	and	old.IsRemoved=	0'	-- возобновлённые записи НЕ должны появляться как "неизменённые"
		where
			@bCanFixed=	1 )	t
----------
	set	@sExec=	@sExec+	'
	and	('+	stuff ( @sExec1 , 1 , 6 , '' )	+	' )'
end
----------
if	@iFilterJoinFields=	0
	select
		@sExec=	@sExec+	'
	and	'+	case
				when	@sFilterStart	is	not	null	then	@sFilterStart+	'<=	new.'+	@sFieldDateQuoted+	'	and	'
				else							''
			end
		+	case
				when	@sFilterFinish	is	not	null	then	'new.'+	@sFieldDateQuoted+	'<	'+	@sFilterFinish
				else							''
			end
	where
			@sFieldDateQuoted	is	not	null				-- фильтрация может быть и внутри функции, возвращающей список идентификаторов
		and	isnull ( @sFilterStart , @sFilterFinish )	is	not	null
----------
select
	@sExec=	'declare	@iRowCount1	int
----------
select
	@iRowCount1=	count ( * )
from
	'+	@sTargetTable1+	'	with	( tablock , holdlock )
where
	0=	1
----------
'+	@sExec
where
	@sTargetType	in	( 'V' , 'U' )	-- блокируем исходную таблицу, чтобы на дату мы взяли все данные
----------
select
	@sExec=		'declare	@iRowCount2	int
----------
select
	@iRowCount2=	count ( * )
from
	'
		+	@sLogTable+	'	with	( tablock , holdlock )
where
	0=	1
----------
'
		+	@sExec
where
	@bComparison=	1			-- блокируем таблицу лога, если с ней есть сравнение
----------
set	@sExec=	@sExec+	'
----------
set	@iRowCount=	@@RowCount
'
----------
if		@bCreateDataLog=	1
	and	@sFieldRelationshipQuoted	is	not	null
begin
	set	@sExecShort=	null
----------
	select
		@sExecShort=	isnull ( @sExecShort+	',	',	'' )+	quotename ( FieldName )
	from
		damit.DataField
	where
			Data=		@gData
		and	IsRelationship=	1
	order	by
		Sequence
----------
	set	@sExec=	@sExec+	'
----------
create	clustered	index	IX001	on	'+	@sLogTableLocal+	'	( '+	@sExecShort+	' )
create	unique		index	IX002	on	'+	@sLogTableLocal+	'	( ExecutionLog,	'+	@sExecShort+	' )'
end
----------
select	@sExec1=	substring ( @sExec , 1 , 4000 )
	,@sExec2=	substring ( @sExec , 4001 , 8000 )
	,@sExec3=	substring ( @sExec , 8001 , 12000 )
if	@bDebug=	1
begin
	print	( @sExec1 )
	print	( @sExec2 )
	print	( @sExec3 )
end
----------
set	@bAlien=	sign ( @@TranCount )
if	@bAlien=	0	begin	tran	@sTransaction	else	save	tran	@sTransaction
----------
/*if	@bDebug=	1
	select			@gExecutionLog,	@gDistribution,	@dtStart,	@dtFilterStart,	@dtFilterFinish,	@sFilterList
----------
set	@dtStart=	getdate()	-- после блокировки данных можно получать дату начала
----------
insert	damit.ExecutionLog	( Id,		Distribution,	Start,		FilterStart,	FilterFinish,		List )		-- создаём новую выгрузку как можно позже, чтобы в случае ошибки её не пришлось подчищать?
select				@gExecutionLog,	@gDistribution,	@dtStart,	@dtFilterStart,	@dtFilterFinish,	@sFilterList
if	@@Error<>	0	or	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибка создания выгрузки',
		@iError=	-3
	goto	error
end
*/
----------
exec	@iError=	sp_executesql
				@statement=	@sExec
				,@params=	N'@iRowCount	int	out'
				,@iRowCount=	@iRowCount	out
if	@@Error<>	0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка вставки из целевой таблицы',
		@iError=	-3
	goto	error
end
----------
if	@iRowCount=	0
begin
	exec	@iError=	damit.SetupVariable
					@gExecutionLog=	@gExecution
					,@sAlias=	'KostylDlyaOstanovki'
					,@oValue=	1
					,@iSequence=	1	-- insert or update
	if	@@Error<>	0	or	@iError<	0
	begin
		select	@sMessage=	'Ошибка',
			@iError=	-3
		goto	error
	end
end
----------
exec	@iError=	damit.SetupVariable
				@gExecutionLog=	@gExecutionLog
				,@sAlias=	'RowCount'
				,@oValue=	@iRowCount
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'Ошибка',
		@iError=	-3
	goto	error
end
----------
exec	@iError=	damit.SetupVariable
				@gExecutionLog=	@gExecutionLog
				,@sAlias=	'Data:ExecutionLog'
				,@oValue=	@gExecutionLog
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'Ошибка',
		@iError=	-3
	goto	error
end
----------
/*if	exists	( select	1	from	#Error	where	IsError=	1 )
begin
	update
		damit.ExecutionLog
	set
		ErrorCode=	-1
		,Message=	isnull ( Message , '' )+	'
Попытка восстановления стёртой записи'
	where
		Id=		@gExecutionLog
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'Ошибка обновления информации о выгрузке',
			@iError=	-3
		goto	error
	end
end*/
----------
-- если дальше есть вызов внешней программы, например, bcp, то без commit данные будут заблокированы и внешняя программа повиснет на ожидании разблокирования
if	@@TranCount>	0	and	@bAlien=	0	commit	tran	@sTransaction
----------
goto	done

error:
if	@@TranCount>	0	and	@bAlien=	0	rollback	tran	@sTransaction
raiserror ( @sMessage , 18 , 1 )

done:

----------
update
	damit.ExecutionLog
set
	Finish=		getdate()
	,ErrorCode=	@iError		-- пока ErrorCode=null выгрузка считается незавершённой и её результат нельзя учитывать в следующих запусках
	,Message=	@sMessage
where
	Id=		@gExecutionLog
--if	@@Error<>	0	or	@@RowCount<>	1
--begin
--	select	@sMessage=	'Ошибка изменения статуса выгрузки',
--		@iError=	-3
--	goto	error
--end
----------
--drop	table	#Error
----------
return	@iError
go
use	tempdb