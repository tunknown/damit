sp_configure	'show advanced options',	1
GO
RECONFIGURE
GO
exec	sp_configure	'Ole Automation Procedures',	1
exec	sp_configure	'xp_cmdshell',			1
GO
RECONFIGURE
GO