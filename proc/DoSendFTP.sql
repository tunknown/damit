use	damit
----------
if	object_id ( 'damit.DoSendFTP' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSendFTP	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSendFTP
	@iExecutionLog		TId
as
-- следить за SQL injection
-- опасно чередовать использование выгрузок по изменению даты и изменению содержимого
-- сначала лучше применять выгрузку по изменению содержимого, после уточнения бизнес-процесса можно перейти к выгрузке по дате изменения
-- эту процедуру нельзя вызывать из транзакции, т.к. bcp не будет иметь доступа к свежевставленным данным до commit tran
if	app_name()	like	'SSIS%'			-- при выполнении из пакета не заходим
	return	0
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	0	-- 1=включить отладочные сообщения

	,@sExecShort		nvarchar ( 4000 )


	,@sFileNameHeader	TFileName
	,@sFileNameData		TFileName
	,@sFileName		TFileName
	,@sFileName1		TFileName
	,@sDirName		TFileName
	,@sCmdFileName		TFileName
	,@sHeader		TFileName




	,@iScript		TId
	,@iProtocol		TId
	,@bSFTP			TBoolean
	,@bFTPS			TBoolean




	,@sServer		TExtName
	,@iPort			TInteger
	,@sLogin		TExtName
	,@sPassword		TName
	,@sPrivateKey		TFileName
	,@sPath			TFileName
	,@iRetryAttempts	TInteger

--	,@sExecType		varchar ( 32 )

	,@sScript		TScript
	,@sScriptCmd		varchar ( 4000 )
	,@sScriptCmd1		varchar ( 4000 )

	,@bFilesOmitted		TBoolean
----------
if	app_name()	like	'SSIS%'	set	@bDebug=	0	-- при выполнении из пакета не заходим
----------
/*if		(	isnull ( sign ( datalength ( @dtFilterChangeDate ) ),	0 )
		+	isnull ( sign ( datalength ( @bFilterChangeTarget ) ),	0 )
		+	isnull ( sign ( datalength ( @sFilterList ) ),		0 ))>	1	-- преобразование выражения к integer, т.к. bit складывать нельзя
--	or	@bFilterTable=	1	and	isnull ( @sFilterList , '' )=	''		-- пока не проверяем существование таблицы
begin
	select	@sMessage=	'Ошибочно заданы параметры фильтрации',
		@iError=	-3
	goto	error
end*/
----------
----------
select
	@iProtocol=	D.Task
from
	damit.ExecutionLog	DL
	inner	join	damit.Distribution	D	on
		D.Id=		DL.Distribution
	inner	join	damit.Protocol		PE	on
		PE.Id=		D.Task
	and	isnull ( PE.SFTP,	PE.FTPS )	is	not	null
where
		DL.Id=		@iExecutionLog
if	@@RowCount<>	1
begin
	select	@sMessage=	'Ошибочно задана выгрузка',
		@iError=	-3
	goto	error
end
----------
select
	@sServer=	t.Server
	,@iPort=	t.Port
	,@sLogin=	t.Login
	,@sPassword=	t.Password
	,@sPrivateKey=	t.PrivateKey
	,@sPath=	t.Path
	,@iRetryAttempts=	t.RetryAttempts
--		,@sExecType=	a.Type
	,@iScript=	t.Script
from
	( select
		Protocol=	Id
		,Script
		,Server
		,Port
		,Login
		,Password
		,PrivateKey
		,Path
		,RetryAttempts
	from
		damit.SFTP
	union	all
	select
		Protocol=	Id
		,Script
		,Server
		,Port
		,Login
		,Password
		,null
		,Path
		,RetryAttempts
	from
		damit.FTPS )	t
	,damit.Script	a
where
		t.Protocol=	@iProtocol
	and	a.Id=		t.Script
----------
select	@sScriptCmd=	Command	from	damit.Script	where	Id=	@iScript
----------
declare	c	cursor	local	fast_forward	for
	select
		convert ( nvarchar ( 4000 ),	Value0 )
	from
		damit.GetVariables ( @iExecutionLog,	'FileName',	default,	default,	default,	default,	default,	default,	default,	default,	default )
	order	by
		Sequence
----------
open	c
----------
while	1=	1
begin
	fetch	next	from	c	into	@sFileName
----------
	if	@bFilesOmitted	is	null
		set	@bFilesOmitted=	case	@@fetch_status
						when	0	then	0
						else			1
					end
	else
		if	@@fetch_status<>	0	break
----------
	set	@sScriptCmd1=	replace (
				replace (
				replace (
				replace (
				replace (
				replace (
				replace (
				@sScriptCmd
				,'<login/>',	isnull ( @sLogin,	'' ) )
				,'<password/>',	isnull ( @sPassword,	'' ) )
				,'<server/>',	isnull ( @sServer,	'' ) )
				,'<port/>',	isnull ( convert ( varchar ( 10 ),	@iPort ),	'' ) )
				,'<privatekey/>',isnull ( @sPrivateKey,	'' ) )
				,'<path/>',	isnull ( @sPath,	'' ) )
				,'<FileName/>',	isnull ( @sFileName,	'' ) )
----------
	if	@bDebug=	1
	begin
		print	@sScriptCmd1
		exec	@iError=	xp_cmdshell	@sScriptCmd1
	end
	else
		exec	@iError=	xp_cmdshell	@sScriptCmd1,	no_output
	if	@@Error<>	0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка выгрузки на FTP',
			@iError=	-3
		goto	error
	end
end
----------
deallocate	c
----------
if	@bFilesOmitted=	1	-- файлов снаружи не передаётся, т.е. это получение файлов с FTP сервера
begin
	print	'***'



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