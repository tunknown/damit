use	damit
go
if	object_id ( 'damit.DoCheckFmtonly' , 'p' )	is	null
	exec	( 'create	proc	damit.DoCheckFmtonly	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoCheckFmtonly	-- проверка установки set fmtonly
	@iFmtonly	int	out	-- возврат только через out параметр, т.к. через return значение то ли не передаётся здесь, то ли не присваивается снаружи
as
----------
/* -- пример логики вызывающего скрипта
exec	damit.DoCheckFmtonly
----------
SET	FMTONLY	OFF			-- чтобы работала проверка if
----------
if	@iFmtonly=	1
begin
	-- здесь полезные действия, например, выдача форматного резалтсета
	SET	FMTONLY	On
end
*/
set	nocount	on			-- например, для того, чтобы OpenQuery не обнаружил "лишних" резалтсетов
----------
declare	@t	table
(	b	bit	)
----------
insert	@t	select	1
----------
select	@iFmtonly=	1-	@@rowcount
----------
return	--@iFmtonly
go
declare	@iFmtonly	int
set	fmtonly	on
exec	damit.DoCheckFmtonly	@iFmtonly	out
set	fmtonly	off
select	@iFmtonly
exec	damit.DoCheckFmtonly	@iFmtonly	out
select	@iFmtonly