if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
----------
if	object_id ( 'damit.GetVariablesList' , 'tf' )	is	null
	exec	( 'create	function	damit.GetVariablesList()	returns	@t	table	( i	int )	as	begin	return	end' )
go
alter	function	damit.GetVariablesList	-- получение списка переменных и количества их значений
(	@iExecutionLog	TId )
returns	@tResult	table
(	Name		varchar ( 256 )	not null
	,Counter	smallint	null )	-- damit.Variable+damit.Parameter не предназначены для передачи больших датасетов
as
begin
	declare	@iDistributionStep	TId
		,@iDistributionRoot	TId
		,@iExecution		TId
----------
	select
		@iDistributionStep=	Distribution
		,@iExecution=		Execution
	from
		damit.ExecutionLog
	where
		Id=			@iExecutionLog
----------
	select
		@iDistributionRoot=	Distribution
	--	,@iExecution=		Execution
	from
		damit.ExecutionLog
	where
			Id=		@iExecution
		and	Execution=	@iExecution
----------




/*
override по Alias+Sequence, если снизу есть Sequence*, которого нет сверху, то данные по этому Sequence* попадают наверх

перенести в комментарии к коду
damit.Parameter
1 для DistributionRoot=null настройка для шага шаблона
2 для DistributionStep=DistributionRoot
3 для DistributionStep из Source- Alias берётся из Source, здесь не указан
4 для DistributionStep из Source- Alias указан здесь
5 для DistributionStep текущего шага

damit.Variable
6 для ExecutionId корневого шага
7 для ExecutionId текущего шага


Source	DistrRoot	Alias
damit.Parameter
0	0		1	3параметры для шага шаблона
0	1		1	6параметры для шага выгрузки
1	0		0	1ссылка на параметры для шага шаблона, Alias указан по ссылке
1	0		1	2ссылка на параметры для шага шаблона, Alias указан здесь
1	1		0	4ссылка на параметры для шага выгрузки, Alias указан по ссылке
1	1		1	5ссылка на параметры для шага выгрузки, Alias указан здесь
damit.Variable
0	1		1	--10параметры для шага выгрузки- не нужны, т.к. параметры передаются другим шагам, а не самому себе
0	1		1	9параметры для шага выгрузки для Root-для совместимости со старыми выгрузками, для damit.Parameter такого нет
1	1		0	7ссылка на параметры для шага выгрузки, Alias указан по ссылке	+damit.Parameter
1	1		1	8ссылка на параметры для шага выгрузки, Alias указан здесь	+damit.Parameter
*/

	declare	@tTemp	table
	(	Alias		varchar ( 256 )		not null
--		,Value		sql_variant		null
--		,Expression	nvarchar ( max )	null
		,Sequence	int			null )
-- сохранять синхронность этого запроса с damit.GetVariables
----------
	insert
		@tTemp
	select
		t.Alias
