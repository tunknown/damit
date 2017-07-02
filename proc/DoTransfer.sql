use	damit
----------
if	object_id ( 'damit.DoTransfer' , 'p' )	is	null
	exec	( 'create	proc	damit.DoTransfer	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoTransfer	-- �������� ������ � �������
	@gExecutionLog		TGUID=		null	out	-- null=������������ ��������� damit.ExecutionLog.Id; not null=��� ���� ���������� �����
	,@gDistribution		TGUID			-- ��������� ��� ���������� Task ��������, �� ����������� � Node=null
	,@sParameters		varchar ( max )=null	-- ��������� ��������
as
-- ��� ��������� ������ �������� �� ����������, �.�. bcp �� ����� ����� ������� � ���������������� ������ �� commit tran	
declare	@sMessage		TMessage
	,@iError		TInteger
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	0	-- 1=�������� ���������� ���������
	,@sTransaction		TSysName
	,@bAlien		TBoolean

	,@iSelector		TInteger

	,@bFirstStep		bit
	,@bComplete		bit
	,@bGoto			bit
	,@sProcedureForTask	TSysName
	,@gExecution		TGUID
	,@gExecutionLog2	TGUID
	,@iSequence		int

	,@gTask			TGUID
	,@gTaskNext		TGUID

	,@gDistributionNext	TGUID

	,@xParameters		xml
----------
set	@iError=	0
----------
select
	@gTask=	Task
from
	damit.Distribution
where
	Id=	@gDistribution
if	@@Error<>	0	or	@@RowCount<>	1
begin
	select	@sMessage=	'������',
		@iError=	-3
	goto	error
end
----------
if	@gExecutionLog	is	null
	set	@iSequence=	1
else
begin
	select
		@gExecution=	Execution
		,@iSequence=	max ( Sequence )+	1
	from
		damit.ExecutionLog					-- ***������� �� ����� �������� ���������� �� insert damit.ExecutionLog ( Sequence )
	where
		Id=		@gExecutionLog
	group	by
		Execution
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	set	@gExecutionLog=	null	-- ������ ��� �������� �� �����
end
----------
select	@bFirstStep=	1
	,@bComplete=	0
----------
while	@bComplete=	0
begin
	select	@gExecutionLog2=	newid()
		,@gExecutionLog=	isnull ( @gExecutionLog,	@gExecutionLog2 )
		,@gExecution=		isnull ( @gExecution,		@gExecutionLog2 )
----------
	insert
		damit.ExecutionLog	( Id,	Distribution,	Start,	Finish,	ErrorCode,	Message,	Execution,	Sequence )
	select
		@gExecutionLog2							-- ��������� �������� ����������, ����� ������ ��� ������ � @gDistribution
		,@gDistribution
		,getdate()
		,null
		,null
		,null
		,@gExecution
		,@iSequence
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	if	@bFirstStep=	1	-- ������ �� ������ ���
	begin
		if	@sParameters	like	'%<%=%"%/%>%'
		begin
			set	@xParameters=	@sParameters
----------
			insert
				damit.Variable	( Id,	ExecutionLog,	Alias,	Value,	Sequence )
			select
				newid()
				,@gExecution
				,Alias=		x.n.value ( 'local-name(.)',	'varchar ( 256 )' )	--,Element=	x.n.value ( 'local-name(..)',	'varchar ( 256 )' )
				,Value=		x.n.value ( '.',		'varchar ( 8000 )' )
				,Sequence=	x.n.value ( 'for $s in . return count(../../*[.<<$s])+1',	'integer' )		-- ��������� +1 ��������� ������ ��� ��������������� ������ �����������
			from
				@xParameters.nodes ( '//*/@*' )	x ( n )
		end
		else
			insert
				damit.Variable	( Id,	ExecutionLog,	Alias,	Value,	Sequence )
			select
				newid()
				,@gExecution
				,Alias=		'FilterList'
				,convert ( varchar ( 8000 ) , Value )
				,Sequence
			from
				damit.ToListFromStringAuto ( @sParameters )
		if	@@Error<>	0
		begin
			select	@sMessage=	'������',
				@iError=	-3
			goto	error
		end
----------
		set	@bFirstStep=	0
	end
----------
	select
		@sProcedureForTask=	case
						when	Data		is	not	null	then	'damit.DoGet'		-- ��� ��������� ������ ����� ������ ������ ����������
						when	Query		is	not	null	then	'damit.DoQuery'
						when	Script		is	not	null	then	'damit.DoScript'
						when	Format		is	not	null	then	'damit.DoSave'
						when	Protocol	is	not	null	then	'damit.DoTransmit'
						when	Condition	is	not	null	then	'damit.DoEval'
						when	Distribution	is	not	null	then	null
						-- ������������ damit.Distribution.Task=Distribution � �������� ���������/�������������� ���������� ��� �������������� ���������
					end
		,@bGoto=		case
						when	Distribution	is	not	null	then	1
						else							0
					end
	from
		damit.TaskEntity
	where
		Id=	@gTask
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	if	@sProcedureForTask	is	not	null
	begin
		exec	@iSelector=	@sProcedureForTask
						@gExecutionLog=	@gExecutionLog2
		if	@@Error<>	0	or	@iSelector<	0	-- *** � ���� ����� ���������� �������� � �� �������� ����������(�� ����������) ������???
		begin
			select	@sMessage=	'������',
				@iError=	-3
			goto	error
		end
	end
	else
		set	@iSelector=	null
----------
	update
		damit.ExecutionLog
	set
		Finish=		getdate()
		--,ErrorCode=	@iSelector ��� @iError				-- ***��� ����� ������������ ���� ���?
	where
		Id=		@gExecutionLog2
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	select	@gTaskNext=		null
		,@gDistributionNext=	null
		,@iSequence=		@iSequence+	1
----------
	if	@bGoto=		0
		select
			@gDistributionNext=	Id
			,@gTaskNext=		Task
		from
			damit.Distribution
		where
				Node=		@gDistribution
			and	Sequence=	@iSelector			-- ������? ������������� ������� ������ �� ���� Condition?
	else
		select
			@gDistributionNext=	Id
			,@gTaskNext=		Task
		from
			damit.Distribution
		where
				Id=		@gTask	/*Id*/
			--and	Sequence=	@iSelector			-- ������������� ������� ������ �� ���� Condition?
	select	@iRowCount=	@@RowCount
		,@bComplete=	case	@iRowCount
					when	0	then	1
					else			0
				end
	if	1<	@iRowCount
	begin
		select	@sMessage=	'������������� ��������� ����������',
			@iError=	-3
		goto	error
	end
----------
-- ������ ����� ������ �� ����������� ��������
	if	exists	( select
				1
			from
				damit.GetVariables ( @gExecution,	'KostylDlyaOstanovki',	default,	default,	default,	default,	default,	default,	default,	default,	default )
			where
				convert ( int , Value0 )=	1 )
	begin
		set	@gTask=	null
----------
		update
			damit.ExecutionLog
		set
			Message=	'KostylDlyaOstanovki=1'
		where
			Id=		@gExecutionLog2
		if	@@Error<>	0	or	@@RowCount<>	1
		begin
			select	@sMessage=	'������',
				@iError=	-3
			goto	error
		end
	end
-- ^^^������ ����� ������ �� ����������� ��������



	select	@gDistribution=	@gDistributionNext
		,@gTask=	@gTaskNext
end
----------
goto	done

error:
if	@@TranCount>	0	and	@bAlien=	0	rollback	tran	@sTransaction
raiserror ( @sMessage , 18 , 1 )

done:

----------
update
	damit.ExecutionLog
set
	Finish=		getdate()
	,ErrorCode=	@iError		-- ���� ErrorCode=null �������� ��������� ������������� � � ��������� ������ ��������� � ��������� ��������
	,Message=	@sMessage
where
	Id=		@gExecutionLog2
--if	@@Error<>	0	or	@@RowCount<>	1
--begin
--	select	@sMessage=	'������ ��������� ������� ��������',
--		@iError=	-3
--	goto	error
--end
----------
--drop	table	#Error
----------
return	@iError
go
use	tempdb