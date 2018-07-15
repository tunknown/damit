use	damit
go
if	object_id ( 'damit.PushJobError' , 'p' )	is	null
	exec	( 'create	proc	damit.PushJobError	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.PushJobError
	@gJobId		uniqueidentifier=	null
as
set	nocount		on
----------
declare	@sMessage	TMessage
	,@iError	TInteger
	,@iRowCount	TInteger
	,@bDebug	TBoolean

	,@iInstance	integer
----------
set	@iError=	0
----------
if	@gJobId	is	null
	select	@gJobId=	JobId	from	damit.damit.GetJobId()
----------
if	not	exists	( select
				1
			from
				msdb..sysjobs
			where
				job_id=	@gJobId )
begin
	select	@sMessage=	'������ �������� ��������� '+	isnull(app_name(),'***'),
		@iError=	-3
	goto	error
end
----------
select
	@iInstance=	max ( instance_id )
from
	msdb..sysjobhistory
where
		job_id=		@gJobId
	and	step_id=	1	-- �.�. step=0 ���������� � ��������� �������
if	@@RowCount<>	1	or	@iInstance	is	null
begin
	select	@sMessage=	'������ ��������� ������� �����'
		,@iError=	-3
	goto	error
end
----------
select
	@iRowCount=	count ( * )
from
	msdb..sysjobhistory
where
		job_id=		@gJobId
	and	@iInstance<=	instance_id
	and	run_status=	0		-- ������, ���� ����� ���������� ��������
if	0<	@iRowCount
begin
	select	@sMessage=	'���� ���������� � ������� � '+	convert ( varchar ( 10 ) , @iRowCount )+	' �����'
		,@iError=	-3
	goto	error
end
----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go
use	tempdb