use	damit
----------
if	object_id ( 'damit.getdate' , 'v' )	is	null
	exec	( 'create	view	damit.getdate	as	select	ObjectNotCreated=	1/0' )
go
alter	view	damit.getdate	as
select	getdate=	getdate()
go
use	tempdb