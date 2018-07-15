use	damit
----------
if	object_id ( 'damit.DoTest' , 'p' )	is	null
	exec	( 'create	proc	damit.DoTest	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoTest
	@sDistributionList	varchar ( max )=	null	-- список выгрузок через разделитель; null=тестровать все выгрузки
as
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=включить отладочные сообщения

	,@sExec			TScript

	,@iStep			TInteger
	,@gJob			TGUID
	,@iDistribution		TId
	,@iDistributionLog	TId

	,@dtFilterStart		TDateTime
	,@dtFilterFinish	TDateTime
	,@sFilterStart		varchar ( max )
	,@sFilterFinish		varchar ( max )
	,@sFilterList		varchar ( max )
----------
create	table	#jobs
(	Id		int	identity ( 1 , 1 )
	,job_id		uniqueidentifier
	,step_id	int
	,DistributionId	bigint	)
----------
set	@sExec=	'insert
	#jobs	( job_id,	step_id,	DistributionId )
select
	job_id
	,step_id
	,DistributionId
from
	openquery ( '+	quotename ( @@ServerName )+	',	''exec	damit.damit.ListDistributionJob	@sDistributionList=	'+	isnull ( ''''+	@sDistributionList+	'''',	'null' )+	''' )
order	by
	SMTPId
	,SFTPId
	,FTPSId
	,job_id
	,step_id'
----------
if	@bDebug=	1	print	( @sExec )
----------
exec	( @sExec )
if	@@Error<>	0
begin
	select	@sMessage=	'Ошибка',
		@iError=	-3
	goto	error
end
----------
declare	c	cursor	fast_forward	local	for
	select
		job_id
		,step_id
		,DistributionId
	from
		#jobs
	order	by
		Id
----------
open	c
----------
while	1=	1
begin
	fetch	next	from	c	into	@gJob,	@iStep,	@iDistribution
	if	@@fetch_status<>	0	break
----------
	select	@iDistributionLog=	null
		,@sFilterList=		null
		,@dtFilterStart=	null
		,@dtFilterFinish=	null
----------
	select
		@sFilterList=	charindex ( ';' , Value , patindex ( '%::sFilterList%' , Value ) )
	from
		damit.damit.ShowJobStepSSISParams
	where
			job_id=		@gJob
		and	step_id=	@iStep
		and	Value	like	'%::sFilterList%'
----------
	select
		@sFilterStart=	charindex ( ';' , Value , patindex ( '%::dtFilterStart%' , Value ) )
	from
		damit.damit.ShowJobStepSSISParams
	where
			job_id=		@gJob
		and	step_id=	@iStep
		and	Value	like	'%::dtFilterStart%'
----------
	select
		@sFilterFinish=	charindex ( ';' , Value , patindex ( '%::dtFilterFinish%' , Value ) )
	from
		damit.damit.ShowJobStepSSISParams
	where
			job_id=		@gJob
		and	step_id=	@iStep
		and	Value	like	'%::dtFilterFinish%'
----------
	select	@sFilterList=		case	left ( @sFilterList , 1 )
						when	'"'	then	substring ( @sFilterList , 1 , len ( @sFilterList )-	2 )
						else			@sFilterList
					end
		,@dtFilterStart=	case	left ( @sFilterStart , 1 )
						when	'"'	then	substring ( @sFilterStart , 1 , len ( @sFilterStart )-	2 )
						else			@sFilterStart
					end
		,@dtFilterFinish=	case	left ( @sFilterFinish , 1 )
						when	'"'	then	substring ( @sFilterFinish , 1 , len ( @sFilterFinish )-2 )
						else			@sFilterFinish
					end
----------
if	@bDebug=	1
	select	dtFilterStart=	@dtFilterStart
		,dtFilterFinish=@dtFilterFinish
		,sFilterList=	@sFilterList
----------
	exec	@iError=	damit.Do
					@iDistributionLogId=	@iDistributionLog	out
					,@iDistributionId=	@iDistribution
					,@dtFilterStart=	@dtFilterStart
					,@dtFilterFinish=	@dtFilterFinish
					,@sFilterList=		@sFilterList
	if	@@Error<>	0	or	@iError<	0
	begin
		select	@sMessage=	'Ошибка выгрузки Distribution='''+	convert ( char ( 36 ) , @iDistribution )+	''''+	isnull ( ' ,DistributionLog='''+	convert ( char ( 36 ) , @iDistributionLog )+	'''' , '' ),
			@iError=	-3
		goto	error
	end
end
----------
deallocate	c
----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go
use	tempdb