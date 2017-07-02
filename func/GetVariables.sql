if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
----------
if	object_id ( 'damit.GetVariables' , 'tf' )	is	null
	exec	( 'create	function	damit.GetVariables()	returns	@t	table	( i	int )	as	begin	return	end' )
go
alter	function	damit.GetVariables	-- получение значений переменных
(	@gExecutionLog	uniqueidentifier
	,@sAlias0	varchar ( 256 )=	null
	,@sAlias1	varchar ( 256 )=	null
	,@sAlias2	varchar ( 256 )=	null
	,@sAlias3	varchar ( 256 )=	null
	,@sAlias4	varchar ( 256 )=	null
	,@sAlias5	varchar ( 256 )=	null
	,@sAlias6	varchar ( 256 )=	null
	,@sAlias7	varchar ( 256 )=	null
	,@sAlias8	varchar ( 256 )=	null
	,@sAlias9	varchar ( 256 )=	null )
returns	@tResult	table
(	Sequence	int			null
	,Value0		sql_variant		null
	,Expression0	nvarchar ( max )	null
	,Variable0	uniqueidentifier	null
	,Value1		sql_variant		null
	,Expression1	nvarchar ( max )	null
	,Variable1	uniqueidentifier	null
	,Value2		sql_variant		null
	,Expression2	nvarchar ( max )	null
	,Variable2	uniqueidentifier	null
	,Value3		sql_variant		null
	,Expression3	nvarchar ( max )	null
	,Variable3	uniqueidentifier	null
	,Value4		sql_variant		null
	,Expression4	nvarchar ( max )	null
	,Variable4	uniqueidentifier	null
	,Value5		sql_variant		null
	,Expression5	nvarchar ( max )	null
	,Variable5	uniqueidentifier	null
	,Value6		sql_variant		null
	,Expression6	nvarchar ( max )	null
	,Variable6	uniqueidentifier	null
	,Value7		sql_variant		null
	,Expression7	nvarchar ( max )	null
	,Variable7	uniqueidentifier	null
	,Value8		sql_variant		null
	,Expression8	nvarchar ( max )	null
	,Variable8	uniqueidentifier	null
	,Value9		sql_variant		null
	,Expression9	nvarchar ( max )	null
	,Variable9	uniqueidentifier	null )
as
begin
	declare	@gDistributionStep	uniqueidentifier
		,@gDistributionRoot	uniqueidentifier
		,@gExecution		uniqueidentifier
----------
	select
		@gDistributionStep=	Distribution
		,@gExecution=		Execution
	from
		damit.ExecutionLog
	where
		Id=			@gExecutionLog
----------
	select
		@gDistributionRoot=	Distribution
	--	,@gExecution=		Execution
	from
		damit.ExecutionLog
	where
			Id=		@gExecution
		and	Execution=	@gExecution
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
		,Value		sql_variant		null
		,Expression	nvarchar ( max )	null
		,Variable	uniqueidentifier	null
		,Sequence	int			null )
