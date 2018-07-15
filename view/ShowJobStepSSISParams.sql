use	damit
----------
if	object_id ( 'damit.ShowJobStepSSISParams' , 'v' )	is	null
	exec	( 'create	view	damit.ShowJobStepSSISParams	as	select	ObjectNotCreated=	1/0' )
go
alter	view	damit.ShowJobStepSSISParams	as
with	cte	as
(	select
		job_id
		,step_id
		,Value=	substring ( command , patindex ( '%/SET%;%/%' , command ) , len ( command ) )
	from
		msdb.dbo.sysjobsteps
	where
		Command	like	'%/set%'
	union	all
	select
		job_id
		,step_id
		,Value=	substring	( stuff	( cte.Value
						,1
						,4
						,'' )
					,patindex	( '%/SET%;%/%'
							,stuff	( cte.Value
								,1
								,4
								,'' ) )
					,len	( stuff	( cte.Value
							,1
							,4
							,'' ) ) )
	from
		cte
	where
		patindex ( '%/SET%;%/%',	stuff ( cte.Value,	1,	4,	'' ) )<>	0	)
select
	job_id
	,step_id
	,Value=	case	patindex ( '% /%' , cte.Value )
			when	0	then	cte.Value
			else			substring ( cte.Value , patindex ( '%/SET%' , cte.Value )+	5 , patindex ( '% /%' , cte.Value )-	patindex ( '%/SET%' , cte.Value )-	1-	4 )
		end
from
	cte
go
use	tempdb
select
	*
from
	damit.damit.ShowJobStepSSISParams
order	by
	job_id
	,step_id
	,Value