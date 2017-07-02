use	damit
----------
if	object_id ( 'damit.ToBinaryFromHexStr' , 'fn' )	is	null
	exec	( 'create	function	damit.ToBinaryFromHexStr()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.ToBinaryFromHexStr
(	@sValue	varchar ( 38 )	)	-- 38=максимальный размер гуида в текстовом виде
returns	varbinary ( 256 )
as
begin
	declare	@iPos		int
		,@iHalfLeft	tinyint
		,@iHalfRight	tinyint
		,@iLen		tinyint
		,@vResult	varbinary ( 256 )
		,@i		tinyint
----------
	select	@vResult=	0x
		,@sValue=	reverse ( replace ( replace ( replace ( replace ( upper ( @sValue ) , '0x' , '' ) , '-' , '' ) , '}' , '' ) , '{' , '' ) )	-- reverse чтобы 0x1 выравнивался в 0x01
		,@iPos=		1
		,@iLen=		len ( @sValue )
----------
	while	@iPos<=	@iLen
		select	@iHalfRight=	ascii ( substring ( @sValue,	@iPos,		1 ) )
			,@i=		@iHalfRight-	case
								when	@iHalfRight	between	48/*0*/	and	57/*9*/	then	48/*0*/
								when	@iHalfRight	between	65/*A*/	and	70/*F*/	then	55/*A-10*/
								else								null	-- при символе вне [0-9A-F]
							end
			,@iHalfLeft=	ascii ( substring ( @sValue,	@iPos+	1,	1 ) )
			,@vResult=	convert ( varbinary ( 1 ),	isnull ( ( @iHalfLeft-	case
													when	@iHalfLeft	between	48/*0*/	and	57/*9*/	then	48/*0*/
													when	@iHalfLeft	between	65/*A*/	and	70/*F*/	then	55/*A-10*/
													else								null
												end )*	16,	0 )+	@i )+	@vResult
			,@iPos=		@iPos+	2
----------
	return	@vResult
end
go
select	damit.ToBinaryFromHexStr	('0x054AC0D5FCB371468F1A0C1F30160852')
	,damit.ToBinaryFromHexStr	('{D5C04A05-B3FC-4671-8F1A-0C1F30160852}')