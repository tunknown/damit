use	damit
go
----------------------------------------------------------------------------------------------------
if	object_id ( 'damit.ShowColumnDataTypes' , 'v' )	is	null
	exec	( 'create	view	damit.ShowColumnDataTypes	as	select	ObjectNotCreated=	1/0' )
go
alter	view	damit.ShowColumnDataTypes
as
select
	ObjectId=	o.Id,
	SchemaId=	o.uid,
	ColumnId=	c.colid,
	TypeId=		t1.xusertype,
	ObjectType=	o.xtype,
	ObjectAlias=	convert ( nvarchar ( 257 ),	schema_name ( o.uid )+	'.'+	o.name ),
	ObjectName=	o.name,
	SchemaName=	schema_name ( o.uid ),
	ColumnName=	c.name,
	UserType=	schema_name ( t1.uid )+	'.'+	t1.name,
	DataType=	convert ( nvarchar ( 256 ),	case
								when	t2.name	like	'%char'	or	t2.name	like	'%binary'	then	t2.name+	' ( '+	case	c.prec
																						when	-1	then	'max'
																						else			convert ( varchar ( 256 ) , c.prec )
																					end+	' )'
								when	t2.name	in	( 'numeric' , 'decimal' )			then	t2.name+	' ( '+	convert ( varchar ( 256 ) , c.prec )+	' , '+	convert ( varchar ( 256 ) , c.scale )+	' )'
								else										t2.name
							end ),
	SystemType=	t2.name,
	Prec=		typeproperty ( schema_name ( t1.uid )+	'.'+	t1.name , 'precision' ),
	Scale=		typeproperty ( schema_name ( t1.uid )+	'.'+	t1.name , 'scale' ),
	Length=		c.length,
	IsNullable=	c.isnullable,
	IsComputed=	c.iscomputed,
	IsPrimaryKey=	convert ( tinyint,	case	c.name		-- тип bit нельзя использовать в агрегатах
							when	INDEX_COL ( schema_name ( o.uid )+	'.'+	o.name , i.indid , ik.keyno )	then	1
							else										0
						end ),
	IsForeignKey=	convert ( tinyint,	case
							when	fk.fkeyid	is	null	then	0
							else						1
						end ),
	TableIdRef=	fk.rkeyid,
	ColumnIdRef=	fk.rkey,
	TableAliasRef=	convert ( nvarchar ( 257 ),	user_name ( OBJECTPROPERTY ( fk.rkeyid , 'OwnerId' ) )+	'.'+	object_name ( fk.rkeyid ) ),
	TableNameRef=	object_name ( fk.rkeyid ),
	ColumnNameRef=	COL_NAME ( fk.rkeyid , fk.rkey ),
	Entry=		o.crdate
from
	sysobjects	o		-- через type_name ( typeproperty ( name , 'systemtype' ) ) медленнее
	inner	join	systypes	t2	on
		t2.xtype=	t2.xusertype
	inner	join	systypes	t1	on
		t1.xtype=	t2.xtype
	inner	join	syscolumns	c	on
		c.id=		o.id
	and	c.xusertype=	t1.xusertype
	left	join	sysobjects	oc	on
		oc.xtype=	'pk'
	and	oc.parent_obj=	o.id
	left	join	sysindexes	i	on
		i.name=		oc.name
	left	join	sysindexkeys	ik	on
		ik.id=		i.id
	and	ik.indid=	i.indid
	and	ik.colid=	c.colid
	left	join	( select	distinct			-- если одно поле участвует в нескольких FK
				fkeyid,
				rkeyid,
				fkey,
				rkey
			from
				sysforeignkeys )	fk	on
		fk.fkeyid=	o.id
	and	fk.fkey=	c.colid
where
		OBJECTPROPERTY ( o.id , 'IsMSShipped' )=	0
go
select	*	from	damit.ShowColumnDataTypes