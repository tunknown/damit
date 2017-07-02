use	damit
----------
if	object_id ( 'damit.ToDateTimeFromDateAndTime' , 'fn' )	is	null
	exec	( 'create	function	damit.ToDateTimeFromDateAndTime()	returns	datetime	as	begin	return	( 1/	0 )	end' )
go
alter	function	damit.ToDateTimeFromDateAndTime		-- сложение полей даты и времени
(	@dtDate		date			-- дата
	,@dtTime	datetime	)	-- время с отбрасываемой датой
returns	datetime
as
----------
begin
	return	( convert ( datetime , @dtDate )+	convert ( time , @dtTime ) )
end
go
select	getdate(),	damit.ToDateTimeFromDateAndTime	( getdate() , getdate() )
