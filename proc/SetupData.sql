use	damit
go
if	object_id ( 'damit.SetupData' , 'p' )	is	null
	exec	( 'create	proc	damit.SetupData	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.SetupData
	@gId			TGUID=		null	output
	,@sTarget		TSysName
	,@sDataLog		TSysName=	null
	,@sFilter		TSysName

-- можно добавить обработку первого символа
-- '*'	все поля
-- '-'	исключить поле, например '*,-field1,-field2'
	,@sRelationship		TScript			-- в качестве разделителя берём первый символ
	,@sComparison		TScript			-- в качестве разделителя берём первый символ
	,@sResultset		TScript			-- в качестве разделителя берём первый символ
	,@sDate			TScript=	null	-- в качестве разделителя берём первый символ
	,@sList			TScript=	null	-- в качестве разделителя берём первый символ
	,@sSort			TScript=	null	-- в качестве разделителя берём первый символ

	,@sName			TName
	,@sRefiner		TSysName
	,@bCanCreated		TBool
	,@bCanChanged		TBool
	,@bCanRemoved		TBool
	,@bCanFixed		TBool

	,@bCreateTableLog	bit=		null
	,@sHandleTransaction	varchar ( 16 )=	'none'	-- 'commit' , 'rollback' , 'none'
as
declare	@iError			integer=0
	,@iError2		integer=0
	,@sMessage		varchar ( 256 )
	,@iRowCount		integer
	,@bAlien		bit
	,@sTransaction		sysname
	,@bDebug		bit=	1	-- 1=включить отладочные сообщения

	,@iTranCount		integer

	,@sTargetOld		sysname
	,@sExec			nvarchar ( max )
	,@sExec1		nvarchar ( max )
	,@iColumnCount		integer

	,@sTargetObject		TSysName
	,@sTargetSchema		TSysName
	,@sTargetDatabase	TSysName
	,@sTargetDatabaseQuoted	TSysName
	,@sTargetServerQuoted	TSysName
	,@sTargetType		varchar ( 2 )
	,@sTarget1		TSysName

	,@iTargetObject		TInteger
	,@iLogObject		TInteger

	,@sRelationshipDelimeter	nvarchar ( 2 )
	,@sComparisonDelimeter	nvarchar ( 2 )
	,@sResultsetDelimeter	nvarchar ( 2 )
	,@sDateDelimeter	nvarchar ( 2 )
	,@sListDelimeter	nvarchar ( 2 )
	,@sSortDelimeter	nvarchar ( 2 )

	,@bTargetIsDataLog	bit
----------
if	isnull ( @sHandleTransaction , 'none' )	not	in	( 'commit' , 'rollback' , 'none' )
begin
	select	@sMessage=	'Ошибка задания @sHandleTransaction',
		@iError=	-3
	goto	error
end
----------
if	app_name()	like	'SSIS%'	set	@bDebug=	0	-- при выполнении из пакета не заходим
----------
set	@sTransaction=	object_name ( @@procid )+	replace ( replace ( replace ( replace ( convert ( varchar ( 23 ) , getdate() , 121 ) , '-' , '' ) , ' ' , '' ) , ':' , '' ) , '.' , '' )
----------
select	@sTarget=	SmartName	from	damit.GetParseObjectName ( @sTarget )
----------
select	@sFilter=	SmartName	from	damit.GetParseObjectName ( @sFilter )
----------
select	@sDataLog=	SmartName	from	damit.GetParseObjectName ( @sDataLog )
----------
select
	@sTargetOld=	Target
from
	damit.Data
where
	Id=		@gId
set	@iRowCount=	@@RowCount
----------
select	@sRelationshipDelimeter=left ( @sRelationship,	1 )
	,@sComparisonDelimeter=	left ( @sComparison,	1 )
	,@sResultsetDelimeter=	left ( @sResultset,	1 )
	,@sDateDelimeter=	left ( @sDate,		1 )
	,@sListDelimeter=	left ( @sList,		1 )
	,@sSortDelimeter=	left ( @sSort,		1 )
----------
if		@bCreateTableLog	is	null
	and	(	@iRowCount=	0		-- подан несуществующий guid
		or	@sTarget<>	@sTargetOld	-- или различается источник данных
		or	exists	( select
					1
				from
					damit.damit.ToListFromString ( @sRelationship,	@sRelationshipDelimeter,	1 )	t
					full	join	damit.DataField	df	on
						df.Data=		@gId
					and	df.FieldName=		t.Value
					and	df.IsRelationship=	1
				where
						t.Value		is	null
					or	df.FieldName	is	null )	)
begin
	set	@bCreateTableLog=	case
						when	@sDataLog	is	null	then	0
						else						1
					end
	--begin
	--	select	@sMessage=	'Таблица лога уже существует и требует изменения',
	--		@iError=	-3
	--	goto	error
	--end
end
----------
if	@sHandleTransaction	in	( 'commit' , 'rollback' )
begin
	set	@iTranCount=	@@TranCount
----------
	while	@@TranCount>	0
		if	@sHandleTransaction=	'rollback'	rollback	else	commit	-- откатываем все, даже именованные
end
----------
set	@bTargetIsDataLog=	0
----------
if		@bCreateTableLog=	1			-- выносим из транзакции
	and	@iLogObject	is	null
begin
	exec	@iError=	damit.DoGetObjectId		-- уже @sHandleTransaction обработан раньше
					@sObject=	@sTarget
					,@iObject=	@iTargetObject	out
					,@sType=	@sTargetType	out
	if	@@Error<>	0	or	@iError<	0	or	@iTargetObject	is	null
	begin
		if	@sHandleTransaction	in	( 'commit' , 'rollback' )
			while	@@TranCount<	@iTranCount	begin	tran	-- возможна ошибка, т.к. открываем неименованные, а могли быть именованные
----------
		select	@sMessage=	'Целевая таблица не найдена или найдено несколько временных таблиц с похожим именем',
			@iError=	-3
		goto	error
	end
----------
	if		(	@sTarget	like	'#%'
			or	@sTarget	like	'[[]#%' )
		and	@iTargetObject	is	not	null
		and	exists	( select
					1
				from
					tempdb..syscolumns
				where
						id=	@iTargetObject
					and	name	in	( 'ExecutionLog',	'IsCreated',	'IsChanged',	'IsRemoved',	'IsFixed' ) )	-- наличие одного из этих полей требует совместимости Target и DataLog и по остальным полям
		set	@bTargetIsDataLog=	1
end
----------
exec	@iError=	damit.DoGetObjectId
				@sObject=	@sDataLog
				,@iObject=	@iLogObject	out
set	@iError2=	@@Error
----------
if	@sHandleTransaction	in	( 'commit' , 'rollback' )
	while	@@TranCount<	@iTranCount	begin	tran	-- возможна ошибка, т.к. открываем неименованные, а могли быть именованные
----------
if	@iError2<>	0	or	@iError<	0
begin
	select	@sMessage=	'Ошибка таблицы лога или найдено несколько временных таблиц с похожим именем',
		@iError=	-3
	goto	error
end
----------
set	@bAlien=	sign ( @@TranCount )
if	@bAlien=	0	begin	tran	@sTransaction	else	save	tran	@sTransaction
----------
if	@iRowCount=	0
begin
	set	@gId=	isnull ( @gId , newid() )
----------
	insert	damit.Data	( Id,	Target,		DataLog,	Filter,		Name,	Refiner,	CanCreated,	CanChanged,	CanRemoved,	CanFixed )
	select			@gId,	@sTarget,	@sDataLog,	@sFilter,	@sName,	@sRefiner,	@bCanCreated,	@bCanChanged,	@bCanRemoved,	@bCanFixed
	if	@@Error<>	0
	begin
		select	@sMessage=	'Ошибка сохранения выгрузки',
			@iError=	-3
		goto	error
	end
----------
	insert	damit.TaskEntity	( Id,	Data )
	select				@gId,	@gId
	if	@@Error<>	0
	begin
		select	@sMessage=	'Ошибка сохранения выгрузки',
			@iError=	-3
		goto	error
	end
----------
	insert
		damit.DataField	( Id,	Data,	FieldName,	Value,	IsRelationship,	IsComparison,	IsResultset,	IsList,	IsDate,	Sort,	Sequence )
	select
		Id=		newid()
		,Data=		@gId
		,FieldName
		,Value=		max ( t.Value )
		,IsRelationship=max ( t.IsRelationship )
		,IsComparison=	max ( t.IsComparison )
		,IsResultset=	max ( t.IsResultset )
		,IsList=	max ( t.IsList )
		,IsDate=	max ( t.IsDate )
		,sum ( t.Sort )												-- без агрегатных никак не получается, там они всё равно по одному разу должны быть
		,Sequence=	row_number()	over	( order	by	min ( t.Sequence1 ),	min ( t.Sequence2 ) )	-- пытаемся гарантировать, что поля в резалтсете будут идти в заданном порядке, а остальные- как получится
	from
		( select
			Fieldname=	Value
			,Value=		null
			,IsRelationship=1
			,IsComparison=	0
			,IsResultset=	0
			,IsList=	0
			,IsDate=	0
			,Sort=		null
			,Sequence1=	0x7FFFFFFF
			,Sequence2=	Sequence
		from
			damit.damit.ToListFromString ( @sRelationship,	@sRelationshipDelimeter,	1 )
		union	all
		select
			FieldName=	case
						when	Value	like	'%=%'	then	left ( Value , charindex ( '=' , Value )-	1 )
						else					Value
					end
			,Value=		case
						when	Value	like	'%=%'	then	right ( Value , len ( Value )-	charindex ( '=' , Value ) )
						else					null
					end
			,IsRelationship=0
			,IsComparison=	1
			,IsResultset=	0
			,IsList=	0
			,IsDate=	0
			,Sort=		null
			,Sequence1=	0x7FFFFFFF
			,Sequence2=	Sequence
		from
			damit.damit.ToListFromString ( @sComparison,	@sComparisonDelimeter,	1 )
		union	all
		select
			FieldName=	case
						when	Value	like	'%=%'	then	left ( Value , charindex ( '=' , Value )-	1 )
						else					Value
					end
			,Value=		case
						when	Value	like	'%=%'	then	right ( Value , len ( Value )-	charindex ( '=' , Value ) )
						else					null
					end
			,IsRelationship=0
			,IsComparison=	0
			,IsResultset=	1
			,IsList=	0
			,IsDate=	0
			,Sort=		null
			,Sequence1=	Sequence
			,Sequence2=	0
		from
			damit.damit.ToListFromString ( @sResultset,	@sResultsetDelimeter,	1 )
		union	all
		select
			Fieldname=	Value
			,Value=		null
			,IsRelationship=0
			,IsComparison=	0
			,IsResultset=	0
			,IsList=	1
			,IsDate=	0
			,Sort=		null
			,Sequence1=	0x7FFFFFFF
			,Sequence2=	Sequence
		from
			damit.damit.ToListFromString ( @sList,		@sListDelimeter,	1 )
		union	all
		select
			Fieldname=	Value
			,Value=		null
			,IsRelationship=0
			,IsComparison=	0
			,IsResultset=	0
			,IsList=	0
			,IsDate=	1
			,Sort=		null
			,Sequence1=	0x7FFFFFFF
			,Sequence2=	Sequence
		from
			damit.damit.ToListFromString ( @sDate,		@sDateDelimeter,	1 )
		union	all
		select
			Fieldname=	case	right ( Value , 5 )
						when	' desc'	then	left ( Value , len ( Value )-	5 )
						else			Value
					end
			,Value=		null
			,IsRelationship=0
			,IsComparison=	0
			,IsResultset=	0
			,IsList=	0
			,IsDate=	0
			,Sort=		case	right ( Value , 5 )
						when	' desc'	then	-1
						else			1
					end*	Sequence
			,Sequence1=	0x7FFFFFFF
			,Sequence2=	Sequence
		from
			damit.damit.ToListFromString ( @sSort,		@sSortDelimeter,	1 )	)	t
	group	by
		t.Fieldname
	if	@@Error<>	0	--or	@@RowCount=	0	-- если хотим вручную заполнить поля выгрузки
	begin
		select	@sMessage=	'Ошибка сохранения полей выгрузки',
			@iError=	-3
		goto	error
	end
----------
	if	@bDebug=	1
		select	*	from	damit.DataField	where	Data=	@gId	order	by	Sequence
end
else
begin
	update
		damit.Data
	set
		Target=		@sTarget
		,DataLog=	@sDataLog
		,Filter=	@sFilter
		,Name=		@sName
		,Refiner=	@sRefiner
		,CanCreated=	@bCanCreated
		,CanChanged=	@bCanChanged
		,CanRemoved=	@bCanRemoved
		,CanFixed=	@bCanFixed
	where
		Id=		@gId
end
----------
if	@bCreateTableLog=	1
begin
	if	@iLogObject	is	null
	begin
		select
			@sTargetServerQuoted=	quotename ( Server )
			,@sTargetDatabase=	Db
			,@sTargetDatabaseQuoted=quotename ( Db )
			,@sTargetSchema=	Owner
			,@sTargetObject=	Object
			,@sTarget1=		LocalName
		from
			damit.GetParseObjectName ( @sTarget )
----------
		set	@sExec=	''
----------
		select
			@sExec=	@sExec+     '
	,'+	quotename ( FieldName )+	'=	convert ( sql_variant , null )'		-- тип будет известен в момент выполнения, сейчас его взять неоткуда, если только парсить Value, где писать всегда 'convert ( ТИП...'
		from
			damit.DataField
		where
				Data=		@gId
			and	Value	is	not	null
		order	by
			Sequence
----------
		set	@sExec1=	''
----------
		select
			@sExec1=	@sExec1+	',	'+	quotename ( FieldName )
		from
			damit.DataField
		where
				Data=		@gId
			and	IsRelationship=	1
----------
		if	@@RowCount<>	0
			select
				@sExec1=	'
,constraint	'+	quotename (	'UQ'
				+	isnull ( Server,'' )
				+	isnull ( Db,	'' )
				+	isnull ( Owner,	'' )
				+	isnull ( Object,'' ) )+	'			unique		( ExecutionLog'+	@sExec1+	 ' )'
			from
				damit.GetParseObjectName ( @sDataLog )
----------
		select			-- таблица лога создаётся по всем полям Target, а не только выгружаемым
			@sExec=	'
select
	'+	case	@bTargetIsDataLog			-- *** поля нельзя брать через *, по крайней мере identity нужно исключать через convert к типу
			when	0	then	'ExecutionLog=	convert ( uniqueidentifier , null )
	,IsCreated=	convert ( tinyint , null )
	,IsChanged=	convert ( tinyint , null )
	,IsRemoved=	convert ( tinyint , null )
	,IsFixed=	convert ( tinyint , null )
	,'
			else			''
		end+	'*'+	isnull ( @sExec,	'' )+	'
into
	'+	LocalName+	'
from
	'+	case	@sTargetType
			when	'P'	then	'openquery ( '+	@sTargetServerQuoted+	',	''exec	'+	@sTarget1+	''' )'
			else			@sTarget	-- ?ещё нужно обрабатывать параметры функции, учитывая, что табличная функция через linked сервер не работает
		end+	'
where
	0=	1
----------
alter	table	'+	LocalName+	'	add
constraint	'+	quotename (	'FK'
				+	isnull ( Server,'' )
				+	isnull ( Db,	'' )
				+	isnull ( Owner,	'' )
				+	isnull ( Object,'' )
				+	'ExecutionLog' )+	'	foreign	key	( ExecutionLog )	references	damit.ExecutionLog	( Id )'+	@sExec1+	'
,constraint	'+	quotename (	'CK'
				+	isnull ( Server,'' )
				+	isnull ( Db,	'' )
				+	isnull ( Owner,	'' )
				+	isnull ( Object,'' ) )+	'			check	( 0+	isnull ( IsCreated , 0 )+	isnull ( IsChanged , 0 )+	isnull ( IsRemoved , 0 )+	isnull ( IsFixed , 0 )<=	1 )'	-- если IsChanged+IsRemoved=2, то сообщение об ошибке лучше выдать после её логирования
		from
			damit.GetParseObjectName ( @sDataLog )
----------
		if	@bDebug=	1	print	( @sExec )
		exec	( @sExec )
		if	@@Error<>	0
		begin
			select	@sMessage=	'Ошибка создания таблицы лога',
				@iError=	-3
			goto	error
		end
	end
----------
/*
	if	object_id ( 'dbo.ShowIdentifiers' , 'v' )	is	null
		exec ( 'create	view	dbo.ShowIdentifiers	as	select	Error=	1/0' )
----------
	set	@sExec=	''
----------
	select
		@sExec=	@sExec+	'
union	all	select	ExecutionLog,	Id=	convert ( sql_variant , '+	quotename ( t.Relationship )+	' )	from	'+	tt.SmartName
	from
		( select
			Relationship=	min ( df.FieldName )
			,d.DataLog
		from
			damit.Data	d
			,damit.DataField	df
		where
				d.DataLog	is	not	null
			and	df.Data=		d.Id
			and	df.IsRelationship=	1
		group	by
			d.DataLog
		having
			count ( * )=	1 )	t				-- только если уникальность в одном поле
		cross	apply	damit.GetParseObjectName ( t.DataLog )	tt	-- если обращаться к себе, как к linked серверу, то будет блокировка из-за транзакций, т.к. здесь присутствует запрос к свежесозданной таблице, когда не неё ещё не было commit
	order	by
		t.DataLog
		,t.Relationship
----------
	set	@sExec=	'alter	view	dbo.ShowIdentifiers	as
'+	right ( @sExec , len ( @sExec )-	12 )
----------
	if	@bDebug=	1
	begin
		print	( substring ( @sExec , 1 , 4000 ) )
		print	( substring ( @sExec , 4001 , 8000 ) )
		print	( substring ( @sExec , 8001 , 12000 ) )
		print	( substring ( @sExec , 12001 , 16000 ) )
		print	( substring ( @sExec , 16001 , 20000 ) )
	end
	exec	( @sExec )
	if	@@Error<>	0
	begin
		select	@sMessage=	'Ошибка создания view идентификаторов',
			@iError=	-3
		goto	error
	end
*/
end
----------
if	@@TranCount>	0	and	@bAlien=	0	commit	tran	/*@sTransaction*/
goto	done

error:
if	@@TranCount>	0	and	@bAlien=	0	rollback	tran	/*@sTransaction*/
raiserror ( @sMessage , 18 , 1 )

done:
return	@iError