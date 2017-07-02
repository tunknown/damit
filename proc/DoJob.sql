/*
sp_help_jobactivity '7D4F2106-B141-43F3-9098-B47A60AAFA83'

select * from msdb.dbo.sysjobactivity
where job_id='7D4F2106-B141-43F3-9098-B47A60AAFA83'
select * from msdb.dbo.sysjobhistory
where job_id='7D4F2106-B141-43F3-9098-B47A60AAFA83'
*/

/*					@op_type,	@job_id,	@schedule_id,	@alert_id,	@action_type,	@nt_user_name,	@error_flag,	@@trancount,	@wmi_namespace,	@wmi_query
Usage:  EXECUTE xp_sqlagent_notify <operation type>,	<job id>,	<schedule id>,	<alert id>,	<action type>[,	<login name>] [,<error flag>]
Usage:  EXECUTE xp_sqlagent_notify 'J',			<job id>,	NULL,		NULL,		<action type>[,	<login name>][,	<error flag>]
Usage:  EXECUTE xp_sqlagent_notify 'S',			<job id>,	<schedule id>,	NULL,		<action type>
Usage:  EXECUTE xp_sqlagent_notify 'D',			[<job id>|NULL],NULL,		NULL,		NULL
Usage:  EXECUTE xp_sqlagent_notify 'A',			NULL,		NULL,		<alert_id>,	<action type>

-- One of: J (Job action [refresh or start/stop]),
--         S (Schedule action [refresh only])
--         A (Alert action [refresh only]),
--         G (Re-cache all registry settings),
--         D (Dump job [or job schedule] cache to errorlog)
--         P (Force an immediate poll of the MSX)
--         L (Cycle log file)
--         T (Test WMI parameters (namespace and query))

  @action_type NCHAR(1)         = NULL, -- For 'J' one of: R (Run - no service check),

EXECUTE master.dbo.xp_sqlagent_notify 'J',	'7D4F2106-B141-43F3-9098-B47A60AAFA83',	NULL,		NULL,		'S',	'domain\user'

select * from sysjobs where name='www'
*/
use	damit
go
if	object_id ( 'damit.DoJob' , 'p' )	is	null
	exec	( 'create	proc	damit.DoJob	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoJob		-- гарантированный запуск Job
	@gJob		uniqueidentifier=	null
	,@sJobName	sysname=		null
	,@bPersistent	bit=			1	-- 1=запустить job даже если он сейчас работает, вызов job может занять до 1 секунды, если SQLAgent уже выполняет её
--with	exec	as	owner				-- учитывая права на xp_sqlagent_notify для бесправного пользователя
as
set	nocount		on
----------
declare	@sMessage	TMessage
	,@iError	TInteger=	0
	,@iRowCount	TInteger
	,@bDebug	TBoolean=	1	-- 1=включить отладочные сообщения

	,@op_type	NCHAR ( 1 )
	,@schedule_id	INT
	,@alert_id	INT
	,@action_type	NCHAR ( 1 )
	,@error_flag	INT
	,@nt_user_name	NVARCHAR ( 100 )
	,@i		int=	0
	,@bPersistentCount	bigint=	0
	,@dtStopExecution	datetime
----------
select	@op_type=	N'J'
	,@schedule_id=	0
	,@alert_id=	0
	,@action_type=	N'R'
	,@error_flag=	0              
	,@nt_user_name=	user_name()
----------
select
	@gJob=	job_id
from
	msdb.dbo.sysjobs
where
		job_id=	@gJob
	or	name=	@sJobName
if	@@RowCount<>	1	or	@gJob	is	null
begin
	select	@sMessage=	'Ошибка передачи параметров',
		@iError=	-3
	goto	error
end
----------
while	@i<	1/*0000*/	and	@iError=	0
begin
	while	1=	1
	begin
		select	top	1
			@dtStopExecution=	stop_execution_date
		from
			msdb.dbo.sysjobactivity
		where
				job_id=			@gJob
			and	start_execution_date	is	not	null		-- job был запущен
			--and	stop_execution_date	is		null
		order	by
			session_id	desc
----------
		if		@@RowCount=	0					-- job ещё не был запущен ни разу
			or	@dtStopExecution	is	not	null	break
----------
		if	@bPersistent=	1
			waitfor delay '0:0:0.003'		-- пытаемся обойти ошибку "этот job уже запущен"
		else
		begin
			--if	@bPersistentCount=	MaxBigint	break
			set	@bPersistentCount=	@bPersistentCount+	1
			break
		end
	end
----------
	if	@bPersistentCount=	1	break
----------
	waitfor delay '0:0:0.003'	-- xp_sqlagent_notify должна успеть добраться до данных из sysjobactivity
----------
	-- к этому моменту все внешние параметры(данные для джобба в таблицах) должны быть доступны из другого соединения, например, через commit
	EXEC	@iError=	master.dbo.xp_sqlagent_notify	-- вызывается не чаще 1 раза в секунду
					@op_type
					,@gJob
					,@schedule_id
					,@alert_id
					,@action_type
					,@nt_user_name
					,@error_flag
					,@@trancount
	if	@@Error<>	0	or	@iError<>	0
	begin
		select	@sMessage=	'Ошибка запуска job',
			@iError=	-3
		goto	error
	end

----------
	set	@i=	@i+	1
----------
	if	@i%	10=	0	select	@i
end
----------
select	@i
----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
--***grant	execute	on	damit.DoJob	to	test