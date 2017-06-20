use	tempdb
go
if	db_id ( 'damit' )	is	not	null
	drop	database	damit
go
create	database	damit
go
use	damit
go
begin	tran

go
create	schema	damit	-- Da(ta) Mi(gration) T(asks)
go
-- ���� ��������� ��������� ����
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
create	type	damit.TDelimeter	from	varchar ( 36 )		null		-- ����� ��������� guid � ��������� ����
--create	type	damit.TBLOB	from	varbinary(max)	null
----------
go
create	rule	damit.RPositive	as	@oValue>=	0
go
create	rule	damit.RBool	as	@iValue	in	( 0,	1 )
----------
go
create	default	damit.DGUID	as	newid()						/* ������ ��� PK ����� */
go
----------
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
(	Id			damit.TGUID		not null
	,Name			damit.TName		not null
--	,Type			damit.TName		not null	-- cmd,sql
	,Get			damit.TScript		null
	,Put			damit.TScript		null

	,Subsystem		nvarchar ( 40 )		not null	-- ������������ ��������� �� msdb.dbo.syssubsystems, ��������- TSQL, ActiveScripting(��� .vbs), CmdExec, SSIS
	,FileName		damit.TFileName		null		-- null=��������� ��� ���������� ��� ����=��������� ����� �����������, ����� ������������ ��� �������
	,Folder			damit.TFileName		null		-- � ����� ������� ��������� ���������, ��������, ��� ��������� ������ .exe
	,Command		damit.TScript		not null	-- ����� �������, ��������, � ���������; ��������, ����� .cmd �����(��������������� ����������� FileName) � ����������� ��������� ������
,constraint	PKdamitScript		primary	key	nonclustered	( Id )
,constraint	CKdamitScript		check	(	FileName	is	not	null
						or	Command		is	not	null ) )	-- ��������� ��, ��� ���������, ���� ��������� ���, �� ��������� Command � FileName, ���������, ����� ������� FileName
----------
	create	table	damit.SMTP	-- ������� SMTP �������� � ������ ����������� �������������
	-- ���� ����� ������� �� ������� ������������, �� �������� ����� �������
	(	Id			damit.TGUID		not null
--		,Script			damit.TGUID		null
		,Server			damit.TExtName		not null
		,Proxy			damit.TExtName		null
		,WindowsAuthentication	damit.TBool		not null	-- �������� ����������� ��� ���
		,SSL			damit.TBool		not null
		,Login			damit.TExtName		null		-- ����� ��� �������� ����������� ��� anonymous
		,Password		damit.TName		null
	constraint	PKdamitSMTP		primary	key	nonclustered	( Id )/*
	,constraint	FKdamitSMTPScript	foreign	key	( Script )	references	damit.Script	( Id )*/	)
----------
	create	table	damit.Email	-- ��������� ������� email
	(	Id			damit.TGUID		not null
		,SMTP			damit.TGUID		not null
		,[From]			damit.TExtName		null
		,[To]			varchar ( 1024 )	not null
		,Cc			varchar ( 1024 )	null
		,Bcc			varchar ( 1024 )	null
		,Subject		varchar ( 1024 )	null
		,Body			ntext			null
		,IsHTML			damit.TBool		null
		,CanBlank		damit.TBool		not null	-- �������� ������ ��� ��������
--		,Attachment		image			null		-- ��� �� ������ ���� � ������������ � ������
	constraint	PKdamitEmail		primary	key	nonclustered	( Id )
	,constraint	FKdamitEmailSMTP	foreign	key	( SMTP )	references	damit.SMTP	( Id )	)
