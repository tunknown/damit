use	damit
----------
if	object_id ( 'damit.DoScript' , 'p' )	is	null
	exec	( 'create	proc	damit.DoScript	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoScript		-- ��������� ������������ ������ � ������� � ���� ��������� � � ����������� ������������ �� ���� ���������� ����������
	@iExecutionLog		TId
as
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=�������� ���������� ���������

	,@iData			TId
	,@sLogTable		TSystemName
	,@sFieldsSortQuoted	TSystemName=	''
	,@bCanBlank		TBool
	,@sSaveProc		TSystemName

	,@sCommand		nvarchar ( max )=	''
	,@sExec			varchar ( 8000 )=	''	-- 8000 ��-�� xp_cmdshell
	,@sExec2		varchar ( max )=	''

	,@sAlias0		varchar ( 256 )
	,@sAlias1		varchar ( 256 )
	,@sAlias2		varchar ( 256 )
	,@sAlias3		varchar ( 256 )
	,@sAlias4		varchar ( 256 )
	,@sAlias5		varchar ( 256 )
	,@sAlias6		varchar ( 256 )
	,@sAlias7		varchar ( 256 )
	,@sAlias8		varchar ( 256 )
	,@sAlias9		varchar ( 256 )

	,@oValue		sql_variant
	,@oValue0		sql_variant
	,@oValue1		sql_variant
	,@oValue2		sql_variant
	,@oValue3		sql_variant
	,@oValue4		sql_variant
	,@oValue5		sql_variant
	,@oValue6		sql_variant
	,@oValue7		sql_variant
	,@oValue8		sql_variant
	,@oValue9		sql_variant

	,@iScript		TId

	,@sFileName		nvarchar ( 256 )
	,@sVariable		varchar ( 256 )
	,@sSubsystem		varchar ( 128 )


	,@i			tinyint
	,@iExecution		TId
	,@iExecutionLogData	TId

	,@bIsProcessed		TBool

	,@sParameters		varchar ( max )
	,@xParameters		xml

	,@sDelimeter		varchar ( 32 )=	'973B15234998415D876F29B2A6E068E4'
----------
select
	@iExecution=	dl.Execution
	,@iScript=	f.Id
	,@sSubsystem=	f.Subsystem
	,@sCommand=	f.Command
	,@sFileName=	f.FileName
from
	damit.ExecutionLog	dl
	,damit.Distribution	d
	,damit.Script		f
where
		dl.Id=		@iExecutionLog
	and	d.Id=		dl.Distribution
	and	f.Id=		d.Task
if	@@error<>	0	or	@@rowcount<>	1
begin
	select	@sMessage=	'������ �������� ����������',
		@iError=	-3
	goto	error
end
----------
if	@sCommand	like	'%(*%*)%'
	set	@sCommand=	damit.GetReplacement ( @iExecutionLog,	@sCommand )
----------
if	@sFileName	like	'%(*%*)%'
	set	@sFileName=	damit.GetReplacement ( @iExecutionLog,	@sFileName )
----------
if		isnull ( @sCommand,	'' )=	''
	and	isnull ( @sFileName,	'' )=	''
begin
	select	@sMessage=	'������ ������ ����������� ������� ��� ����� �����',
		@iError=	-3
	goto	error
end
----------
if		@sSubsystem	is	null
	or	@sSubsystem	in	( 'CmdExec',	'ActiveScripting' )
begin
	if		@sFileName	is	not	null
		and	@sCommand	is	not	null
	begin
		exec	@iError=	damit.DoSaveToFile
						@sData=		@sCommand
						,@sFileName=	@sFileName
						,@sCharset=	'ibm866'--'windows-1251'
		if	@@Error<>	0	or	@iError<	0
		begin
			select	@sMessage=	'������ �������� ���������� ����� ��� ��������',
				@iError=	-3
			goto	error
		end
----------
		set	@sExec=	case	@sSubsystem
					when	'CmdExec'		then	@sFileName
					when	'ActiveScripting'	then	'cscript /nologo '+	@sFileName		-- cscript ��� ��������� wscript.stdout.write
				end
	end
	else
		set	@sExec=	@sCommand
----------
	if	@sSubsystem	is	not	null
	begin
		create	table	#cmdshell
		(	txt	nvarchar ( 4000 )	null )
----------
		insert	#cmdshell	( txt )
		exec	xp_cmdshell	@sExec
		if	@@Error<>	0
		begin
			select	@sMessage=	'������ ��������',
				@iError=	-3
			goto	error
		end
----------
	/*	set	@sParameters=	replace ( replace ( (	select
									[data()]=	txt+	@sDelimeter
								from
									#cmdshell
								for
									xml	path ( '' ) ),	@sDelimeter+	' ',	',' ),	@sDelimeter,	',' )
	*/
		set	@sParameters=	''
----------
		select
			@sParameters=	@sParameters+	txt	-- xml ������� ��������� ������, �.�. ���� � ����������� ���� xml �����������- ��� ����������
		from
			#cmdshell
		where
			txt	is	not	null
----------
		if	@sParameters	like	'%<%=%"%/%>%'					-- ***������� � ����������� ���������� ���������� �� ��������� �������?
		begin
			set	@xParameters=	@sParameters
----------
			insert
				damit.Variable	( ExecutionLog,	Alias,	Value,	Sequence )
			select
				@iExecutionLog
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
			if	isnull ( @sParameters,	'' )<>	''
				insert
					damit.Variable	( ExecutionLog,	Alias,	Value,	Sequence )
				select
					@iExecutionLog
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
		if		@sFileName	is	not	null
			and	@sSubsystem	is	not	null	-- ���������� �� ��������� ������ �������� ����� ��� ����������, ������� ��������� ����
		begin
			set	@sExec=	'del /f /q '+	@sFileName
----------
			if	@bDebug=	1
				exec	xp_cmdshell	@sExec
			else
				exec	xp_cmdshell	@sExec,	no_output
			if	@@Error<>	0
			begin
				select	@sMessage=	'������ ��������',
					@iError=	-3
				goto	error
			end
		end
	end
end
----------
if	@sSubsystem=	'TSQL'
begin
	select	@sExec2=	null
		,@i=		0
----------
	select
		@sExec2=	isnull ( @sExec2+	',	',	'' )+	isnull ( Name,	'@'+	convert ( char ( 1 ),	@i ) )+	'	sql_variant	output'
		,@sAlias0=	case	@i	when	0	then	Name	else	@sAlias0	end
		,@sAlias1=	case	@i	when	1	then	Name	else	@sAlias1	end
		,@sAlias2=	case	@i	when	2	then	Name	else	@sAlias2	end
		,@sAlias3=	case	@i	when	3	then	Name	else	@sAlias3	end
		,@sAlias4=	case	@i	when	4	then	Name	else	@sAlias4	end
		,@sAlias5=	case	@i	when	5	then	Name	else	@sAlias5	end
		,@sAlias6=	case	@i	when	6	then	Name	else	@sAlias6	end
		,@sAlias7=	case	@i	when	7	then	Name	else	@sAlias7	end
		,@sAlias8=	case	@i	when	8	then	Name	else	@sAlias8	end
		,@sAlias9=	case	@i	when	9	then	Name	else	@sAlias9	end
		,@i=		@i+	1
	from
		damit.GetVariablesList ( @iExecutionLog )
	order	by						-- ������������������� ����������� � �������� � order by ����� ���������
		Name
----------
	select
		@oValue0=	Value0
		,@oValue1=	Value1
		,@oValue2=	Value2
		,@oValue3=	Value3
		,@oValue4=	Value4
		,@oValue5=	Value5
		,@oValue6=	Value6
		,@oValue7=	Value7
		,@oValue8=	Value8
		,@oValue9=	Value9
	from
		damit.GetVariables ( @iExecutionLog,	@sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
----------
	exec	@iError=	sp_executesql
					/*@statement=	*/@sCommand
					,/*@params=	*/@sExec2
					,/*@oValue0=	*/@oValue0	output		-- ��� �������� ���������� ���� ������������� ���������; ��������� �� �������, ����� �� ������ exec()
					,/*@oValue1=	*/@oValue1	output
					,/*@oValue2=	*/@oValue2	output
					,/*@oValue3=	*/@oValue3	output
					,/*@oValue4=	*/@oValue4	output
					,/*@oValue5=	*/@oValue5	output
					,/*@oValue6=	*/@oValue6	output
					,/*@oValue7=	*/@oValue7	output
					,/*@oValue8=	*/@oValue8	output
					,/*@oValue9=	*/@oValue9	output
	if	@@Error<>	0	or	@iError<>	0
	begin
		select	@sMessage=	'������',
			@iError=	-3
		goto	error
	end
----------
	declare	c	cursor	local	fast_forward	for
				select	Name=	@sAlias0,	Value=	@oValue0
		union	all	select	Name=	@sAlias1,	Value=	@oValue1
		union	all	select	Name=	@sAlias2,	Value=	@oValue2
		union	all	select	Name=	@sAlias3,	Value=	@oValue3
		union	all	select	Name=	@sAlias4,	Value=	@oValue4
		union	all	select	Name=	@sAlias5,	Value=	@oValue5
		union	all	select	Name=	@sAlias6,	Value=	@oValue6
		union	all	select	Name=	@sAlias7,	Value=	@oValue7
		union	all	select	Name=	@sAlias8,	Value=	@oValue8
		union	all	select	Name=	@sAlias9,	Value=	@oValue9
				order	by	Name	desc
----------
	open	c
----------
	while	1=	1
	begin
		fetch	next	from	c	into	@sExec,	@oValue
		if	@@fetch_status<>	0	or	@sExec	is	null	break
----------
		exec	@iError=	damit.SetupVariable
						@iExecutionLog=	@iExecutionLog
						,@sAlias=	@sExec
						,@oValue=	@oValue
		if	@@Error<>	0	or	@iError<	0
		begin
			select	@sMessage=	'������',
				@iError=	-3
			goto	error
		end
	end
	deallocate	c
end
----------

--***������������ ��������� ����� ��������� ����� ���������� damit.SetupVariable, ��� ��������� ���������(field="output"), ��������, �� xp_cmdshell?
-- ����� �������������� �������� ����������?

----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go
use	tempdb