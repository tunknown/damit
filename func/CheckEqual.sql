use	damit
----------
if	object_id ( 'damit.CheckEqual' , 'fn' )	is	null
	exec	( 'create	function	damit.CheckEqual()	returns	int	as	begin	return	( -1 )	end' )
go
alter	function	damit.CheckEqual	-- проверка равенства
(	@oValue1	sql_variant
	,@oValue2	sql_variant	)
returns	bit
as
----------
begin
	return	( case
			when	nullif ( checksum ( @oValue1 ) , checksum ( @oValue2 ) )	is	null	then	1
			else												0
		end )
end
go
declare	@dt	datetime,	@dts	smalldatetime
select	@dt=	getdate(),	@dts=	@dt
select	1	where	damit.CheckEqual	( @dt , @dts )='true'