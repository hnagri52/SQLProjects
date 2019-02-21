DROP TABLE IF EXISTS timerange2
SELECT *
INTO TIMERANGE2
FROM TimeRangeBookmarks




--variable declaration
DECLARE @yearChecks AS int;
DECLARE @tableName nvarchar(50)
DECLARE @columnName nvarchar(50)
DECLARE @deleteData AS CURSOR
DECLARE @temp varchar(max)
DECLARE @outerloop int
DECLARE @innerloop_1stPass int
DECLARE @innerloop_2ndPass int
DECLARE @donecalclowestdatediff bit
DECLARE @YEARCOUNT int = 0
declare @lowestdatediff int = 0
SET @outerloop = 0
SET @innerloop_1stPass = 0
SET @innerloop_2ndPass = 0
SET @donecalclowestdatediff = 0

--create cursor to loop through all of the tables in the database
SET @deleteData = CURSOR FOR
SELECT isc.table_name
FROM INFORMATION_SCHEMA.COLUMNS isc
LEFT OUTER JOIN INFORMATION_SCHEMA.VIEWS isv ON isc.TABLE_CATALOG = isv.TABLE_CATALOG
    AND isc.TABLE_SCHEMA = isv.TABLE_SCHEMA
    AND isc.TABLE_NAME = isv.TABLE_NAME
WHERE DATA_TYPE = 'datetime' and isv.TABLE_NAME is null AND ISC.TABLE_NAME = 'TIMERANGE2'
ORDER BY TABLE_NAME, COLUMN_NAME


  OPEN @deleteData
FETCH NEXT FROM @deleteData INTO @tableName
IF CHARINDEX('[', @tableName ) = 0 BEGIN   
  SET @tableName = '[' + @tableName + ']'
END
print @tableName

--begin cursor
SET @outerloop = @@FETCH_STATUS
WHILE @outerloop = 0
BEGIN

set @yearcount = 0
set @lowestdatediff = 0 

DROP TABLE IF EXISTS ##X
DROP TABLE IF EXISTS ##Y
SET @innerloop_2ndPass = 0


