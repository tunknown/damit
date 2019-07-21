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
-- типы данных поддержки единости структур базы
create	type	damit.TIdBig		from	bigint			null		-- i
create	type	damit.TId		from	int			null		-- i
create	type	damit.TIdSmall		from	smallint		null		-- i
create	type	damit.TIdTiny		from	tinyint			null		-- i
create	type	damit.TGUID		from	uniqueidentifier	null		-- g
create	type	damit.TName		from	varchar ( 256 )		null		-- s
create	type	damit.TNName		from	nvarchar ( 256 )	null		-- s/su
create	type	damit.TInteger		from	int			null		-- i
create	type	damit.TIntegerNeg	from	int			null		-- i
create	type	damit.TBool		from	tinyint			not null	-- i тип bit неудобен при использовании в индексах
create	type	damit.TBoolean		from	bit			not null	-- b
create	type	damit.TExtName		from	varchar ( 256 )		not null	-- s	названия сторонних объектов, например, серверов
create	type	damit.TSysName		from	nvarchar ( 256 )	not null	-- s/su	объект SQL сервера без проверки существования
create	type	damit.TFileName		from	nvarchar ( 260 )	null		-- s/su	например, путь в файловой системе
create	type	damit.TPassword		from	varchar ( 128 )		null		-- s
create	type	damit.TNote		from	varchar ( 256 )		null		-- s
create	type	damit.TТNote		from	nvarchar ( 256 )	null		-- s
create	type	damit.TMessage		from	varchar ( 256 )		null		-- s
create	type	damit.TScript		from	nvarchar ( max )	null		-- s
create	type	damit.TDateTime		from	datetime		null		-- dt
create	type	damit.TScriptShort	from	nvarchar ( 4000 )	null		-- s	например, для xp_cmdshell
create	type	damit.TSystemName	from	nvarchar ( 1024 )	null		-- s	full qualified object name= len(sysname)*4+len('.')*4+len('[]')*len(sysname)*4
create	type	damit.TDelimeter	from	varchar ( 36 )		null		-- чтобы уместился guid в текстовом виде для заведомой уникальности разделителя
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
create	default	damit.DGUID	as	newid()						/* только для PK полей */
go
----------
exec	sp_bindrule	'damit.RId',		'damit.TIdBig'				-- исключаем 0 для возможности isnull(*,0)=0
exec	sp_bindrule	'damit.RId',		'damit.TId'				-- исключаем 0 для возможности isnull(*,0)=0
exec	sp_bindrule	'damit.RId',		'damit.TIdSmall'			-- исключаем 0 для возможности isnull(*,0)=0
exec	sp_bindrule	'damit.RId',		'damit.TIdTiny'				-- исключаем 0 для возможности isnull(*,0)=0
exec	sp_bindrule	'damit.RPositive',	'damit.TInteger'
exec	sp_bindrule	'damit.RBool',		'damit.TBool'
----------





/*
Jet Database Engine documentation

ADODB.Stream пишет на диск блоками по 2048 байта, размер блока можно менять?
bcp пишет блоками не всегда по 4096, а очень близкими по размеру
AccessDatabaseEngine.exe попробовать на 32 разрядном сервере выгрузку в файл
поискать про "OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "txtsrv" returned message "Недопустимая закладка."."
----------



Обработка пачки данных:
1) транзакция нужна
	при выгрузке с блокировкой при обработке многошаговой пачки данных
	при загрузке, чтобы она загрузилась только целиком(в т.ч. включая статус), если это нужно
2) процедура начала пачки BeforePackage, например, меняет статус отсылаемых в пачке данных
3) выполнение шагов
4) процедура завершения пачки AfterPackage, например, меняет статус отосланных в пачке данных

Обработка шага:
экспорта:
	1) если указана #таблица для экспорта, то она создаётся по форматному view или ао view с данными через генератор-чем выше её создать, тем дольше проживёт
	2) выполняет захардкоденную процедуру, заполняющую таблицу для экспорта(с Id лога выгрузки?) исходя из заданного параметра
эти параметры передаются в запускалку батча- как их хранить в логе выгрузки???
где хранить разделитель параметров в строке?
		-только указание параметра, сам список, например, через временные таблицы
		выборочно по списку идентификаторов- функция ListToTableInteger(varchar(max))
		всё
		только изменения
			по дате обновления/актуальности, в т.ч. и при неизменных данных
			по содержимому
	3) заменяет недопустимые символы- отдельно от предыдущего шага, чтобы была модульность
	4) если заданы только изменения по содержимому, то сравнивает (таблицу старой отсылки/дату старой отсылки) и таблицу(резалтсет?) новой отсылки, затем стирает неизменившиеся записи
	5) формирует имя исходящего объекта по шаблону
	6) если протокол передаёт файл или ничего не передаёт, то сохраняет исходящий файл с содержимым по шаблону в локальный каталог
с этого шага пусть работает SSIS
	7) передаёт по протоколу из файла или таблицы
	8) если для пачки не указано менять статус, то шаг изменяет статус отосланных записей
импорта:
?	0) опознаватель формата входящего объекта
	1) задаёт имя по шаблону(другие параметры?) входящего объекта(файла, таблицы)
	2) принимает объект по протоколу
	3) если объект не в таблице, то сохраняет во входящий файл содержимое во формату
	4) сравнивает таблицу старого приёма и новые данные
	5) пишет в базу импортированные записи, если они не изменились, то только их время обновления локальное или присланное
	6) если для пачки не указано менять статус, то создаёт/изменяет статус принятых в этом шаге записей

*/


