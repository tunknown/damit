use	damit
----------
if	object_id ( 'damit.SetupJobAndStep' , 'p' )	is	null
	exec	( 'create	proc	damit.SetupJobAndStep	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.SetupJobAndStep
	@gJob			uniqueidentifier=	null	output	--\задан один из них или оба
	,@sJobName		sysname=		null		--/
	,@sStepName		sysname=		null
	,@gDistribution		uniqueidentifier=	null		--\
	,@sParameters		varchar ( max )=	null		--\заданы либо эти два, либо тот один. как узнать, есть ли шаг с таким содержанием?
	,@sScript		varchar ( max )=	null		--/
	,@sNotifyEMail		sysname=		'Errors'
	,@sDescription		nvarchar ( 512 )=	null

	,@sScheduleName		sysname=		null
	,@iFreqType		integer=		null
	,@iFreqInterval		integer=		null
	,@iFreqSubdayType	integer=		null
	,@iFreqSubdayInterval	integer=		null
	,@iFreqRelativeInterval	integer=		null
	,@iFreqRecurrenceFactor	integer=		null
	,@dtStart		datetime=		null
	,@dtFinish		datetime=		null
-- джоб создаётся запрещённым, его нужно проверить и включить
as
set	nocount	on
----------
DECLARE	@iError		int=	0
	,@sMessage	varchar ( 256 )
	,@iRowCount	integer
	,@bAlien	bit
	,@sTransaction	sysname
	,@bDebug	bit=	1	-- 1=включить отладочные сообщения

	,@iSequence	integer
	,@iSuccess	integer
	,@iFail		integer
	,@bIsJobCreate	bit

	,@iStartDate	integer
	,@iFinishDate	integer
	,@iStartTime	integer
	,@iFinishTime	integer
----------
select	@iSuccess=	1
	,@iFail=	2
----------
set	@sTransaction=	object_name ( @@procid )+	replace ( replace ( replace ( replace ( convert ( varchar ( 23 ) , getdate() , 121 ) , '-' , '' ) , ' ' , '' ) , ':' , '' ) , '.' , '' )
----------
set	@bAlien=	sign ( @@TranCount )
if	@bAlien=	0	begin	tran	@sTransaction	else	save	tran	@sTransaction
----------
select	@gJob=	job_id	FROM	msdb..sysjobs	where	name=	@sJobName	or	job_id=	@gJob
if		1<	@@rowcount
	or	@gDistribution	is	not	null	and	@sScript	is	not	null
	or	@gDistribution	is		null	and	@sScript	is		null
begin
	select	@sMessage=	'Заданы неверные параметры',
		@iError=	-3
	goto	error
end
----------
if	@gJob	is	null
begin
	set	@bIsJobCreate=	1
----------
	EXEC	@iError=	msdb.dbo.sp_add_job
					@job_name=			@sJobName
					,@enabled=			0
					,@notify_level_eventlog=	0
					,@notify_level_email=		2
					,@notify_level_netsend=		0
					,@notify_level_page=		0
					,@notify_email_operator_name=	@sNotifyEMail
					,@delete_level=			0
					,@description=			@sDescription
					,@category_id=			0
					,@owner_login_name=		'sa'
					,@job_id=			@gJob	out
	IF	@@Error<>	0	OR	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 1',
			@iError=	-3
		goto	error
	end
----------
	EXEC	@iError=	msdb.dbo.sp_add_jobserver
					@job_id=	@gJob,
					@server_name=	'(local)'
	IF	@@Error<>	0	OR	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 2',
			@iError=	-3
		goto	error
	end
----------
	select	@iStartDate=	convert ( integer,	convert ( varchar ( 8 ),	@dtStart,	112 ) )
		,@iFinishDate=	convert ( integer,	convert ( varchar ( 8 ),	@dtFinish,	112 ) )
		,@iStartTime=	convert ( integer,	replace ( convert ( varchar ( 8 ),	@dtStart,	108 ),	':',	'' ) )
		,@iFinishTime=	convert ( integer,	replace ( convert ( varchar ( 8 ),	@dtFinish,	108 ),	':',	'' ) )
----------
	EXEC	@iError=	msdb.dbo.sp_add_jobschedule
					@job_id=			@gJob
					,@name=				@sScheduleName
					,@enabled=			1
					,@freq_type=			@iFreqType
					,@freq_interval=		@iFreqInterval
					,@freq_subday_type=		@iFreqSubdayType
					,@freq_subday_interval=		@iFreqSubdayInterval
					,@freq_relative_interval=	@iFreqRelativeInterval
					,@freq_recurrence_factor=	@iFreqRecurrenceFactor
					,@active_start_date=		@iStartDate
					,@active_end_date=		@iFinishDate
					,@active_start_time=		@iStartTime
					,@active_end_time=		@iFinishTime
					--,@schedule_uid=		'D5C04A05-B3FC-4671-8F1A-0C1F30160852'	output
	IF	@@ERROR<>	0	OR	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 3',
			@iError=	-3
		goto	error
	end
----------
	set	@iSequence=	1
end
else
begin
	select	@iSequence=	isnull ( max ( step_id ),	0 )+	1	from	msdb..sysjobsteps	where	job_id=	@gJob		-- учитываем возможность отсутствия шагов в существующем джобе
----------
	update
		msdb.dbo.sysjobsteps
	set
		on_success_action=	3
		,on_fail_action=	3
	where
			job_id=	@gJob		-- для надёжности все шаги(вместо только последнего) переделываем на переход на следующий шаг
		and	( on_success_action<>	3	or	on_fail_action<>	3 )
	IF	@@Error<>	0
	begin
		select	@sMessage=	'Ошибка 3.1',
			@iError=	-3
		goto	error
	end
end
----------
if	@gDistribution	is	not	null
	set	@sScript=	'exec	damit.damit.DoTransfer
			@gDistributionId=	''{'+	convert ( char ( 36 ) , @gDistribution )+	'}'''
			+	case
					when	@sParameters	is	null	then	''
					else						'
			,@sParameters=		'''+	@sParameters+	''''
				end
----------
EXEC	@iError=	msdb.dbo.sp_add_jobstep
				@job_id=		@gJob
				,@step_name=		@sStepName
				,@step_id=		@iSequence
				,@cmdexec_success_code=	0
				,@on_success_action=	@iSuccess
				,@on_success_step_id=	0
				,@on_fail_action=	@iFail
				,@on_fail_step_id=	0
				,@retry_attempts=	0		-- число повторов
				,@retry_interval=	0
				,@os_run_priority=	0
				,@subsystem=		'TSQL'
				,@command=		@sScript
				,@database_name=	'tempdb'
				,@flags=		0
IF	@@Error<>	0	OR	@iError<>	0
begin
	select	@sMessage=	'Ошибка 4',
		@iError=	-3
	goto	error
end
----------
if	@bIsJobCreate=	1
begin
	EXEC	@iError=	msdb.dbo.sp_update_job
					@job_id=	@gJob,
					@start_step_id=	@iSequence
	IF	@@Error<>	0	OR	@iError<>	0
	begin
		select	@sMessage=	'Ошибка 5',
			@iError=	-3
		goto	error
	end
end
----------
if	@@TranCount>	0	and	@bAlien=	0	commit	tran	/*@sTransaction*/
----------
goto	done
----------
error:
if	@@TranCount>	0	and	@bAlien=	0	rollback	tran	/*@sTransaction*/
raiserror ( @sMessage , 18 , 1 )

done:

go
use	tempdb