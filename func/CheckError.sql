use	damit
----------
if	object_id ( 'damit.CheckError' , 'fn' )	is	null
	exec	( 'create	function	damit.CheckError()	returns	int	as	begin	return	( -1 )	end' )
go
alter	function	damit.CheckError	-- �������� ������
(	@iError	int	)		-- ��� ������ sql ��������
returns	bit				-- 1=������, 0=��� ������, warning/hint �������� �� ���������; tinyint ��� ������ ������ � ���������?
as
----------
begin
	return	( case
			when	@iError<	0	then	1
			else					0
		end )
end
go
select	1	where	damit.CheckError	( -23746 )='true'