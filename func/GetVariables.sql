if	db_id ( 'damit' )	is	not	null	-- ����� ������������ ������� ����
	use	damit
go
----------
if	object_id ( 'damit.GetVariables' , 'tf' )	is	null
	exec	( 'create	function	damit.GetVariables()	returns	@t	table	( i	int )	as	begin	return	end' )
go
alter	function	damit.GetVariables	-- ��������� �������� ����������
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
override �� Alias+Sequence, ���� ����� ���� Sequence*, �������� ��� ������, �� ������ �� ����� Sequence* �������� ������

��������� � ����������� � ����
damit.Parameter
1 ��� DistributionRoot=null ��������� ��� ���� �������
2 ��� DistributionStep=DistributionRoot
3 ��� DistributionStep �� Source- Alias ������ �� Source, ����� �� ������
4 ��� DistributionStep �� Source- Alias ������ �����
5 ��� DistributionStep �������� ����

damit.Variable
6 ��� ExecutionId ��������� ����
7 ��� ExecutionId �������� ����


Source	DistrRoot	Alias
damit.Parameter
0	0		1	3��������� ��� ���� �������
0	1		1	6��������� ��� ���� ��������
1	0		0	1������ �� ��������� ��� ���� �������, Alias ������ �� ������
1	0		1	2������ �� ��������� ��� ���� �������, Alias ������ �����
1	1		0	4������ �� ��������� ��� ���� ��������, Alias ������ �� ������
1	1		1	5������ �� ��������� ��� ���� ��������, Alias ������ �����
damit.Variable
0	1		1	--10��������� ��� ���� ��������- �� �����, �.�. ��������� ���������� ������ �����, � �� ������ ����
0	1		1	9��������� ��� ���� �������� ��� Root-��� ������������� �� ������� ����������, ��� damit.Parameter ������ ���
1	1		0	7������ �� ��������� ��� ���� ��������, Alias ������ �� ������	+damit.Parameter
1	1		1	8������ �� ��������� ��� ���� ��������, Alias ������ �����	+damit.Parameter
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
			Variable=	v.Id					-- ��� ���������������� ��� ����� � ������������ IsCurrent
		from
			damit.Variable	v					-- IsCurrent �� ���������, �.�. ������ ����� �������������� ��� ������ ���� ����� Condition, ��� � ��� ���
			inner	join	damit.ExecutionLog	el	on
				el.Id=			v.ExecutionLog
			inner	join	damit.Parameter		p	on
				p.DistributionStep=	el.Distribution
			and	p.Alias=		v.Alias

			inner	join	damit.Parameter		pp	on	-- ???***���������� ������ ����� �������� �� ������������� IsCurrent � ����� Condition
				pp.Source=		p.Id
			and	pp.DistributionRoot=	p.DistributionRoot	--??? � ��� �� ��������
			and	pp.Alias=		'ForEach'		-- ������������� ������� ���������������� ��� ����� Condition
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
				,Sequence2=	3					-- ��������� ��������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
			from
				damit.Parameter
			where
					DistributionRoot	is	null
				and	DistributionStep=	@gDistributionStep
				and	Source		is	null			-- ��� ������� ������ ������������� ��������� �� ������������ ���������
--				and	Alias		is	not	null
				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				Alias
				,Value
				,Expression
				,Variable=	null
				,Sequence
				,Sequence2=	6					-- ��������� ��������� ��� ���� ��������
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
				,Sequence2=	1					-- �������� �� ������� ���� ������ �� �������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
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
				,Sequence2=	2					-- �������� �� ������� ���� �������� ��������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
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
				,Sequence2=	4					-- �������� �� ������� ���� ������ �� �������� ��� ���� ��������
			from
				damit.Parameter	c
				inner	join	damit.Parameter	p	on
					p.Id=			c.Source
--				and	p.Alias		is	not	null
				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				left	join	( select				-- ������ ������ inner join damit.ExecutionLog ��� ������ �� ��������� ����������� ��� �� ����������� �����
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
				and	t.Distribution		is	null		-- �������� �������� ��������� ������ ���� ��� ������������ ��������� � ����������
			union	all
			select
				c.Alias
				,p.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	null
				,p.Sequence
				,Sequence2=	5					-- �������� �� ������� ���� �������� ��������� ��� ���� ��������
			from
				damit.Parameter	c
				inner	join	damit.Parameter	p	on
					p.Id=			c.Source
				left	join	( select				-- ������ ������ inner join damit.ExecutionLog ��� ������ �� ��������� ����������� ��� �� ����������� �����
							el.Distribution
							,v.Alias
						from
							damit.ExecutionLog	el		-- ��� ������ ��� ������������ ��� join, ���� ��� �������� �����������(��������, ��-�� ���������� �������)?
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
				and	t.Distribution	is	null			-- �������� �������� ��������� ������ ���� ��� ������������ ��������� � ����������
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	null
				,Variable=	v.Id
				,v.Sequence
				,Sequence2=	9					-- �������� ���������� ��� ���� ��������. ���� ��� ���������� ��� ���������, �� � �� ��������� �� �����
			from
				damit.Variable	v
				left	join	cte	on
					cte.Variable=	v.Id
			where
					v.ExecutionLog=	@gExecutionLog			-- ����������- ������ ���� ���������� �������� ����� ������� ������ ����?
--				and	v.Alias	is	not	null			-- ��� ��� not null, ����� ������ ��� ������������ ������ ��������
				and	v.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )

				and	(	cte.Variable	is	null		--/��� �� ��������������� ��� ����� Condition
					or	v.IsCurrent=	1 )			--\��� ��������� ������ �� ���������������
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	v.Id
				,v.Sequence
				,Sequence2=	7					-- ��.4, �������� �� ������� ���� ������ �� ���������� ��� ���� ��������
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
				c.Alias							-- ��������� ������ ���� �� ����� ��������� �������� � v.Alias
				,v.Value
				,Expression=	isnull ( p.Expression,	c.Expression )
				,Variable=	v.Id
				,v.Sequence
				,Sequence2=	8					-- ��.5, �������� �� ������� ���� �������� ���������� ��� ���� ��������
			from
				damit.Parameter	c
				inner	join	damit.Parameter		p	on
					p.Id=			c.Source
				inner	join	damit.ExecutionLog	el	on	-- ��� ������ ��� ������������ ��� join, ���� ��� �������� �����������(��������, ��-�� ���������� �������)?
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
		and	isnull ( nullif ( t0.Sequence,	t.Sequence ),	nullif ( t.Sequence,	t0.Sequence ) )	is	null	-- ������������� ���������
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