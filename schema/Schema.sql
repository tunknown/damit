use	tempdb
go
if	db_id ( 'damit' )	is	not	null
	drop	database	damit
go
----------
CREATE	DATABASE
	damit
ON	PRIMARY
(	NAME=		N'damit'
	,FILENAME=	N'g:\MSSQL12.MSSQLSERVER\MSSQL\DATA\damit.mdf'
	,SIZE=		5120KB
	,FILEGROWTH=	10024KB )
,FILEGROUP	Files	CONTAINS	FILESTREAM	DEFAULT
(	NAME=		N'Files'
	,FILENAME=	N'g:\MSSQL12.MSSQLSERVER\MSSQL\DATA\DMTFiles' )
LOG	ON 
(	NAME=		N'damit_log'
	,FILENAME=	N'g:\MSSQL12.MSSQLSERVER\MSSQL\DATA\damit_log.ldf'
	,SIZE=		1024KB
	,FILEGROWTH=	10024KB )
with	FILESTREAM
(	NON_TRANSACTED_ACCESS=	FULL
	,DIRECTORY_NAME=	N'DMTFiles' )
go
----------
use	damit
go
begin	tran

go
create	schema	damit	-- Da(ta) Mi(gration) T(asks)
go
-- ���� ������ ��������� �������� �������� ����
create	type	damit.TIdBig		from	bigint			null		-- i
create	type	damit.TId		from	int			null		-- i
create	type	damit.TIdSmall		from	smallint		null		-- i
create	type	damit.TIdTiny		from	tinyint			null		-- i
create	type	damit.TGUID		from	uniqueidentifier	null		-- g
create	type	damit.TName		from	varchar ( 256 )		null		-- s
create	type	damit.TNName		from	nvarchar ( 256 )	null		-- s/su
create	type	damit.TInteger		from	int			null		-- i
create	type	damit.TIntegerNeg	from	int			null		-- i
create	type	damit.TBool		from	tinyint			not null	-- i ��� bit �������� ��� ������������� � ��������
create	type	damit.TBoolean		from	bit			not null	-- b
create	type	damit.TExtName		from	varchar ( 256 )		not null	-- s	�������� ��������� ��������, ��������, ��������
create	type	damit.TSysName		from	nvarchar ( 256 )	not null	-- s/su	������ SQL ������� ��� �������� �������������
create	type	damit.TFileName		from	nvarchar ( 260 )	null		-- s/su	��������, ���� � �������� �������
create	type	damit.TPassword		from	varchar ( 128 )		null		-- s
create	type	damit.TNote		from	varchar ( 256 )		null		-- s
create	type	damit.T�Note		from	nvarchar ( 256 )	null		-- s
create	type	damit.TMessage		from	varchar ( 256 )		null		-- s
create	type	damit.TScript		from	nvarchar ( max )	null		-- s
create	type	damit.TDateTime		from	datetime		null		-- dt
create	type	damit.TScriptShort	from	nvarchar ( 4000 )	null		-- s	��������, ��� xp_cmdshell
create	type	damit.TSystemName	from	nvarchar ( 1024 )	null		-- s	full qualified object name= len(sysname)*4+len('.')*4+len('[]')*len(sysname)*4
create	type	damit.TDelimeter	from	varchar ( 36 )		null		-- ����� ��������� guid � ��������� ���� ��� ��������� ������������ �����������
--create	type	damit.TBLOB	from	varbinary(max)	null
----------
go
create	rule	damit.RId	as	0<	@oValue
go
create	rule	damit.RPositive	as	0<=	@oValue
go
create	rule	damit.RBool	as	@iValue	in	( 0,	1 )
----------
go
create	default	damit.DGUID	as	newid()						/* ������ ��� PK ����� */
go
----------
exec	sp_bindrule	'damit.RId',		'damit.TIdBig'				-- ��������� 0 ��� ����������� isnull(*,0)=0
exec	sp_bindrule	'damit.RId',		'damit.TId'				-- ��������� 0 ��� ����������� isnull(*,0)=0
exec	sp_bindrule	'damit.RId',		'damit.TIdSmall'			-- ��������� 0 ��� ����������� isnull(*,0)=0
exec	sp_bindrule	'damit.RId',		'damit.TIdTiny'				-- ��������� 0 ��� ����������� isnull(*,0)=0
exec	sp_bindrule	'damit.RPositive',	'damit.TInteger'
exec	sp_bindrule	'damit.RBool',		'damit.TBool'
----------





/*
Jet Database Engine documentation

ADODB.Stream ����� �� ���� ������� �� 2048 �����, ������ ����� ����� ������?
bcp ����� ������� �� ������ �� 4096, � ����� �������� �� �������
AccessDatabaseEngine.exe ����������� �� 32 ��������� ������� �������� � ����
�������� ��� "OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "txtsrv" returned message "������������ ��������."."
----------



��������� ����� ������:
1) ���������� �����
	��� �������� � ����������� ��� ��������� ������������ ����� ������
	��� ��������, ����� ��� ����������� ������ �������(� �.�. ������� ������), ���� ��� �����
2) ��������� ������ ����� BeforePackage, ��������, ������ ������ ���������� � ����� ������
3) ���������� �����
4) ��������� ���������� ����� AfterPackage, ��������, ������ ������ ���������� � ����� ������

��������� ����:
��������:
	1) ���� ������� #������� ��� ��������, �� ��� �������� �� ���������� view ��� �� view � ������� ����� ���������-��� ���� � �������, ��� ������ �������
	2) ��������� �������������� ���������, ����������� ������� ��� ��������(� Id ���� ��������?) ������ �� ��������� ���������
��� ��������� ���������� � ���������� �����- ��� �� ������� � ���� ��������???
��� ������� ����������� ���������� � ������?
		-������ �������� ���������, ��� ������, ��������, ����� ��������� �������
		��������� �� ������ ���������������- ������� ListToTableInteger(varchar(max))
		��
		������ ���������
			�� ���� ����������/������������, � �.�. � ��� ���������� ������
			�� �����������
	3) �������� ������������ �������- �������� �� ����������� ����, ����� ���� �����������
	4) ���� ������ ������ ��������� �� �����������, �� ���������� (������� ������ �������/���� ������ �������) � �������(���������?) ����� �������, ����� ������� �������������� ������
	5) ��������� ��� ���������� ������� �� �������
	6) ���� �������� ������� ���� ��� ������ �� �������, �� ��������� ��������� ���� � ���������� �� ������� � ��������� �������
� ����� ���� ����� �������� SSIS
	7) ������� �� ��������� �� ����� ��� �������
	8) ���� ��� ����� �� ������� ������ ������, �� ��� �������� ������ ���������� �������
�������:
?	0) ������������ ������� ��������� �������
	1) ����� ��� �� �������(������ ���������?) ��������� �������(�����, �������)
	2) ��������� ������ �� ���������
	3) ���� ������ �� � �������, �� ��������� �� �������� ���� ���������� �� �������
	4) ���������� ������� ������� ����� � ����� ������
	5) ����� � ���� ��������������� ������, ���� ��� �� ����������, �� ������ �� ����� ���������� ��������� ��� ����������
	6) ���� ��� ����� �� ������� ������ ������, �� ������/�������� ������ �������� � ���� ���� �������

*/