----------
	;with	cte	as
	(	select
			Variable=	v.Id					-- эта мультипеременная для цикла и поддерживает IsCurrent
		from
			damit.Variable	v					-- IsCurrent не проверяем, т.к. запрос может использоваться как внутри шага цикла Condition, так и вне его
			inner	join	damit.ExecutionLog	el	on
				el.Id=			v.ExecutionLog
			inner	join	damit.Parameter		p	on
				p.DistributionStep=	el.Distribution
			and	p.Alias=		v.Alias

			inner	join	damit.Parameter		pp	on	-- ???***переменную нельзя будет получить до инициализации IsCurrent в цикле Condition
				pp.Source=		p.Id
			and	pp.DistributionRoot=	p.DistributionRoot	--??? в той же выгрузке
			and	pp.Alias=		'ForEach'		-- захадкоженный признак мультипеременной для цикла Condition
			inner	join	damit.Distribution	d	on
				d.Id=			pp.DistributionStep
			inner	join	damit.TaskEntity		t	on
				t.Condition=		d.Task )
	insert
		@tTemp
	select
		t.Alias
		,t.Value
		,t.Expression
		,t.Variable
		,t.Sequence
	from
		( select
			t.Alias
			,t.Value
			,t.Expression
			,t.Variable
			,t.Sequence
			,Sequence2=	row_number()	over	( partition	by	t.Alias,	t.Sequence	order	by	t.Sequence2	desc )
		from
			( select
				Alias
				,Value
				,Expression
				,Variable=	null
				,Sequence
				,Sequence2=	3					-- настройка параметра для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter
			where
					DistributionRoot	is	null
				and	DistributionStep=	@gDistributionStep
				and	Source		is	null			-- для шаблона нельзя отнаследовать настройки из неизвестного источника
--				and	Alias		is	not	null
				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				Alias
				,Value
				,Expression
				,Variable=	null
				,Sequence
				,Sequence2=	6					-- настройка параметра для шага выгрузки
			from
				damit.Parameter
			where
					DistributionRoot=	@gDistributionRoot
				and	DistributionStep=	@gDistributionStep
				and	Source		is	null
--				and	Alias		is	not	null
				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				p.Alias
				,p.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	null
				,p.Sequence
				,Sequence2=	1					-- передача из другого шага ссылки на параметр для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter	c
				,damit.Parameter	p
			where
					c.DistributionRoot	is	null
				and	c.DistributionStep=	@gDistributionStep
				and	p.Id=			c.Source
				and	c.Alias		is	null
--				and	p.Alias		is	not	null
				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				c.Alias
				,p.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	null
				,p.Sequence
				,Sequence2=	2					-- передача из другого шага значения параметра для шага шаблонной выгрузки, даже если он не используется как шаблон
			from
				damit.Parameter	c
				,damit.Parameter	p
			where
					c.DistributionRoot	is	null
				and	c.DistributionStep=	@gDistributionStep
				and	p.Id=			c.Source
--				and	c.Alias		is	not	null
				and	c.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				p.Alias
				,p.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	null
				,p.Sequence
				,Sequence2=	4					-- передача из другого шага ссылки на параметр для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter	p	on
					p.Id=			c.Source
--				and	p.Alias		is	not	null
				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				left	join	( select				-- нельзя делать inner join damit.ExecutionLog для ссылки на параметры последующих ещё не выполненных шагов
							el.Distribution
							,v.Alias
						from
							damit.ExecutionLog	el
							,damit.Variable		v
						where
								el.Execution=	@gExecution
							and	v.ExecutionLog=	el.Id )	t	on
					t.Distribution=		p.DistributionStep
				and	t.Alias=		p.Alias
			where
					c.DistributionRoot=	@gDistributionRoot
				and	c.DistributionStep=	@gDistributionStep
				and	c.Alias			is	null
				and	t.Distribution		is	null		-- отдавать значение параметра только если нет заполненного оверрайда в переменных
			union	all
			select
				c.Alias
				,p.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	null
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
							damit.ExecutionLog	el		-- что делать при дублировании при join, если шаг выгрузки повторяется(например, из-за применения шаблона)?
							,damit.Variable		v
						where
								el.Execution=	@gExecution
							and	v.ExecutionLog=	el.Id )	t	on
					t.Distribution=		p.DistributionStep
				and	t.Alias=		p.Alias
			where
					c.DistributionRoot=	@gDistributionRoot
				and	c.DistributionStep=	@gDistributionStep
--				and	c.Alias		is	not	null
				and	c.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				and	t.Distribution	is	null			-- отдавать значение параметра только если нет заполненного оверрайда в переменных
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	null
				,Variable=	v.Id
				,v.Sequence
				,Sequence2=	9					-- значение переменной для шага выгрузки. если для переменной нет параметра, то её не наследуем по имени
			from
				damit.Variable	v
				left	join	cte	on
					cte.Variable=	v.Id
			where
					v.ExecutionLog=	@gExecutionLog			-- бесполезно- только если передавать значение между частями одного шага?
--				and	v.Alias	is	not	null			-- там уже not null, пишем только для соответствия другим запросам
				and	v.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )

				and	(	cte.Variable	is	null		--/это не мультпеременная для цикла Condition
					or	v.IsCurrent=	1 )			--\или единичная запись из мультпеременной
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	v.Id
				,v.Sequence
				,Sequence2=	7					-- см.4, передача из другого шага ссылки на переменную для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter		p	on
					p.Id=			c.Source
