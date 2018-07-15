use	damit
----------
if	object_id ( 'damit.DoSaveToExcel' , 'p' )	is	null
	exec	( 'create	proc	damit.DoSaveToExcel	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoSaveToExcel	-- �������� ������ � �������
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

	,@sExecBefore		nvarchar ( max )
	,@sExec1		nvarchar ( max )
	,@sExecFinal		nvarchar ( max )

	,@sCmdFileName		varchar ( 8000 )
	,@sCmdFileNameExec	varchar ( 8000 )

	,@sHeader		varchar ( max )
	,@sHeaderFinal		varchar ( max )
	,@sHeaderQuoted		varchar ( max )
	,@dtMoment		datetime
	,@sFilterList		varchar ( max )
	,@sFieldsSort		varchar ( max )

	,@iExecutionLogData	TId
	,@iExecution		TId
	,@iDistribution		TId
	,@iData			TId
	,@sDelimeter		varchar ( 36 )
	,@sDelimeter2		varchar ( 36 )
	,@sSheetName		varchar ( 32 )
----------
if	@@trancount>	0	-- bcp �� ����� ����� ������� � ���������������� ������ �� commit tran
begin
	select	@sMessage=	'���������� � ���� �� �������� ��� �������� ����������',
		@iError=	-3
	goto	error
end
----------
set	@sDelimeter=	','
----------
select
	@iExecution=	dl.Execution
	,@iDistribution=dl.Distribution
from
	damit.ExecutionLog	dl
where
	dl.Id=		@iExecutionLog
if	@@rowcount<>	1
begin
	select	@sMessage=	'������ �������� ����������',
		@iError=	-3
	goto	error
end
----------
select
	@sFileName=		f.FileName
	,@sExecBefore=		c.Command
from
	damit.Distribution	i
	,damit.Format		f
	,damit.Storage		s
	,damit.Script		c
where
		i.Id=		@iDistribution
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
	@iExecutionLogData=	convert ( bigint,		Value0 )
	,@sFilterList=		convert ( varchar ( max ),	Value1 )
from
	damit.GetVariables ( @iExecutionLog,	'Data:ExecutionLog',	'FilterList',	default,	default,	default,	default,	default,	default,	default,	default )
if	@@RowCount>	1
begin
	select	@sMessage=	'�������� ������ ��������� ��������',
		@iError=	-3
	goto	error
end
----------
select
	@iData=		da.Id
from
	damit.ExecutionLog	el
	,damit.Distribution	d
	,damit.Data		da
where
		el.Id=		@iExecutionLogData
	and	d.Id=		el.Distribution
	and	da.Id=		d.Task
if	@@rowcount<>	1
begin
	select	@sMessage=	'������ �������� ����������',
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
SET	@sDelimeter2=	'
	,'			-- ������ ���������� �� ��������� select, �.�. �� �������, ��� @sDelimeter2=null, �.�. ��� �� ��������
----------
SELECT	@sHeader=	STUFF ( ( SELECT
					@sDelimeter+	FieldName
				FROM
					damit.DataField
				where
						Data=		@iData
					and	IsResultset=	1
				order	by
					Sequence
				FOR
					XML	PATH ( '' )
					,TYPE ).value ( '.',	'varchar(max)' ),	1,	len ( @sDelimeter ),	'' )
	,@sHeaderFinal=	STUFF ( ( SELECT
					@sDelimeter2+	'F'+	convert ( varchar ( 10 ) , ( row_number()	over	( order	by	Sequence ) ) )+	'=	'''+	FieldName+	''''
				FROM
					damit.DataField
				where
						Data=		@iData
					and	IsResultset=	1
				order	by
					Sequence
				FOR
					XML	PATH ( '' )
					,TYPE ).value ( '.',	'varchar(max)' ),	1,	len ( @sDelimeter2 ),	'
	' )
	,@sHeaderQuoted=STUFF ( ( SELECT
					@sDelimeter+	'convert ( varchar ( max ) , '+	quotename ( FieldName )+	' )'
				FROM
					damit.DataField
				where
						Data=		@iData
					and	IsResultset=	1
				order	by
					Sequence
				FOR
					XML	PATH ( '' )
					,TYPE ).value ( '.',	'varchar(max)' ),	1,	len ( @sDelimeter ),	'' )
	,@sFieldsSort=	STUFF ( ( SELECT
					@sDelimeter+	quotename ( FieldName )+	case
												when	Sequence<	0	then	'	desc'
												else					''
											end
				FROM
					damit.DataField
				where
						Data=	@iData
					and	Sort	is	not	null
				order	by
					abs ( Sequence )
				FOR
					XML	PATH ( '' )
					,TYPE ).value ( '.',	'varchar(max)' ),	1,	len ( @sDelimeter ),	'' )
----------
-- ��� HDR=Yes Excel ����� ������������ ����� � ��� ����������� ����� ������ � ������� �������� �����, ������� ����� ����������� �� 255 �������� � ���� �������
select
	@sExec1=	'
insert
	OPENROWSET ( ''Microsoft.ACE.OLEDB.12.0'' , ''Excel 12.0;HDR=No;DATABASE=<FileName/>'' , ''SELECT * FROM [<SheetName/>$]'' )
select
	'+	@sHeaderQuoted+	'
from
	'+	DataLog+	'
where
	ExecutionLog=		'''+	convert ( varchar ( 36 ) , @iExecutionLogData )+	''''+	isnull ( '
order	by
	'+	@sFieldsSort , '' )
	,@sExecFinal=	'
update
	OPENROWSET ( ''Microsoft.ACE.OLEDB.12.0'' , ''Excel 12.0;HDR=No;DATABASE=<FileName/>'' , ''SELECT top 1 * FROM [<SheetName/>$]'' )
set
'+	@sHeaderFinal+	'
where
	F1	like	'''+	t.FieldName+	'%'''	-- �������������� � top 1 ��������, ��� � ������ ������ �������� ����� � ��������� � �����
from
	damit.Data	d
	,( SELECT
		FieldName
		,Sequence2=	row_number()	over	( order	by	Sequence )
	FROM
		damit.DataField
	where
			Data=		@iData
		and	IsResultset=	1 )	t
where
		d.Id=		@iData
	and	t.Sequence2=	1
----------
select
	@sSheetName=		'����1'
	,@sFileName=		FullName
	,@sExecBefore=		replace (
				replace (
				replace (
				replace (
				replace (
				@sExecBefore
				,'<SheetName/>',isnull ( @sSheetName,	'' ) )
				,'<Delimeter/>',isnull ( @sDelimeter,	'' ) )
				,'<Header/>',	isnull ( @sHeader,	'' ) )
				,'<DirName/>',	isnull ( DirName,	'' ) )
				,'<FileName/>',	isnull ( FullName,	'' ) )
	,@sExec1=		replace (
				replace (
				replace (
				replace (
				replace (
				@sExec1
				,'<SheetName/>',isnull ( @sSheetName,	'' ) )
				,'<Delimeter/>',isnull ( @sDelimeter,	'' ) )
				,'<Header/>',	isnull ( @sHeader,	'' ) )
				,'<DirName/>',	isnull ( DirName,	'' ) )
				,'<FileName/>',	isnull ( FullName,	'' ) )
	,@sExecFinal=		replace (
				replace (
				replace (
				replace (
				replace (
				@sExecFinal
				,'<SheetName/>',isnull ( @sSheetName,	'' ) )
				,'<Delimeter/>',isnull ( @sDelimeter,	'' ) )
				,'<Header/>',	isnull ( @sHeader,	'' ) )
				,'<DirName/>',	isnull ( DirName,	'' ) )
				,'<FileName/>',	isnull ( FullName,	'' ) )
	,@sCmdFileName=		FullName+	'.vbs'
	,@sCmdFileNameExec=	case	charindex ( '"' , DirName )
					when	0	then	quotename ( FullName+	'.vbs' , '"' )	-- ���� � ����+����� ����� ���� �����������, ��������, ������
					else			FullName+	'.vbs'
				end
from
	damit.GetFormatFileName ( @sFileName , @dtMoment , @sFilterList )







----------
if	@bDebug=	1
begin
	print	( @sExecBefore )
end
----------
exec	@iError=	damit.DoSaveToFile
				@sData=		@sExecBefore
				,@sFileName=	@sCmdFileName
				,@sCharset=	'windows-1251'
if	@@Error<>	0	or	@iError<	0
begin
	select	@sMessage=	'������ �������� ���������� ����� ��� ��������',
		@iError=	-3
	goto	error
end









----------
if	@bDebug=	1							-- MSScriptControl.ScriptControl �� �������� ��� sql 64-bit, ������� ��������� � ��������� ��� .vbs ������ �� �����
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
if	@bDebug=	1
begin
	print	( @sExec1 )
	print	( @sExecFinal )
end
----------
exec	( @sExec1 )		-- ����� ������� sqlservr.exe ����� ������ �� ��������� ������� ��� ���������� ������ MSDTC, ������, ��-�� ���� ������� � ����-��

exec	( @sExecFinal )



















----------
goto	done

error:
raiserror ( @sMessage , 18 , 1 )

done:

----------
return	@iError
go
use	tempdb