----------
create	table	damit.Script
--������- ������� ���� � ��������� �����������-��������� ��������� ������ ��� ����� � �����������-���������
--��� �������� ��������� ���������? sql ������ ����� ��������� ��� � damit.Parameter, ��� ��� ������� .CMD?
--��� ���������� �������� ��������� � sql ����� ����� ������ � �������? � sql ��������� ����� ���������� �� �����
--� SFTP ���� ��������� ������ �����������, ����� ��� ������ ��������� SFTP ������������ ����� damit.Parameter/damit.Variable, ������� �� ����� ����������� ������
--��� ������ �������� ������ ���� ������������ ��� ������� .cmd ������? ������� Command?
--���� Subsystem='ActiveScripting', �� output ��������� �� .vbs �������� ����� wscript.echo. ���� ������ ������ '<', �� ����������� xml; ����� ������������ ����� ToListFromStringAuto � ������ ��������- ������������
(	Id			damit.TIdSmall		not null
	,Name			damit.TName		not null
--	,Type			damit.TName		not null	-- cmd,sql
	,Subsystem		nvarchar ( 40 )		null		-- null=��������� ���� �� ��������; ������������ ��������� �� msdb.dbo.syssubsystems, ��������- TSQL, ActiveScripting(��� .vbs), CmdExec, SSIS
	,FileName		damit.TFileName		null		-- null=��������� ��� ���������� ��� ����=��������� ����� �����������, ����� ������������ ��� �������
	,Folder			damit.TFileName		null		-- � ����� ������� ��������� ���������, ��������, ��� ��������� ������ .exe
	,Command		damit.TScript		null		-- null=��������� ���� �� �����; ����� �������, ��������, � ���������; ��������, ����� .cmd �����(��������������� ����������� FileName) � ����������� ��������� ������
,constraint	PKdamitScript		primary	key	clustered	( Id )
,constraint	CKdamitScript		check	(	FileName	is	not	null
						or	Command		is	not	null ) )	-- ��������� ��, ��� ���������, ���� ��������� ���, �� ��������� Command � FileName, ���������, ����� ������� FileName
----------
	create	table	damit.SMTP	-- ������� SMTP �������� � ������ ����������� �������������
	-- ���� ����� ������� �� ������� ������������, �� �������� ����� �������
	(	Id			damit.TIdTiny		not null	identity ( 1,	1 )
--		,Script			damit.TIdSmall		null
		,Server			damit.TExtName		not null
		,Proxy			damit.TExtName		null
		,WindowsAuthentication	damit.TBool		not null	-- �������� ����������� ��� ���
		,SSL			damit.TBool		not null
		,Login			damit.TExtName		null		-- ����� ��� �������� ����������� ��� anonymous
		,Password		damit.TName		null
	,constraint	PKdamitSMTP		primary	key	clustered	( Id )/*
	,constraint	FKdamitSMTPScript	foreign	key	( Script )	references	damit.Script	( Id )*/	)
----------
	create	table	damit.Email	-- ��������� ������� email
	(	Id			damit.TIdSmall		not null
		,SMTP			damit.TIdTiny		not null
		,[From]			damit.TExtName		null
		,[To]			varchar ( 1024 )	not null
		,Cc			varchar ( 1024 )	null
		,Bcc			varchar ( 1024 )	null
		,Subject		varchar ( 1024 )	null
		,Body			ntext			null
		,IsHTML			damit.TBool		null
		,CanBlank		damit.TBool		not null	-- �������� ������ ��� ��������
--		,Attachment		image			null		-- ��� �� ������ ���� � ������������ � ������
	,constraint	PKdamitEmail		primary	key	clustered	( Id )
	,constraint	FKdamitEmailSMTP	foreign	key	( SMTP )	references	damit.SMTP	( Id )	)
