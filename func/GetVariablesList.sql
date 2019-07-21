if	db_id ( 'damit' )	is	not	null	-- ����� ������������ ������� ����
	use	damit
go
----------
if	object_id ( 'damit.GetVariablesList' , 'tf' )	is	null
	exec	( 'create	function	damit.GetVariablesList()	returns	@t	table	( i	int )	as	begin	return	end' )
go
alter	function	damit.GetVariablesList	-- ��������� ������ ���������� � ���������� �� ��������
(	@iExecutionLog	TId )
returns	@tResult	table
(	Name		varchar ( 256 )	not null
	,Counter	smallint	null )	-- damit.Variable+damit.Parameter �� ������������� ��� �������� ������� ���������
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
--		,Value		sql_variant		null
--		,Expression	nvarchar ( max )	null
		,Sequence	int			null )
-- ��������� ������������ ����� ������� � damit.GetVariables
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
			,Sequence2=	row_number()	over	( partition	by	t.Alias,	t.Sequence/*���� �������� ����� ������� � damit.Do, �� Sequence=1 ������ null*/	order	by	t.Sequence2	desc )
		from
			(
			select
				Alias
				,Value
				,Expression=	'-1'
				,Sequence
				,Sequence2=	-1					-- ��������� ��������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
			from
				damit.Parameter
			where
					DistributionRoot	is	null
				and	DistributionStep	is	null
				and	Source		is	null			-- ��� ������� ������ ������������� ��������� �� ������������ ���������
				and	Alias		is	not	null
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				p.Alias
				,Value=		case
							when	t.Distribution	is	null	then	p.Value
							else						t.Value	-- � �.�. Value=null
						end
				,Expression=	'1'--p.Expression
				,p.Sequence
				,Sequence2=	0					-- ���������� �������� ���� ��������
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
				and	p.Alias			is	not	null	-- ���������� ��������� ����������� ���������
			union	all
			select
				Alias
				,Value
				,Expression=	'3'
				,Sequence
				,Sequence2=	3					-- ��������� ��������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
			from
				damit.Parameter
			where
					DistributionRoot	is	null
				and	DistributionStep=	@iDistributionStep
				and	Source		is	null			-- ��� ������� ������ ������������� ��������� �� ������������ ���������
				and	Alias		is	not	null
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
			union	all
			select
				Alias
				,Value
				,Expression=	'6'
				,Sequence
				,Sequence2=	6					-- ��������� ��������� ��� ���� ��������
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
				,Sequence2=	1					-- �������� �� ������� ���� ������ �� �������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
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
				,Sequence2=	2					-- �������� �� ������� ���� �������� ��������� ��� ���� ��������� ��������, ���� ���� �� �� ������������ ��� ������
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
				,Sequence2=	4					-- �������� �� ������� ���� ������ �� �������� ��� ���� ��������
			from
				damit.Parameter	c
				inner	join	damit.Parameter	p	on
					p.Id=			c.Source
				and	p.Alias		is	not	null
--				and	p.Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				left	join	( select				-- ������ ������ inner join damit.ExecutionLog ��� ������ �� ��������� ����������� ��� �� ����������� �����
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
				and	t.Distribution		is	null			-- �������� �������� ��������� ������ ���� ��� ������������ ��������� � ����������
			union	all
			select
				c.Alias
				,p.Value
				,Expression=	'5'	--p.Expression
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
							damit.ExecutionLog	el	-- ��� ������ ��� ������������ ��� join, ���� ��� �������� �����������(��������, ��-�� ���������� �������)?
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
				and	t.Distribution	is	null		-- �������� �������� ��������� ������ ���� ��� ������������ ��������� � ����������
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	'9'--null
				,Sequence=	case	v.ExecutionLog
							when	@iExecutionLog	then	isnull ( v.Sequence,	 0xFFFFFFFF )+	0xFFFFFFFF	-- �������� ��������� �������� ���������� �������� ����
							else				v.Sequence
						end
				,Sequence2=	9					-- �������� ���������� ��� ���� ��������. ���� ��� ���������� ��� ���������, �� � �� ��������� �� �����
			from
				damit.Variable	v
				left	join	damit.Parameter	p	on
					p.DistributionRoot=	@iDistributionRoot
				and	(	p.DistributionStep=	@iDistributionStep
					or	p.DistributionStep	is	null )
				and	p.Alias=		v.Alias
			where
					v.ExecutionLog	in	( @iExecutionLog,	@iExecution )
--				and	Alias	is	not	null			-- ��� ��� not null, ����� ������ ��� ������������ ������ ��������
--				and	Alias		in	( @sAlias0,	@sAlias1,	@sAlias2,	@sAlias3,	@sAlias4,	@sAlias5,	@sAlias6,	@sAlias7,	@sAlias8,	@sAlias9 )
				and	p.DistributionRoot	is	null		-- ��������� ����������, ���������� ����� ����� ������������ �������
			union	all
			select
				v.Alias
				,v.Value
				,Expression=	'7'--p.Expression
				,v.Sequence
				,Sequence2=	7					-- ��.4, �������� �� ������� ���� ������ �� ���������� ��� ���� ��������
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
				c.Alias							-- ��������� ������ ���� �� ����� ��������� �������� � v.Alias
				,v.Value
				,Expression=	'8'	--p.Expression
				,v.Sequence
				,Sequence2=	8					-- ��.5, �������� �� ������� ���� �������� ���������� ��� ���� ��������
			from
				damit.Parameter	c
				inner	join	damit.Parameter		p	on
					p.Id=			c.Source
				inner	join	damit.ExecutionLog	el	on	-- ��� ������ ��� ������������ ��� join, ���� ��� �������� �����������(��������, ��-�� ���������� �������)?
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