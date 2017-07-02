use	damit
----------
if	object_id ( 'dbo.ltrimm' , 'fn' )	is	null
	exec	( 'create	function	dbo.ltrimm()	returns	int	as	begin	return	1	end' )
go
alter	function	dbo.ltrimm
(	@sValue	varchar ( max )	)
returns	varchar ( max )
as
begin
	return	substring ( @sValue,	patindex ( '%[^'
					+	char ( 9 )
					+	char ( 10 )
					+	char ( 13 )
					+	char ( 32 )
					+	']%',	@sValue ),	len ( @sValue ) )
end
go
select	dbo.ltrimm	('	
  1dfghkdjfhgjkdh')