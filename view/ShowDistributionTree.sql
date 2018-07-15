use	damit
----------
if	object_id ( 'damit.ShowDistributionTree' , 'v' )	is	null
	exec	( 'create	view	damit.ShowDistributionTree	as	select	ObjectNotCreated=	1/0' )
go
alter	view	damit.ShowDistributionTree	as
with	cte	as
(	select
		DistributionRoot=	Id
		,DistributionStep=	Id
		,Task
		,Level=			convert ( varbinary ( 8000 ),	convert ( binary ( 2 ),	1 ) )
	from
		damit.Distribution
	where
		Node	is	null
	union	all
	select
		cte.DistributionRoot
		,d.Id
		,d.Task
		,Level=			convert ( varbinary ( 8000 ),	cte.Level+	convert ( binary ( 2 ),	row_number()	over	( partition	by	d.Node	order	by	d.Sequence ) ) )
	from
		cte
		,damit.Distribution	d
	where
		d.Node=	cte.DistributionStep )
select
	cte.DistributionRoot
	,cte.DistributionStep
	,cte.Level
	,te.*
	,Task=		case
				when	te.Data		is	not	null	then	'Data'
				when	te.Query	is	not	null	then	'Query'
				when	te.Format	is	not	null	then	'Format'
				when	te.Protocol	is	not	null	then	'Protocol'
				when	te.Distribution	is	not	null	then	'Distribution'
				when	te.Script	is	not	null	then	'Script'
				when	te.Layout	is	not	null	then	'Layout'
				when	te.Condition	is	not	null	then	'Condition'
				else							'Other task'
			end

	,Caption=	coalesce ( d.Target,	q.Alias,	f.FileName/*,	p.Id*/,	i.Name,	s.Name )
from
	cte
	left	join	damit.Task		te	on	-- для пустого шага, например, держателя общих параметров
		te.Id=		cte.Task
	left	join	damit.Data		d	on
		d.Id=		cte.Task
	left	join	damit.Query		q	on
		q.Id=		cte.Task
	left	join	damit.Format		f	on
		f.Id=		cte.Task
/*	left	join	damit.Protocol		p	on
		p.Id=		cte.Task
*/	left	join	damit.Distribution	i	on
		i.Id=		cte.Task
	left	join	damit.Script		s	on
		s.Id=		cte.Task
/*order	by
	DistributionRoot
	,Level*/
go
select
	*
from
	damit.damit.ShowDistributionTree
order	by
	DistributionRoot
	,Level