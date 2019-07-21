/*
set @Charset='koi8-r'
-- пропущен код, приведенный Shurgenz или аналогичный
EXEC @iError=sp_OASetProperty	@iOLE,	'TextBodyPart.Charset', @Charset

-- или
EXEC @iError=sp_OASetProperty	@iOLE,	'HTMLBodyPart.Charset', @Charset
*/



use	damit
go
if	object_id ( 'damit.DoSendMailInternal' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSendMailInternal	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSendMailInternal
	@sSMTP		varchar ( 256 )
	,@iSMTPPort	int=			null
	,@iTimeout	smallint=		null
	,@sProxy	varchar ( 256 )=	null
	,@sUser		varchar ( 256 )
	,@sPwd		varchar ( 256 )
	,@sFrom		varchar ( 256 )
	,@sTo		varchar ( 1024 )		-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sCc		varchar ( 1024 )=	null	-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sBcc		varchar ( 1024 )=	null	-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sSubject	varchar ( 1024 )
	,@sCharset	varchar ( 256 )			-- HKEY_CLASSES_ROOT\MIME\DataBase\Charset
	,@iImportance	tinyint=		null
	,@iPriority	tinyint=		null
	,@sBody		ntext=			null
	,@bHTMLBody	bit=			0
	,@sFileNames	nvarchar ( 4000 )=	null	-- список файлов-вложений, первый символ в качестве разделителя
	,@bFilesDelete	bit=			0	-- файлы нужно удалить, они нужны только для отправки
as
--http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_messaging.asp
--http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_schema_configuration_sendusing.asp
set	nocount	on
----------
declare	@iError			int
	,@iRowCount		int
	,@sMessage		varchar ( 256 )
	,@sMessage1		varchar ( 256 )
	,@sMessage2		varchar ( 256 )
	,@bDebug		bit=	0

	,@iOLE			int
	,@iProperty		int
	,@sProperty		varchar ( 256 )
	,@sFileNameSingle	nvarchar ( 4000 )
----------
exec	@iError=	sp_OACreate	'CDO.Message',	@iOLE	out
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 1'
		,@iError=	-1
	goto	error
end
----------
if	isnull ( @sProxy,	'' )<>	''
begin
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/urlproxyserver").Value',	@sProxy	-- servername:port
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 2'
			,@iError=	-1
		goto	error
	end
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value',		'2'	-- cdoSendUsingPort должно быть текстом
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 3'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value',		@sSMTP
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 4'
		,@iError=	-1
	goto	error
end
----------
if	@iSMTPPort	is	not	null
begin
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserverport").Value',		@iSMTPPort
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 4.1'
			,@iError=	-1
		goto	error
	end
end
----------
if	@sUser	is	not	null
begin
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate").Value',	'1'	-- cdoBasic
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 5'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusername").Value',		@sUser
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 6'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendpassword").Value',		@sPwd
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 7'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpaccountname").Value',		@sUser
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 8'
			,@iError=	-1
		goto	error
	end
--	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:content-transfer-encoding").Value', "Base64"
----------
	if	@iTimeout	is	not	null
	begin
		exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout").Value',	@iTimeout
		if	@@Error<>0	or	@iError<>	0
		begin
			select	@sMessage=	'Ошибка 8.1'
				,@iError=	-1
			goto	error
		end
	end
end
----------
--  exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:lines").Value', '0'
exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:content-language").Value',		"windows-1251"
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 9'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:httpmail:content-disposition-type").Value',	"attachment"	-- unspecified,other,attachment,inline
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 9.2'
		,@iError=	-1
	goto	error
end
----------
if	@iImportance	is	not	null
begin
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:httpmail:importance").Value',		@iImportance
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 9.3'
			,@iError=	-1
		goto	error
	end
end
----------
if	@iPriority	is	not	null
begin
	exec	@iError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:httpmail:priority").Value',			@iPriority
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 9.4'
			,@iError=	-1
		goto	error
	end
end
----------
exec	@iError=	sp_OAMethod		@iOLE,	'Configuration.Fields.Update',	null
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 10'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OAGetProperty	@iOLE,	'BodyPart',	@iProperty	OUTPUT
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 9.1'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iProperty,	'Charset',	'koi8-r'
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 9.2'
		,@iError=	-1
	goto	error
end
----------
--   exec	@iError=	sp_OASetProperty	@iOLE,	'MimeFormatted ', 'False'
exec	@iError=	sp_OASetProperty	@iOLE,	'From',		@sFrom
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 11'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'To',		@sTo
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 12'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'Cc',		@sCc
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 13'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'Bcc',		@sBcc
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 14'
		,@iError=	-1
	goto	error
end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	'Subject',	@sSubject
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 15'
		,@iError=	-1
	goto	error
end
----------
set	@sProperty=	case	isnull ( @bHTMLBody , 0 )
				when	1	then	'HTMLBody'
				else			'TextBody'
			end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	@sProperty,	@sBody
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 16'
		,@iError=	-1
	goto	error
end
----------
set	@sProperty=	case	isnull ( @bHTMLBody , 0 )
				when	1	then	'HTMLBodyPart.Charset'
				else			'TextBodyPart.Charset'
			end
----------
exec	@iError=	sp_OASetProperty	@iOLE,	@sProperty,	@sCharset
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 16.5'
		,@iError=	-1
	goto	error
end
----------
declare	cFiles	cursor	local	scroll	read_only	for
	select
		Value
	from
		damit.ToListFromStringAuto ( @sFileNames )
	order	by
		Sequence
----------
open	cFiles
----------
while	1=	1
begin
	fetch	next	from	cFiles	into	@sFileNameSingle
	if	@@fetch_status<>	0	break
----------
	set	@iProperty=	null
----------
	exec	@iError=	sp_OAMethod	@iOLE,	'AddAttachment',	@iProperty	out,	@sFileNameSingle		-- должны быть права на файл у учётной записи sql сервера
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 17'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iError=	sp_OASetProperty	@iProperty,	'ContentMediaType',	'application/octet-stream'	-- нетипизированное вложение. если не указать, то .mht автоматически перед отправкой превратится в .msg
	if	@@Error<>0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 9.4'
			,@iError=	-1
		goto	error
	end
end
----------
exec	@iError=	sp_OAMethod	@iOLE,	'Send',	NULL
if	@@Error<>0	or	@iError<>	0
begin
	select	@sMessage=	'Ошибка 18'
		,@iError=	-1
	goto	error
end
----------
if		@bFilesDelete=				1
	and	@@fetch_status=				-1
	and	isnull ( @sFileNameSingle,	'' )<>	''
	while	1=	1
	begin
		set	@sFileNameSingle=	'del /f /q '+	quotename ( @sFileNameSingle,	'"' )	-- кажется, не удалит скрытые или системные
----------
		if	@bDebug=	0
			exec	@iError=	xp_cmdshell	@sFileNameSingle,	no_output
		else
			exec	@iError=	xp_cmdshell	@sFileNameSingle
		if	@@Error<>0	or	@iError<>	0
		begin
			select	@sMessage=	'Ошибка удаления отправленного файла'
				,@iError=	-1
			goto	error
		end
----------
		fetch	prior	from	cFiles	into	@sFileNameSingle
		if	@@fetch_status<>	0	break
	end
----------
deallocate	cFiles
----------
goto	done

error:

EXEC	sp_OAGetErrorInfo	@iOLE,	@sMessage2	out,	@sMessage1	out
----------
set	@sMessage=	isnull ( @sMessage,	'Ошибка 0' )+	isnull ( ' '+	@sMessage2,	'' )+	isnull ( ': '+	@sMessage1 , '' )
----------
raiserror ( @sMessage , 18 , 1 )

done:

exec	/*@iError=	*/sp_OADestroy	@iOLE
----------
return	@iError
GO
use	tempdb