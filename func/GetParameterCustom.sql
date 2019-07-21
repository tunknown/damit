use	damit
----------
if	object_id ( 'damit.GetParameterCustom' , 'fn' )	is	null
	exec	( 'create	function	damit.GetParameterCustom()	returns	int	as	begin	return	1	end' )
go
alter	function	damit.GetParameterCustom
(	@iExecutionLog	TId
	,@sValue	nvarchar ( max )	)
returns	nvarchar ( max )
as
begin
	declare	@sResult	nvarchar ( max )
----------
	set	@sResult=	@sValue
----------
	if	@sResult	like	'%(*1*)%'
		set	@sResult=	replace ( @sResult,	'(*1*)',	convert ( varchar ( 256 ),	dateadd ( month,	-2,	getdate() ),	102 ) )
----------
	if	@sResult	like	'%(*2*)%'
		set	@sResult=	replace ( @sResult,	'(*2*)',	convert ( varchar ( 256 ),	getdate(),	102 ) )
----------
	return	@sResult
end
go
select	damit.GetParameterCustom	( null,	null )