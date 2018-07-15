use	damit
----------
if	object_id ( 'damit.DoTransmit' , 'p' )	is	null
	exec	( 'create	proc	damit.DoTransmit	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoTransmit
	@iExecutionLog	TId
as
-- ������� �� SQL injection
-- ������ ���������� ������������� �������� �� ��������� ���� � ��������� �����������
-- ������� ����� ��������� �������� �� ��������� �����������, ����� ��������� ������-�������� ����� ������� � �������� �� ���� ���������
-- ��� ��������� ������ �������� �� ����������, �.�. bcp �� ����� ����� ������� � ���������������� ������ �� commit tran
declare	@sMessage	TMessage
	,@iError	TInteger=	0
	,@iRowCount	TInteger
	,@bDebug	TBoolean=	0	-- 1=�������� ���������� ���������

	,@sFileName	nvarchar ( 4000 )
	,@iProtocol	TId
	,@bEmail	TBoolean
	,@bSFTP		TBoolean
	,@bFTPS		TBoolean

	,@iExecution	TId
----------
----------
select
	@iExecution=	dl.Execution
	,@iProtocol=	D.Task
	,@bEmail=	case
				when	PE.Email	is	not	null	then	1
				else							0
			end
	,@bSFTP=	case
				when	PE.SFTP		is	not	null	then	1
				else							0
			end
	,@bFTPS=	case
				when	PE.FTPS		is	not	null	then	1
				else							0
			end
from
	damit.ExecutionLog	DL
	left	join	damit.Distribution	D	on
		D.Id=	DL.Distribution
	left	join	damit.Protocol		PE	on
		PE.Id=	D.Task
where
		DL.Id=	@iExecutionLog
if	@@RowCount<>	1
begin
	select	@sMessage=	'�������� ������ ��������',
		@iError=	-3
	goto	error
end
----------
select	@sFileName=	convert ( nvarchar ( 4000 ),	Value0 )	from	damit.GetVariables ( @iExecutionLog,	'FileName',	default,	default,	default,	default,	default,	default,	default,	default,	default )
set	@iRowCount=	@@RowCount			-- ���� ���������� �� ���������, �� ������������� � ����������, �� ����� ������ ������ � ������ ���������
----------
if	1<	@iRowCount
begin
	select	@sMessage=	'��������',
		@iError=	-3
	goto	error
end
----------
if		@iRowCount=	0
	or	@iProtocol	is	null
	goto	done
----------
if		1	in	( @bSFTP , @bFTPS )
	and	@sFileName	is	not	null
begin
	exec	@iError=	damit.DoSendFTP
					@iExecutionLog=	@iExecutionLog
	if	@@Error<>	0	or	@iError<	0
	begin
		select	@sMessage=	'������ �������� �� FTP',
			@iError=	-3
		goto	error
	end
end
----------
if	@bEmail=	1
begin
	exec	@iError=	damit.DoSendMail
					@iProtocol=	@iProtocol
					,@sFileName=	@sFileName
	if	@@Error<>	0	or	@iError<	0
	begin
		select	@sMessage=	'������ �������� �� �����',
			@iError=	-3
		goto	error
	end
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