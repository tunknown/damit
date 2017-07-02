use	damit
----------
if	object_id ( 'damit.GetCompatibleData' , 'if' )	is	null
	exec	( 'create	function	damit.GetCompatibleData()	returns	table	as	return	( select	Error=	1/0 )' )
go
alter	function	damit.GetCompatibleData	-- получение совместимых выгрузок, в т.ч. и зацикленных
(	@gData	damit.TGUID	)
returns	table
as
-- учитывать, что выгрузка может быть несовместима сама с собой, т.е. независима от любых предыдущих выгрузок
----------
return	( with	cte	( Data,	Path,	IsProcessed,	IsClosed )	as
	(	select
			Data=		Data1
			,Path=		convert ( varbinary ( max ) , convert ( binary ( 16 ) , Data1 ) )
			,IsProcessed=	convert ( tinyint , 0 )
			,IsClosed
		from
			damit.DataData
		where
			Data2=		@gData
		union	all
		select
			dd.Data1
			,Path=		convert ( varbinary ( max ) , cte.Path+	convert ( binary ( 16 ) , dd.Data1 ) )
			,IsProcessed=	convert ( tinyint,	case	( charindex ( convert ( binary ( 16 ) , dd.Data1 ) , cte.Path )-	1 )%	16
									when	0	then	1
									else			0
								end	)
			,dd.IsClosed
		from
			damit.DataData	dd
			,cte
		where
				dd.Data2=	cte.Data
			and	dd.Data2<>	dd.Data1	-- чтобы не зациклиться на совместимости с самой собой
			and	cte.IsProcessed=	0	-- чтобы сложные циклы(например, через 1) не привели в бесконечную рекурсию
			and	cte.IsClosed=		0	)
	select
		Data
	from
		cte
	group	by
		Data )
go
select	*	from	damit.GetCompatibleData	( 'D5C04A05-B3FC-4671-8F1A-0C1F30160852' )