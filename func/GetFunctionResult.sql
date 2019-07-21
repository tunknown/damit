use	damit
----------
if	object_id ( 'damit.GetFunctionResult' , 'fn' )	is	null
	exec	( 'create	function	damit.GetFunctionResult()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.GetFunctionResult	-- выполнение функции по имени (в процедурном стиле)
(	@iExecutionLog	TId
	,@sFunction	nvarchar ( 1024 )	-- название функции на локальном сервере
	,@sValue	nvarchar ( max ) )	-- параметр функции
returns	nvarchar ( max )
as
begin
	declare	@sResult	nvarchar ( max )
----------
	if	@sFunction	is	null
		set	@sResult=	@sValue
	else
		exec	@sResult=	@sFunction			-- вызываем функцию с первым параметром в процедурном стиле
						@iExecutionLog		-- параметры в фиксированном порядке, а не по имени
						,@sValue
----------
	return	@sResult
end
go
select	damit.GetFunctionResult	( null,	null,	null )