----------
	create	table	damit.SFTP	-- ��������� SFTP ��������
	(	Id			damit.TGUID		not null
		,Script			damit.TGUID		null		-- ������ �������� �� ���� ������ ��� ������ � ���� �����
		,Server			damit.TExtName		not null
		,Port			damit.TInteger		null
		,Login			damit.TExtName		null
		,Password		damit.TPassword		null
		,PrivateKey		damit.TFileName		null		-- ���� � ������ ����� �����
		,Path			damit.TFileName		null		-- ���� � ������� ����� �� �������
		,RetryAttempts		damit.TInteger		not null
	constraint	PKdamitSFTP		primary	key	nonclustered	( Id )
	,constraint	FKdamitSFTPScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
	create	table	damit.FTPS	-- ��������� FTPS ��������
	(	Id			damit.TGUID		not null
		,Script			damit.TGUID		null		-- ������ �������� �� ���� ������ ��� ������ � ���� �����
		,Server			damit.TExtName		not null
		,Port			damit.TInteger		null
		,Login			damit.TExtName		null
		,Password		damit.TPassword		null
		,Path			damit.TFileName		null		-- ���� � ������� ����� �� �������
		,RetryAttempts		damit.TInteger		null
	constraint	PKdamitFTPS		primary	key	nonclustered	( Id )
	,constraint	FKdamitFTPSScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
	create	table	damit.Folder	-- �������� ��������, ��������, UNC ��� �� ��������� �����
	(	Id			damit.TGUID		not null
		,Script			damit.TGUID		null		-- ������ ����������� ����� � ���� ������� ��� �� ����� ��������
		,Path	 		damit.TFileName		not null
	constraint	PKdamitFolder		primary	key	nonclustered	( Id )
	,constraint	FKdamitFolderScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
create	table	damit.ProtocolEntity
-- �� ������ �� ���� ������ ����� �������, ��������� ��� �������������� TF
(	Id		damit.TGUID		not null,
	Email		damit.TGUID		null,
	SFTP		damit.TGUID		null,
	FTPS		damit.TGUID		null,
	Folder		damit.TGUID		null,
constraint	PKdamitProtocolEntity		primary	key	nonclustered	( Id ),
constraint	FKdamitProtocolEntityEmail	foreign	key	( Email )	references	damit.Email	( Id ),
constraint	FKdamitProtocolEntitySFTP	foreign	key	( SFTP )	references	damit.SFTP	( Id ),
constraint	FKdamitProtocolEntityFTPS	foreign	key	( FTPS )	references	damit.FTPS	( Id ),
constraint	FKdamitProtocolEntityFolder	foreign	key	( Folder )	references	damit.Folder	( Id ),
constraint	CKdamitProtocolEntity		check	( Id=	isnull ( convert ( varbinary ( 16 ),	Email ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	SFTP ),		0x )+
								isnull ( convert ( varbinary ( 16 ),	FTPS ),		0x )+
								isnull ( convert ( varbinary ( 16 ),	Folder ),	0x ) )	)
----------
create	table	damit.Storage		-- ������� ������ �������� ������
--.csv,.txt,.xml,.xls
--���� ��� .xml, �� ��� ������� .xsd- ������ ��� ��������
-- �� ���� ���������� ����� ����� ����� ��������� ��������, ������������� ������ ���������
(	Id		damit.TGUID		not null
	,Script		damit.TGUID		null		-- ������ ��������� �������� ��� �������� �������
	,Name		damit.TName		not null	-- �� ���� ���������� ����� ����� ���� ��������� ��������
	,Extension	damit.TFileName		not null	-- ���������� �����
	,Saver		damit.TSysName		null		-- ��������� �������� � ���� ����� �������
	,Loader		damit.TSysName		null		-- ��������� �������� �� ����� ����� �������
--	,Purifier	damit.TSysName		null		-- ������� ������ ���������� ��������, ������� ������ �� ������� � ������ �� �� ����?
constraint	PKdamitStorage		primary	key	nonclustered	( Id )
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
--.csv,.txt,.xml,.xls
--���� ��� .xml, �� ��� ������� .xsd- ������ ��� ��������
-- �� ���� ���������� ����� ����� ����� ��������� ��������, ������������� ������ ���������
(	Id		damit.TGUID		not null
	,Storage	damit.TGUID		not null
	,Name		damit.TName		not null
	,FileName	damit.TFileName		not null	-- ������/������ ����� ���������� �������, ��������, ������� ���� � ����������
	,CanBlank	damit.TBool		not null	-- ��������� ��������� �����(��������, ������ �����) ��� �����������
,constraint	PKdamitFormat		primary	key	nonclustered	( Id )
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
(	Id		damit.TGUID		not null
	,Alias		damit.TName		not null	-- �������� ��������� ��� ����������
,constraint	PKdamitQuery		primary	key	nonclustered	( Id )
,constraint	UQdamitQuery		unique	( Alias )
/*,constraint	CKdamitQuery		check	( object_id ( Alias )	is	not	null )*/	)
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

(	Id		damit.TGUID		not null
	,Distribution	damit.TGUID		not null
	,FilePath	damit.TFileName		null		-- ����� ������� ��� ���� ��������, � �������� ����� ���� ��������� ������� �������� ������
	,Name		damit.TName		not null
constraint	PKdamitBatch			primary	key	nonclustered	( Id )
constraint	FKdamitBatchDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id ) )*/
----------
create	table	damit.Data		-- �������� ��������
-- ��� ������ ��� ������������� ������� ���������� ���������� ������- �������� ���� counter ��� ������������� � ������� ����� ������������ � ����� �����?
-- ��� ������ � �������� �������, ���� ���������� ������ ���������� ������?
-- ���������� ��������� ������������� ��������� ������, ���� ������ ������� �� view, � �� �� ���������
-- � ��������� �������� ��������� �������� ����, ����� ����� ����� �������� �� ����� ���� � object_id ����� �������� ���������
-- ����� �������������� ������� ��������� ����� ���������� ����� �������������� � ���������� ���������� ��������� �������
-- �������� ��: ��������� � ����� �����- Target, ����� �������- Filter, ������� ���������� �������- FieldSort
-- ������������� �������� ��� ������������ ���������� �������� ������ �� ������������� ������ ���� �������, ������ ����� ����������� ����������� �������� � damit.DataData
-- ?��� ����� ��������, ��� ������� ���������� ���������� ����������� ��������� ����������, �.�. ������������� ���� ����������- �� ����� � ����� �������� ������������� ���� ������???
--,Pattern	damit.TSysName		null		-- ��������� view, null=���� ������ ������� �� �� ���������, � �� view, �� ����� �� ���� ������� ������ ��� ��������� �������, ��� _�������_ �������� ��������� �������, ����� ��� ���� �� ������������, ����� �������������� ��� ���������� linked server\jet\schema.ini
(	Id		damit.TGUID		not null
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
,constraint	PKdamitData		primary	key	nonclustered	( Id )	)
----------
create	table	damit.DataField		-- ���� ��������
(	Id		damit.TGUID		not null
	,Data		damit.TGUID		not null
	,FieldName	damit.TSysName		not null	-- ��� ������������� ���� ��� �������� ������ ����(�������� ������������ � ������������) �� ��������� Value
	,Value		damit.TScript		null		-- ������ �������� ����, ��������, ��� ����������� ���������� �� ������ ���������������� �������

	,IsRelationship	damit.TBool		not null	-- ���� �������������� ������ � ���������� �������� ��������(view)
	,IsComparison	damit.TBool		not null	-- ���� ��� ����������� ���������, ������������ �� checksum
	,IsResultset	damit.TBool		not null	-- ���� ���������� ������
	,IsList		damit.TBool		not null	-- ���� �� ������ ������� ���������� ��� ��������� �� ����� ���������; ���� ��� ���������� �� ������ ���������������, ���� ����� ��������� � IsRelationship
	,IsDate		damit.TBool		not null	-- ���� �� ������ ������� ���������� ��� ��������� �� ����� ���������; ���� ���� ������ � ���������� �������� ��������(view), ��������, ���� ��������� ������
	,Sort		damit.TIntegerNeg	null		-- ����������� �� abs(Sort), ������������� �������� �������� order by desc
	,Sequence	damit.TInteger		not null	-- � ���� ������� ���� ���� IsResultset � �������� ������; ������� ������������������ +1 �� �����������
constraint	PKdamitDataField	primary	key	nonclustered	( Id )
,constraint	FKdamitDataFieldData	foreign	key	( Data )	references	damit.Data	( Id )
,constraint	UQdamitDataField	unique		( Data,	FieldName )
,constraint	UQdamitDataField1	unique		( Data,	Sequence )	)
----------
create	table	damit.DataData		-- ����������� ������ �������� ���� �� �����
-- ���� ��������(2) ������� �� ������(1), ��� ������, ��� ��� �������� ��������� � (2) ����������� ������ � ����� (1)
-- ��� ����������� �������� ������ �����, �������, ���� ��� �������� ��� ������ (1)=(1) ��� �� ������������ ��������� � ������ �������� ������ ����� ������
-- �������� �������� ����� �������� �� ������ ������, �� �� �� ����� �������� ������ �������� ��������, �� �� ������
-- �������� ������ ������������ ����� ����� cte
-- ����� �� ������ ����������� Distribution � ������� Data? � ��������, ��� ������������� ����� ������ ������ ��������������� �� ����� �������
(	Id		damit.TGUID	not null
	,Data1		damit.TGUID	not null	-- �������
	,Data2		damit.TGUID	not null	-- ���������
	,IsClosed	damit.TBool	not null	-- ��� ����� ����������� �� �������������, ������������ ������ ��������� � ���� ������ ������, �� �� ��� ��������/�����������
constraint	PKdamitDataData		primary	key	nonclustered	( Id )
,constraint	FKdamitDataDataData1	foreign	key	( Data1 )	references	damit.Data	( Id )
,constraint	FKdamitDataDataData2	foreign	key	( Data2 )	references	damit.Data	( Id )
,constraint	UQdamitDataData		unique	( Data1,	Data2 )	)
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'����������� ������ �������� ���� �� �����'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'DataData'
----------
create	table	damit.Condition		-- ���������� ��� sql WHERE �������
-- ������� ���� (a=1 and (b=2 or c=3))
(	Id		damit.TGUID	/*identity ( 1,	1 )*/	not null	-- ��������� ��� � UQorNull
	,Parent		damit.TGUID	null		-- ������ ��� ������
	,FieldName	damit.TSysname	null
	,Operator	varchar ( 16 )	not null	-- �������� ��������� ��� ����� � ������ � ����������� ���������, �.�. ������ ������ ������ ���� ���������� ��������
	,Value		sql_variant	null		-- ����� ���� �������� FieldName?
	,Sequence	smallint	null		-- ������� ���������� ������ ������, �� ����� 32787 ������� � (); null=root
	,UQorNull	as	isnull ( convert ( binary ( 16 ),	Sequence ),	convert ( binary ( 16 ),	Id ) )	persisted	not null	-- ��������� ��� Id
,constraint	PKdamitCondition	primary	key	clustered/*�� ����*/	( Id )
,constraint	FKdamitCondition	foreign	key	( Parent )	references	damit.Condition	( Id )
,constraint	UQdamitCondition	unique	( Parent,	UQorNull )
,constraint	CKdamitCondition1	check	(	Operator	in	( '=',	'<>',	'>',	'>=',	'<',	'<=',	'like',	'not like' )	and	FieldName	is	not	null	and	Value		is	not	null
						or	Operator	in	( 'and',	'or' )							and	FieldName	is		null	and	Value		is		null )
,constraint	CKdamitCondition2	check	(	Operator	in	( '=',	'and',	'or' )
						or	Value	is	not	null ) )	-- =null->is null
----------
create	table	damit.Layout	-- ��� ������ ������ ����� ��� SELECT/FROM/WHERE/ORDER_BY ������� � ��������� � ��������
-- ������� ������� damit.Data, �� ��� �������� � � ���������- ������ ����� � ���������, � �� ��� ResultSet � DataLog
-- ?����� �� ��������� ���������� ������� ��� ��� ������ ������?
-- ������� ��������� excel ����� �� ������, �.�. � �� 3 ������ �������- ��� 3 ������, � �� 3 ����
-- FileName ��������� ��������������� � �����, �������, ��� ����� ���
(	Id		damit.TGUID		not null
	,Target		damit.TSysName		not null	-- ��������, view ��� DataLog_* ������� � ExecutionLog �����������
/*?*/	,Filter		damit.TSysName		null		-- ��������, � ExecutionLog �����������, join �� �������� ����?
/*?*/	,Refiner	damit.TSysName		null		-- ��� ������������ ��������� ����� ��� ����?
/*?*/	,CanBlank	damit.TBool		not null	-- ��������� �� ���� � 0 �������, ��������, ������ �� ��������� � ������
/*?*/	,Delimeter	damit.TDelimeter	null		-- ����������� ��� ������ ����� �� � SQL �������
	,Name		damit.TName		not null
,constraint	PKdamitLayout	primary	key	nonclustered	( Id )
,constraint	UQdamitLayout	unique	( Name )	)
----------
create	table	damit.LayoutField	-- ������ ����� ��������
-- ������� ������� damit.DataField
-- ��� ������� ����, �� ������� ������� ������� ����������?
(	Id		damit.TGUID		not null
	,Layout		damit.TGUID		not null
	,FieldName	damit.TSysName		not null
	,DataType	damit.TSysName		null		-- null=�� ��������� �� Layout.Target
	,Expression	damit.TScript		null		-- ���������� damit.DataField.Value
	,IsRelationship	damit.TBool		not null	-- ������ ����� �������� ����� ������� unique, ��������, �� ��������� �������, ���� ��� �� ��������� � �������?
	,IsResultset	damit.TBool		not null	-- ��� ���� ������ ������� � ResultSet
	,Sort		damit.TIntegerNeg	null		-- ������� ����������, ��� 0< ���������� DESC
	,Sequence	damit.TInteger		not null	-- ������� ����� � ResultSet
,constraint	PKdamitLayoutField		primary	key	nonclustered	( Id )
,constraint	FKdamitLayoutFieldLayout	foreign	key	( Layout )	references	damit.Layout	( Id )
,constraint	UQdamitLayoutField1		unique	( Layout,	FieldName )
,constraint	UQdamitLayoutField2		unique	( Layout,	Sequence )	)
----------
create	table	damit.TaskEntity
-- �� ������ �� ���� ������ ����� �������, ��������� ��� �������������� TF
(	Id		damit.TGUID		not null
	,Data		damit.TGUID		null
	,Query		damit.TGUID		null
	,Format		damit.TGUID		null
	,Protocol	damit.TGUID		null
	,Script		damit.TGUID		null
	,Condition	damit.TGUID		null
	,Layout		damit.TGUID		null
	,Distribution	damit.TGUID		null
,constraint	PKdamitTaskEntity		primary	key	nonclustered	( Id )
,constraint	FKdamitTaskEntityData		foreign	key	( Data )		references	damit.Data		( Id )
,constraint	FKdamitTaskEntityQuery		foreign	key	( Query )		references	damit.Query		( Id )
,constraint	FKdamitTaskEntityFormat		foreign	key	( Format )		references	damit.Format		( Id )
,constraint	FKdamitTaskEntityProtocol	foreign	key	( Protocol )		references	damit.ProtocolEntity	( Id )
,constraint	FKdamitTaskEntityScript		foreign	key	( Script )		references	damit.Script		( Id )
,constraint	FKdamitTaskEntityCondition	foreign	key	( Condition )		references	damit.Condition		( Id )
,constraint	FKdamitTaskEntityLayout		foreign	key	( Layout )		references	damit.Layout		( Id )
--,constraint	FKTaskEntityDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
,constraint	CKdamitTaskEntity		check	( Id=	isnull ( convert ( varbinary ( 16 ),	 Data ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	 Query ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	 Script ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	 Format ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	 Protocol ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	 Distribution ),0x )+
								isnull ( convert ( varbinary ( 16 ),	 Condition ),	0x )+
								isnull ( convert ( varbinary ( 16 ),	 Layout ),	0x ) )	)
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'�������� ����� ������� ����������� �� ����'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'TaskEntity'
----------
create	table	damit.Distribution	-- ��� ��������� ��������������� ������
-- ��� ����� ���� ���������� �� ��������� � �������� �/��� ��� ����� ������������ ��� ��������� ����������; ��� ��� ����������� ��������� �� ������ �����, ����� ��� ��� ���������, � �� ��������?
-- ��� �������� ��������� �� �����������(��������������, �� �����������) ���� ��� ������������� ���������?
--	Condition	int		null		-- ������� ��������, null=����������� �������
--,constraint	FKdamitDistribution1	foreign	key	( Condition )	references	damit.Condition	( Id )
(	Id		damit.TGUID		not null
	,Node		damit.TGUID		null		-- null=����� ������ ���
	,Task		damit.TGUID		null		-- null=���, ��������, ��� ��������� ���������� ����� � ���� �����, null=��� ��������� ����������� ���������� ��� ��������� �������� �� ����
	,Name		damit.TName		null		-- ��������
	,Sequence	damit.TInteger		not null	default	( 0 )	-- ������� �������� ��� ������������� ��������; ���� ����������, �� ��������� ����������� � ����������, ���� ������, �� ������� ����� �����, ���� ������ ���� �� ��������� �����="�������"
,constraint	PKdamitDistribution		primary	key	nonclustered	( Id )
,constraint	FKdamitDistributionNode		foreign	key	( Node )	references	damit.Distribution	( Id )
,constraint	FKdamitDistributionTask		foreign	key	( Task )	references	damit.TaskEntity	( Id )
,constraint	UQdamitDistribution1		unique	( Node,	Task )	-- ��������� ������������, ����� �� ��� ������������, ��������, ��� �������������� Sequence?
--,constraint	UQdamitDistribution2		unique	( Node,	Sequence )
,constraint	CKdamitDistribution1		check	( Id<>	Task )	-- ��������� ������������
,constraint	CKdamitDistribution2		check	(	Task	is	not	null
							or	Name	is	not	null )	)
----------
alter	table	damit.TaskEntity	add
constraint	FKdamitTaskEntityDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
----------
create	table	damit.ExecutionLog	-- ��� ����������� �����
-- ����� ������� ��� �������� �����
-- ��������������� �� ��� �/��� ��������� �� ������ ������, ���������� ����� ������ �� �������� ���������� ����������� ������, ��� ������ ������� ����, ��� ������ ���������
-- ���� ��� ������� ���������� �� AND, �� �������������� ���������� �� �������� ������� �������� � ����� ����� ������� �������� ��� �������������� �������, ����� �������� ������� � ������������ ���������
-- ��������� ��������� ����� ���� ��������� ����������� ��������=������� ������� ����� ������� ����������
-- ����� �������� �����?
-- ���������(�� �������, sequence ��� ��� ���?) ExecutionLog.Id ��������� ������������� � ������ ������?
(	Id			damit.TGUID		not null	-- ������������ ��� FK � �������� DataLog_*, ����� �������, ��� �� ���� �������� ������� DataLog_* ����� ���� ��������� ��������� ���
	,Execution		damit.TGUID		not null	-- ������������ ������ ��� �����������? ��������, ������ � �������� ExecutionLog.Id, ����� ������������ ����� ������� ������� � �������� �� ����� cte
	,Distribution		damit.TGUID		not null	-- ������� ��������
	,Sequence		damit.TIntegerNeg	not null
	,Start			damit.TDateTime		not null	-- ��������, ������ ���������� ����- ������� � ������ ������ ����
	,Finish			damit.TDateTime		null		-- ��������, ����� ���������� ����- ������� � ������ ���������� ����
	,ErrorCode		damit.TIntegerNeg	null		-- ��� ������, 0=��� ������, <0=������-������������� �������� ����������, >0=��� ������, �� ����� ���� ��������� hint/warning/information
	,Message		damit.TNote		null		-- ��������� � ��������� ��������
constraint	PKdamitDistributionLog			unique	nonclustered	( Id )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary"
,constraint	FKdamitExecutionLogExecution		foreign	key	( Execution )		references	damit.ExecutionLog	( Id )
,constraint	FKdamitDistributionLogDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
,constraint	UQdamitDistributionLog			unique	( Distribution , Start )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary"	-- ���� � ���� ����� �������� ��� �������� � ����������� ���������� ���������������, �� �� ����, ����� ��������� ���� �������
,constraint	UQdamitExecutionLog			unique	( Execution,	Sequence )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary" )
--check	Start<=	Finish	-- ������, �.�. windows time ����� �������� ����� � ������ ������ ��������
----------
create	clustered	index	IXdamitExecutionLog	on	damit.ExecutionLog	( Start )	on	"Primary"
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

/*
������ ����� ������ dbo.Replacement+dbo.ReplacementValue :
	damit.Variable
	damit.Parameter
	left join ����� �������
*/

(	Id			damit.TGUID		not null
	,Source			damit.TGUID		null		-- FK(damit.Parameters.Id) ������ ������������ ���� �� �������� DistributionRoot, ����� ��������� �������������; ������������� ������ �� ���� �������, ��� ���������� ��������; ���������������� � �� ��������� ������ ����� damit.Variable. ������ �� damit.Parameter.Id, � �� DistributionStep, ������� ����� ������������ ������� � ��� �������� ����������� �������� DistributionRoot
	,DistributionRoot	damit.TGUID		null		-- ��� ����������� ���������� ������������� �������� � ������� ����������� ��� ������ DistributionRoot, ��� null=��� ���� ��������; ������ DistributionRoot ������ DistributionStep ����� ���� ����������� ������ 1 ���
	,DistributionStep	damit.TGUID		not null	-- ��� ������ ���� ��������
--	,Condition		damit.TGUID		null		-- XML ������� (��� ��������?) ��� ���������. ��� join ���� �� damit.Data ������ Distribution �����, ���� ���� ��������� Data ������ ��������� Distribution?
	,Alias			damit.TName		null		-- �������� ���������, null= �������� �� Source, ���� ����� � Alias � Source, �� Alias ������������ ������(��� ����������� ��������������), � �������� ������
	,Value	sql_variant	/*damit.TBLOB*/		null		-- ����������� �������� ���������, ��� null ������ ������, ��� ����������� �������� ��� �������� �������� Source
	,Expression		damit.TScript		null		-- SQL ��������� ��� ������� ��� �������������� Value, � �������, ���������� ��� ���� � SELECT. ������ �� ������� ����� ����, �������� ������������, ��������, ������������� ��������
--	,IsStatic		damit.TBool		not null	-- ������������ �������� �� ���� ������� ������ damit.Variable
	,Sequence		damit.TIntegerNeg	null		-- ������� ����������, ���� � ����������������� ���������, ������ ������ �� ��� � Value- ���� ���������� � ����� ��������� ���������, ���� ����� ����� � �������� � ����� ������ ����, �� ��� ���������� ���������� ����� ����������, ��������, �������� ������ � email
,constraint	PKdamitParameter			primary	key	nonclustered	( Id )
,constraint	FKdamitParameterSource			foreign	key	( Source )		references	damit.Parameter		( Id )
,constraint	FKdamitParameterDistributionRoot	foreign	key	( DistributionRoot )	references	damit.Distribution	( Id )
,constraint	FKdamitParameterDistributionStep	foreign	key	( DistributionStep )	references	damit.Distribution	( Id )
--,constraint	FKdamitParameterCondition		foreign	key	( Condition )		references	dbo.Condition		( Id )
,constraint	UQdamitParameter1			unique		( DistributionRoot,	DistributionStep,	Alias,	Sequence )	-- DistributionRoot ����� ��������� �������� ������ ��������� ��� ������ ����, ����������� � �������� �������

-- �������� Expression � check

,constraint	CKdamitParameter1			check	(	(	Source		is	not	null
									or	Alias		is	not	null )
								and	(	Source		is		null
									or	Value		is		null )
								and	(	Alias		is	not	null
									or	Value		is		null )
								and	(	Alias		is	not	null
									or	Sequence	is		null )	)	)
/*,constraint	CKdamitParameterN			check	(	Condition	is		null	and	Alias	is	not	null
								or	Condition	is	not	null	and	Alias	is		null )*/
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'���������� ������������� ���������� � ���������� ��� �������� � ����������������� �������� ����������'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Parameter'
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
-- ���� ������������ ��� ��������� �������
-- Task-� ��������� ���� ���������� ����� ����������, ������� ���������� ����� ������ �� ���� Sequence ������� Alias
-- ???��������� � ��������� ���� �� ����������� ���� ���������� �������������� �������

-- ����������: ��������� ���, ���� �� Task ���� ��������� �����

/*Alias:
Data(DataSet)		�������
Format(FileName)	����, ��� ������ ������������ Sequence
*/
--������ ��� ����� �����-damit.Condition- ���� ��� ��������� damit.Variable.Value � ���������� Alias � ��������������� Sequence is not null
(	Id			damit.TGUID		not null
	,Execution		damit.TGUID		/*not */null	-- ������� ��������� ����������, null=��������, ��� ���������� ���������
	,Alias			damit.TName		not null	-- �������� ����������, ����� ������� ����� ���������� �������� ����� Task
	,Value			sql_variant		null		-- ����������, ��������, �������� �������/view � ���������� ���������- ������ ����� ���� ������ ����� ���� ���������������� � ��������� ����
	,Sequence		damit.TIntegerNeg	null		-- �����������, ���� � ����� ��������� ��������� ����������; null=���� Alias ������ ����������� ������ ���� ���, �.�. �� ������ �������������� � Sequence<>null
	,Moment			damit.TDateTime		not null	default	getdate()	-- ������ ��������� ���������� � ��������, ������ ��� ����������� �����
	,ValueBLOB		image			null		-- ��� BLOB, ��������, ������
	,IsCurrent		damit.TBool		null		-- ��� ������ �������� �������� 'ForEach' ���������� �� ���������� �������, ���� ��� ��������� � �����
	,UQorNull		as	isnull ( convert ( binary ( 16 ),	nullif ( IsCurrent,	0 ) ),	convert ( binary ( 16 ),	Id ) )	persisted	not null	-- ��������� ��� Id
,constraint	PKdamitVariable			primary	key	nonclustered	( Id )
,constraint	FKdamitVariableExecution	foreign	key	( Execution )	references	damit.ExecutionLog	( Id )
,constraint	UQdamitVariable			unique	( Execution,	Alias,	Sequence )
--,constraint	DFdamitVariable			default	getdate()	for	Moment	-- �� 2008R2 �������� �� ��������������
,constraint	UQdamitVariable1		unique	( Execution,	Alias,	UQorNull )	)
--,constraint	CKdamitVariable			check	( Value	is	null	or	ValueBLOB	is	not	null )	-- ������ ����� �������?
----------
CREATE	clustered	index	IXdamitVariable01	on	damit.Variable	( Moment )
/*
----------
alter	table	damit.Variable	add
-- ��� Execution=root ������������ ValueEx ��� ���������� ����������?
	ValueEx	varbinary ( max )	null	-- ����� �������� damit.DoSaveToXML � �������������� ��������� ��������� ������� �� damit.DoScript � ������������� ��������� � damit.DoSave
,constraint	CKdamitVariable	check	(	Value	is	not	null	and	ValueEx	is		null
					or	Value	is		null	and	ValueEx	is	not	null )
*/
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