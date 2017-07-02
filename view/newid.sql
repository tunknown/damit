use	damit
----------
if	object_id ( 'damit.NewID' , 'v' )	is	null
	exec	( 'create	view	damit.NewID	as	select	ObjectNotCreated=	1/0' )
go
alter	view	damit.newid	as
select	newid=	newid()
go
use	tempdb