use	damit
----------
if	object_id ( 'damit.DoSaveToXML_utf8' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSaveToXML_utf8	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSaveToXML_utf8	-- выгрузка данных с сервера
	@gDistributionLogId	uniqueidentifier
	,@sQueryHeader		nvarchar ( max )=	null	-- не используется
	,@sQueryData		nvarchar ( max )
as
-- следить за SQL injection
-- опасно чередовать использование выгрузок по изменению даты и изменению содержимого
-- сначала лучше применять выгрузку по изменению содержимого, после уточнения бизнес-процесса можно перейти к выгрузке по дате изменения
-- эту процедуру нельзя вызывать из транзакции, т.к. bcp не будет иметь доступа к свежевставленным данным до commit tran
declare	@sMessage		varchar ( 256 )
	,@iError		integer
	,@iRowCount		integer
	,@bDebug		bit=	1	-- 1=включить отладочные сообщения

	,@sExec			nvarchar ( max )

	,@sFileName		nvarchar ( 256 )

	,@dtMoment		datetime
	,@sFilterList		varchar ( max )
	,@x			xml
	,@iPos			int

	,@sFieldsResultset	nvarchar ( max )
	,@sFieldsSort		nvarchar ( max )
	,@sDataLog		nvarchar ( max )
	,@sCharset		varchar ( 32 )=	'utf-8'
----------
if	app_name()	like	'SSIS%'	set	@bDebug=	0	-- при выполнении из пакета не заходим
----------
select
	@sFileName=		f.FileName
	,@dtMoment=		l.Start
	,@sFilterList=		l.List
	,@sExec=		c.Put
	,@sDataLog=		d.DataLog
from
	damit.DistributionLog	l
	inner	join	damit.Distribution	i	on
		i.DistributionId=	l.DistributionId
	inner	join	damit.Data		d	on
		d.DataId=		i.DataId
	inner	join	damit.Format		f	on
		f.FormatId=		i.FormatId
	inner	join	damit.Storage		s	on
		s.StorageId=		f.StorageId
	left	join	damit.Script		c	on
		c.ScriptId=		s.ScriptId
where
		l.DistributionLogId=	@gDistributionLogId
if	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибочно задан лог выгрузки',
		@iError=	-3
	goto	error
end
----------
if	@sExec	is	null
	select	@iPos=			charindex ( '	with	',	@sQueryData )
		,@sQueryData=		case	@iPos
						when	0	then	@sQueryData
						else			stuff ( @sQueryData , @iPos , 0 , '	row' )	-- алиас таблицы для помещения в xml
					end
		,@sExec=		'set	@x=	('+	@sQueryData+	'	for	xml	auto,	root ( ''rows'' ) )'
else
	select	@sFieldsResultset=	replace ( left ( @sQueryData , charindex ( '	from	' , @sQueryData ) ) , 'select	' , '' )
		,@iPos=			charindex ( 'order	by',	@sQueryData )
		,@sFieldsSort=		case	@iPos
						when	0	then	''
						else			right ( @sQueryData , len ( @sQueryData )-	@iPos-	len ( 'order	by' ) )
					end
		,@sExec=		replace (
					replace (
					replace (
					replace (
					@sExec
					,'<FieldsResultset/>',	isnull ( @sFieldsResultset,	'' ) )
					,'<FieldsSort/>',	isnull ( @sFieldsSort,		'' ) )
					,'<DataLog/>',		isnull ( @sDataLog,		'' ) )
					,'<DistributionLogId/>',''''+	convert ( char ( 36 ) , @gDistributionLogId )+	'''' )
----------
if	@bDebug=	1	print	( @sExec )
----------
exec	sp_executesql
		@statement=	@sExec
		,@params=	N'@x	xml	OUT'
		,@x=		@x		OUT
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка получения xml',
		@iError=	-3
	goto	error
end
----------
----------
select
	@sFileName=	FullName
	,@sExec=	'<?xml version="1.0" encoding="'+	@sCharset+	'"?>'+	convert ( nvarchar ( max ) , @x )
from
	damit.GetFormatFileName ( @sFileName , @dtMoment , @sFilterList )
----------
if	@bDebug=	1	print	( @sFileName )
if	@bDebug=	1	print	( @sExec )
----------
exec	@iError=	damit.DoSaveToFile
				@sData=		@sExec
				,@sFileName=	@sFileName
				,@sCharset=	@sCharset
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'Ошибка выгрузки xml файла',
		@iError=	-3
	goto	error
end
----------
update
	damit.DistributionLog
set
	FileName=	@sFileName
where
	DistributionLogId=	@gDistributionLogId
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка указания имени файла',
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