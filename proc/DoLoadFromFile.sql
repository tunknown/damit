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
if	db_id ( 'damit' )	is	not	null	-- ����� ������������ ������� ����
	use	damit
go
if	object_id ( 'damit.DoLoadFromFile' , 'p' )	is	null
	exec	( 'create	proc	damit.DoLoadFromFile	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoLoadFromFile
	@mData		varbinary ( max )	output	-- ������ �� �����
	,@sFileName	sysname				-- ��� �����
	,@sCharset	sysname=	null		-- null=�������� ����, ����� ������� �������� ������, ��������, 'windows-1251','utf-8' ��� ����� �� HKEY_CLASSES_ROOT\MIME\Database\Charset
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
if	app_name()	like	'SSIS%'	set	@bDebug=	0	-- ��� ���������� �� ������ �� �������
----------
set	@iError=	0
----------
if	isnull ( @sFileName , '' )=	''
begin
	select	@sMessage=	'������ ������ ��� �����'
		,@iError=	-1
	goto	error
end
----------
----------
----------
set	@sPath=	left ( @sFileName , len ( @sFileName )-	charindex ( '\' , reverse ( @sFileName ) ) )	-- �������� �� ����� ����� �������
if	@bDebug=	1	print	@sPath
----------
----------
----------
exec	@iOLEError=	sp_OACreate	'ADODB.Stream',	@iStream	out
if		@@Error<>	0
	or	@iOLEError<>	0
	or	@iStream=	0
begin
	select	@sMessage=	'������ ������������� ADODB.Stream'
		,@iError=	-1
	goto	error
end
----------
if	@sCharset	is	null
begin
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Type',	1
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'��� ������ �� ���������������'
			,@iError=	-1
		goto	error
	end
end
else
begin
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Charset',	@sCharset
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'��������� ������ �� ���������������'
			,@iError=	-1
		goto	error
	end
----------
	exec	@iOLEError=	sp_OASetProperty	@iStream,	'Type',	2
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'��� ������ �� ���������������'
			,@iError=	-1
		goto	error
	end
end
----------
/*exec	@iOLEError=	sp_OASetProperty	@iStream,	'Mode',	1	-- adModeRead
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'����� ������ �� ���������������'
		,@iError=	-1
	goto	error
end*/
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'Open' 
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'����� �� �����������'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'LoadFromFile',	Null,	@sFileName--,	2
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'������ �������� �� ����� '+	convert ( varchar ( 11 ) , @iOLEError )
		,@iError=	-1
	goto	error
end
----------
set	@iSize=	0
exec	@iOLEError=	sp_OAGetProperty	@iStream,	'Size',	@iSize	OUTPUT
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'������ ��������� ����� ����� '+	convert ( varchar ( 11 ) , @iOLEError )
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
		exec	@iOLEError=	sp_OAMethod	@iStream,	'Read',		@mBuffer	output,	@iBufSize	-- ������ 8000 ��� Read �� �����, ���� ����� insert exec ��� output ���������
	else
		exec	@iOLEError=	sp_OAMethod	@iStream,	'ReadText',	@mBuffer	output,	@iBufSize
	if	@@Error<>	0	or	@iOLEError<>	0
	begin
		select	@sMessage=	'����� �� ������������� '+	convert ( varchar ( 11 ) , @iOLEError )
			,@iError=	-1
		goto	error
	end
----------
	set	@iPos=	@iPos+	@iBufSize
----------
	if	@bSkipBOM=	1	-- sql �� ����� �������������� ���������� ��������� ���������
		if	datalength ( @mData )=	0
			if	left ( @mBuffer,	3 )=	'﻿'	/*0xEFBBBF*/
				set	@mData=	@mData+	substring ( @mBuffer,	4,	len ( @mBuffer ) )
			else
				set	@mData=	@mData+	@mBuffer
		else
			set	@mData=	@mData+	@mBuffer
	else
		set	@mData=	@mData+	@mBuffer	-- ��� ������������� ����� �������� �� UPDATETEXT	#temp.data	@Image	@Pos	0	@Buffer	�� sql 2016 ��� �� ��� ��������
end
----------
exec	@iOLEError=	sp_OAMethod	@iStream,	'Close'
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'������ �������� ������'
		,@iError=	-1
	goto	error
end
----------
exec	@iOLEError=	sp_OADestroy	@iStream
if	@@Error<>	0	or	@iOLEError<>	0
begin
	select	@sMessage=	'������ ������������ ������'
		,@iError=	-1
	goto	error
end
----------
goto	done

error:

if	@sMessage	is	null	set	@sMessage=	'������'
raiserror ( @sMessage , 18 , 1 )
--EXEC	@iOLEError=	sp_OAGetErrorInfo	null,	@source	OUT,	@desc	OUT
--SELECT	OLEObject=	CONVERT ( binary ( 4 ),	@iOLEError ),	source=	@source,	description=	@desc
if	isnull ( @iStream , 0 )>	0	exec	/*@iOLEError=	*/sp_OADestroy	@iStream

done:

return	@iError

----------
go
use	tempdb