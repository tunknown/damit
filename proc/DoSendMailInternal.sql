/*
set @Charset='koi8-r'
-- пропущен код, приведенный Shurgenz или аналогичный
EXEC @iOLEError=sp_OASetProperty	@iOLE,	'TextBodyPart.Charset', @Charset

-- или
EXEC @iOLEError=sp_OASetProperty	@iOLE,	'HTMLBodyPart.Charset', @Charset
*/



use	damit
go
if	object_id ( 'damit.DoSendMailInternal' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSendMailInternal	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSendMailInternal
	@sSMTP		varchar ( 256 )
	,@sProxy	varchar ( 256 )
	,@sUser		varchar ( 256 )
	,@sPwd		varchar ( 256 )
	,@sFrom		varchar ( 256 )
	,@sTo		varchar ( 1024 )	-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sCc		varchar ( 1024 )	-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sBcc		varchar ( 1024 )	-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sSubject	varchar ( 1024 )
	,@sCharset	varchar ( 256 )		-- HKEY_CLASSES_ROOT\MIME\DataBase\Charset
	,@sBody		ntext
	,@bHTMLBody	bit
	,@sFileNames	nvarchar ( 4000 )	-- список файлов-вложений, первый символ в качестве разделителя
as
--http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_messaging.asp
--http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_schema_configuration_sendusing.asp
set	nocount	on
----------
declare	@iError		int=	0
	,@iRowCount	int
	,@iOLEError	int
	,@sMessage	varchar ( 256 )
	,@sMessage1	varchar ( 256 )
	,@bDebug	bit=			0

	,@iStream	int
	,@iOLE		int
	,@iProperty	int
	,@iPropertyAttch	int
	,@source	varchar ( 255 )
	,@out		varchar ( 1000 )
	,@sFileNameSingle	varchar ( 255 )

	,@sProperty	varchar ( 256 )
----------
exec	@iOLEError=	sp_OACreate	'CDO.Message',	@iOLE	out
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 1'
		,@iError=	-1
	goto	error
end
----------
if	@sProxy<>	''
begin
	exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/urlproxyserver").Value',	@sProxy
	if	@iOLEError<>	0
	begin
		select	@sMessage=	'Ошибка 2'
			,@iError=	-1
		goto	error
	end
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value',	'2'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 3'
		,@iError=	-1
	goto	error
end
-- This is to configure the Server Name or IP address. 
-- Replace MailServerName by the name or IP of your SMTP Server.
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value',	@sSMTP
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 4'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate").Value',	'1' 
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 5'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusername").Value',	@sUser
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 6'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendpassword").Value',	@sPwd
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 7'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpaccountname").Value',	@sUser
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 8'
		,@iError=	-1
	goto	error
end
--   exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:content-transfer-encoding").Value', "Base64"
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:content-language").Value',	"windows-1251"
--  exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:lines").Value', '0'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 9'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:httpmail:content-disposition-type").Value',	"attachment"	-- unspecified,other,attachment,inline
--  exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Configuration.fields("urn:schemas:mailheader:lines").Value', '0'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 9.2'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OAMethod	@iOLE,	'Configuration.Fields.Update',	null
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 10'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OAGetProperty	@iOLE,	'BodyPart',	@iProperty	OUTPUT
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 9.1'
		,@iError=	-1
	goto	error
end
-- Set the e-mail parameters.
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'From',	@sFrom
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 11'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'To',	@sTo
--   exec	@iOLEError=	sp_OASetProperty	@iOLE,	'MimeFormatted ', 'False'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 12'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Cc',	@sCc
--   exec	@iOLEError=	sp_OASetProperty	@iOLE,	'MimeFormatted ', 'False'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 13'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Bcc',	@sBcc
--   exec	@iOLEError=	sp_OASetProperty	@iOLE,	'MimeFormatted ', 'False'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 14'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iOLE,	'Subject',	@sSubject
if	@iOLEError<>	0
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
exec	@iOLEError=	sp_OASetProperty	@iOLE,	@sProperty,	@sBody
if	@iOLEError<>	0
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
exec	@iOLEError=	sp_OASetProperty	@iOLE,	@sProperty,	@sCharset
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 16.5'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OASetProperty	@iProperty,	'Charset',	'koi8-r'
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 9.2'
		,@iError=	-1
	goto	error
end



----------
declare	c	cursor	local	fast_forward	for
	select
		Value
	from
		damit.ToListFromStringAuto ( @sFileNames )
	order	by
		Sequence
----------
open	c
----------
while	1=	1
begin
	fetch	next	from	c	into	@sFileNameSingle
	if	@@fetch_status<>	0	break
----------
	exec	@iOLEError=	sp_OAMethod	@iOLE,	'AddAttachment',	@iPropertyAttch	out,	@sFileNameSingle
	if	@iOLEError<>	0
	begin
		select	@sMessage=	'Ошибка 17'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OASetProperty	@iPropertyAttch,	'ContentMediaType',	'application/octet-stream'	-- нетипизированное вложение. если не указать, то .mht автоматически перед отправкой превратится в .msg
	if	@iOLEError<>	0
	begin
		select	@sMessage=	'Ошибка 9.4'
			,@iError=	-1
		goto	error
	end
end
----------
deallocate	c
----------
exec	@iOLEError=	sp_OAMethod	@iOLE,	'Send',	NULL
if	@iOLEError<>	0
begin
	select	@sMessage=	'Ошибка 18'
		,@iError=	-1
	goto	error
end
----------
goto	done

error:

EXEC	sp_OAGetErrorInfo	@iOLE,	@source	out,	@sMessage1	out
----------
exec	@iOLEError=	sp_OADestroy	@iOLE
if	@sMessage	is	null	set	@sMessage=	'Ошибка 0'
set	@sMessage=	@sMessage+	isnull ( ': '+	@sMessage1 , '' )
raiserror ( @sMessage , 18 , 1 )

done:

return	@iError
GO
use	tempdb