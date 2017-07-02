use	damit
----------
if	object_id ( 'damit.GetParseObjectName' , 'if' )	is	null
	exec	( 'create	function	damit.GetParseObjectName(@sObject	damit.TSystemName)	returns	table	as	return	( select	q=	1)' )
go
alter	function	damit.GetParseObjectName	-- разбор имени объекта
(	@sObject	damit.TSystemName	)	-- название объекта(длина с запасом)
returns	table
as
-- ?следить за SQL injection
----------
return	( select
		Server
		,Db
		,Owner
		,Object
		,SmartName=	case	Server									-- если сервер чужой, то полное имя, если свой, то локальное
					when	@@ServerName	then	LocalName
					else				RemoteName
				end
		,RemoteName
		,LocalName
		,SmartNameT=	case	Server									-- если сервер чужой, то полное имя, если свой, то локальное
					when	@@ServerName	then	LocalNameT
					else				RemoteNameT
				end
		,RemoteNameT
		,LocalNameT
	from
		( select
			Server
			,Db
			,Owner
			,Object
			,RemoteName=		quotename ( Server )
					+	'.'
					+	case	Db							-- полное имя с сервером
							when	'tempdb'	then	'.'
							else				quotename ( Db )
										+	'.'
										+	quotename ( Owner )
						end
					+	'.'
					+	quotename ( Object )
			,RemoteNameT=		quotename ( Server )
					+	'.'
					+	quotename ( Db )
					+	'.'
					+	quotename ( Owner )
					+	'.'
					+	quotename ( Object )
			,LocalName=		case	Db							-- локальное имя без сервера
							when	'tempdb'	then	''
							else				quotename ( Db )
										+	'.'
										+	quotename ( Owner )
										+	'.'
						end
					+	quotename ( Object )
			,LocalNameT=		quotename ( Db )
					+	'.'
					+	quotename ( Owner )
					+	'.'
					+	quotename ( Object )
		from
			( select
				Server=	isnull ( parsename ( @sObject,	4 ),	@@servername )
				,Db=	case
						when		(	0<	charindex ( '.#',	@sObject )
								or	0<	charindex ( '.[#',	@sObject ) )
							or	(	(	left ( @sObject,	1 )=	'#'
									or	left ( @sObject,	2 )=	'[#' )
								and	charindex ( '.',	@sObject )=	0 )	then	'tempdb'
						else										isnull ( parsename ( @sObject,	3 ),	db_name() )
					end
				,Owner=	isnull ( parsename ( @sObject,	2 ),	'dbo' )
				,Object=parsename ( @sObject,	1 )	)	t )	t )
----------
go
select	*	from	damit.GetParseObjectName	( 'servername.w.e.#r' )