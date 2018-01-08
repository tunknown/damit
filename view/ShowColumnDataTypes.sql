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
	ColumnId=	c.colid,										--/не гарантирует последовательность
	Sequence=	row_number()	over	( partition	by	o.Id	order	by	c.colid ),	--\гарантирует последовательность
	IsLast=		case	row_number()	over	( partition	by	o.Id	order	by	c.colid	desc )
				when	1	then	1
				else			0
			end,
	TypeId=		t1.xusertype,
	ObjectType=	o.xtype,
	ObjectAlias=	convert ( nvarchar ( 257 ),	schema_name ( o.uid )+	'.'+	o.name ),
	ObjectName=	o.name,
	SchemaName=	schema_name ( o.uid ),
	ColumnName=	c.name,
	UserType=	schema_name ( t1.uid )+	'.'+	t1.name,
	DataType=	convert ( nvarchar ( 256 ),	case
								when		t2.name	like	'%char'
									or	t2.name	like	'%binary'		then	t2.name
															+	' ( '
															+	case	c.prec
																	when	-1	then	'max'
																	else			convert ( varchar ( 256 ),	c.prec )
																end+	' )'
								when	t2.name	in	( 'numeric',	'decimal' )	then	t2.name
															+	' ( '
															+	convert ( varchar ( 256 ),	c.prec )
															+	' , '
															+	convert ( varchar ( 256 ),	c.scale )
															+	' )'
								else								isnull ( t2.name,	t1.name )
							end ),
	SystemType=	isnull ( t2.name,	t1.name ),
	Prec=		typeproperty ( schema_name ( t1.uid )+	'.'+	t1.name,	'precision' ),
	Scale=		typeproperty ( schema_name ( t1.uid )+	'.'+	t1.name,	'scale' ),
	Length=		c.length,
	IsNullable=	c.isnullable,
	IsComputed=	c.iscomputed,
	IsPrimaryKey=	convert ( tinyint,	case	c.name		-- тип bit нежелательно использовать в агрегатах?
							when	INDEX_COL ( schema_name ( o.uid )+	'.'+	o.name,	ik.indid,	ik.keyno )	then	1
							else													0
						end ),
	IsForeignKey=	convert ( tinyint,	case
							when	fk.fkeyid	is	null	then	0
							else						1
						end ),
	TableIdRef=	fk.rkeyid,
	ColumnIdRef=	fk.rkey,
	TableAliasRef=	convert ( nvarchar ( 257 ),	user_name ( OBJECTPROPERTY ( fk.rkeyid,	'OwnerId' ) )+	'.'+	object_name ( fk.rkeyid ) ),
	TableNameRef=	object_name ( fk.rkeyid ),
	ColumnNameRef=	COL_NAME ( fk.rkeyid,	fk.rkey ),
	Entry=		o.crdate
from
	sysobjects	o						-- через type_name ( typeproperty ( name , 'systemtype' ) ) медленнее
	inner	join	syscolumns	c	on
		c.id=		o.id
	inner	join	systypes	t1	on			-- сработает ли inner для select Col_With_UserType into #temp?
		t1.xusertype=	c.xusertype
	left	join	systypes	t2	on			-- left для поддержки hierarchyid xtype=240
		t2.xtype=	t1.xtype
	and	t2.xtype=	t2.xusertype
	left	join	( select
				so.parent_obj
				,i.id
				,i.indid
			from
				sysobjects	so
				,sysindexes	i
			where
					so.xtype=	'pk'		-- дополнительный join из-за определения, что это primary
				and	i.name=		so.name
				and	i.id=		so.parent_obj )	opk	on
		opk.parent_obj=	o.id
	left	join	sysindexkeys	ik	on
		ik.id=		opk.id
	and	ik.indid=	opk.indid
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
select	*	from	damit.ShowColumnDataTypes	order	by	ObjectId,	ColumnId