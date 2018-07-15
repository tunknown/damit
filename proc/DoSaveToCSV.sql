use	damit
----------
if	object_id ( 'damit.DoSaveToCSV' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSaveToCSV	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSaveToCSV	-- �������� ������ � �������
	@iExecutionLog		TId
	,@sQueryHeader		nvarchar ( max )
	,@sQueryData		nvarchar ( max )
	,@sFileName		nvarchar ( 256 )	output
as
-- ������� �� SQL injection
-- ������ ���������� ������������� �������� �� ��������� ���� � ��������� �����������
-- ������� ����� ��������� �������� �� ��������� �����������, ����� ��������� ������-�������� ����� ������� � �������� �� ���� ���������
-- ��� ��������� ������ �������� �� ����������, �.�. bcp �� ����� ����� ������� � ���������������� ������ �� commit tran
declare	@sMessage		varchar ( 256 )
	,@iError		integer
	,@iRowCount		integer
	,@bDebug		bit=	0	-- 1=�������� ���������� ���������

	,@sExec			nvarchar ( max )

	,@sCmdFileName		nvarchar ( 256 )
	,@sCmdFileNameExec	nvarchar ( 256 )
	,@sHeader		sysname
	,@dtMoment		datetime
	,@sFilterList		varchar ( max )

	,@iExecution		TId
----------
if	@@trancount>	0	-- bcp �� ����� ����� ������� � ���������������� ������ �� commit tran
begin
	select	@sMessage=	'���������� � ���� �� �������� ��� �������� ����������',
		@iError=	-3
	goto	error
end
----------
select
	@iExecution=		l.Execution
	,@sFileName=		f.FileName
	,@sExec=		c.Command
from
	damit.ExecutionLog	l
	,damit.Distribution	i
	,damit.Format		f
	,damit.Storage		s
	,damit.Script		c
where
		l.Id=		@iExecutionLog
	and	i.Id=		l.Distribution
	and	f.Id=		i.Task
	and	s.Id=		f.Storage
	and	c.Id=		s.Script
if	@@RowCount<>	1
begin
	select	@sMessage=	'�������� ����� ��� ��������',
		@iError=	-3
	goto	error
end
----------
select
	@dtMoment=	Start
from
	damit.ExecutionLog
where
	Id=		@iExecution
----------
select
	@sFilterList=		convert ( varchar ( max ),	Value0 )
from
	damit.GetVariables ( @iExecutionLog,	'FilterList',	default,	default,	default,	default,	default,	default,	default,	default,	default )
if	@@RowCount>	1
begin
	select	@sMessage=	'�������� ������ ��������� ��������',
		@iError=	-3
	goto	error
end
----------
select
	@sHeader=		convert ( char ( 36 ) , @iExecutionLog )		-- ����� ����� ������ ��������� � ��������������� �� ����
	,@sCmdFileName=		DirName+	'\'+	@sHeader+	'.cmd'
	,@sCmdFileNameExec=	case	charindex ( '"' , DirName )
					when	0	then	quotename ( DirName+	'\'+	@sHeader+	'.cmd' , '"' )	-- ���� � ����+����� ����� ���� �����������, ��������, ������
					else			DirName+	'\'+	@sHeader+	'.cmd'
				end
	,@sFileName=		FullName
	,@sExec=		replace (
				replace (
				replace (
				replace (
				replace (
				@sExec
				,'<Header/>',		isnull ( @sHeader , '' ) )
				,'<DirName/>',		isnull ( DirName , '' ) )
				,'<FileName/>',		isnull ( FullName , '' ) )
				,'<QueryHeader/>',	isnull ( @sQueryHeader , '' ) )
				,'<QueryData/>',	isnull ( @sQueryData , '' )	)
from
	damit.GetFormatFileName ( @sFileName , @dtMoment , @sFilterList )
----------
set	@sExec=	convert ( nvarchar ( max ) , damit.GetReplacement ( @iExecutionLog,	default,	@sExec ) )







----------
if	@bDebug=	1	print	( @sExec )
if	@bDebug=	1	print	( @sCmdFileName )
----------
exec	@iError=	damit.DoSaveToFile
				@sData=		@sExec
				,@sFileName=	@sCmdFileName
				,@sCharset=	'ibm866'--'windows-1251'
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'������ �������� ���������� ����� ��� ��������',
		@iError=	-3
	goto	error
end







----------
if	@bDebug=	1
	exec	xp_cmdshell	@sCmdFileNameExec
else
	exec	xp_cmdshell	@sCmdFileNameExec,	no_output
if	@@Error<>	0
begin
	select	@sMessage=	'������ ��������',
		@iError=	-3
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