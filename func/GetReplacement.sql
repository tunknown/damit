use	damit
----------
if	object_id ( 'damit.GetReplacement' , 'fn' )	is	null
	exec	( 'create	function	damit.GetReplacement()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.GetReplacement	-- заполнение переменной или параметра в контексте заданного выполнения
(	@iExecutionLog	TId
	,@sAlias	TName=			null		--/задаётся только один из них- предустановленная переменная
	,@sValue	nvarchar ( max )=	null	)	--\или произвольное значение
returns	nvarchar ( max )	-- ''=ошибка
as
begin
	declare	@bIsProcessed	TBool
		,@sResult	nvarchar ( max )
		,@c		cursor
----------
	if	@sAlias	is	null
		set	@sResult=	@sValue
	else
		select
			@sResult=	damit.GetFunctionResult ( @iExecutionLog,	Expression0,	Value0 )
		from
			damit.GetVariables ( @iExecutionLog,	@sAlias,	default,	default,	default,	default,	default,	default,	default,	default,	default )
----------
	if	@sResult	like	'%(*%*)%'	-- '%(*%[^*()]%*)%' не годится, т.к. могут быть вложенные переменные
	begin
		set	@c=	cursor	local	fast_forward	for
					select	distinct					-- исключаем возможные множественные включения из-за мультзначений
						Name
					from
						damit.GetVariablesList ( @iExecutionLog )
					order	by
						Name
----------
		set	@bIsProcessed=	1
----------
		while	@bIsProcessed=	1	-- повторяем, пока даже вложенные переменные не будут заменены
		begin
			open	@c
----------
			set	@bIsProcessed=	0
----------
			while	1=	1
			begin
				fetch	next	from	@c	into	@sAlias
				if	@@fetch_status<>	0	break
----------
				if	@sResult	like	'%(*'+	@sAlias+	'*)%'
					select
						@sResult=	replace ( @sResult,	'(*'+	@sAlias+	'*)',	case	isnull ( Sequence,	1 )
																when	1	then	''
																else			'(*'+	@sAlias+	'*)'	-- если нужно заменять параметр значениями нескольких записей, то нужно сохранить макрос до последней замены
															end+	damit.GetFunctionResult ( @iExecutionLog,	Expression0,	Value0 ) )
						,@bIsProcessed=	1
					from
						damit.GetVariables ( @iExecutionLog,	@sAlias,	default,	default,	default,	default,	default,	default,	default,	default,	default )
					order	by
						Sequence	desc
			end
----------
			close	@c
		end
----------
		deallocate	@c
----------
		if	@sResult	like	'%(*%*)%'
			set	@sResult=	''	--ошибка: незаменённые макросы в шаблоне скрипта или имени файла
	end
----------
	return	@sResult
end
go
select	damit.GetReplacement	(null,	null,	null)