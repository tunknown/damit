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
use	damit
go
if	object_id ( 'damit.DoSaveToFile' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSaveToFile	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSaveToFile
	@sData		nvarchar ( max )	-- данные для выгрузки всегда в unicode/windows-1251
	,@sFileName	nvarchar ( 256 )	-- имя текстового файла
	,@sCharset	sysname			-- кодовая страница сохраняемого файла, например, 'windows-1251','utf-8' или любая из HKEY_CLASSES_ROOT\MIME\Database\Charset
	,@bSkipBOM	bit=	1		-- для UTF-8 на записывать первые 3 байта BOM-маркера, приводит к двойному потреблению памяти
as
set	nocount	on
declare	@bDebug		bit=	1
	,@iError	int
	,@iRowCount	int
	,@iOLEError	int
	,@iFSO		int
	,@iStream	int
	,@iStream1	int
	,@iStreamSave	int
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
exec	@iOLEError=	sp_OASetProperty	@iStream,	'Type',	2	-- text
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Тип потока не устанавливается'
		,@iError=	-1
	goto	error
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
exec	@iOLEError=	sp_OASetProperty	@iStream,	'Charset',	@sCharset	-- не получилось примененить до загрузки и после загрузки текста с целью указать входящую и исходящую кодировку
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Кодировка исходящего потока не устанавливается'
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
if	datalength ( isnull ( @sData , '' ) )>	0	-- в поток нельзя помещать пустые данные
begin
	exec	@iOLEError=	sp_OAMethod	@iStream,	'WriteText',	null,	@sData
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Поток не заполняется'
			,@iError=	-1
		goto	error
	end
end
----------
if	@bSkipBOM=	1	and	@sCharset=	'utf-8'
begin
	exec	@iOLEError=	sp_OACreate	'ADODB.Stream',	@iStreamSave	out
	if		@@Error<>	0
		or	@iOLEError<>	0
		or	@iStreamSave=	0
	begin
		select	@sMessage=	'Ошибка инициализации ADODB.Stream'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OASetProperty	@iStreamSave,	'Type',	1	-- binary
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Тип потока не устанавливается'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OASetProperty	@iStreamSave,	'Mode',	3
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Режим потока не установливается'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OAMethod	@iStreamSave,	'Open' 
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Поток не открывается'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Position',	3
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Указатель потока не установливается'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OAMethod	@iStream,	'CopyTo',	null,	@iStreamSave,	-1	-- двойное потребление памяти
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Ошибка копирования'
			,@iError=	-1
		goto	error
	end
----------
	set	@iStream1=	@iStreamSave
end
else
	set	@iStream1=	@iStream
----------
exec	@iOLEError=	sp_OAMethod	@iStream1,	'SaveToFile',	Null,	@sFileName,	2
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка записи в файл '+	convert ( varchar ( 11 ) , @iOLEError )
		,@iError=	-1
	goto	error
end
----------
if	@iStreamSave	is	not	null
begin
	exec	@iOLEError=	sp_OAMethod	@iStreamSave,	'Close'
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Ошибка закрытия потока'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OADestroy	@iStreamSave
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'Ошибка освобождения потока'
			,@iError=	-1
		goto	error
	end
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