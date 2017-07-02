use	damit
----------
if	object_id ( 'damit.DoGetObjectId' , 'p' )	is	null
	exec	( 'create	proc	damit.DoGetObjectId	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoGetObjectId	-- получение на SQLServer sysobjects.Id для объекта
	@sObject	TSysName
	,@iObject	TInteger=	null	out
	,@sType		varchar ( 2 )=	null	out
as
----------
set	nocount	on
----------
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=включить отладочные сообщения
	,@sTransaction		TSysName
	,@bAlien		TBoolean
	,@iError2		TInteger=	0

	,@sExec			TScript
	,@sExecAtServer		TSystemname

	,@sSchema		TSysName
	,@sDatabase		TSysName
	,@sDatabaseQuoted	TSysName
	,@sServerQuoted		TSysName
----------
select
	@sServerQuoted=		quotename ( Server )
	,@sDatabase=		Db
	,@sDatabaseQuoted=	quotename ( Db )
	,@sSchema=		Owner
	,@sObject=		Object
from
	damit.GetParseObjectName ( @sObject )
----------
select	@sExecAtServer=	@sServerQuoted+	'...sp_executesql'
	,@sExec=
'select
	@iObject=	so.id
	,@sType=	so.xtype
from
	'+	@sDatabaseQuoted+	'.dbo.sysobjects	so
	,'+	@sDatabaseQuoted+	'.sys.schemas	s
where
		so.name'+	case
					when		@sDatabase=	'tempdb'
						and	@sObject	like	'#[^#]%'	then	'	like	@sObject+	''[___]%'''	-- захватим #объект из чужого коннекта:-(((
					else								'=	@sObject'
				end+	'
	and	so.uid=		s.schema_id
	and	s.name=		@sSchema'
----------
if	@bDebug=	1
begin
	print	( @sDatabaseQuoted )
	print	( @sSchema )
	print	( @sObject )
	print	( @sExecAtServer )
	print	( @sExec )
end
----------
exec	@iError2=	@sExecAtServer
				@statement=	@sExec
				,@params=	N'@sObject	sysname
						,@sSchema	sysname
						,@iObject	int		out
						,@sType		varchar ( 2 )	out'
				,@sObject=	@sObject
				,@sSchema=	@sSchema
				,@iObject=	@iObject	out
				,@sType=	@sType		out
select	@iError=	@@Error
	,@iRowCount=	@@RowCount
----------
if	@iError<>	0	or	@iError2<>	0
begin
	select	@sMessage=	'Ошибка получения целевой таблицы',
		@iError=	-3
	goto	error
end
----------
if	@iRowCount>	1		-- найдено больше одного объекта с таким именем, например, временные таблицы
	select	@iObject=	null
		,@sType=	null
----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go

create	table	#q	(	q	int	)
----------
declare	@sObject	damit.TSysName=	'#q'
	,@iObject	damit.TInteger
	,@sType		varchar ( 2 )
----------
exec	damit.damit.DoGetObjectId
	@sObject=	@sObject
	,@iObject=	@iObject	out
	,@sType=	@sType		out
----------
drop	table	#q
----------
select	sObject=	@sObject
	,iObject=	@iObject
	,sType=		@sType
----------
use	tempdb