----------
create	table	damit.Script
--скрипт- готовый файл с входящими параметрами-макросами командной строки ИЛИ текст с параметрами-макросами
--как выдавать выходящие параметры? sql скрипт может сохранить сам в damit.Parameter, как это сделать .CMD?
--как передавать входящие параметры в sql текст кроме замены в шаблоне? в sql процедуру можно промаппить по имени
--в SFTP шаге настройки только статические, через шаг скрипт настройки SFTP используются через damit.Parameter/damit.Variable, поэтому их можно динамически менять
--как быстро получить список всех используемых как скрипты .cmd файлов? парсить Command?
--если Subsystem='ActiveScripting', то output параметры из .vbs получаем через wscript.echo. Если первый символ '<', то обрабатывам xml; иначе обрабатываем через ToListFromStringAuto с первым символом- разделителем
(	Id			damit.TIdSmall		not null
	,Name			damit.TName		not null
--	,Type			damit.TName		not null	-- cmd,sql
	,Subsystem		nvarchar ( 40 )		null		-- null=сохранить файл не выполняя; поддерживаем некоторые из msdb.dbo.syssubsystems, например- TSQL, ActiveScripting(для .vbs), CmdExec, SSIS
	,FileName		damit.TFileName		null		-- null=исполнять без сохранения или файл=сохранять перед исполнением, можно использовать для отладки
	,Folder			damit.TFileName		null		-- с каким текущим каталогом исполнять, например, для упрощения вызова .exe
	,Command		damit.TScript		null		-- null=выполнить файл по имени; текст скрипта, возможно, с макросами; например, вызов .cmd файла(безотносительно содержимого FileName) с параметрами командной строки
,constraint	PKdamitScript		primary	key	clustered	( Id )
,constraint	CKdamitScript		check	(	FileName	is	not	null
						or	Command		is	not	null ) )	-- выполнять то, что заполнено, если заполнены оба, то сохранить Command в FileName, выполнить, затем стереть FileName
----------
	create	table	damit.SMTP	-- профили SMTP серверов с учётом рассылающих пользователей
	-- если нужно послать от другого пользователя, то создадим новый профиль
	(	Id			damit.TIdTiny		not null	identity ( 1,	1 )
--		,Script			damit.TIdSmall		null
		,Server			damit.TExtName		not null
		,Proxy			damit.TExtName		null
		,WindowsAuthentication	damit.TBool		not null	-- доменная авторизация или нет
		,SSL			damit.TBool		not null
		,Login			damit.TExtName		null		-- пусто при доменной авторизации или anonymous
		,Password		damit.TName		null
	,constraint	PKdamitSMTP		primary	key	clustered	( Id )/*
	,constraint	FKdamitSMTPScript	foreign	key	( Script )	references	damit.Script	( Id )*/	)
----------
	create	table	damit.Email	-- параметры отсылки email
	(	Id			damit.TIdSmall		not null
		,SMTP			damit.TIdTiny		not null
		,[From]			damit.TExtName		null
		,[To]			varchar ( 1024 )	not null
		,Cc			varchar ( 1024 )	null
		,Bcc			varchar ( 1024 )	null
		,Subject		varchar ( 1024 )	null
		,Body			ntext			null
		,IsHTML			damit.TBool		null
		,CanBlank		damit.TBool		not null	-- посылать письмо без вложений
--		,Attachment		image			null		-- его мы создаём сами и прикладываем к письму
	,constraint	PKdamitEmail		primary	key	clustered	( Id )
	,constraint	FKdamitEmailSMTP	foreign	key	( SMTP )	references	damit.SMTP	( Id )	)