--		,t.Value
--		,t.Expression
		,t.Sequence
	from
		( select
			t.Alias
			,t.Value
			,t.Expression
			,t.Sequence
			,Sequence2=	row_number()	over	( partition	by	t.Alias,	t.Sequence/*если параметр подан снаружи в damit.Do, то Sequence=1 вместо null*/	order	by	t.Sequence2	desc )
		from
			(
			select
				Alias
				,Value
				,Expression=	'-1'
				,Sequence
				,Sequence2=	-1					-- настройка параметра для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter
			where
					DistributionRoot	is	null
				and	DistributionStep	is	null
				and	Source		is	null			-- для шаблона нельзя отнаследовать настройки из неизвестного источника
				and	Alias		is	not	null
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				p.Alias
				,Value=		case
							when	t.Distribution	is	null	then	p.Value
							else						t.Value	-- в т.ч. Value=null
						end
				,Expression=	'1'--p.Expression
				,p.Sequence
				,Sequence2=	0					-- глобальный параметр всей выгрузки
			from
				damit.Parameter	p
				left	join	( select
							el.Distribution
							,v.Alias
							,v.Value
							,v.Sequence
						from
							damit.ExecutionLog	el
							,damit.Variable		v
						where
								el.Execution=	@iExecution
							and	v.ExecutionLog=	el.Id )	t	on
					t.Distribution=		p.DistributionRoot
				and	t.Alias=		p.Alias
				and	isnull ( t.Sequence,	0x7fffffff )=	isnull ( p.Sequence,	0x7fffffff )
			where
					p.DistributionRoot=	@iDistributionRoot
				and	p.DistributionStep	is		null
				and	p.Alias			is	not	null	-- глобальные параметры обязательно именованы
			union	all
			select
				Alias
				,Value
				,Expression=	'3'
				,Sequence
				,Sequence2=	3					-- настройка параметра для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter
			where
					DistributionRoot	is	null
				and	DistributionStep=	@iDistributionStep
				and	Source		is	null			-- для шаблона нельзя отнаследовать настройки из неизвестного источника
				and	Alias		is	not	null
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				Alias
				,Value
				,Expression=	'6'
				,Sequence
				,Sequence2=	6					-- настройка параметра для шага выгрузки
			from
				damit.Parameter
			where
					DistributionRoot=	@iDistributionRoot
				and	DistributionStep=	@iDistributionStep
				and	Source		is	null
				and	Alias		is	not	null
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				p.Alias
				,p.Value
				,Expression=	'1'	--p.Expression
				,p.Sequence
				,Sequence2=	1					-- передача из другого шага ссылки на параметр для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter	c
				,damit.Parameter	p
			where
					c.DistributionRoot	is	null
				and	c.DistributionStep=	@iDistributionStep
				and	p.Id=			c.Source
				and	c.Alias		is	null
				and	p.Alias		is	not	null
--				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				c.Alias
				,p.Value
				,Expression=	'2'	--p.Expression
				,p.Sequence
				,Sequence2=	2					-- передача из другого шага значения параметра для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter	c
				,damit.Parameter	p
			where
					c.DistributionRoot	is	null
				and	c.DistributionStep=	@iDistributionStep
				and	p.Id=			c.Source
				and	c.Alias		is	not	null
--				and	c.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				p.Alias
				,p.Value
				,Expression=	'4'--p.Expression
				,p.Sequence
				,Sequence2=	4					-- передача из другого шага ссылки на параметр для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter	p	on
					p.Id=			c.Source
				and	p.Alias		is	not	null
--				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				left	join	( select				-- нельзя делать inner join damit.ExecutionLog для ссылки на параметры последующих ещё не выполненных шагов
							el.Distribution
							,v.Alias
						from
							damit.ExecutionLog	el
							,damit.Variable		v
						where
								el.Execution=	@iExecution
							and	v.ExecutionLog=	el.Id )	t	on
					t.Distribution=		p.DistributionStep
				and	t.Alias=		p.Alias
			where
					c.DistributionRoot=	@iDistributionRoot
				and	c.DistributionStep=	@iDistributionStep
				and	c.Alias			is	null
				and	t.Distribution		is	null			-- отдавать значение параметра только если нет заполненного оверрайда в переменных
			union	all
			select
				c.Alias
				,p.Value
				,Expression=	'5'	--p.Expression
				,p.Sequence
				,Sequence2=	5					-- передача из другого шага значения параметра для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter	p	on
					p.Id=			c.Source
				left	join	( select				-- нельзя делать inner join damit.ExecutionLog для ссылки на параметры последующих ещё не выполненных шагов
							el.Distribution
							,v.Alias
						from
							damit.ExecutionLog	el	-- что делать при дублировании при join, если шаг выгрузки повторяется(например, из-за применения шаблона)?
							,damit.Variable		v
						where
								el.Execution=	@iExecution
							and	v.ExecutionLog=	el.Id )	t	on
					t.Distribution=		p.DistributionStep
				and	t.Alias=		p.Alias
			where
					c.DistributionRoot=	@iDistributionRoot
				and	c.DistributionStep=	@iDistributionStep
				and	c.Alias		is	not	null
--				and	c.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				and	t.Distribution	is	null		-- отдавать значение параметра только если нет заполненного оверрайда в переменных
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	'9'--null
				,Sequence=	case	v.ExecutionLog
							when	@iExecutionLog	then	isnull ( v.Sequence,	 0xFFFFFFFF )+	0xFFFFFFFF	-- повышаем приоритет значения переменной текущего шага
							else				v.Sequence
						end
				,Sequence2=	9					-- значение переменной для шага выгрузки. если для переменной нет параметра, то её не наследуем по имени
			from
				damit.Variable	v
				left	join	damit.Parameter	p	on
					p.DistributionRoot=	@iDistributionRoot
				and	(	p.DistributionStep=	@iDistributionStep
					or	p.DistributionStep	is	null )
				and	p.Alias=		v.Alias
			where
					v.ExecutionLog	in	( @iExecutionLog,	@iExecution )
--				and	Alias	is	not	null			-- там уже not null, пишем только для соответствия другим запросам
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				and	p.DistributionRoot	is	null		-- исключаем переменные, получаемые через более приоритетные разделы
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	'7'--p.Expression
				,v.Sequence
				,Sequence2=	7					-- см.4, передача из другого шага ссылки на переменную для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter		p	on
					p.Id=			c.Source
				and	p.Alias		is	not	null
--				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				inner	join	damit.ExecutionLog	el	on
					el.Distribution=	p.DistributionStep
				and	el.Execution=		@iExecution
				inner	join	damit.Variable		v	on
					v.ExecutionLog=		el.Id
				and	v.Alias=		p.Alias
			where
					c.DistributionRoot=	@iDistributionRoot
				and	c.DistributionStep=	@iDistributionStep
				and	c.Alias		is	null
			union	all
			select
				c.Alias							-- следующий запрос ищет не через настоящее название в v.Alias
				,v.Value
				,Expression=	'8'	--p.Expression
				,v.Sequence
				,Sequence2=	8					-- см.5, передача из другого шага значения переменной для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter		p	on
					p.Id=			c.Source
				inner	join	damit.ExecutionLog	el	on	-- что делать при дублировании при join, если шаг выгрузки повторяется(например, из-за применения шаблона)?
					el.Distribution=	p.DistributionStep
				and	el.Execution=		@iExecution
				inner	join	damit.Variable		v	on
					v.ExecutionLog=		el.Id
				and	v.Alias=		p.Alias
			where
					c.DistributionRoot=	@iDistributionRoot
				and	c.DistributionStep=	@iDistributionStep
				and	c.Alias		is	not	null
--				and	c.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
 )	t )	t
	where
		t.Sequence2=	1
----------
	insert
		@tResult
	select
		Alias
		,count ( * )
	from
		@tTemp
	group	by
		Alias
----------
	return
end
go
select	*	from	damit.GetVariablesList
(	null )