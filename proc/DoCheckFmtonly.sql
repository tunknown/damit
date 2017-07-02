use	damit
go
if	object_id ( 'damit.DoCheckFmtonly' , 'p' )	is	null
	exec	( 'create	proc	damit.DoCheckFmtonly	as	select	ObjectNotCreated=	1/0' )
go
alter	proc	damit.DoCheckFmtonly	-- �������� ��������� set fmtonly
	@iFmtonly	int	out	-- ������� ������ ����� out ��������, �.�. ����� return �������� �� �� �� ��������� �����, �� �� �� ������������� �������
as
----------
/* -- ������ ������ ����������� �������
exec	damit.DoCheckFmtonly
----------
SET	FMTONLY	OFF			-- ����� �������� �������� if
----------
if	@iFmtonly=	1
begin
	-- ����� �������� ��������, ��������, ������ ���������� ����������
	SET	FMTONLY	On
end
*/
set	nocount	on			-- ��������, ��� ����, ����� OpenQuery �� ��������� "������" �����������
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