----------
	create	table	damit.SFTP	-- ��������� SFTP ��������
	(	Id			damit.TIdSmall		not null
		,Script			damit.TIdSmall		null		-- ������ �������� �� ���� ������ ��� ������ � ���� �����
		,Server			damit.TExtName		not null
		,Port			damit.TInteger		null
		,Login			damit.TExtName		null
		,Password		damit.TPassword		null
		,PrivateKey		damit.TFileName		null		-- ���� � ������ ����� �����
		,Path			damit.TFileName		null		-- ���� � ������� ����� �� �������
		,RetryAttempts		damit.TInteger		not null
	,constraint	PKdamitSFTP		primary	key	clustered	( Id )
	,constraint	FKdamitSFTPScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
	create	table	damit.FTPS	-- ��������� FTPS ��������
	(	Id			damit.TIdSmall		not null
		,Script			damit.TIdSmall		null		-- ������ �������� �� ���� ������ ��� ������ � ���� �����
		,Server			damit.TExtName		not null
		,Port			damit.TInteger		null
		,Login			damit.TExtName		null
		,Password		damit.TPassword		null
		,Path			damit.TFileName		null		-- ���� � ������� ����� �� �������
		,RetryAttempts		damit.TInteger		null
	,constraint	PKdamitFTPS		primary	key	clustered	( Id )
	,constraint	FKdamitFTPSScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
	create	table	damit.Folder	-- �������� ��������, ��������, UNC ��� �� ��������� �����
	(	Id			damit.TIdSmall		not null
		,Script			damit.TIdSmall		null		-- ������ ����������� ����� � ���� ������� ��� �� ����� ��������
		,Path	 		damit.TFileName		not null
	,constraint	PKdamitFolder		primary	key	clustered	( Id )
	,constraint	FKdamitFolderScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
create	table	damit.Protocol
-- �� ������ �� ���� ������ ����� �������, ��������� ��� �������������� TF
-- PK ������ ������� computed, �.�. ���� ������������ �������� ����, �� ������� ��������� FK+PK � ������ drop/add
(	Id		damit.TIdSmall		not null	--constraint	FKdamitProtocolId	references	damit.TaskIdentity	( Id )
	,Email		damit.TIdSmall		null		constraint	FKdamitProtocolEmail	references	damit.Email		( Id )
	,SFTP		damit.TIdSmall		null		constraint	FKdamitProtocolSFTP	references	damit.SFTP		( Id )
	,FTPS		damit.TIdSmall		null		constraint	FKdamitProtocolFTPS	references	damit.FTPS		( Id )
	,Folder		damit.TIdSmall		null		constraint	FKdamitProtocolFolder	references	damit.Folder		( Id )
,constraint	PKdamitProtocol			primary	key	clustered	( Id )
,constraint	CKdamitProtocol			check	( Id=		isnull ( convert ( varbinary ( 2 ),	Email ),	0x )
								+	isnull ( convert ( varbinary ( 2 ),	SFTP ),		0x )
								+	isnull ( convert ( varbinary ( 2 ),	FTPS ),		0x )
								+	isnull ( convert ( varbinary ( 2 ),	Folder ),	0x ) )	)
----------
create	table	damit.Storage		-- ������� ������ �������� ������
-- .csv,.txt,.xml,.xls
-- ���� ��� .xml, �� ��� ������� .xsd- ������ ��� ��������
-- �� ���� ���������� ����� ����� ����� ��������� ��������, ������������� ������ ���������
(	Id		damit.TIdSmall		not null
	,Script		damit.TIdSmall		null		-- ������ ��������� �������� ��� �������� �������
	,Name		damit.TName		not null	-- �� ���� ���������� ����� ����� ���� ��������� ��������
	,Extension	damit.TFileName		not null	-- ���������� �����
	,Saver		damit.TSysName		null		-- ��������� �������� � ���� ����� �������
	,Loader		damit.TSysName		null		-- ��������� �������� �� ����� ����� �������
--	,Purifier	damit.TSysName		null		-- ������� ������ ���������� ��������, ������� ������ �� ������� � ������ �� �� ����?
constraint	PKdamitStorage		primary	key	clustered	( Id )
,constraint	FKdamitStorageScript	foreign	key	( Script )	references	damit.Script	( Id )
/*,constraint	CKdamitStorageSaver	check	(	Saver			is		null
						or	object_id ( Saver )	is	not	null  )
,constraint	CKdamitStorageLoader	check	(	Loader			is		null
						or	object_id ( Loader )	is	not	null  )
,constraint	CKdamitStoragePurifier	check	(	Purifier		is		null
						or	object_id ( Purifier )	is	not	null  )
,constraint	CKdamitStorage		check	(	Saver			is	not	null
						or	Loader			is	not	null  )*/	)
----------
create	table	damit.Format		-- ������� ������ �������� ������
-- .csv,.txt,.xml,.xls
-- ���� ��� .xml, �� ��� ������� .xsd- ������ ��� ��������
-- �� ���� ���������� ����� ����� ����� ��������� ��������, ������������� ������ ���������
-- ��� ������ ��� ������������� ������� ���������� ���������� ������- �������� ���� counter ��� ������������� � ������� ����� ������������ � ����� �����?
(	Id		damit.TIdSmall		not null
	,Storage	damit.TIdSmall		not null
	,Name		damit.TName		not null
	,FileName	damit.TFileName		not null	-- ������/������ ����� ���������� �������, ��������, ������� ���� � ����������
	,CanBlank	damit.TBool		not null	-- ��������� ��������� �����(��������, ������ �����) ��� �����������
,constraint	PKdamitFormat		primary	key	clustered	( Id )
,constraint	FKdamitFormatStorage	foreign	key	( Storage )	references	damit.Storage	( Id )
/*,constraint	CKdamitFormatSaver	check	(	Saver			is		null
						or	object_id ( Saver )	is	not	null  )
,constraint	CKdamitFormatLoader	check	(	Loader			is		null
						or	object_id ( Loader )	is	not	null  )
,constraint	CKdamitFormatPurifier	check	(	Purifier		is		null
						or	object_id ( Purifier )	is	not	null  )
,constraint	CKdamitFormat		check	(	Saver			is	not	null
						or	Loader			is	not	null  )*/	)
----------
create	table	damit.Query		-- ��������� �������
(	Id		damit.TIdSmall		not null
	,Alias		damit.TName		not null	-- �������� ��������� ��� ����������
,constraint	PKdamitQuery		primary	key	clustered	( Id )
,constraint	UQdamitQuery		unique	( Alias )
/*,constraint	CKdamitQuery		check	( object_id ( Alias )	is	not	null )*/	)	-- ��� ����� �� ������������ � ������ �������� ���� ��������
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'�������'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Query'
----------
/*create	table	damit.Batch		-- ����� ��� ��������� ���������� ������ �� ���� ������
-- ��� ������� ���� ��� ��������?

--TransferEntity:File, Batch, Node
--����� �������������, ����� ����� ���� ����������� ��������� �� �����

--������� ������� ������ ��������, ��� Routes

--Parent, ��������, ������� ������� ����� ������(���� �� ���), ����� ��� ���������� �� ������� ���������(������ �� �����)
--������� ���� ����� ��� ��������-	��� ��� �������?
--Sequence ������ Parent

--���� ����� ��� � ������ Distribution, �� ���������������� �� ������ ��� �� �����

(	Id		damit.TId		not null
	,Distribution	damit.TId		not null
	,FilePath	damit.TFileName		null		-- ����� ������� ��� ���� ��������, � �������� ����� ���� ��������� ������� �������� ������
	,Name		damit.TName		not null
constraint	PKdamitBatch			primary	key	clustered	( Id )
constraint	FKdamitBatchDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id ) )*/
----------
create	table	damit.Data		-- ��������� ������ ��������
-- ��� ������ � �������� �������, ���� ���������� ������ ���������� ������?
-- ���������� ��������� ������������� ��������� ������, ���� ������ ������� �� view, � �� �� ���������
-- � ��������� �������� ��������� �������� ����, ����� ����� ����� �������� �� ����� ���� � object_id ����� �������� ���������
-- �������� ��: ��������� � ����� �����- Target, ����� �������- Filter, ������� ���������� �������- FieldSort
-- ?��� ����� ��������, ��� ������� ���������� ���������� ����������� ��������� ����������, �.�. ������������� ���� ����������- �� ����� � ����� �������� ������������� ���� ������???
--,Pattern	damit.TSysName		null		-- ��������� view, null=���� ������ ������� �� �� ���������, � �� view, �� ����� �� ���� ������� ������ ��� ��������� �������, ��� _�������_ �������� ��������� �������, ����� ��� ���� �� ������������, ����� �������������� ��� ���������� linked server\jet\schema.ini
(	Id		damit.TIdSmall		not null
	,Target		damit.TSysName		not null	-- �� ����� view ��� ��������� ��� ��������, ������� ������� �� ����(������� �� ��������� �������)- ��������/����������� ��������� �������
	,DataLog	damit.TSysName		null		-- �������, ����������� ��������� � ���������� ������ ��� ���������, ����� �������� ������ ���������, ���� null, �� �������� ��
	,Filter		damit.TSysName		null		-- ��� ���������� �������(� �����������) ��� view(��� ����������) ��� join �� ����������� �����
	,Name		damit.TName		not null	-- ��������
--	,CanBlank	damit.TBool		not null	-- ������ �������� ��������� �������� 0=���, 1=��
	,Refiner	damit.TSysName		null		-- ������� ������ ���������� ��������, ���� ������� ������ �� �������, �� ������ ���������� ������ ����
	,CanCreated	damit.TBool		not null	-- ��������� ������������� � ���������� ���������
	,CanChanged	damit.TBool		not null	-- ��������� ������������ �� ������������ � ���������� ���������
	,CanRemoved	damit.TBool		not null	-- ��������� ������������� ������ � ������������ � ���������� ���������
	,CanFixed	damit.TBool		not null	-- ��������� �������������� � ���������� ��������
,constraint	PKdamitData		primary	key	clustered	( Id )	)
----------
create	table	damit.DataField		-- ���� ��������
(	Data		damit.TIdSmall		not null
	,FieldName	damit.TSysName		not null	-- ��� ������������� ���� ��� �������� ������ ����(�������� ������������ � ������������) �� ��������� Value
	,Value		damit.TScript		null		-- ������ �������� ����, ��������, ��� ����������� ���������� �� ������ ���������������� �������

	,IsRelationship	damit.TBool		not null	-- ���� �������������� ������ � ���������� �������� ��������(view)
	,IsComparison	damit.TBool		not null	-- ���� ��� ����������� ���������, ������������ �� checksum
	,IsResultset	damit.TBool		not null	-- ���� ���������� ������
	,IsList		damit.TBool		not null	-- ���� �� ������ ������� ���������� ��� ��������� �� ����� ���������; ���� ��� ���������� �� ������ ���������������, ���� ����� ��������� � IsRelationship
	,IsDate		damit.TBool		not null	-- ���� �� ������ ������� ���������� ��� ��������� �� ����� ���������; ���� ���� ������ � ���������� �������� ��������(view), ��������, ���� ��������� ������
	,Sort		damit.TIntegerNeg	null		-- ����������� �� abs(Sort), ������������� �������� �������� order by desc
	,Sequence	damit.TInteger		not null	-- � ���� ������� ���� ���� IsResultset � �������� ������; ������� ������������������ +1 �� �����������
constraint	FKdamitDataFieldData	foreign	key		( Data )	references	damit.Data	( Id )
,constraint	UQdamitDataField0	unique	clustered	( Data,	Sequence )
,constraint	UQdamitDataField	unique			( Data,	FieldName )	)
----------
create	table	damit.DataData		-- ����������� �������� ���� �� �����, ������������� �������� ��� ������������ ���������� ������ ������
-- ���� ��������(2) ������� �� ������(1), ��� ������, ��� ��� �������� ��������� � (2) ����������� ������ � ����� (1)
-- ��� ����������� �������� ������ �����, �������, ���� ��� �������� ��� ������ (1)=(1) ��� �� ������������ ��������� � ������ �������� ������ ����� ������
-- �������� �������� ����� �������� �� ������ ������, �� �� �� ����� �������� ������ �������� ��������, �� �� ������
-- �������� ������ ������������ ����� ����� cte
-- ����� �� ������ ����������� Distribution � ������� Data? � ��������, ��� ������������� ����� ������ ������ ��������������� �� ����� �������
(	Data1		damit.TIdSmall	not null	-- �������
	,Data2		damit.TIdSmall	not null	-- ���������
	,IsClosed	damit.TBool	not null	-- ��� ����� ����������� �� �������������, ������������ ������ ��������� � ���� ������ ������, �� �� ��� ��������/�����������
,constraint	FKdamitDataDataData1	foreign	key	( Data1 )	references	damit.Data	( Id )
,constraint	FKdamitDataDataData2	foreign	key	( Data2 )	references	damit.Data	( Id )
,constraint	UQdamitDataData		unique	clustered	( Data1,	Data2 )	)
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'����������� ������ �������� ���� �� �����'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'DataData'
----------
create	table	damit.Condition		-- ���������� ��� sql WHERE �������
-- ������� ���� (a=1 and (b=2 or c=3))
(	Id		damit.TIdSmall	not null	-- ��������� ��� � UQorNull
	,Parent		damit.TIdSmall	null		-- ������ ��� ������
	,FieldName	damit.TSysname	null		-- ?damit.Variable.Alias
	,Operator	varchar ( 16 )	not null	-- �������� ��������� ��� ����� � ������ � ���������� ���������, �.�. ������ ������ ������ ���� ���������� ��������
	,Value		sql_variant	null		-- ����� ���� �������� FieldName?
	,Sequence	smallint	null		-- ������� ���������� ������ ������, �� ����� 32787 ������� � (); null=root
	,UQorNull	as	isnull ( convert ( binary ( 2 ),	Sequence ),	convert ( binary ( 2 ),	Id ) )	persisted	not null	-- ��������� ��� Id
,constraint	PKdamitCondition	primary	key	clustered/*�� ����*/	( Id )
,constraint	FKdamitCondition	foreign	key	( Parent )	references	damit.Condition	( Id )
,constraint	UQdamitCondition	unique	( Parent,	UQorNull )
,constraint	CKdamitCondition1	check	(	Operator	in	( '>',	'>=',	'<',	'<=',	'like',	'not like' )	and	FieldName	is	not	null	and	Value	is	not	null
						or	Operator	in	( '=',	'<>' )						and	FieldName	is	not	null	-- =(<>)null->is (not)null
						or	Operator	in	( 'and','or' )						and	FieldName	is		null	and	Value	is		null ) )
----------
create	table	damit.Layout	-- ��� ������ ������ ����� ��� SELECT/FROM/WHERE/ORDER_BY ������� � ��������� � ��������
-- ������� ������� damit.Data, �� ��� �������� � � ���������- ������ ����� � ���������, � �� ��� ResultSet � DataLog
-- ?����� �� ��������� ���������� ������� ��� ��� ������ ������?
-- ������� ��������� excel ����� �� ������, �.�. � �� 3 ������ �������- ��� 3 ������, � �� 3 ����
-- FileName ��������� ��������������� � �����, �������, ��� ����� ���
(	Id		damit.TIdSmall		not null
	,Target		damit.TSysName		not null	-- ��������, view ��� DataLog_* ������� � ExecutionLog �����������
/*?*/	,Filter		damit.TSysName		null		-- ��������, � ExecutionLog �����������, join �� �������� ����?
/*?*/	,Refiner	damit.TSysName		null		-- ��� ������������ ��������� ����� ��� ����?
/*?*/	,CanBlank	damit.TBool		not null	-- ��������� �� ���� � 0 �������, ��������, ������ �� ��������� � ������
/*?*/	,Delimeter	damit.TDelimeter	null		-- ����������� ��� ������ ����� �� � SQL �������
	,Name		damit.TName		not null
,constraint	PKdamitLayout	primary	key	clustered	( Id )
,constraint	UQdamitLayout	unique	( Name )	)
----------
create	table	damit.LayoutField	-- ������ ����� ��������
-- ������� ������� damit.DataField
-- ��� ������� ����, �� ������� ������� ������� ����������?
(	Layout		damit.TIdSmall		not null
	,FieldName	damit.TSysName		not null
	,DataType	damit.TSysName		null		-- null=�� ��������� �� Layout.Target
	,Expression	damit.TScript		null		-- ���������� damit.DataField.Value
	,IsRelationship	damit.TBool		not null	-- ������ ����� �������� ����� ������� unique, ��������, �� ��������� �������, ���� ��� �� ��������� � �������?
	,IsResultset	damit.TBool		not null	-- ��� ���� ������ ������� � ResultSet
	,Sort		damit.TIntegerNeg	null		-- ������� ����������, ��� 0< ���������� DESC
	,Sequence	damit.TInteger		not null	-- ������� ����� � ResultSet
,constraint	FKdamitLayoutFieldLayout	foreign	key		( Layout )	references	damit.Layout	( Id )
,constraint	UQdamitLayoutField0		unique	clustered	( Layout,	Sequence )
,constraint	UQdamitLayoutField1		unique			( Layout,	FieldName )	)
----------
create	table	damit.TaskIdentity
(	Id		damit.TIdSmall		not null	identity ( 1,	1 )	-- ������ ��� �������� IDENT_CURRENT(), ����� �� ����� ������
	,Dumb		damit.TIdTiny		null		-- ����� ����� ���� �������� ����� �������, � �� ������ ���� ����� insert <table> default values � ��� �������� merge
,constraint	PKdamitTaskIdentity		primary	key	clustered	( Id )	)
----------
alter	table	damit.Protocol	add
constraint	FKdamitProtocolId	foreign	key	( Id )	references	damit.TaskIdentity	( Id )
----------
alter	table	damit.Protocol	NOCHECK	CONSTRAINT	FKdamitProtocolId	-- ������ ��� ���������� ����������; constraint <name> default ident_current('<table>') �� �������, �.�. �� ��������� ������� <table>
----------
create	table	damit.Task
-- �� ������ �� ���� ������ ����� �������, ��������� ��� �������������� TF
(	Id		damit.TIdSmall		not null	constraint	FKdamitTaskId		references	damit.TaskIdentity	( Id )
	,Data		damit.TIdSmall		null		constraint	FKdamitTaskData		references	damit.Data		( Id )
	,Query		damit.TIdSmall		null		constraint	FKdamitTaskQuery	references	damit.Query		( Id )
	,Format		damit.TIdSmall		null		constraint	FKdamitTaskFormat	references	damit.Format		( Id )
	,Protocol	damit.TIdSmall		null		constraint	FKdamitTaskProtocol	references	damit.Protocol		( Id )
	,Script		damit.TIdSmall		null		constraint	FKdamitTaskScript	references	damit.Script		( Id )
	,Condition	damit.TIdSmall		null		constraint	FKdamitTaskCondition	references	damit.Condition		( Id )
	,Layout		damit.TIdSmall		null		constraint	FKdamitTaskLayout	references	damit.Layout		( Id )
	,Distribution	damit.TIdSmall		null		--constraint	FKdamitTaskDistribution	references	damit.Distribution	( Id )
,constraint	PKdamitTask			primary	key	clustered	( Id )
,constraint	CKdamitTask			check	( Id=	isnull ( convert ( varbinary ( 2 ),	 Data ),	0x )+
								isnull ( convert ( varbinary ( 2 ),	 Query ),	0x )+
								isnull ( convert ( varbinary ( 2 ),	 Script ),	0x )+
								isnull ( convert ( varbinary ( 2 ),	 Format ),	0x )+
								isnull ( convert ( varbinary ( 2 ),	 Protocol ),	0x )+
								isnull ( convert ( varbinary ( 2 ),	 Distribution ),0x )+
								isnull ( convert ( varbinary ( 2 ),	 Condition ),	0x )+
								isnull ( convert ( varbinary ( 2 ),	 Layout ),	0x ) )	)
----------
alter	table	damit.Task	NOCHECK	CONSTRAINT	FKdamitTaskId	-- ������ ��� ���������� ����������; constraint <name> default ident_current('<table>') �� �������, �.�. �� ��������� ������� <table>
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'�������� ����� ������� ����������� �� ����'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Task'
----------
create	table	damit.Distribution	-- ��� ��������� ��������������� ������
-- ��� ����� ���� ���������� �� ��������� � �������� �/��� ��� ����� ������������ ��� ��������� ����������; ��� ��� ����������� ��������� �� ������ �����, ����� ��� ��� ���������, � �� ��������?
-- ��� �������� ��������� �� �����������(��������������, �� �����������) ���� ��� ������������� ���������?
--	Condition	int		null		-- ������� ��������, null=����������� �������
--,constraint	FKdamitDistribution1	foreign	key	( Condition )	references	damit.Condition	( Id )
(	Id		damit.TIdSmall		not null
	,Node		damit.TIdSmall		null		-- null=����� ������ ���
	,Task		damit.TIdSmall		null		-- null=���, ��������, ��� ��������� ���������� ����� � ���� �����, null=��� ��������� ����������� ���������� ��� ��������� �������� �� ����
	,Name		damit.TName		null		-- ��������
	,Sequence	damit.TInteger		not null	default	( 0 )	-- ������� �������� ��� ������������� ��������; ���� ����������, �� ��������� ����������� � ����������, ���� ������, �� ������� ����� �����, ���� ������ ���� �� ��������� �����="�������"
,constraint	PKdamitDistribution		primary	key	clustered	( Id )
,constraint	FKdamitDistributionNode		foreign	key	( Node )	references	damit.Distribution	( Id )
,constraint	FKdamitDistributionTask		foreign	key	( Task )	references	damit.Task		( Id )
--,constraint	UQdamitDistribution1		unique	( Node,	Task,	Sequence )	-- ��������� ������������, ����� �� ��� ������������, ��������, ��� �������������� Sequence?
--,constraint	UQdamitDistribution2		unique	( Node,	Sequence )
,constraint	CKdamitDistribution1		check	( Id<>	Task )	-- ��������� ������������
,constraint	CKdamitDistribution2		check	(	Task	is	not	null
							or	Name	is	not	null )	)
----------
alter	table	damit.Task	add
constraint	FKdamitTaskDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
----------
create	table	damit.Parameter		-- ���������� ������������� ���������� � ���������� ��� �������� � ����������������� �������� ����������
--��������, ��� ������� ���������� ��������: ������������� �������- �����, �.�. �� ������������ � ��������, Start,Finish ����� damit.Variable, �.�. ����������� � �������� �������
--���� ��� ���� ������ ��������� ���������� � ������� Sequence, �� ���������� ���������� ���������� ����?
--��� ����, ���� ��� ���� ������ ������ ���������, �� � ������ ������ ���������� Sequence?
--��� ����� ����� ���� ��� ���, ��������, � Email ����� ������� ��������� ������, � �� ���������� ��������� ����� � ����� ������
--����� input ��������� �, ��������, �� ������������� ��������. ����� ��������� ����� Source �� output �������� ������� ���� � damit.Variable ��� ����� ��������� ���� � Value=null
--���� �� Value ������ ������ ���, �� ����, ������������ �������� ������ ���� ����������� � ��� �����
--������� �� ��� ������� ����������� ������ � damit.Variable? ���� ��� ������ � damit.Parameter, �� ��������� �� ����� ���� ���������� � �� ����� ������(�� ����� warning � ExecutionLog), ��� ������ ������- �������� �� ���������� damit.Variable ��� ���������� ���������� ���� GarbageCollector?
--����������� �������� ������ ������������ ����� damit.Variable?
--������� ��������� ����� damit.SetupVariable �������� ����� ������ damit.Variable: Source=null,DistributionRoot<>null,Value<>null(������ �������� ��������� ������� insert/update?)
--�������������� ������ ���������� Task �������� �� sql ���� ��� ������� � damit.Parameter?
--�������� � Source FK(Parameter) �� FK-Entity(Parameter,DistributionStep), ����� � input ����� ���� ��������� �� ����������� output �������� DistributionStep �������� �� �������� ���
--DistributionRoot and DistributionStep is null=�������� ��� ���� ��������
--��� ������ �������� �� �������� ����, ��� ������ ��������� ��� ��������
/*
������ ����� ������ dbo.Replacement+dbo.ReplacementValue :
	damit.Variable
	damit.Parameter
	left join ����� �������
*/

(	Id			damit.TIdSmall		not null	identity ( 1,	1 )
	,Source			damit.TIdSmall		null		-- FK(damit.Parameters.Id) ������ ������������ ���� �� �������� DistributionRoot, ����� ��������� �������������; ������������� ������ �� ���� �������, ��� ���������� ��������; ���������������� � �� ��������� ������ ����� damit.Variable. ������ �� damit.Parameter.Id, � �� DistributionStep, ������� ����� ������������ ������� � ��� �������� ����������� �������� DistributionRoot
	,DistributionRoot	damit.TIdSmall		null		-- ��� ����������� ���������� ������������� �������� � ������� ����������� ��� ������ DistributionRoot, ��� null=��� ���� ��������; ������ DistributionRoot ������ DistributionStep ����� ���� ����������� ������ 1 ���
	,DistributionStep	damit.TIdSmall		/*not */null	-- ��� ������ ���� ��������, null=�������� ��� ���� ����� ��������
--	,Condition		damit.TIdSmall		null		-- XML ������� (��� ��������?) ��� ���������. ��� join ���� �� damit.Data ������ Distribution �����, ���� ���� ��������� Data ������ ��������� Distribution?
	,Alias			damit.TName		null		-- �������� ���������, null= �������� �� Source, ���� ����� � Alias � Source, �� Alias ������������ ������(��� ����������� ��������������), � �������� ������
	,Value	sql_variant	/*damit.TBLOB*/		null		-- ����������� �������� ���������, ��� null ������ ������, ��� ����������� �������� ��� �������� �������� Source
	,Expression		damit.TScript		null		-- SQL ��������� ��� ������� ��� �������������� Value, � �������, ���������� ��� ���� � SELECT. ������ �� ������� ����� ����, �������� ������������, ��������, ������������� ��������
--	,IsStatic		damit.TBool		not null	-- ������������ �������� �� ���� ������� ������ damit.Variable
	,Sequence		damit.TIntegerNeg	null		-- ������� ����������, ���� � ����������������� ���������, ������ ������ �� ��� � Value- ���� ���������� � ����� ��������� ���������, ���� ����� ����� � �������� � ����� ������ ����, �� ��� ���������� ���������� ����� ����������, ��������, �������� ������ � email
,constraint	PKdamitParameter			primary	key	clustered	( Id )
,constraint	FKdamitParameterSource			foreign	key	( Source )		references	damit.Parameter		( Id )
,constraint	FKdamitParameterDistributionRoot	foreign	key	( DistributionRoot )	references	damit.Distribution	( Id )
,constraint	FKdamitParameterDistributionStep	foreign	key	( DistributionStep )	references	damit.Distribution	( Id )
--,constraint	FKdamitParameterCondition		foreign	key	( Condition )		references	dbo.Condition		( Id )
,constraint	UQdamitParameter1			unique		( DistributionRoot,	DistributionStep,	Alias,	Sequence )	-- DistributionRoot ����� ��������� �������� ������ ��������� ��� ������ ����, ����������� � �������� �������

-- �������� Expression � check

,constraint	CKdamitParameter1			check	(	(	Source			is	not	null
									or	Alias			is	not	null )
								and	(	Source			is		null
									or	Value			is		null )
								and	(	Alias			is	not	null
									or	Value			is		null )
								and	(	Alias			is	not	null
									or	Sequence		is		null )
								and	(	DistributionStep	is		null	and	Alias	is	not	null	-- ���������� ��������� ����������� ���������
									or	DistributionStep	is	not	null )	)	)
/*,constraint	CKdamitParameterN			check	(	Condition	is		null	and	Alias	is	not	null
								or	Condition	is	not	null	and	Alias	is		null )*/
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'���������� ������������� ���������� � ���������� ��� �������� � ����������������� �������� ����������'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Parameter'
----------
create	table	damit.ExecutionLog	-- ��� ����������� �����
-- ����� ������� ��� �������� �����
-- ��������������� �� ��� �/��� ��������� �� ������ ������, ���������� ����� ������ �� �������� ���������� ����������� ������, ��� ������ ������� ����, ��� ������ ���������
-- ���� ��� ������� ���������� �� AND, �� �������������� ���������� �� �������� ������� �������� � ����� ����� ������� �������� ��� �������������� �������, ����� �������� ������� � ������������ ���������
-- ��������� ��������� ����� ���� ��������� ����������� ��������=������� ������� ����� ������� ����������
-- ����� � Distribution ����� Condition ����� ����� ������ ����� ������������������ Start
-- ���������(�� �������, sequence ��� ��� ���?) ExecutionLog.Id ��� Finish=null ��������� ������������� � ������ ������
(	Id			damit.TId		not null	identity ( 1,	1 )	-- ������������ ��� FK � �������� DataLog_*, ����� �������, ��� �� ���� �������� ������� DataLog_* ����� ���� ��������� ��������� ���
	,Execution		damit.TId		null		-- ������������ ������ ��� �����������? ��������, ������ � �������� ExecutionLog.Id, ����� ������������ ����� ������� ������� � �������� �� ����� cte; ��-�� identity ��� not null ������ �������� ������ ������
	,Distribution		damit.TIdSmall		not null	-- ������� ��������
	,Sequence		damit.TIntegerNeg	not null
	,Start			damit.TDateTime		not null	constraint	DdamitExecutionLogStart	default	getdate()	-- ��������, ������ ���������� ����- ������� � ������ ������ ����
	,Finish			damit.TDateTime		null		-- ��������, ����� ���������� ����- ������� � ������ ���������� ����
	,ErrorCode		damit.TIntegerNeg	null		-- ��� ������, 0=��� ������, <0=������-������������� �������� ����������, >0=��� ������, �� ����� ���� ��������� hint/warning/information
	,Message		damit.TNote		null		-- ��������� � ��������� ��������
constraint	PKdamitExecutionLog		unique	clustered	( Id )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary"
,constraint	FKdamitExecutionLogExecution	foreign	key	( Execution )		references	damit.ExecutionLog	( Id )
,constraint	FKdamitExecutionLogDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
,constraint	�KdamitExecutionLog1		check	(	Finish	is		null
							or	Finish	is	not	null	and	Execution	is	not	null )
,constraint	UQdamitExecutionLog1		unique	( Distribution , Start )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary"	-- ���� � ���� ����� �������� ��� �������� � ����������� ���������� ���������������, �� �� ����, ����� ��������� ���� �������
,constraint	UQdamitExecutionLog2		unique	( Execution,	Sequence )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary" )
--check	Start<=	Finish	-- ������, �.�. windows time ����� �������� ����� � ������ ������ ��������
----------
--create	clustered	index	IXdamitExecutionLog	on	damit.ExecutionLog	( Start )	on	"Primary"
----------
/*
����������� ���������� �����= (Task=Distribution) � �������� goto �� ��� ������
��� Condition=true ���������� � ���� �����, ��� Condition=false- �� ��������� ����� ����� Task
����������� �� ��������� damit.Variable.Sequence (�� ����������� ������ �� �������) ������������ �������� � ������� sign('Step'); +'Step' ������ ��-�� ��������� ��������� � ��������� damit.Variable.Sequence
��������� ���� ForEach ���������� � ����� ���� damit.Variable.Sequence
	'Begin'		��� �������� ��� ����, ������ � ������ �������� ������ 'Current'?
	'End'
	'Step'		�����, ����� ������ ����������� ������ ��� ��� For, ��� � ��� ForEach
	'Current'
	*damit.Variable.Alias(��� Sequence is not null)- ���� ��� �� ������, �� ������� �������� �����- 'Current'. ��� ����� ����� �������������� ������������ ������ ��������������?

��������� 'IsCurrent' ��� ����������:
-� ���� Condition: ��� Condition ��������� �� ���������� � ������������� ������ 'ForEach' ��� ����������� �� � ��������� ����� � ���������� ������� � ���
-��� ���� Condition: ���������� ��� Condition, ������� ��������� �� ���������� � ������������� ������ 'ForEach' � ������ �� ��������� ���������� 'IsCurrent' ��� ����������� �� � ��������� ����� � ���������� ������� � ���


����� �� ����������� ������������ ������� ������� ����� damit.Variable.IsCurrent+damit.Parameter.Value ������ ������������ �������� ����� damit.Variable.Value?

������� ������- damit.Variable: .Sequence is not null and .Value is null ��� �������� Alias � ������ Sequence, damit.Parameter: .Sequence is not null and .Value is not null
*/
create	table	damit.Variable			-- ������� ������������ ����������
-- Task-� ��������� ���� ���������� ����� ����������, ������� ���������� ����� ������ �� ���� Sequence ������� Alias
-- ???��������� � ��������� ���� �� ����������� ���� ���������� �������������� �������

-- ����������: ��������� ���, ���� �� Task ���� ��������� �����

/*Alias:
Data(DataSet)		�������
Format(FileName)	����, ��� ������ ������������ Sequence
*/
--������ ��� ����� �����-damit.Condition- ���� ��� ��������� damit.Variable.Value � ���������� Alias � ��������������� Sequence is not null
-- ��� Execution=root ������������ Value ��� ���������� ����������?
-- FILESTREAM ����� �������� damit.DoSaveToXML � �������������� ��������� ��������� ������� �� damit.DoScript � ������������� ��������� � damit.DoSave
(	Id			damit.TGUID		not null	rowguidcol	constraint	DdamitVariableId	default	newid()
	,ExecutionLog		damit.TId		/*not */null	-- ������� ��������� ����������, null=��������, ��� ���������� ���������
	,Alias			damit.TName		not null	-- �������� ����������, ����� ������� ����� ���������� �������� ����� Task
	,Value			sql_variant		null		-- ����������, ��������, �������� �������/view � ���������� ���������- ������ ����� ���� ������ ����� ���� ���������������� � ��������� ����
	,Sequence		damit.TIntegerNeg	null		-- �����������, ���� � ����� ��������� ��������� ����������; null=���� Alias ������ ����������� ������ ���� ���, �.�. �� ������ �������������� � Sequence<>null
	,Moment			damit.TDateTime		not null	constraint	DdamitVariableMoment	default	getdate()	-- ������ ��������� ���������� � ��������, ������ ��� ����������� �����
	,ValueBLOB		varbinary ( max )	FILESTREAM	null	-- ��� BLOB, ��������, ������
	,IsCurrent		damit.TBool		null		-- ��� ������ �������� �������� 'ForEach' ���������� �� ���������� �������, ���� ��� ��������� � �����
	,UQorNull		as	isnull ( convert ( binary ( 16 ),	nullif ( IsCurrent,	0 ) ),	convert ( binary ( 16 ),	Id ) )	persisted	not null	-- ��������� ��� Id
	--Id			damit.TIdBig		not null	identity ( 1,	1 )	-- ������ ��� ��������� constraint
	--,UQorNull		as	isnull ( convert ( binary ( 8 ),	nullif ( IsCurrent,	0 ) ),	convert ( binary ( 8 ),		Id ) )	persisted	not null	-- ��������� ��� Id
--,constraint	PKdamitVariable			primary	key	clustered	( Id )
,constraint	PKdamitVariable			primary	key	nonclustered	( Id )
,constraint	FKdamitVariableExecutionLog	foreign	key	( ExecutionLog )	references	damit.ExecutionLog	( Id )
,constraint	UQdamitVariable			unique	( ExecutionLog,	Alias,	Sequence )
,constraint	UQdamitVariable1		unique	( ExecutionLog,	Alias,	UQorNull )	)
--,constraint	DFdamitVariable			default	getdate()	for	Moment	-- �� 2008R2 �������� �� ��������������
--,constraint	CKdamitVariable			check	( Value	is	null	or	ValueBLOB	is	not	null )	-- ������ ����� �������?
----------
CREATE	clustered	index	IXdamitVariable01	on	damit.Variable	( Moment )
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'����������(��������������� ������������) ��� �������� ������ ����� ������'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Variable'
----------
rollback
--commit
go
use	tempdb