--				and	p.Alias		is	not	null
				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				inner	join	damit.ExecutionLog	el	on
					el.Distribution=	p.DistributionStep
				and	el.Execution=		@gExecution
				inner	join	damit.Variable		v	on
					v.ExecutionLog=		el.Id
				and	v.Alias=		p.Alias
				left	join	cte				on
					cte.Variable=		v.Id
			where
					c.DistributionRoot=	@gDistributionRoot
				and	c.DistributionStep=	@gDistributionStep
				and	c.Alias		is	null

				and	(	cte.Variable	is	null
					or	v.IsCurrent=	1 )
			union	all
			select
				c.Alias							-- следующий запрос ищет не через настоящее название в v.Alias
				,v.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	v.Id
				,v.Sequence
				,Sequence2=	8					-- см.5, передача из другого шага значения переменной для шага выгрузки
			from
				damit.Parameter	c
				inner	join	damit.Parameter		p	on
					p.Id=			c.Source
				inner	join	damit.ExecutionLog	el	on	-- что делать при дублировании при join, если шаг выгрузки повторяется(например, из-за применения шаблона)?
					el.Distribution=	p.DistributionStep
				and	el.Execution=		@gExecution
				inner	join	damit.Variable		v	on
					v.ExecutionLog=		el.Id
				and	v.Alias=		p.Alias
				left	join	cte				on
					cte.Variable=		v.Id
			where
					c.DistributionRoot=	@gDistributionRoot
				and	c.DistributionStep=	@gDistributionStep
--				and	c.Alias		is	not	null
				and	c.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )

				and	(	cte.Variable	is	null
					or	v.IsCurrent=	1 )
 )	t )	t
	where
		t.Sequence2=	1
----------
	insert
		@tResult
	select	--top	100	percent
		t.Sequence
		,Value0=	t0.Value
		,Expression0=	t0.Expression
		,Variable0=	t0.Variable
		,Value1=	t1.Value
		,Expression1=	t1.Expression
		,Variable1=	t1.Variable
		,Value2=	t2.Value
		,Expression2=	t2.Expression
		,Variable2=	t2.Variable
		,Value3=	t3.Value
		,Expression3=	t3.Expression
		,Variable3=	t3.Variable
		,Value4=	t4.Value
		,Expression4=	t4.Expression
		,Variable4=	t4.Variable
		,Value5=	t5.Value
		,Expression5=	t5.Expression
		,Variable5=	t5.Variable
		,Value6=	t6.Value
		,Expression6=	t6.Expression
		,Variable6=	t6.Variable
		,Value7=	t7.Value
		,Expression7=	t7.Expression
		,Variable7=	t7.Variable
		,Value8=	t8.Value
		,Expression8=	t8.Expression
		,Variable8=	t8.Variable
		,Value9=	t9.Value
		,Expression9=	t9.Expression
		,Variable9=	t9.Variable
	from
		( select
			Sequence
		from
			@tTemp
		group	by
			Sequence )	t
		left	join	@tTemp	t0	on
			t0.Alias=	@sAlias0
		and	isnull ( nullif ( t0.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t0.Sequence ) )	is	null	-- универсальное сравнение
		left	join	@tTemp	t1	on
			t1.Alias=	@sAlias1
		and	isnull ( nullif ( t1.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t1.Sequence ) )	is	null
		left	join	@tTemp	t2	on
			t2.Alias=	@sAlias2
		and	isnull ( nullif ( t2.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t2.Sequence ) )	is	null
		left	join	@tTemp	t3	on
			t3.Alias=	@sAlias3
		and	isnull ( nullif ( t3.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t3.Sequence ) )	is	null
		left	join	@tTemp	t4	on
			t4.Alias=	@sAlias4
		and	isnull ( nullif ( t4.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t4.Sequence ) )	is	null
		left	join	@tTemp	t5	on
			t5.Alias=	@sAlias5
		and	isnull ( nullif ( t5.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t5.Sequence ) )	is	null
		left	join	@tTemp	t6	on
			t6.Alias=	@sAlias6
		and	isnull ( nullif ( t6.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t6.Sequence ) )	is	null
		left	join	@tTemp	t7	on
			t7.Alias=	@sAlias7
		and	isnull ( nullif ( t7.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t7.Sequence ) )	is	null
		left	join	@tTemp	t8	on
			t8.Alias=	@sAlias8
		and	isnull ( nullif ( t8.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t8.Sequence ) )	is	null
		left	join	@tTemp	t9	on
			t9.Alias=	@sAlias9
		and	isnull ( nullif ( t9.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t9.Sequence ) )	is	null
	--order	by
	--	t0.Sequence
----------
	return
end
go
select	*	from	damit.GetVariables
(	null
	,null
	,null
	,null
	,null
	,null
	,null
	,null
	,null
	,null
	,null )