--delete the unwanted years to allow maximal date shift
IF @yearChecks > 1
  BEGIN
  --obtain the year with the most data
    SET @temp = 'SELECT DISTINCT TOP(1) (YEAR (' + @columnName + ')) YR, COUNT(*) NUMROWS INTO ##Y FROM ' + @tableName + ' GROUP BY (YEAR (' + @columnName + ' )) ORDER BY NUMROWS DESC'
    EXEC (@temp) 
    SET @yearChecks = (SELECT YR FROM ##Y)
    SET @temp = 'DELETE FROM ' + @tableName + ' where year( ' + @columnName + ') != ' + CONVERT(varchar(50),@yearChecks)
    EXEC (@temp)
    PRINT 'done delete'
  END

--Obtain the lowest shift date difference to shift the data by
DECLARE @ParmDefinition nvarchar(500);
DECLARE @sqlcommand nvarchar(max)
DECLARE @lowestNumber int

DECLARE columns_cursor_1stPass CURSOR FOR 

SELECT COLUMN_NAME 
FROM  INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE = 'DATETIME' and TABLE_NAME = @tableName
ORDER BY COLUMN_NAME

OPEN columns_cursor_1stPass  
FETCH NEXT FROM columns_cursor_1stPass INTO @columnname 
IF CHARINDEX('[', @columnName ) = 0 BEGIN   
  SET @columnName = '[' + @columnName + ']'
END


WHILE @innerloop_1stPass = 0 and @donecalclowestdatediff = 0
       BEGIN
       --obtain the amount of years in the table
SET @temp = ' select count (distinct (year (' + @columnName + ' ))) as cd into ##X from ' + @tableName + ' where ' + @columnName + ' is not null '
EXEC (@temp)
SET @yearChecks = (SELECT cd FROM ##X)

              DECLARE @sqlcommand1 nvarchar(max)
               DECLARE @currentmindatediff int
               SET @sqlcommand1 = 'select @date = min(DATEDIFF( DAY,' + @columnname +', GETUTCDATE() -1))  from ' + @tablename
               DECLARE @ParamDefinition nvarchar(500);
               SET @ParamDefinition = N'@date int OUTPUT';  
               EXECUTE sp_executesql @sqlcommand1, @ParamDefinition, @date=@currentmindatediff OUTPUT;  


                IF @lowestdatediff = 0 BEGIN
                  SET @lowestdatediff = @currentmindatediff
                END
                IF @YEARCOUNT = 0
                SET @YEARCOUNT = @yearChecks

                IF @lowestdatediff > @currentmindatediff BEGIN
                  SET @lowestdatediff = @currentmindatediff
                END
                IF @yearChecks > @yearcount BEGIN
                  SET @yearcount = @yearChecks
                END

                FETCH NEXT FROM columns_cursor_1stPass INTO @columnname
                 IF CHARINDEX('[', @columnName ) = 0 BEGIN   
                   SET @columnName = '[' + @columnName + ']'
                 END
                  SET @innerloop_1stPass = @@FETCH_STATUS
                  IF @@FETCH_STATUS != 0 BEGIN
                    SET @outerloop = 0
                    SET @donecalclowestdatediff = 1
                  END
                  if @donecalclowestdatediff != 0
                    set @innerloop_1stPass = -1
      
       END 
CLOSE columns_cursor_1stPass  
DEALLOCATE columns_cursor_1stPass 

print @yearcount
print @lowestdatediff



DECLARE columns_cursor_2ndPass CURSOR FOR 

SELECT COLUMN_NAME 
FROM  INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE = 'DATETIME' and TABLE_NAME = @tableName
ORDER BY COLUMN_NAME

OPEN columns_cursor_2ndPass 
FETCH NEXT FROM columns_cursor_2ndPass INTO @columnname
IF CHARINDEX('[', @columnName ) = 0 BEGIN   
  SET @columnName = '[' + @columnName + ']'
END


WHILE @innerloop_2ndPass = 0 and @donecalclowestdatediff = 1 BEGIN  
--applies no shift if there is a null value
  IF coalesce(@lowestdatediff,0) != 0 BEGIN
    SET @sqlCommand = 'UPDATE ' + @tableName + ' SET ' + @columnname + ' = DATEADD(DAY, ' + CONVERT(varchar(50), @lowestdatediff ) + ', ' + @columnname + ')'
    EXEC( @sqlCommand)
  END 

  FETCH NEXT FROM columns_cursor_2ndPass INTO @columnname
  IF CHARINDEX('[', @columnName ) = 0 BEGIN   
    SET @columnName = '[' + @columnName + ']'
  END

    SET @innerloop_2ndPass = @@FETCH_STATUS
    IF @@FETCH_STATUS != 0 BEGIN
      SET @outerloop = 0
    END

END 
CLOSE columns_cursor_2ndPass  
DEALLOCATE columns_cursor_2ndPass 


--close the cursor
FETCH NEXT FROM @deleteData INTO @tableName, @columnName
IF CHARINDEX('[', @tableName ) = 0 BEGIN   
  SET @tableName = '[' + @tableName + ']'
END
print @tableName
IF CHARINDEX('[', @columnName ) = 0 BEGIN   
  SET @columnName = '[' + @columnName + ']'
END

  SET @outerloop = @@FETCH_STATUS
  IF @outerloop = -1 
    SET @innerloop_1stPass = -1
  ELSE 
    SET @innerloop_1stPass = 0

   

END
CLOSE @deleteData;
DEALLOCATE @deleteData

--DROP TABLE IF EXISTS timerange2
--SELECT *
--INTO TIMERANGE2
--FROM TimeRangeBookmarks
