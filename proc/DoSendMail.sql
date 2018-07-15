/*
set @Charset='koi8-r'
-- пропущен код, приведенный Shurgenz или аналогичный
EXEC @iOLEError=sp_OASetProperty	@iOLE,	'TextBodyPart.Charset', @Charset

-- или
EXEC @iOLEError=sp_OASetProperty	@iOLE,	'HTMLBodyPart.Charset', @Charset
*/



use	damit
go
if	object_id ( 'damit.DoSendMail' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSendMail	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSendMail
	@iProtocol	TId
	,@sFileName	nvarchar ( 4000 )	--разделитель=|, соблюдать совместимость с damit.DoSendMailInternal
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
	,@bDebug		bit=			0

	,@sProperty	varchar ( 256 )
	,@sSMTP		varchar ( 256 )
	,@sProxy	varchar ( 256 )=	''
	,@sUser		varchar ( 256 )
	,@sPwd		varchar ( 256 )
	,@sFrom		varchar ( 256 )
	,@sTo		varchar ( 8000 )		-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sCc		varchar ( 8000 )		-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sBcc		varchar ( 8000 )		-- одно имя не длиннее 256 символов, разделённые точкой с запятой?
	,@sSubject	varchar ( 256 )=	''
	,@sBody		nvarchar ( max )=	''
	,@bHTMLBody	bit=			0
	,@bCanBlank	TBool
----------
select
	@sSMTP=		s.Server
	,@sProxy=	s.Proxy
	,@sUser=	s.Login
	,@sPwd=		s.Password
	,@sFrom=	e.[From]
	,@sTo=		e.[To]
	,@sCc=		e.Cc
	,@sBcc=		e.Bcc
	,@sSubject=	e.Subject
	,@sBody=	e.Body
	,@bHTMLBody=	e.IsHTML
	,@sFileName=	'|'+	@sFileName
	,@bCanBlank=	e.CanBlank
from
	damit.Email	e
	,damit.SMTP	s
where
		e.Id=	@iProtocol
	and	s.Id=	e.SMTP
----------
if		@bCanBlank=	1
	or	isnull ( @sFileName,	'|' )<>	'|'
begin
	exec	@iError=	damit.DoSendMailInternal
					@sSMTP=		@sSMTP
					,@sProxy=	@sProxy
					,@sUser=	@sUser
					,@sPwd=		@sPwd
					,@sFrom=	@sFrom
					,@sTo=		@sTo
					,@sCc=		@sCc
					,@sBcc=		@sBcc
					,@sSubject=	@sSubject
					,@sCharset=	'windows-1251'	--@sCharset
					,@sBody=	@sBody
					,@bHTMLBody=	@bHTMLBody
					,@sFileNames=	@sFileName
	if	@@Error<>	0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 1'
			,@iError=	-1
		goto	error
	end
end
----------
goto	done

error:

----------
raiserror ( @sMessage , 18 , 1 )

done:

return	@iError
GO
use	tempdb