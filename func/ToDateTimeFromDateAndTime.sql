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
begin
	return	( dateadd ( ms,	datediff ( ms,	0,	@dtTime ),	convert ( datetime,	@dtDate ) ) )	-- после sql2008 + не работает
end
go
select	getdate(),	damit.ToDateTimeFromDateAndTime	( getdate() , '23:59:59.997' )
