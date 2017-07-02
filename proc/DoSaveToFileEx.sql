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
if	object_id ( 'damit.DoSaveToFileEx' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSaveToFileEx	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSaveToFileEx
	@mData		image			-- данные для выгрузки в файл, нельзя подавать тип text
	,@sFileName	nvarchar ( 256 )	-- имя файла
	,@sCharset	sysname=	null	-- null=бинарный файл, иначе кодовая страница текста, например, 'windows-1251','utf-8' или любая из HKEY_CLASSES_ROOT\MIME\Database\Charset
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
	,@s		varchar ( 256 )
	,@sLinkedTable	sysname
	,@sPath		nvarchar ( 256 )
	,@sPath1	nvarchar ( 256 )
	,@sDB		sysname
	,@sSchema	sysname
	,@sObject	sysname
	,@sObject1	sysname
	,@iResult	int
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
exec	@iOLEError=	sp_OACreate	'Scripting.FileSystemObject',	@iFSO	out
IF	@@Error<>	0	or	@iOLEError<>	0
begin
	set	@sMessage=	'Ошибка инициализации Scripting.FileSystemObject'
	goto	error
end
----------
exec	@iOLEError=	sp_OAMethod	@iFSO,	'FolderExists',	@iResult	out,	@sPath		-- проверяем существование каталога
IF		@@Error<>	0
	or	@iOLEError<>	0
begin
	set	@sMessage=	'Ошибка проверки существования каталога'
	goto	error
end
----------
if	@iResult=	0
begin
	declare	c	cursor	fast_forward	for
		select
			Value
		from
			damit.ToListFromString ( @sPath , '\' , 1 )
		order	by
			Sequence
----------
	open	c
----------
	set	@sPath=	''
----------
	while	1=	1		
	begin
		fetch	next	from	c	into	@sPath1
		if	@@FETCH_STATUS<>	0	break
----------
		if	@bDebug=	1	print	@sPath1
----------
		set	@sPath=	@sPath+	@sPath1+	'\'
----------
		if	@sPath1	not	like	'%:%'
		begin
			exec	@iOLEError=	sp_OAMethod	@iFSO,	'FolderExists',	@iResult	out,	@sPath	-- проверяем существование каталога следующего уровня
			IF		@@Error<>	0
				or	@iOLEError<>	0
			begin
				set	@sMessage=	'Ошибка проверки существования каталога'
				goto	error
			end
----------
			if	@iResult=	0
			begin
				exec	@iOLEError=	sp_OAMethod	@iFSO,	'CreateFolder',	@iResult	out,	@sPath	-- создаём каталог следующего уровня
				IF		@@Error<>	0
					or	@iOLEError<>	0
				begin
					deallocate	c
----------
					set	@sMessage=	'Ошибка создания каталога '+	convert ( varchar ( 11 ) , @iOLEError )
					goto	error
				end
			end
		end
	end
----------
	deallocate	c
end
----------
exec	@iOLEError=	sp_OADestroy	@iFSO
IF	@@Error<>	0	or	@iOLEError<>	0
begin
	set	@sMessage=	'Ошибка освобождения Scripting.FileSystemObject'
	goto	error
end
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
exec	@iOLEError=	sp_OASetProperty	@iStream,	'Mode',	3
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Режим потока не установливается'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'Open' 
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Поток не открывается'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iStream,	'Position',	0
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Позиция потока не устанавливается'
		,@iError=	-1
	goto	error
end
----------
if	datalength ( isnull ( @mData , '' ) )>	0	-- в поток нельзя помещать пустые данные
begin
	if	@sCharset	is	null
		exec	@iOLEError=	sp_OAMethod	@iStream,	'Write',	null,	@mData
	else
		exec	@iOLEError=	sp_OAMethod	@iStream,	'WriteText',	null,	@mData
----------
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Поток не заполненяется'
			,@iError=	-1
		goto	error
	end
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'SetEOS'
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Неверный размер данных'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'SaveToFile',	Null,	@sFileName,	2
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка записи в файл '+	convert ( varchar ( 11 ) , @iOLEError )
		,@iError=	-1
	goto	error
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