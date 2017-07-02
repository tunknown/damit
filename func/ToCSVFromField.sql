use	damit
----------
if	object_id ( 'damit.ToCSVFromField' , 'fn' )	is	null
	exec	( 'create	function	damit.ToCSVFromField()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.ToCSVFromField
(	@sValue	varchar ( max )	)
returns	varchar ( max )				-- преобразователь значени€ к представлению в csv формате ћикрософта
as
begin
	return	replace ( 
		replace ( 
		replace ( 
		replace ( 
		replace ( @sValue
		,char ( 13 )+	char ( 10 ),	' ' )	-- CRLF
		,char ( 10 ),	' ' )			-- недобитки с linux
		,char ( 13 ),	' ' )			-- недобитки с linux
		,';',		',' )
		,'"',		'У' )
end
go
select	damit.ToCSVFromField	('
1d;fghkdjf;hgУj
"kdh;')