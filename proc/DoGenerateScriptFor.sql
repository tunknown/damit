use	damit
go
if	object_id ( 'damit.DoGenerateScriptFor' , 'p' )	is	null
	exec	( 'create	proc	damit.DoGenerateScriptFor	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoGenerateScriptFor
	@sObject	sysname
	,@sScript	varchar ( max )	out
as
declare	@sMessage	TMessage
	,@iError	TInteger=	0
	,@iRowCount	TInteger
	,@bDebug	TBoolean=	0	-- 1=включить отладочные сообщения
	,@sTransaction	TSysName
	,@bAlien	TBoolean
----------
select
	name
	,prec
	,scale
	,xusertype
	,colid
	,isnullable
into
	#syscolumns
from
	syscolumns
where
	0=	1
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка подготовки получения полей целевого объекта',
		@iError=	-3
	goto	error
end
----------
select
	name
	,xusertype
	,xtype
into
	#systypes
from
	systypes
where
	0=	1
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка подготовки получения полей целевого объекта',
		@iError=	-3
	goto	error
end
----------
select
	@sScript=	'
insert
	#syscolumns	( name,	prec,	scale,	xusertype,	colid,	isnullable )
select
	sc.name
	,sc.prec
	,sc.scale
	,sc.xusertype
	,sc.colid
	,sc.isnullable
from
	'+	quotename ( Server )+	'.'+	quotename ( Db )+	'.dbo.sysobjects	so
	,'+	quotename ( Server )+	'.'+	quotename ( Db )+	'.sys.schemas		s
	,'+	quotename ( Server )+	'.'+	quotename ( Db )+	'.dbo.syscolumns	sc
where
		so.name'+	case	Db
					when	'tempdb'	then	'	like	'''+	Object+	'[___]%'''
					else				'=	'''+		Object+	''''
				end+	'
	and	s.name=		'''+	Owner+	'''
	and	s.schema_id=	so.uid
	and	sc.id=		so.id
----------
insert
	#systypes	( name,	xusertype,	xtype )
select
	name
	,xusertype
	,xtype
from
	'+	quotename ( Server )+	'.'+	quotename ( Db )+	'.dbo.systypes'
from
	damit.damit.GetParseObjectName ( @sObject )
----------
if	@bDebug=	1	print	@sScript
----------
exec	( @sScript )
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка получения полей целевого объекта',
		@iError=	-3
	goto	error
end
----------
set	@sScript=	''
----------
/*
select
	@sScript=	@sScript+	'
	,'+	quotename ( ColumnName )+	'=	convert ( '+	DataType+	' , null )'
from
	( select
		ColumnName=	c.name
		,DataType=	convert ( nvarchar ( 256 ),	case
									when	t2.name	like	'%char'	or	t2.name	like	'%binary'	then	t2.name+	' ( '+	case	c.prec
																							when	-1	then	'max'
																							else			convert ( varchar ( 256 ) , c.prec )
																						end+	' )'
									when	t2.name	in	( 'numeric' , 'decimal' )			then	t2.name+	' ( '+	convert ( varchar ( 256 ) , c.prec )+	' , '+	convert ( varchar ( 256 ) , c.scale )+	' )'
									else										t2.name
								end )
		,colid
	from
		#syscolumns	c
		inner	join	#systypes	t1	on
			t1.xusertype=	c.xusertype
		inner	join	#systypes	t2	on
			t2.xtype=	t2.xusertype
		and	t2.xtype=	t1.xtype	)	t
order	by
	colid
----------
set	@sScript=	'select
	'+	right ( @sScript , len ( @sScript )-	4 )+	'
where
	0=	1'
*/




----------
select
	@sScript=	@sScript+	'
	,'+	quotename ( ColumnName )+	'	'+	DataType+	'	'+	case	isnullable
													when	1	then	''
													else			'not '
												end+	'null'
from
	( select
		ColumnName=	c.name
		,DataType=	convert ( nvarchar ( 256 ),	case
									when	t2.name	like	'%char'	or	t2.name	like	'%binary'	then	t2.name+	' ( '+	case	c.prec
																							when	-1	then	'max'
																							else			convert ( varchar ( 256 ) , c.prec )
																						end+	' )'
									when	t2.name	in	( 'numeric' , 'decimal' )			then	t2.name+	' ( '+	convert ( varchar ( 256 ) , c.prec )+	' , '+	convert ( varchar ( 256 ) , c.scale )+	' )'
									else										t2.name
								end )
		,c.colid
		,c.isnullable
	from
		#syscolumns	c
		inner	join	#systypes	t1	on
			t1.xusertype=	c.xusertype
		inner	join	#systypes	t2	on
			t2.xtype=	t2.xusertype
		and	t2.xtype=	t1.xtype	)	t
order	by
	colid
----------
set	@sScript=	'create	table	#temp
(
	'+	right ( @sScript , len ( @sScript )-	4 )+	'
)'

----------
if	@bDebug=	1	print	@sScript
----------
goto	done

error:
if	@@TranCount>	0	and	@bAlien=	0	rollback	tran	@sTransaction
raiserror ( @sMessage , 18 , 1 )

done:
----------
return	@iError


go
use	tempdb
declare	@sScript	varchar ( max )
exec	damit.damit.DoGenerateScriptFor	@sObject=	'damit.damit.ShowColumnDataTypes',	@sScript=	@sScript	out
print	@sScript