if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
if	object_id ( 'damit.DoSaveFile' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSaveFile	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSaveFile
	@iExecutionLog		TId
as
set	nocount	on
declare	@sMessage		TMessage
	,@iError		TInteger
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	0	-- 1=включить отладочные сообщения
	,@sTransaction		TSysName
	,@bAlien		TBoolean

	,@gVariable		TGUID
	,@mData			varbinary ( max )
	,@sFileName		TFileName
----------
set	@bDebug=	1
----------
set	@iError=	0
----------
select
	@gVariable=	Variable0
	,@sFileName=	convert ( varchar ( 256 ),	Value1 )
from
	damit.GetVariables ( @iExecutionLog,	'FileBody',	'FileName',	default,	default,	default,	default,	default,	default,	default,	default )
if	@@RowCount>	1
begin
	select	@sMessage=	'Ошибочно заданы параметры выгрузки',
		@iError=	-3
	goto	error
end 
----------
select
	@mData=	ValueBLOB
from
	damit.Variable
where
	Id=	@gVariable
----------
exec	@iError=	damit.DoSaveToFileExInternal
				@mData=		@mData
				,@sFileName=	@sFileName
				,@sCharset=	null














----------
goto	done

error:

if	@sMessage	is	null	set	@sMessage=	'Ошибка'
raiserror ( @sMessage , 18 , 1 )

done:

return	@iError

----------
go
use	tempdb