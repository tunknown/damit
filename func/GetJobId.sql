if	db_id ( 'damit' )	is	not	null	-- иначе использовать текущую базу
	use	damit
go
----------
if	object_id ( 'damit.GetJobId' , 'tf' )	is	null
	exec	( 'create	function	damit.GetJobId()	returns	@t	table	( f	int )	as	begin	return	end' )
go
alter	function	damit.GetJobId()	-- преобразование строки параметров в датасет
returns	@table	table
(	JobId	uniqueidentifier
	,StepId	int )
as
begin
	declare	@sAppName		varchar ( 256 )
		,@sAppNamePattern	varchar ( 256 )
		,@sJodId		varchar ( 34 )
		,@sJodStepId		varchar ( 10 )
----------
	select	@sAppName=		app_name()	-- 'SQLAgent - TSQL JobStep (Job 0x76150EB277A3524EB05AACE03F7200E0 : Step 2)'
		,@sAppNamePattern=	'SQLAgent - TSQL JobStep (Job %s : Step %s)'
----------
	exec	xp_sscanf
			@sAppName
			,@sAppNamePattern
			,@sJodId	output
			,@sJodStepId	output
----------
	insert	@table
	select	damit.ToBinaryFromHexStr	( @sJodId )
		,convert ( int , replace ( @sJodStepId , ')' , '' ) )	-- xp_sscanf плохо парсит последний параметр в строке
----------
	return
end