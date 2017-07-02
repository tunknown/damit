use	damit
----------
if	object_id ( 'damit.DoColumnsFromXML' , 'p' )	is	null
	exec	( 'create	proc	damit.DoColumnsFromXML	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoColumnsFromXML	-- преобразование xml с полями в текстовую строку для создания динамического запроса
	@x		xml				-- список полей в xml
	,@sPath		nvarchar ( 256 )=	null	-- путь в xml файле
	,@sPrefix	varchar ( 256 )=	null	-- префикс колонки
	,@sResult	nvarchar ( max )=	null	out	-- текстовую строку с колонками для создания динамического запроса
	,@iColumns	smallint=		null	out	-- количество колонок
as							-- внутри функции нельзя вызывать sp_xml_preparedocument
if	@x	is	null
begin
	select	@sResult=	null
		,@iColumns=	0
----------
	return	0
end
----------
declare	@iXML	int
----------
select	@sResult=	''
	,@sPath=	isnull ( @sPath , '/columns/column' )
	,@sPrefix=	isnull ( @sPrefix , ',	' )
----------
exec	sp_xml_preparedocument	@iXML	out,	@x
----------
select
	@sResult=	@sResult+	@sPrefix+	FieldName
from
	openxml ( @iXML , @sPath )
WITH
	(	FieldName	varchar ( 256 )	'text()' )
set	@iColumns=	@@RowCount
----------
exec	sp_xml_removedocument	@iXML
----------
return	0
go
use	tempdb
declare	@sResult	nvarchar ( max )
	,@iColumns	int
----------
exec damit.damit.DoColumnsFromXML	'
<columns>
	<column>f1</column>
	<column>f2</column>
	<column>f3</column>
	<column>f4</column>
	<column>f5</column>
	<column>f6</column>
</columns>
' , '/columns/column' , '
		,q.' ,	@sResult	out,	@iColumns	out
print	@iColumns
print	@sResult