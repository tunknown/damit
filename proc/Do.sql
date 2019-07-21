use	damit
----------
if	object_id ( 'damit.Do' , 'p' )	is	null
	exec	( 'create	proc	damit.Do	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.Do	-- �������� ������ � �������
	@iDistribution		TIdSmall				-- ��������� ��� ���������� Task ��������, �� ����������� � Node=null. ���������� ������ ��� ��������� ������ ���������� ��� ���������� ������
	,@iExecutionLog		TId=			null	out	-- null=������������ ��������� damit.ExecutionLog.Id; not null=��� ���� ���������� �����
	,@sParameters		nvarchar ( max )=	null		-- ��������� ��������
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
	,@iExecution		TId
	,@iSequence		int

	,@iTask			TIdSmall
	,@iTaskNext		TIdSmall

	,@iDistributionNext	TIdSmall

	,@xParameters		xml
----------
set	@iError=	0
----------
select
	@iTask=	Task
from
	damit.Distribution
where
	Id=	@iDistribution
if	@@Error<>	0	or	@@RowCount<>	1
begin
	select	@sMessage=	'������',
		@iError=	-3
	goto	error
end
----------
if	@iExecutionLog	is	null
	set	@iSequence=	1
else
begin
	select
		@iExecution=	Execution
		,@iSequence=	max ( Sequence )+	1
	from
		damit.ExecutionLog					-- ***������� �� ����� �������� ���������� �� insert damit.ExecutionLog ( Sequence )
	where
		Id=		@iExecutionLog
	group	by
		Execution
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	set	@iExecutionLog=	null	-- ������ ��� �������� �� �����
end
----------
select	@bFirstStep=	1
	,@bComplete=	0
----------
while	@bComplete=	0
begin
	insert	damit.ExecutionLog	( Execution,	Distribution,	Sequence )
	values				( @iExecution,	@iDistribution,	@iSequence )	-- ��������� �������� ����������, ����� ������ ���� ��� ��� ������ � @iDistribution
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	set	@iExecutionLog=	scope_identity()
----------
	if	@iExecution	is	null
	begin
		update
			damit.ExecutionLog
		set
			Execution=	@iExecutionLog
			,@iExecution=	@iExecutionLog
		where
			Id=		@iExecutionLog
	end
----------
	if	@bFirstStep=	1	-- ������ �� ������ ���
	begin
		if	@sParameters	like	'%<%=%"%/%>%'
		begin
			set	@xParameters=	@sParameters
----------
			insert
				damit.Variable	( ExecutionLog,	Alias,	Value,	Sequence )
			select
				@iExecution
				,Alias=		x.n.value ( 'local-name(.)',	'varchar ( 256 )' )	--,Element=	x.n.value ( 'local-name(..)',	'varchar ( 256 )' )
				,Value=		x.n.value ( '.',		'varchar ( 8000 )' )
				,Sequence=	case	x.n.value ( 'count(../../*)',	'integer' )
							when	1	then	null			-- ��� damit.GetVariables, ��� null ������������� ���������� ���������, � �� ������ ���������� �������
							else			x.n.value ( 'for $s in . return count(../../*[.<<$s])+1',	'integer' )	-- ������ +1? ��������� +1 ��������� ������ ��� ��������������� ������ �����������
						end
			from
				@xParameters.nodes ( '//*/@*' )	x ( n )
		end
		else
			if	@sParameters	is	not	null
				insert
					damit.Variable	( ExecutionLog,	Alias,	Value,	Sequence )
				select
					@iExecution
					,Alias=		'FilterList'			-- ***������ �������
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
	select	@sProcedureForTask=	null	-- ����� �������� ����������, ���� ��������� ������ ����� 0 �������
		,@bGoto=		null
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
		damit.Task
	where
		Id=	@iTask
	if	@@Error<>	0	or	1<	@@RowCount
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	if	@sProcedureForTask	is	not	null
	begin
		exec	@iSelector=	@sProcedureForTask
						@iExecutionLog=	@iExecutionLog
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
		Id=		@iExecutionLog
	if	@@Error<>	0	or	@@RowCount<>	1
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	select	@iTaskNext=		null
		,@iDistributionNext=	null
		,@iSequence=		@iSequence+	1
----------
	if	@bGoto=		1
		select
			@iDistributionNext=	Id
			,@iTaskNext=		Task
		from
			damit.Distribution
		where
				Id=		@iTask	/*Id*/
			--and	Sequence=	@iSelector			-- ������������� ������� ������ �� ���� Condition?
	else
		select
			@iDistributionNext=	Id
			,@iTaskNext=		Task
		from
			damit.Distribution
		where
				Node=		@iDistribution
			and	Sequence=	isnull ( @iSelector,	Sequence )	-- ������? ������������� ������� ������ �� ���� Condition?
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
	select	@iDistribution=	@iDistributionNext
		,@iTask=	@iTaskNext
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
	Id=		@iExecutionLog
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