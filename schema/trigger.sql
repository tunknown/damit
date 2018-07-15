-- НУЖЕН ГЕНЕРАТОР для всех entity вариантов таблиц


use	damit
go
create	trigger	damit.TRdamitFolderInsert	on	damit.Folder
instead	of	insert	as
set	nocount	on
----------
declare	@dIdentity	numeric ( 38,	0 )
----------
declare	@tIds	table
(	Id	smallint	not null
	/*,CC526421EF0D6244A5AF9E938300EB60	smallint	not null	identity ( 1,	1 )*/	)	-- что дешевле, inserd identity или row_number()?
----------
if	@@trancount=	0
	begin	tran	CC526421EF0D6244A5AF9E938300EB60
else
	save	tran	CC526421EF0D6244A5AF9E938300EB60
----------
insert
	damit.TaskIdentity	( Dumb )
output
	inserted.Id
into
	@tIds	( Id )
select
	null
from
	inserted
----------
rollback	tran	CC526421EF0D6244A5AF9E938300EB60	-- это дешевле, чем делать delete
----------
insert
	damit.Folder	( Id,	Script,	Path )
select
	tt.Id							-- как при insert снаружи получить свежевставленные идентификаторы?
	,t.Script
	,t.Path
from
	( select
		*
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )	-- порядок вставки может не сохраниться, т.к. сейчас там null
	from
		inserted )	t
	,( select
		Id
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )
	from
		@tIds )	tt
where
		tt.CC526421EF0D6244A5AF9E938300EB60=	t.CC526421EF0D6244A5AF9E938300EB60
----------
insert
	damit.Protocol	( Id,	Folder )
select
	tt.Id
	,tt.Id
from
	( select
		*
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )	-- порядок вставки может не сохраниться, т.к. сейчас там null
	from
		inserted )	t
	,( select
		Id
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )
	from
		@tIds )	tt
where
		tt.CC526421EF0D6244A5AF9E938300EB60=	t.CC526421EF0D6244A5AF9E938300EB60
----------
if	object_id ( 'tempdb..#CC526421EF0D6244A5AF9E938300EB60',	'u' )	is	not	null
begin
	insert
		#CC526421EF0D6244A5AF9E938300EB60	( /*SPID,	*/ObjectName,	Value )		-- сохраняем все свежевставленные идентификаторы
	select
		/*SPID=		@@SPID
		,*/ObjectName=	'damit.Folder'
		,Value=		Id
	from
		@tIds
end
----------
select	@dIdentity=	min ( Id )	from	@tIds	-- первый индентификатор уповая на то, что сортировка ASC и следующие будут ниже в гриде
----------
create	table	#identity
(	Id	numeric ( 38,	0 )	identity ( 1,	1 )	)
----------
DBCC	CHECKIDENT	( 'tempdb..#identity',	reseed,	@dIdentity )	WITH	NO_INFOMSGS	-- или использовать @tIds.CC526421EF0D6244A5AF9E938300EB60, чтобы не создавать лишнюю таблицу?
----------
insert	#identity	default	values	-- set @@identity=first(@tIds) сохраняем тлько первый свежевставленный идентификатор
----------
drop	table	#identity
go
----------------------------------------------------------------------------------------------------
go
create	trigger	damit.TRdamitDataInsert	on	damit.Data
instead	of	insert	as
set	nocount	on
----------
declare	@dIdentity	numeric ( 38,	0 )
----------
declare	@tIds	table
(	Id	smallint	not null
	/*,CC526421EF0D6244A5AF9E938300EB60	smallint	not null	identity ( 1,	1 )*/	)	-- что дешевле, inserd identity или row_number()?
----------
if	@@trancount=	0
	begin	tran	CC526421EF0D6244A5AF9E938300EB60
else
	save	tran	CC526421EF0D6244A5AF9E938300EB60
----------
insert
	damit.TaskIdentity	( Dumb )
output
	inserted.Id
into
	@tIds	( Id )
select
	null
from
	inserted
----------
rollback	tran	CC526421EF0D6244A5AF9E938300EB60	-- это дешевле, чем делать delete
----------
insert
	damit.Data	( Id,	Target,	DataLog,	Filter,	Name,	Refiner,	CanCreated,	CanChanged,	CanRemoved,	CanFixed )
select
	tt.Id
	,t.Target
	,t.DataLog
	,t.Filter
	,t.Name
	,t.Refiner
	,t.CanCreated
	,t.CanChanged
	,t.CanRemoved
	,t.CanFixed
from
	( select
		*
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )	-- порядок вставки может не сохраниться, т.к. сейчас там null
	from
		inserted )	t
	,( select
		Id
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )
	from
		@tIds )	tt
where
		tt.CC526421EF0D6244A5AF9E938300EB60=	t.CC526421EF0D6244A5AF9E938300EB60
----------
insert
	damit.Task	( Id,	Data )
select
	tt.Id
	,tt.Id
from
	( select
		*
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )	-- порядок вставки может не сохраниться, т.к. сейчас там null
	from
		inserted )	t
	,( select
		Id
		,CC526421EF0D6244A5AF9E938300EB60=	row_number()	over	( order	by	Id )
	from
		@tIds )	tt
where
		tt.CC526421EF0D6244A5AF9E938300EB60=	t.CC526421EF0D6244A5AF9E938300EB60
----------
if	object_id ( 'tempdb..#CC526421EF0D6244A5AF9E938300EB60',	'u' )	is	not	null
begin
	insert
		#CC526421EF0D6244A5AF9E938300EB60	( /*SPID,	*/ObjectName,	Value )		-- сохраняем все свежевставленные идентификаторы
	select
		/*SPID=		@@SPID
		,*/ObjectName=	'damit.Data'
		,Value=		Id
	from
		@tIds
end
----------
select	@dIdentity=	min ( Id )	from	@tIds	-- первый индентификатор уповая на то, что сортировка ASC и следующие будут ниже в гриде
----------
create	table	#identity
(	Id	numeric ( 38,	0 )	identity ( 1,	1 )	)
----------
DBCC	CHECKIDENT	( 'tempdb..#identity',	reseed,	@dIdentity )	WITH	NO_INFOMSGS	-- или использовать @tIds.CC526421EF0D6244A5AF9E938300EB60, чтобы не создавать лишнюю таблицу?
----------
insert	#identity	default	values	-- set @@identity=first(@tIds) сохраняем тлько первый свежевставленный идентификатор
----------
drop	table	#identity