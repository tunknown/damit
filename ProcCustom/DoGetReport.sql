use	damit
----------
if	object_id ( 'damit.DoGetReport' , 'p' )	is	null
	exec	( 'create	proc	damit.DoGetReport	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoGetReport
	@iExecutionLog	TId
as
set	nocount	on
declare	@bDebug		bit=	1
	,@iError	int
	,@iRowCount	int
	,@sMessage	varchar ( 256 )

	,@sServer	varchar ( 256 )
	,@sPath		varchar ( 256 )		--'/ReportServer/Pages/ReportViewer.aspx?'
	,@sReport	varchar ( 256 )
	,@sRender	varchar ( 256 )		--'&rs:Command=Render&rs:Format=EXCEL'

	,@sURL		varchar ( 8000 )
	,@mData		nvarchar ( max )
----------
select
	@sServer=	convert ( varchar ( 256 ),	Value0 )
	,@sPath=	convert ( varchar ( 256 ),	Value1 )
	,@sReport=	convert ( varchar ( 256 ),	Value2 )
	,@sRender=	convert ( varchar ( 256 ),	Value3 )
from
	damit.GetVariables ( @iExecutionLog,	'Server',	'Path',	'Report',	'Render',	default,	default,	default,	default,	default,	default )
if	@@RowCount>	1
begin
	select	@sMessage=	'Ошибочно заданы параметры выгрузки',
		@iError=	-3
	goto	error
end 
----------
set	@sURL=	@sServer+	@sPath+	@sReport+	@sRender
----------
exec	@iError=	damit.DoReceiveHTTPInternal
				@sURL=		@sURL
				,@mData=	@mData	output
if	@iError<>	0
BEGIN
	select	@sMessage=	'Ошибка получения отчёта',
		@iError=	-3
	goto	error
END
----------
exec	@iError=	damit.SetupVariable
				@iExecutionLog=	@iExecutionLog
				,@sAlias=	'FileBody'
				,@mValue=	@mData
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'Ошибка',
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