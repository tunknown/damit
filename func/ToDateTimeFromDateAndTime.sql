use	damit
----------
if	object_id ( 'damit.ToDateTimeFromDateAndTime' , 'fn' )	is	null
	exec	( 'create	function	damit.ToDateTimeFromDateAndTime()	returns	datetime	as	begin	return	( 1/	0 )	end' )
go
alter	function	damit.ToDateTimeFromDateAndTime		-- �������� ����� ���� � �������
(	@dtDate		date			-- ����
	,@dtTime	datetime	)	-- ����� � ������������� �����
returns	datetime
as
----------
begin
	return	( convert ( datetime , @dtDate )+	convert ( time , @dtTime ) )
end
go
select	getdate(),	damit.ToDateTimeFromDateAndTime	( getdate() , getdate() )
