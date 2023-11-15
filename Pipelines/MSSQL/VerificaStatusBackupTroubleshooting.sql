CREATE TABLE #STATUSBACKUP (
[DATABASE_NAME] VARCHAR(40),
LASTFULLBACKUP DATETIME,
LASTDIFFERENTIAL DATETIME,
LASTLOG DATETIME
)

INSERT INTO #STATUSBACKUP 
SELECT BS.DATABASE_NAME, 
	MAX(CASE WHEN BS.TYPE = 'D' THEN BS.BACKUP_FINISH_DATE ELSE NULL END) AS LASTFULLBACKUP,
	MAX(CASE WHEN BS.TYPE = 'I' THEN BS.BACKUP_FINISH_DATE ELSE NULL END) AS LASTDIFFERENTIAL,
	MAX(CASE WHEN BS.TYPE = 'L' THEN BS.BACKUP_FINISH_DATE ELSE NULL END) AS LASTLOG
FROM MSDB.dbo.BACKUPSET BS
	INNER JOIN SYS.DATABASES D
	ON BS.DATABASE_NAME = D.NAME
	where d.recovery_model_desc = 'Full'
	and d.name in (SELECT
dbcs.database_name AS [DatabaseName]
FROM master.sys.availability_groups AS AG
LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
ON AG.group_id = agstates.group_id
INNER JOIN master.sys.availability_replicas AS AR
ON AG.group_id = AR.group_id
INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs
ON arstates.replica_id = dbcs.replica_id
LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs
ON dbcs.replica_id = dbrs.replica_id AND dbcs.group_database_id = dbrs.group_database_id
where  ISNULL(agstates.primary_replica, '')  = SERVERPROPERTY('servername') )
	GROUP BY BS.DATABASE_NAME
	ORDER BY BS.DATABASE_NAME ASC
	
if exists (SELECT * FROM #STATUSBACKUP
WHERE LASTLOG < DATEADD(HOUR, -12, GETDATE()))
begin
	set @resultadostatus = @resultadostatus + 1
end
else
begin
	set @resultadostatus = @resultadostatus + 0
end


/* Verifica se existe alguma base com backup de diferencial sem backup nas ultimas 24 horas */
if exists (SELECT * FROM #STATUSBACKUP
WHERE LASTDIFFERENTIAL < DATEADD(HOUR, -24, GETDATE()))
begin
	set @resultadostatus = @resultadostatus + 10
end
else
begin
	set @resultadostatus = @resultadostatus + 0
end

/* Verifica se existe alguma base com backup de diferencial sem backup nas ultimas 24 horas */
if exists (SELECT * FROM #STATUSBACKUP
WHERE LASTFULLBACKUP < DATEADD(DAY, -8, GETDATE()))
begin
	set @resultadostatus = @resultadostatus + 100
end
else
begin
	set @resultadostatus = @resultadostatus + 0
end
select * from #STATUSBACKUP	



