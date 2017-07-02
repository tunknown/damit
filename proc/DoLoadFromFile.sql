/*
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'Ole Automation Procedures', 1
GO
RECONFIGURE
GO
*/
if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
if	object_id ( 'damit.DoLoadFromFile' , 'p' )	is	null
	exec	( 'create	proc	damit.DoLoadFromFile	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoLoadFromFile
	@mData		varbinary ( max )	output	-- данные из файла
	,@sFileName	sysname				-- имя файла
	,@sCharset	sysname=	null		-- null=бинарный файл, иначе кодовая страница текста, например, 'windows-1251','utf-8' или любая из HKEY_CLASSES_ROOT\MIME\Database\Charset
	,@bSkipBOM	bit=		1
as
set	nocount	on
declare	@bDebug		bit
	,@iError	int
	,@iRowCount	int
	,@iOLEError	int
	,@iFSO		int
	,@iStream	int
	,@sMessage	varchar ( 256 )
	,@iFile		int

	,@iSize		int

	,@s		varchar ( 256 )
	,@sFile		sysname
	,@sLinkedFile	sysname
	,@sLinkedTable	sysname
	,@sPath		sysname
	,@sPath1	sysname
	,@sDB		sysname
	,@sSchema	sysname
	,@sObject	sysname
	,@sObject1	sysname
	,@iResult	int

	,@mBuffer	varbinary ( 8000 )
	,@iPos		int
	,@iBufSize	int
----------
set	@bDebug=	1
----------
if	app_name()	like	'SSIS%'	set	@bDebug=	0	-- при выполнении из пакета не заходим
----------
set	@iError=	0
----------
if	isnull ( @sFileName , '' )=	''
begin
	select	@sMessage=	'Задано пустое имя файла'
		,@iError=	-1
	goto	error
end
----------
----------
----------
set	@sPath=	left ( @sFileName , len ( @sFileName )-	charindex ( '\' , reverse ( @sFileName ) ) )	-- получаем из имени файла каталог
if	@bDebug=	1	print	@sPath
----------
----------
----------
exec	@iOLEError=	sp_OACreate	'ADODB.Stream',	@iStream	out
if		@@Error<>	0
	or	@iOLEError<>	0
	or	@iStream=	0
begin
	select	@sMessage=	'Ошибка инициализации ADODB.Stream'
		,@iError=	-1
	goto	error
end
----------
if	@sCharset	is	null
begin
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Type',	1
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Тип потока не установливается'
			,@iError=	-1
		goto	error
	end
end
else
begin
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Charset',	@sCharset
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Кодировка потока не устанавливается'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Type',	2
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Тип потока не установливается'
			,@iError=	-1
		goto	error
	end
end
----------
/*exec	@iOLEError=	sp_OASetProperty	@iStream,	'Mode',	1	-- adModeRead
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Режим потока не установливается'
		,@iError=	-1
	goto	error
end*/
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'Open' 
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Поток не открывается'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'LoadFromFile',	Null,	@sFileName--,	2
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка загрузки из файла '+	convert ( varchar ( 11 ) , @iOLEError )
		,@iError=	-1
	goto	error
end
----------
set	@iSize=	0
exec	@iOLEError=	sp_OAGetProperty	@iStream,	'Size',	@iSize	OUTPUT
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка получения длины файла '+	convert ( varchar ( 11 ) , @iOLEError )
		,@iError=	-1
	goto	error
end
----------
----------
select	@iPos=		0
	,@mData=	0x
----------
while	@iPos<	@iSize
begin
	set	@iBufSize=	case
					when	@iSize-	@iPos<	8000	then	@iSize-	@iPos
					else					8000
				end
----------
	if	@sCharset	is	null
		exec	@iOLEError=	sp_OAMethod	@iStream,	'Read',		@mBuffer	output,	@iBufSize	-- больше 8000 для Read не выдаёт, даже через insert exec без output параметра
	else
		exec	@iOLEError=	sp_OAMethod	@iStream,	'ReadText',	@mBuffer	output,	@iBufSize
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Поток не заполненяется '+	convert ( varchar ( 11 ) , @iOLEError )
			,@iError=	-1
		goto	error
	end
----------
	set	@iPos=	@iPos+	@iBufSize
----------
	if	@bSkipBOM=	1	-- sql не умеет оптимизировать вычисление булевских выражений
		if	datalength ( @mData )=	0
			if	left ( @mBuffer,	3 )=	'п»ї'	/*0xEFBBBF*/
				set	@mData=	@mData+	substring ( @mBuffer,	4,	len ( @mBuffer ) )
			else
				set	@mData=	@mData+	@mBuffer
		else
			set	@mData=	@mData+	@mBuffer
	else
		set	@mData=	@mData+	@mBuffer	-- для совместимости можно заменить на UPDATETEXT	#temp.data	@Image	@Pos	0	@Buffer	на sql 2016 это всё ещё работает
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'Close'
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка закрытия потока'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OADestroy	@iStream
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка освобождения потока'
		,@iError=	-1
	goto	error
end
----------
goto	done

error:

if	@sMessage	is	null	set	@sMessage=	'Ошибка'
raiserror ( @sMessage , 18 , 1 )
--EXEC	@iOLEError=	sp_OAGetErrorInfo	null,	@source	OUT,	@desc	OUT
--SELECT	OLEObject=	CONVERT ( binary ( 4 ),	@iOLEError ),	source=	@source,	description=	@desc
if	isnull ( @iStream , 0 )>	0	exec	/*@iOLEError=	*/sp_OADestroy	@iStream

done:

return	@iError

----------
go
use	tempdb