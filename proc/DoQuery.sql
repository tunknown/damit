use	damit
----------
if	object_id ( 'damit.DoQuery' , 'p' )	is	null
	exec	( 'create	proc	damit.DoQuery	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoQuery
	@gExecutionLog		TGUID
as
declare	@sMessage		TMessage
	,@iError		TInteger=	0
	,@iRowCount		TInteger
	,@bDebug		TBoolean=	1	-- 1=�������� ���������� ���������

	,@sExec			TScript
	,@sExec1		varchar ( max )=	''
	,@sExec2		varchar ( max )=	''

	,@oValue		sql_variant

	,@gExecution		TGUID
	,@gExecutionLogData	TGUID

	,@sQuery		TSystemName

	,@sExecAtServer		TSystemName
	,@sExecShort		TScript
	,@sTargetDatabaseQuoted	TSysName
	,@sTargetServerQuoted	TSysName
	,@sTargetProc		TSystemName
	,@sTargetProc1		TSystemName

	,@iTargetObject		TInteger
	,@sTargetType		varchar ( 2 )
	,@sDeclareParams	TScript
	,@sProcParams		TScript
	,@sSaveParams		TScript
	,@bIsOutParam		bit
	,@bIsDate		bit
	,@oParamValue		sql_variant
	,@sParamValue		varchar ( max )
	,@sDataType		varchar ( 256 )
	,@iSequence		tinyint
----------
select
	@gExecution=	dl.Execution
	,@sTargetProc=	f.Alias
from
	damit.ExecutionLog	dl
	,damit.Distribution	d
	,damit.Query		f
where
		dl.Id=	@gExecutionLog
	and	d.Id=	dl.Distribution
	and	f.Id=	d.Task
if	@@error<>	0	or	@@rowcount<>	1
begin
	select	@sMessage=	'������ �������� ����������',
		@iError=	-3
	goto	error
end
----------
select
	@sTargetServerQuoted=	quotename ( Server )
	,@sTargetDatabaseQuoted=quotename ( Db )
	,@sTargetProc=		LocalName
	,@sTargetProc1=		SmartName
from
	damit.GetParseObjectName ( @sTargetProc )
----------
exec	@iError=	damit.DoGetObjectId
				@sObject=	@sTargetProc1
				,@iObject=	@iTargetObject	out
				,@sType=	@sTargetType	out
if	@@Error<>	0	or	@iError<	0	or	@iTargetObject	is	null
begin
	select	@sMessage=	'������� ������ �� ������ ��� ������� ��������� ��������� ������ � ������� ������',
		@iError=	-3
	goto	error
end
----------
select
	name
	,colid
	,isoutparam
	,IsDate=	convert ( bit,			null )
	,DataType=	convert ( varchar ( 256 ),	null )
into
	#syscolumns_Params
from
	syscolumns
where
	0=	1
----------
select
	@sExecAtServer=	SmartName
	,@sExecShort=	'
select
	sc.name
	,sc.colid
	,sc.isoutparam
	,IsDate=	case
				when	st.xtype	in	( 40 , 41 , 42 , 43 , 58 , 61 )	then	1
				else									0
			end
	,DataType=	convert ( varchar ( 256 ),	case
								when		st.name	like	''%char''
									or	st.name	like	''%binary''		then	st.name+	'' ( ''+	case	sc.prec
																				when	-1	then	''max''
																				else			convert ( varchar ( 256 ),	sc.prec )
																			end+	'' )''
								when	st.name	in	( ''numeric'',	''decimal'' )	then	st.name+	'' ( ''+	convert ( varchar ( 256 ),	sc.prec )+	'',	''+	convert ( varchar ( 256 ),	sc.scale )+	'' )''
								else								st.name
							end )
from
	'+	@sTargetDatabaseQuoted+	'.dbo.syscolumns	sc
	inner	join	'+	@sTargetDatabaseQuoted+	'.dbo.systypes	st	on
		st.xusertype=	sc.xtype						-- ���� ��������� ���, � �� ����������������; ����� �� ������������ ������������ ����� ����� ������
where
		sc.id=	@iTargetObject'
from
	damit.GetParseObjectName ( @sTargetServerQuoted+	'...sp_executesql' )
----------
insert	#syscolumns_Params
exec	@sExecAtServer
		@statement=	@sExecShort
		,@params=	N'@iTargetObject	int'
		,@iTargetObject=@iTargetObject
if	@@Error<>	0	--or	@@RowCount=	0
begin
	select	@sMessage=	'�� ������� �������� ��������� ������� ���������',
		@iError=	-3
	goto	error
end
----------
if	0<	( select	count ( 1 )	from	#syscolumns_Params )
begin
	select	@sProcParams=		''
		,@sDeclareParams=	''
		,@sSaveParams=		''
		,@sExec=		''
----------
	declare	c	cursor	fast_forward	for
		select
			name
			,isoutparam
			,IsDate
			,DataType
			,Sequence=	row_number()	over	( order	by	colid )
		from
			#syscolumns_Params
		order	by
			colid
----------
	open	c
----------
	while	1=	1
	begin
		fetch	next	from	c	into	@sExec1,	@bIsOutParam,	@bIsDate,	@sDataType,	@iSequence
		if	@@fetch_status<>	0	break
----------
		set	@oParamValue=	null
----------
		select
			@oParamValue=	Value0
		from
			damit.GetVariables ( @gExecutionLog,	@sExec1,	default,	default,	default,	default,	default,	default,	default,	default,	default )
		if	1<	@@RowCount
		begin
			select	@sMessage=	'������� ����� ������ �������� ��� ��������� '+	@sExec1+	' ��������� '+	@sTargetProc
				,@iError=	-3
			goto	error
		end
----------
		select	@sParamValue=	convert ( varchar ( 8000 ),	@oParamValue )
			,@sProcParams=		@sProcParams
					+	'
		'
					+	case	@iSequence
							when	1	then	''
							else			','
						end
					+	@sExec1
					+	'=	'
					+	case	@bIsOutParam
							when	1	then	@sExec1+	'	output'
							else			''
						end
					+	case
							when	@bIsOutParam=	1		then	''
							when	@sExec1	like	'%Execution%'	then	''''+	convert ( varchar ( 36 ),	@gExecutionLog )+	''''
							when	@sParamValue	is	null	then	'null'									-- ����������, ��� �������� ��� ���������� ��������; ������ �������� �������� null, �.�. default ����� ���� ������
							when	@bIsDate=	1		then	''''+	convert ( varchar ( 23 ),	@oParamValue,	121 )+	''''
							else						''''+	@sParamValue+	''''						-- �������, ��� �� ���������� �������� ������������������� � ��� ���������
						end
			,@sDeclareParams=	@sDeclareParams
					+	case	@bIsOutParam
							when	1	then		case	@iSequence
												when	1	then	'	'
												else			'
	,'
											end
										+	@sExec1
										+	'	'
										+	@sDataType
							else			''
						end
			,@sSaveParams=		@sSaveParams
					+	case	@bIsOutParam
							when	1	then		'
----------
exec	damit.SetupVariable
		@gExecutionLog=	'''
										+	convert ( varchar ( 36 ),	@gExecutionLog )
										+	'''
		,@sAlias=	'''
										+	@sExec1
										+	'''
		,'
										+	case
												when		@sDataType	like	'%(%max%)'
													or	@sDataType	in	( 'image',	'text',	'ntext',	'xml' )	then	'@mValue'
												else												'@oValue'
											end
										+	'=	'
										+	@sExec1+	'
'
							else				''
						end
	end
----------
	deallocate	c
end
----------
set	@sExec=		'declare'
		+	@sDeclareParams
		+	'
----------
'
		+	'exec	'
		+	@sTargetProc
		+	@sProcParams+	'
'
		+	@sSaveParams
----------
if	@bDebug=	1
	print	( @sExec )
----------
exec	( @sExec )
if	@@Error<>	0
begin
	select	@sMessage=	'������',
		@iError=	-3
	goto	error
end

/*
*** ����� ��������� output ��������� � damit.Variable

select object_name(id),isoutparam,* from syscolumns
where name like '@%'
order by id,colid
*/


----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go
use	tempdb