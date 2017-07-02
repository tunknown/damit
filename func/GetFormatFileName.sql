use	damit
----------
if	object_id ( 'damit.GetFormatFileName' , 'if' )	is	null
	exec	( 'create	function	damit.GetFormatFileName()	returns	table	as	return	( select	Error=	1/	0)' )
go
alter	function	damit.GetFormatFileName	-- создание имени файла
(	@sFileName	varchar ( 256 )
	,@dtMoment	datetime=		null
	,@sAux		varchar ( 256 )=	null	)
returns	table
as	-- в названии каталога тоже могут быть шаблоны даты
----------
return	( select
		DirName=	left ( FileName , len ( FileName )-	charindex ( '\' , reverse ( FileName ) ) )
		,FileName=	right ( FileName , charindex ( '\' , reverse ( FileName ) )-	1 )
		,ExtName=	right ( FileName , charindex ( '.' , reverse ( FileName ) )-	1 )
		,FullName=	FileName
	from
		( select
			FileName=	replace (
					replace (
					replace (
					replace (
					replace (
					replace (
					replace (
					replace (
					replace (
					@sFileName,
					'{aux}',	convert ( varchar ( 256 ),	isnull ( @sAux , '' ) ) ),
					'{guid}',	convert ( char ( 36 ),		newid ) ),
					'{ms}',		left ( replace ( str ( datepart ( ms , Moment ) , 3 ) , ' ' , '0' ) , 2 ) ),
					'{ss}',		replace ( str ( datepart ( ss , Moment ) , 2 ) , ' ' , '0' ) ),
					'{mi}',		replace ( str ( datepart ( mi , Moment ) , 2 ) , ' ' , '0' ) ),
					'{hh}',		replace ( str ( datepart ( hh , Moment ) , 2 ) , ' ' , '0' ) ),
					'{dd}',		replace ( str ( datepart ( dd , Moment ) , 2 ) , ' ' , '0' ) ),
					'{mm}',		replace ( str ( datepart ( mm , Moment ) , 2 ) , ' ' , '0' ) ),
					'{yyyy}',	str ( datepart ( yyyy , Moment ) , 4 ) )
		from
			damit.newid
			,( select	Moment=	isnull ( @dtMoment , getdate )	from	damit.getdate )	t )	t	)
go
use	tempdb
select	*	from	damit.damit.GetFormatFileName ( 'C:\temp\1.csv',GETDATE(),default)