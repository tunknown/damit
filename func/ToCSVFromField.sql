use	damit
----------
if	object_id ( 'damit.ToCSVFromField' , 'fn' )	is	null
	exec	( 'create	function	damit.ToCSVFromField()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.ToCSVFromField
(	@sValue	varchar ( max )	)
returns	varchar ( max )				-- ��������������� �������� � ������������� � csv ������� ����������
as
begin
	return	replace ( 
		replace ( 
		replace ( 
		replace ( 
		replace ( @sValue
		,char ( 13 )+	char ( 10 ),	' ' )	-- CRLF
		,char ( 10 ),	' ' )			-- ��������� � linux
		,char ( 13 ),	' ' )			-- ��������� � linux
		,';',		',' )
		,'"',		'�' )
end
go
select	damit.ToCSVFromField	('
1d;fghkdjf;hg�j
"kdh;')