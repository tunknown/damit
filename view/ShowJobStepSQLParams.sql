use	damit
----------
if	object_id ( 'damit.ShowJobStepSQLParams' , 'v' )	is	null
	exec	( 'create	view	damit.ShowJobStepSQLParams	as	select	ObjectNotCreated=	1/0' )
go
alter	view	damit.ShowJobStepSQLParams	as
with	cte	as
(	select
		job_id
		,step_id
		,command=	substring ( command , charindex ( '@' , command , patindex ( '%damit.DoTransfer%' , command ) ) , len ( command ) )
		,commandFull=	command
	from
		msdb.dbo.sysjobsteps
	where
		command	like	'%damit.DoTransfer%' )
,	cte1	as
(	select
		job_id
		,step_id
		,Name=	substring ( command,	charindex ( '@' , command ),	charindex ( '=' , command )-	charindex ( '@' , command ) )
		,Value=	dbo.ltrimm ( substring ( command,	charindex ( '=' , command )+	1,	case	patindex ( '%,%@%' , command )
														when	0	then	len ( command )
														else			patindex ( '%,%@%' , command )-	charindex ( '=' , command )-	1
													end ) )
		,commandTail=	case	patindex ( '%,%@%' , command )
					when	0	then	''
					else			right ( command , len ( command )-	patindex ( '%,%@%' , command ) )
				end
		,Sequence=	1
	from
		cte
	union	all
	select
		job_id
		,step_id
		,Name=	substring ( commandTail,	charindex ( '@' , commandTail ),	charindex ( '=' , commandTail )-	charindex ( '@' , commandTail ) )
		,Value=	dbo.ltrimm ( substring ( commandTail,	charindex ( '=' , commandTail )+	1,	case	patindex ( '%,%@%' , commandTail )
														when	0	then	len ( commandTail )
														else			patindex ( '%,%@%' , commandTail )-	charindex ( '=' , commandTail )-	1
													end ) )
		,commandTail=	case	patindex ( '%,%@%' , commandTail )
					when	0	then	''
					else			right ( commandTail , len ( commandTail )-	patindex ( '%,%@%' , commandTail ) )
				end
		,Sequence=	Sequence+	1
	from
		cte1
	where
		commandTail<>	''
)
select
	cte1.job_id
	,JobName=	sj.name		-- для удобства
	,cte1.step_id
	,StepName=	cte1.Name
	,cte1.Value
	,cte1.Sequence
from
	cte1
	,msdb.dbo.sysjobs	sj
where
	sj.job_id=	cte1.job_id
/*order	by
	job_id
	,step_id*/
go
select
	*
from
	damit.ShowJobStepSQLParams
order	by
	job_id
	,step_id
	,Sequence