----------
	create	table	damit.SFTP	-- параметры SFTP серверов
	(	Id			damit.TIdSmall		not null
		,Script			damit.TIdSmall		null		-- скрипт выгрузки на этот сервер или взятия с него файла
		,Server			damit.TExtName		not null
		,Port			damit.TInteger		null
		,Login			damit.TExtName		null
		,Password		damit.TPassword		null
		,PrivateKey		damit.TFileName		null		-- путь к нашему файлу ключа
		,Path			damit.TFileName		null		-- путь к рабочей папке на сервере
		,RetryAttempts		damit.TInteger		not null
	,constraint	PKdamitSFTP		primary	key	clustered	( Id )
	,constraint	FKdamitSFTPScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
	create	table	damit.FTPS	-- параметры FTPS серверов
	(	Id			damit.TIdSmall		not null
		,Script			damit.TIdSmall		null		-- скрипт выгрузки на этот сервер или взятия с него файла
		,Server			damit.TExtName		not null
		,Port			damit.TInteger		null
		,Login			damit.TExtName		null
		,Password		damit.TPassword		null
		,Path			damit.TFileName		null		-- путь к рабочей папке на сервере
		,RetryAttempts		damit.TInteger		null
	,constraint	PKdamitFTPS		primary	key	clustered	( Id )
	,constraint	FKdamitFTPSScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
	create	table	damit.Folder	-- файловые каталоги, например, UNC или на локальном диске
	(	Id			damit.TIdSmall		not null
		,Script			damit.TIdSmall		null		-- скрипт копирования файла в этот каталог или из этого каталога
		,Path	 		damit.TFileName		not null
	,constraint	PKdamitFolder		primary	key	clustered	( Id )
	,constraint	FKdamitFolderScript	foreign	key	( Script )	references	damit.Script	( Id )	)
----------
create	table	damit.Protocol
-- на каждую из этих таблиц нужен триггер, поскольку нет инфраструктуры TF
-- PK нельзя сделать computed, т.к. если понадобиться добавить поле, то придётся отключать FK+PK и делать drop/add
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
create	table	damit.Storage		-- форматы файлов передачи данных
-- .csv,.txt,.xml,.xls
-- если это .xml, то где указать .xsd- только для загрузки
-- на одно расширение файла можно иметь несколько форматов, различающихся только названием
(	Id		damit.TIdSmall		not null
	,Script		damit.TIdSmall		null		-- скрипт локальной выгрузки или загрузки таблицы
	,Name		damit.TName		not null	-- на одно расширение файла может быть несколько форматов
	,Extension	damit.TFileName		not null	-- Расширение файла
	,Saver		damit.TSysName		null		-- процедура выгрузки в файл этого формата
	,Loader		damit.TSysName		null		-- процедура загрузки из файла этого формата
--	,Purifier	damit.TSysName		null		-- Функция замены допустимых символов, зависит только от формата и больше ни от чего?
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
create	table	damit.Format		-- форматы файлов передачи данных
-- .csv,.txt,.xml,.xls
-- если это .xml, то где указать .xsd- только для загрузки
-- на одно расширение файла можно иметь несколько форматов, различающихся только названием
-- что делать при одновременном запуске нескольких одинаковых файлов- добавить поле counter или дополнительно в шаблоне имени миллисекунда к имени файла?
(	Id		damit.TIdSmall		not null
	,Storage	damit.TIdSmall		not null
	,Name		damit.TName		not null
	,FileName	damit.TFileName		not null	-- формат/шаблон имени исходящего объекта, возможно, включая путь и расширение
	,CanBlank	damit.TBool		not null	-- Сохранять заголовок файла(например, список полей) без содержимого
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
create	table	damit.Query		-- отдельные запросы
(	Id		damit.TIdSmall		not null
	,Alias		damit.TName		not null	-- название процедуры для выполнения
,constraint	PKdamitQuery		primary	key	clustered	( Id )
,constraint	UQdamitQuery		unique	( Alias )
/*,constraint	CKdamitQuery		check	( object_id ( Alias )	is	not	null )*/	)	-- она может не существовать в момент создания шага выгрузки
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'Запросы'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Query'
----------
/*create	table	damit.Batch		-- пачки для обработки нескольких файлов за один проход
-- где указать приём или передача?

--TransferEntity:File, Batch, Node
--пачки иерархические, чтобы можно было наследовать параметры из пачки

--сделать таблицу дерева выгрузки, как Routes

--Parent, например, указать сначала пачку данных(файл на фтп), затем его оповещение по другому протоколу(письмо по почте)
--Отсылка всей пачки или пошагово-	это про статусы?
--Sequence внутри Parent

--если пачка идёт в едином Distribution, то перелогиниваться на каждый шаг не нужно

(	Id		damit.TId		not null
	,Distribution	damit.TId		not null
	,FilePath	damit.TFileName		null		-- общий каталог для всех выгрузок, к которому могут быть добавлены частные каталоги файлов
	,Name		damit.TName		not null
constraint	PKdamitBatch			primary	key	clustered	( Id )
constraint	FKdamitBatchDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id ) )*/
----------
create	table	damit.Data		-- источники данных выгрузки
-- что делать с таблицей истории, если поменяется формат отсылаемых данных?
-- попытаться сокращать использование временных таблиц, если данные берутся из view, а не из процедуры
-- в названиях объектов указывать название базы, тогда можно будет вызывать из любой базы и object_id будет работать правильно
-- отвечают за: структуру и число полей- Target, число записей- Filter, порядок следования записей- FieldSort
-- ?где можно пометить, что функция фильтрации игнорирует стандартные параметры фильтрации, т.е. совместимость этих параметров- не важна и такая проверка совместимости даже вредна???
--,Pattern	damit.TSysName		null		-- форматное view, null=если данные берутся не из процедуры, а из view, то можно по нему собрать данные для временной таблицы, для _раннего_ создания временной таблицы, чтобы она рано не уничтожилась, может использоваться для построения linked server\jet\schema.ini
(	Id		damit.TIdSmall		not null
	,Target		damit.TSysName		not null	-- по этому view или процедуре для выгрузки, берущей датасет из базы(пишущей во временную таблицу)- создаётся/заполняется временная таблица
	,DataLog	damit.TSysName		null		-- таблица, заполненная экспортом в предыдущий запуск для сравнения, чтобы отсылать только изменения, если null, то отсылать всё
	,Filter		damit.TSysName		null		-- для фильтрации функция(с параметрами) или view(без параметров) для join по совпадающим полям
	,Name		damit.TName		not null	-- название
--	,CanBlank	damit.TBool		not null	-- пустая выгрузка считается валидной 0=нет, 1=да
	,Refiner	damit.TSysName		null		-- Функция замены допустимых символов, хотя зависит только от формата, но должна вызываться раньше него
	,CanCreated	damit.TBool		not null	-- выгружать отсутствующие в предыдущих выгрузках
	,CanChanged	damit.TBool		not null	-- выгружать отличающиеся от существующих в предыдущих выгрузках
	,CanRemoved	damit.TBool		not null	-- выгружать отсутствующие сейчас и существующие в предыдущих выгрузках
	,CanFixed	damit.TBool		not null	-- выгружать неизменившуюся с предыдущей выгрузки
,constraint	PKdamitData		primary	key	clustered	( Id )	)
----------
create	table	damit.DataField		-- поля выгрузок
(	Data		damit.TIdSmall		not null
	,FieldName	damit.TSysName		not null	-- имя существующего поля или название нового поля(возможно совпадающего с существующим) со значением Value
	,Value		damit.TScript		null		-- скрипт значения поля, например, для отображения информации из самого сгенерированного запроса

	,IsRelationship	damit.TBool		not null	-- поле идентификатора записи в резалтсете предмета выгрузки(view)
	,IsComparison	damit.TBool		not null	-- поля для обнаружения изменений, сравниваемые по checksum
	,IsResultset	damit.TBool		not null	-- поля выдаваемые наружу
	,IsList		damit.TBool		not null	-- если не задана функция фильтрации или резалтсет не через процедуру; поле для фильтрации по списку идентификаторов, чаще всего совпадает с IsRelationship
	,IsDate		damit.TBool		not null	-- если не задана функция фильтрации или резалтсет не через процедуру; поле даты записи в резалтсете предмета выгрузки(view), например, даты изменения записи
	,Sort		damit.TIntegerNeg	null		-- сортируется по abs(Sort), отрицательные значения означают order by desc
	,Sequence	damit.TInteger		not null	-- в этом порядке идут поля IsResultset в выгрузке наружу; строгая последовательность +1 не обязательна
constraint	FKdamitDataFieldData	foreign	key		( Data )	references	damit.Data	( Id )
,constraint	UQdamitDataField0	unique	clustered	( Data,	Sequence )
,constraint	UQdamitDataField	unique			( Data,	FieldName )	)
----------
create	table	damit.DataData		-- зависимости выгрузок друг от друга, совместимость выгрузок для отслеживания предыдущих версий данных
-- если выгрузка(2) зависит от другой(1), это значит, что при выгрузке изменений в (2) учитываются данные в логах (1)
-- все зависимости хранятся только здесь, поэтому, если для выгрузки нет записи (1)=(1) она не поддерживает изменения и всегда содержит полный набор данных
-- тестовая выгрузка может зависеть от других боевых, но от неё могут зависеть только тестовые выгрузки, но не боевые
-- собирать список зависимостей можно через cte
-- можно ли делать зависимости Distribution с разными Data? в принципе, для совместимости важен только список идентификаторов из одной таблицы
(	Data1		damit.TIdSmall	not null	-- главная
	,Data2		damit.TIdSmall	not null	-- зависящая
	,IsClosed	damit.TBool	not null	-- эту ветку зависимости не разворачивать, использовать только указанный в этой записи объект, но не его потомков/зависимости
,constraint	FKdamitDataDataData1	foreign	key	( Data1 )	references	damit.Data	( Id )
,constraint	FKdamitDataDataData2	foreign	key	( Data2 )	references	damit.Data	( Id )
,constraint	UQdamitDataData		unique	clustered	( Data1,	Data2 )	)
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'Зависимости данных выгрузок друг от друга'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'DataData'
----------
create	table	damit.Condition		-- подходящие для sql WHERE условия
-- условия типа (a=1 and (b=2 or c=3))
(	Id		damit.TIdSmall	not null	-- учитывать тип в UQorNull
	,Parent		damit.TIdSmall	null		-- группа для скобок
	,FieldName	damit.TSysname	null		-- ?damit.Variable.Alias
	,Operator	varchar ( 16 )	not null	-- оператор сравнения или учёта в группе её подчинённых элементов, т.е. внутри группы только один логический оператор
	,Value		sql_variant	null		-- здесь тоже возможен FieldName?
	,Sequence	smallint	null		-- порядок следования внутри группы, не более 32787 условий в (); null=root
	,UQorNull	as	isnull ( convert ( binary ( 2 ),	Sequence ),	convert ( binary ( 2 ),	Id ) )	persisted	not null	-- учитывать тип Id
,constraint	PKdamitCondition	primary	key	clustered/*их мало*/	( Id )
,constraint	FKdamitCondition	foreign	key	( Parent )	references	damit.Condition	( Id )
,constraint	UQdamitCondition	unique	( Parent,	UQorNull )
,constraint	CKdamitCondition1	check	(	Operator	in	( '>',	'>=',	'<',	'<=',	'like',	'not like' )	and	FieldName	is	not	null	and	Value	is	not	null
						or	Operator	in	( '=',	'<>' )						and	FieldName	is	not	null	-- =(<>)null->is (not)null
						or	Operator	in	( 'and','or' )						and	FieldName	is		null	and	Value	is		null ) )
----------
create	table	damit.Layout	-- шаг создаёт списки полей для SELECT/FROM/WHERE/ORDER_BY запроса и сохраняет в параметр
-- таблица подобна damit.Data, но без слежения и её результат- список полей в параметры, а не сам ResultSet в DataLog
-- ?может ли посчитать количество записей или это лишний запрос?
-- сложное получение excel файла не делаем, т.к. в нём 3 вызова скрипта- это 3 записи, а не 3 поля
-- FileName относится непосредственно к файлу, поэтому, его здесь нет
(	Id		damit.TIdSmall		not null
	,Target		damit.TSysName		not null	-- например, view или DataLog_* таблица с ExecutionLog фильтрацией
/*?*/	,Filter		damit.TSysName		null		-- например, с ExecutionLog фильтрацией, join по названию поля?
/*?*/	,Refiner	damit.TSysName		null		-- для оборачивания текстовых полей или всех?
/*?*/	,CanBlank	damit.TBool		not null	-- создавать ли файл с 0 записей, например, только из заголовка с полями
/*?*/	,Delimeter	damit.TDelimeter	null		-- разделитель для списка полей не в SQL формате
	,Name		damit.TName		not null
,constraint	PKdamitLayout	primary	key	clustered	( Id )
,constraint	UQdamitLayout	unique	( Name )	)
----------
create	table	damit.LayoutField	-- список полей датасета
-- таблица подобна damit.DataField
-- где указать поля, по которым задаётся внешняя фильтрация?
(	Layout		damit.TIdSmall		not null
	,FieldName	damit.TSysName		not null
	,DataType	damit.TSysName		null		-- null=по умолчанию из Layout.Target
	,Expression	damit.TScript		null		-- аналогично damit.DataField.Value
	,IsRelationship	damit.TBool		not null	-- внутри одной выгрузки можно создать unique, например, во временной таблице, хотя шаг не сохраняет в таблицу?
	,IsResultset	damit.TBool		not null	-- эти поля должны попасть в ResultSet
	,Sort		damit.TIntegerNeg	null		-- порядок сортировки, при 0< сортировка DESC
	,Sequence	damit.TInteger		not null	-- порядок полей в ResultSet
,constraint	FKdamitLayoutFieldLayout	foreign	key		( Layout )	references	damit.Layout	( Id )
,constraint	UQdamitLayoutField0		unique	clustered	( Layout,	Sequence )
,constraint	UQdamitLayoutField1		unique			( Layout,	FieldName )	)
----------
create	table	damit.TaskIdentity
(	Id		damit.TIdSmall		not null	identity ( 1,	1 )	-- только для хранения IDENT_CURRENT(), здесь не нужны записи
	,Dumb		damit.TIdTiny		null		-- чтобы можно было вставить много записей, а не только одну через insert <table> default values и без сложного merge
,constraint	PKdamitTaskIdentity		primary	key	clustered	( Id )	)
----------
alter	table	damit.Protocol	add
constraint	FKdamitProtocolId	foreign	key	( Id )	references	damit.TaskIdentity	( Id )
----------
alter	table	damit.Protocol	NOCHECK	CONSTRAINT	FKdamitProtocolId	-- только для сохранения метаданных; constraint <name> default ident_current('<table>') не годится, т.к. не проверяет наличие <table>
----------
create	table	damit.Task
-- на каждую из этих таблиц нужен триггер, поскольку нет инфраструктуры TF
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
alter	table	damit.Task	NOCHECK	CONSTRAINT	FKdamitTaskId	-- только для сохранения метаданных; constraint <name> default ident_current('<table>') не годится, т.к. не проверяет наличие <table>
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'Сущность задач могущих содержаться на шаге'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Task'
----------
create	table	damit.Distribution	-- все параметры распространения данных
-- шаг может быть недоступен по ветвлению в выгрузке и/или его можно использовать как держатель параметров; как ему проставлять параметры из других шагов, когда они его наследуют, а не наоборот?
-- как получать параметры из предыдущего(относительного, не абсолютного) шага при множественном ветвлении?
--	Condition	int		null		-- условие перехода, null=безусловный переход
--,constraint	FKdamitDistribution1	foreign	key	( Condition )	references	damit.Condition	( Id )
(	Id		damit.TIdSmall		not null
	,Node		damit.TIdSmall		null		-- null=самый первый шаг
	,Task		damit.TIdSmall		null		-- null=хаб, например, для схождения нескольких веток в одну точку, null=для пассивной группировки параметров без активного действия по шагу
	,Name		damit.TName		null		-- название
	,Sequence	damit.TInteger		not null	default	( 0 )	-- порядок перехода при множественных потомках; если одинаковый, то запускать параллельно и асинхронно, если разный, то простой выбор ветки, куда дальше идти со следующим шагом="условие"
,constraint	PKdamitDistribution		primary	key	clustered	( Id )
,constraint	FKdamitDistributionNode		foreign	key	( Node )	references	damit.Distribution	( Id )
,constraint	FKdamitDistributionTask		foreign	key	( Task )	references	damit.Task		( Id )
--,constraint	UQdamitDistribution1		unique	( Node,	Task,	Sequence )	-- исключаем дублирование, может ли оно понадобиться, например, для резервирования Sequence?
--,constraint	UQdamitDistribution2		unique	( Node,	Sequence )
,constraint	CKdamitDistribution1		check	( Id<>	Task )	-- исключаем зацикливание
,constraint	CKdamitDistribution2		check	(	Task	is	not	null
							or	Name	is	not	null )	)
----------
alter	table	damit.Task	add
constraint	FKdamitTaskDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
----------
create	table	damit.Parameter		-- разрешение использования переменных и параметров для выгрузок и предустановленные значения параметров
--например, для задания параметров выгрузки: идентификатор клиента- здесь, т.к. он зафиксирован в выгрузке, Start,Finish через damit.Variable, т.к. вычисляются и подаются снаружи
--если для шага заданы несколько параметров с разными Sequence, то обработчик параметров организует цикл?
--как быть, если для шага заданы разные параметры, но в каждом разное количество Sequence?
--Шаг может уметь цикл или нет, например, в Email можно вложить несколько файлов, а не отправлять несколько писем с одним файлом
--здесь input параметры и, возможно, их фиксированные значения. Чтобы сослаться через Source на output параметр другого шага в damit.Variable его нужно поместить сюда с Value=null
--если из Value нельзя узнать тип, то шаги, использующие параметр должны сами разбираться с его типом
--считать ли эту таблицу разрешением писать в damit.Variable? если нет записи в damit.Parameter, то процедура не пишет свои переменные и не выдаёт ошибку(но пишет warning в ExecutionLog), что писать нельзя- экономия на заполнении damit.Variable при отсутствии последнего шага GarbageCollector?
--статические значения отсюда оверрайдятся через damit.Variable?
--условия изменения через damit.SetupVariable значения здесь вместо damit.Variable: Source=null,DistributionRoot<>null,Value<>null(первое значение сохранить вручную insert/update?)
--автоматический список параметров Task собирать из sql кода для вставки в damit.Parameter?
--заменить в Source FK(Parameter) на FK-Entity(Parameter,DistributionStep), чтобы в input можно было сослаться на одноименный output параметр DistributionStep отдельно не создавая его
--DistributionRoot and DistributionStep is null=параметр для всех выгрузок
--чем дальше параметр от текущего шага, тем меньше приоритет его значения
/*
список замен вместо dbo.Replacement+dbo.ReplacementValue :
	damit.Variable
	damit.Parameter
	left join любая таблица
*/

(	Id			damit.TIdSmall		not null	identity ( 1,	1 )
	,Source			damit.TIdSmall		null		-- FK(damit.Parameters.Id) должен принадлежать этой же выгрузке DistributionRoot, иначе результат непредсказуем; разворачиваем только на один уровень, без дальнейшей рекурсии; распространяется и на получение данных через damit.Variable. Ссылка на damit.Parameter.Id, а не DistributionStep, который может принадлежать шаблону и для которого обязательно указание DistributionRoot
	,DistributionRoot	damit.TIdSmall		null		-- для возможности повторного использования шаблонов с другими параметрами для разных DistributionRoot, при null=для всех шаблонов; внутри DistributionRoot шаблон DistributionStep может быть использован только 1 раз
	,DistributionStep	damit.TIdSmall		/*not */null	-- для какого шага параметр, null=параметр для всех шагов выгрузки
--	,Condition		damit.TIdSmall		null		-- XML условия (или значения?) для параметра. Для join поля из damit.Data какого Distribution брать, если есть несколько Data внутри корневого Distribution?
	,Alias			damit.TName		null		-- название параметра, null= получать из Source, если задан и Alias и Source, то Alias используется отсюда(для возможности переименования), а значение оттуда
	,Value	sql_variant	/*damit.TBLOB*/		null		-- статическое значение параметра, при null нельзя понять, это заполненное значение или указание лукапить Source
	,Expression		damit.TScript		null		-- SQL выражение или функция для преобразования Value, в формате, подходящем для поля в SELECT. Хорошо бы сделать здесь язык, понятный пользователю, например, распознавание макросов
--	,IsStatic		damit.TBool		not null	-- использовать значение из этой таблицы вместо damit.Variable
	,Sequence		damit.TIntegerNeg	null		-- порядок следования, поле с предустановленным значением, берётся оттуда же где и Value- если параметров с одним названием несколько, если стоит число и параметр с таким именем один, то это допустимое количество таких параметров, например, вложений файлов в email
,constraint	PKdamitParameter			primary	key	clustered	( Id )
,constraint	FKdamitParameterSource			foreign	key	( Source )		references	damit.Parameter		( Id )
,constraint	FKdamitParameterDistributionRoot	foreign	key	( DistributionRoot )	references	damit.Distribution	( Id )
,constraint	FKdamitParameterDistributionStep	foreign	key	( DistributionStep )	references	damit.Distribution	( Id )
--,constraint	FKdamitParameterCondition		foreign	key	( Condition )		references	dbo.Condition		( Id )
,constraint	UQdamitParameter1			unique		( DistributionRoot,	DistributionStep,	Alias,	Sequence )	-- DistributionRoot здесь позволяет задавать разные параметры для одного шага, вызываемого в качестве шаблона

-- включить Expression в check

,constraint	CKdamitParameter1			check	(	(	Source			is	not	null
									or	Alias			is	not	null )
								and	(	Source			is		null
									or	Value			is		null )
								and	(	Alias			is	not	null
									or	Value			is		null )
								and	(	Alias			is	not	null
									or	Sequence		is		null )
								and	(	DistributionStep	is		null	and	Alias	is	not	null	-- глобальные параметры обязательно именованы
									or	DistributionStep	is	not	null )	)	)
/*,constraint	CKdamitParameterN			check	(	Condition	is		null	and	Alias	is	not	null
								or	Condition	is	not	null	and	Alias	is		null )*/
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'Разрешение использования переменных и параметров для выгрузок и предустановленные значения параметров'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Parameter'
----------
create	table	damit.ExecutionLog	-- лог выполненных шагов
-- можно хранить лог выгрузки вечно
-- ориентироваться на код и/или сообщение об ошибке нельзя, совпадение кодов ошибок не означает совпадения содержимого таблиц, это только признак того, что ошибка произошла
-- если все условия фильтрации по AND, то дополнительная фильтрация не нарушает порядок выгрузки и потом можно сделать выгрузку без дополнительных условий, чтобы привести порядок к стандартному поведению
-- выгружать изменённые после даты последней совместимой выгрузки=придётся создать такую функцию фильтрации
-- циклы в Distribution через Condition здесь видны только через последовательность Start
-- последний(по времени, sequence или ещё как?) ExecutionLog.Id при Finish=null считается исполняющимся в данный момент
(	Id			damit.TId		not null	identity ( 1,	1 )	-- используется для FK в таблицах DataLog_*, таким образом, что за одну выгрузку таблица DataLog_* может быть заполнена несколько раз
	,Execution		damit.TId		null		-- используется только для группировки? например, первый в выгрузке ExecutionLog.Id, можно использовать более сложные деревья и собирать их через cte; из-за identity при not null нельзя вставить первую запись
	,Distribution		damit.TIdSmall		not null	-- предмет выгрузки
	,Sequence		damit.TIntegerNeg	not null
	,Start			damit.TDateTime		not null	constraint	DdamitExecutionLogStart	default	getdate()	-- например, начало исполнения шага- пишется в момент начала шага
	,Finish			damit.TDateTime		null		-- например, конец исполнения шага- пишется в момент завершения шага
	,ErrorCode		damit.TIntegerNeg	null		-- код ошибки, 0=нет ошибки, <0=ошибка-завершённость действия неизвестна, >0=нет ошибки, но может быть сообщение hint/warning/information
	,Message		damit.TNote		null		-- сообщение о прошедшей выгрузке
constraint	PKdamitExecutionLog		unique	clustered	( Id )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary"
,constraint	FKdamitExecutionLogExecution	foreign	key	( Execution )		references	damit.ExecutionLog	( Id )
,constraint	FKdamitExecutionLogDistribution	foreign	key	( Distribution )	references	damit.Distribution	( Id )
,constraint	СKdamitExecutionLog1		check	(	Finish	is		null
							or	Finish	is	not	null	and	Execution	is	not	null )
,constraint	UQdamitExecutionLog1		unique	( Distribution , Start )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary"	-- если в одно время стартуют две выгрузки с изменениями одинаковых идентификаторов, то не ясно, какое изменения было позднее
,constraint	UQdamitExecutionLog2		unique	( Execution,	Sequence )	/*WITH	( SORT_IN_TEMPDB=	ON,	ONLINE=	ON )*/	on	"Primary" )
--check	Start<=	Finish	-- нельзя, т.к. windows time может подветси время в момент работы выгрузки
----------
--create	clustered	index	IXdamitExecutionLog	on	damit.ExecutionLog	( Start )	on	"Primary"
----------
/*
структурное завершение цикла= (Task=Distribution) в качестве goto на его начало
при Condition=true переходить в тело цикла, при Condition=false- на следующий после цикла Task
переключает на следующий damit.Variable.Sequence (не обязательно идущий по порядку) относительно текущего в сторону sign('Step'); +'Step' нельзя из-за возможных пропусков в нумерации damit.Variable.Sequence
параметры шага ForEach совместимы с типом поля damit.Variable.Sequence
	'Begin'		или обойтись без него, считая в начале операции равным 'Current'?
	'End'
	'Step'		нужен, чтобы задать направление обхода как при For, так и при ForEach
	'Current'
	*damit.Variable.Alias(при Sequence is not null)- если она не задана, то текущее значение цикла- 'Current'. Для этого нужно многоуровневое наследование вместо двухуровневого?

поддержка 'IsCurrent' для переменной:
-в шаге Condition: шаг Condition ссылается на переменную с внутришаговым именем 'ForEach' вне зависимости от её исходного имени и количества записей в ней
-вне шага Condition: существует шаг Condition, который ссылается на переменную с внутришаговым именем 'ForEach' и внутри неё правильно установлен 'IsCurrent' вне зависимости от её исходного имени и количества записей в ней


нужна ли возможность статического задания массива через damit.Variable.IsCurrent+damit.Parameter.Value вместо динамической передачи через damit.Variable.Value?

условия джоина- damit.Variable: .Sequence is not null and .Value is null при заданном Alias и разных Sequence, damit.Parameter: .Sequence is not null and .Value is not null
*/
create	table	damit.Variable			-- таблица динамических переменных
-- Task-и публикуют свои результаты через переменные, затирая предыдущий набор данных по всем Sequence данного Alias
-- ???параметры в следующем шаге из предыдущего шага получаются захардкоденной логикой

-- переменная: следующий шаг, если из Task есть несколько путей

/*Alias:
Data(DataSet)		таблица
Format(FileName)	файл, для списка использовать Sequence
*/
--массив для цикла цикла-damit.Condition- одна или несколько damit.Variable.Value с одинаковым Alias и неповторяющимся Sequence is not null
-- для Execution=root использовать Value как глобальную переменную?
-- FILESTREAM чтобы заменить damit.DoSaveToXML с захардкоденной передачей параметра скрипта на damit.DoScript с универсальной передачей в damit.DoSave
(	Id			damit.TGUID		not null	rowguidcol	constraint	DdamitVariableId	default	newid()
	,ExecutionLog		damit.TId		/*not */null	-- область видимости переменной, null=например, для глобальных счётчиков
	,Alias			damit.TName		not null	-- название переменной, через которую можно передавать значения между Task
	,Value			sql_variant		null		-- содержимое, например, название таблицы/view с содержимым параметра- формат этого поля должны знать сами заинтересованные в параметре шаги
	,Sequence		damit.TIntegerNeg	null		-- заполняется, если с одним названием несколько переменных; null=этот Alias должен упоминаться только один раз, т.е. не должен присутствовать с Sequence<>null
	,Moment			damit.TDateTime		not null	constraint	DdamitVariableMoment	default	getdate()	-- момент появления переменной в выгрузке, только для кластерного ключа
	,ValueBLOB		varbinary ( max )	FILESTREAM	null	-- для BLOB, например, файлов
	,IsCurrent		damit.TBool		null		-- для выбора текущего значения 'ForEach' переменной из нескольких записей, если она относится к циклу
	,UQorNull		as	isnull ( convert ( binary ( 16 ),	nullif ( IsCurrent,	0 ) ),	convert ( binary ( 16 ),	Id ) )	persisted	not null	-- учитывать тип Id
	--Id			damit.TIdBig		not null	identity ( 1,	1 )	-- только для поддержки constraint
	--,UQorNull		as	isnull ( convert ( binary ( 8 ),	nullif ( IsCurrent,	0 ) ),	convert ( binary ( 8 ),		Id ) )	persisted	not null	-- учитывать тип Id
--,constraint	PKdamitVariable			primary	key	clustered	( Id )
,constraint	PKdamitVariable			primary	key	nonclustered	( Id )
,constraint	FKdamitVariableExecutionLog	foreign	key	( ExecutionLog )	references	damit.ExecutionLog	( Id )
,constraint	UQdamitVariable			unique	( ExecutionLog,	Alias,	Sequence )
,constraint	UQdamitVariable1		unique	( ExecutionLog,	Alias,	UQorNull )	)
--,constraint	DFdamitVariable			default	getdate()	for	Moment	-- на 2008R2 синаксис не поддерживается
--,constraint	CKdamitVariable			check	( Value	is	null	or	ValueBLOB	is	not	null )	-- только через триггер?
----------
CREATE	clustered	index	IXdamitVariable01	on	damit.Variable	( Moment )
----------
EXEC	sys.sp_addextendedproperty
		@name=		N'MS_Description'
		,@value=	N'Переменные(преимущественно динамические) для передачи данных между шагами'
		,@level0type=	N'SCHEMA'	,@level0name=	N'damit'
		,@level1type=	N'TABLE'	,@level1name=	N'Variable'
----------
rollback
--commit
go
use	tempdb