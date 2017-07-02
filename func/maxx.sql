use	damit
go
if	object_id ( 'dbo.maxx' )	is	not	null
	drop	function	dbo.maxx
go
create	function	dbo.maxx
(	@oValue1	sql_variant,
	@oValue2	sql_variant	)
returns	sql_variant
with	schemabinding
as
begin
	return	case
			when	@oValue1>	@oValue2	then	isnull ( @oValue1 , @oValue2 )
			else						isnull ( @oValue2 , @oValue1 )
		end
end