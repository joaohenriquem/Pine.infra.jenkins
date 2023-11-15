USE DBAPineCube
GO

ALTER PROCEDURE VerificaStatusBackup
AS
BEGIN
		declare @resultadostatus int

		set @resultadostatus = 0


		/*STEP 0 - Primeiramente temos que verificar qual a versão do SQL Server estamos pois caso seja um 2014 temos que verificar se
		estamos no node ativo ou no node ativo, pois somente o node ativo teremos backup diff e de log para verificar, sendo assim temos 2 grandes blocos
		de verificação o TRUE para 2014 com alwaysOn e FALSE para SQL 2008 onde temos uma instancia unica*/
		if (SELECT  CAST(SERVERPROPERTY ('ProductVersion') AS VARCHAR(10))) like '12%'
		BEGIN
		/*Caso base seja 2014*/
		---PRINT '2014'	
									/* INICIO- Verificação de backup para AlwayON*/
									if exists(
									SELECT count(*) as 'BasesCopiasPrimarias'
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
									   where  ISNULL(agstates.primary_replica, '')  = SERVERPROPERTY('servername'))
									   BEGIN
									   /*caso esteja como node ativo no alwaysON*/
									  IF OBJECT_ID('tempdb..#STATUSBACKUP') IS NOT NULL
										DROP TABLE #STATUSBACKUP

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

																	/* Verifica se existe alguma base com backup de log sem backup nas ultimas 12 horas */
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
										drop table #STATUSBACKUP

										---print @resultadostatus
										EXECUTE sp_user_counter9 @resultadostatus

									   END
									   else
										begin
									   /*caso esteja como node passivo no alwaysON*/
									   print 'Node passivo'
									   EXECUTE sp_user_counter9 0
									   end
									/* FIM - Verificação de backup para AlwayON*/
									END
		ELSE
		BEGIN
			/*Caso base seja 2008*/	
		---PRINT '2008'				
							 IF OBJECT_ID('tempdb..#STATUSBACKUP2') IS NOT NULL
										DROP TABLE #STATUSBACKUP2

								CREATE TABLE #STATUSBACKUP2 (
										[DATABASE_NAME] VARCHAR(40),
										LASTFULLBACKUP DATETIME,
										LASTDIFFERENTIAL DATETIME,
										LASTLOG DATETIME
								)

									INSERT INTO #STATUSBACKUP2 
									SELECT BS.DATABASE_NAME, 
										MAX(CASE WHEN BS.TYPE = 'D' THEN BS.BACKUP_FINISH_DATE ELSE NULL END) AS LASTFULLBACKUP,
										MAX(CASE WHEN BS.TYPE = 'I' THEN BS.BACKUP_FINISH_DATE ELSE NULL END) AS LASTDIFFERENTIAL,
										MAX(CASE WHEN BS.TYPE = 'L' THEN BS.BACKUP_FINISH_DATE ELSE NULL END) AS LASTLOG
									FROM MSDB.dbo.BACKUPSET BS
										INNER JOIN SYS.DATABASES D
										ON BS.DATABASE_NAME = D.NAME
										where d.recovery_model_desc = 'Full'
										GROUP BY BS.DATABASE_NAME
										ORDER BY BS.DATABASE_NAME ASC

								/* Verifica se existe alguma base com backup de log sem backup nas ultimas 12 horas */
									if exists (SELECT * FROM #STATUSBACKUP2
									WHERE LASTLOG < DATEADD(HOUR, -12, GETDATE()))
										begin
											set @resultadostatus = @resultadostatus + 1
										end
									else
										begin
											set @resultadostatus = @resultadostatus + 0
										end


								/* Verifica se existe alguma base com backup de diferencial sem backup nas ultimas 24 horas */
									if exists (SELECT * FROM #STATUSBACKUP2
									WHERE LASTDIFFERENTIAL < DATEADD(HOUR, -24, GETDATE()))
										begin
											set @resultadostatus = @resultadostatus + 10
										end
									else
										begin
											set @resultadostatus = @resultadostatus + 0
										end

									/* Verifica se existe alguma base com backup de diferencial sem backup nas ultimas 24 horas */
									if exists (SELECT * FROM #STATUSBACKUP2
									WHERE LASTFULLBACKUP < DATEADD(DAY, -8, GETDATE()))
										begin
											set @resultadostatus = @resultadostatus + 100
										end
									else
										begin
											set @resultadostatus = @resultadostatus + 0
										end

									drop table #STATUSBACKUP2

									---print @resultadostatus
									EXECUTE sp_user_counter9 @resultadostatus

		END
END










