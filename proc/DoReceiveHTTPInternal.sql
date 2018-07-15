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
if	object_id ( 'damit.DoReceiveHTTPInternal' , 'p' )	is	null
	exec	( 'create	proc	damit.DoReceiveHTTPInternal	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoReceiveHTTPInternal
	@sURL		varchar ( 8000 )		-- ***
	,@mData		nvarchar ( max )	output	-- ***
	,@sLogin	nvarchar ( 256 )
	,@sPassword	nvarchar ( 256 )
	,@bIsAsync	bit=	0
as
set	nocount	on
declare	@bDebug		bit=	1
	,@iError	int
	,@iRowCount	int
	,@sMessage	varchar ( 256 )
	,@sMessage2	varchar ( 256 )

	,@iOLEError	int
	,@iOLEObject	int
	,@iResult	int
	,@s		varchar ( 256 )
----------
select	@bDebug=	1
	,@iError=	0
	,@s=		case
				when	@bIsAsync=	1	then	'True'
				else					'False'
			end
----------
exec	@iOLEError=	sp_OACreate	'Microsoft.XMLHTTP',	@iOLEObject	OUT
if	@@Error<>	0	or	@iOLEError<>	0
BEGIN
	EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
	set	@iError=	-1
	goto	error
end
----------
EXEC	@iOLEError=	sp_OAMethod
				@iOLEObject
				,'Open'
				,NULL
				,'GET'
				,@sURL
				,@s
				,@sLogin
				,@sPassword
if	@@Error<>	0	or	@iOLEError<>	0
BEGIN
	EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
	set	@iError=	-1
	goto	error
end
----------
EXEC	@iOLEError=	sp_OAMethod	@iOLEObject,	'Send'--,	NULL,	@iResult
if	@@Error<>	0	or	@iOLEError<>	0
BEGIN
	EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
	set	@iError=	-1
	goto	error
end
----------
EXEC	@iOLEError=	sp_OAGetProperty	@iOLEObject,	'status',	@iResult	OUT
if	@@Error<>	0	or	@iOLEError<>	0
BEGIN
	EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
	set	@iError=	-1
	goto	error
end
----------
if	@iResult<>	200
BEGIN
	select	@sMessage=	'Invalid response status',
		@iError=	-3
	goto	error
END
/*
EXEC	@iOLEError=	sp_OAMethod	@iOLEObject,	'getResponseHeader',	null,	'Content-Length'
EXEC	@iOLEError=	sp_OAMethod	@iOLEObject,	'getResponseHeader',	null,	'Content-Type'
*/
----------
WHILE	1=	1
begin
	EXEC	@iOLEError=	sp_OAGetProperty	@iOLEObject,	'readyState',	@iResult	OUT
	if	@@Error<>	0	or	@iOLEError<>	0
	BEGIN
		EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
		set	@iError=	-1
		goto	error
	end
	if	@iResult=	4	break
----------
	EXEC	@iOLEError=	sp_OAMethod	@iOLEObject,	'waitForResponse',	1	--timeoutInSeconds
	if	@@Error<>	0	or	@iOLEError<>	0
	BEGIN
		EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
		set	@iError=	-1
		goto	error
	end
end
----------
create	table	#damitDoReceiveHTTPInternal_responsetext
(	Data	nvarchar(max)	)								-- varbinary ( max ) не подходит ODSOLE Extended Procedure:Error in srv_sendrow.
----------
SET	TEXTSIZE	2147483647	-- для job агент не делает такую установку, см.http://www.sql.ru/forum/576338/konnektor-k-veb-sluzhbam-ms-sql-2000?mid=5988363#10499359
----------
insert	#damitDoReceiveHTTPInternal_responsetext	( Data )				-- через out параметр получаем ошибку ODSOLE Extended Procedure:Binary source data must be a single-dimensioned array of unsigned char.
EXEC	@iOLEError=	sp_OAGetProperty	@iOLEObject,	'responsetext'--,	@mData	out
select	@iError=	@@Error
	,@iRowCount=	@@RowCount
if	@iError<>	0	or	@iOLEError<>	0	or	1<	@iRowCount
BEGIN
	EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
	set	@iError=	-1
	goto	error
end
----------
SELECT	@mData=	Data	from	#damitDoReceiveHTTPInternal_responsetext
----------
if	@bDebug=	1
	print	'datalength='+	convert ( varchar ( 10 ) , datalength ( @mData ) )
----------
drop	table	#damitDoReceiveHTTPInternal_responsetext
----------
EXEC	@iOLEError=	sp_OADestroy	@iOLEObject
if	@@Error<>	0	or	@iOLEError<>	0 
begin
	EXEC	sp_OAGetErrorInfo	@iOLEObject,	@sMessage	out,	@sMessage2	out
	set	@iError=	-1
	goto	error
end
----------
goto	done

error:

if	@sMessage	is	null	set	@sMessage=	'Ошибка'	else	set	@sMessage=	@sMessage+	isnull ( ':'+	@sMessage2 , '' )
raiserror ( @sMessage , 18 , 1 )
--EXEC	@iOLEError=	sp_OAGetErrorInfo	null,	@source	OUT,	@desc	OUT
--SELECT	OLEObject=	CONVERT ( binary ( 4 ),	@iOLEError ),	source=	@source,	description=	@desc
if	isnull ( @iOLEObject , 0 )>	0	exec	/*@iOLEError=	*/sp_OADestroy	@iOLEObject

done:

return	@iError

----------
go
use	tempdb