use	damit
----------
if	object_id ( 'damit.CheckError' , 'fn' )	is	null
	exec	( 'create	function	damit.CheckError()	returns	int	as	begin	return	( -1 )	end' )
go
alter	function	damit.CheckError	-- проверка ошибок
(	@iError	int	)		-- код ошибки sql процедур
returns	bit				-- 1=ошибка, 0=нет ошибки, warning/hint ошибками не считаются; tinyint для лучшей работы с индексами?
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