
--variable declaration
DECLARE @tableName nvarchar(50)
DECLARE @columnName nvarchar(50)
DECLARE @deleteData AS CURSOR
DECLARE @sqlCommand varchar(max)
DECLARE @dateDiff int =  ( SELECT DATEDIFF(Day, endRange, GETUTCDATE()) FROM [TimeRangeBookmarks] WHERE id = 31 )


--create cursor to loop through all of the tables in the database
SET @deleteData = CURSOR FOR
  SELECT isc.table_name, isc.column_name 
  FROM INFORMATION_SCHEMA.COLUMNS isc
    LEFT OUTER JOIN INFORMATION_SCHEMA.VIEWS isv ON
    isc.TABLE_CATALOG = isv.TABLE_CATALOG AND 
    isc.TABLE_SCHEMA = isv.TABLE_SCHEMA AND
    isc.TABLE_NAME = isv.TABLE_NAME
    WHERE 
      DATA_TYPE = 'datetime' and 
      isv.TABLE_NAME is null
    ORDER BY TABLE_NAME, COLUMN_NAME

--set the table name and column name for all tables and columns in the database
OPEN @deleteData
  FETCH NEXT FROM @deleteData INTO @tableName, @columnName
  --checks for keywords (ie: a column is called 'when')
  IF CHARINDEX('[', @columnname ) = 0 BEGIN
    SET @columnName = '[' + @columnName + ']'
  END

--begin cursor

WHILE @@FETCH_STATUS = 0 BEGIN

  --updates every table in the database by exactly the same amount
  SET @sqlCommand = 'UPDATE ' + @tableName + ' SET ' + @columnname + ' = DATEADD(DAY, ' + CONVERT(varchar(50), @dateDiff ) + ', ' + @columnname + ')'
  EXEC( @sqlCommand)

  FETCH NEXT FROM @deleteData INTO @tableName, @columnName

  IF CHARINDEX('[', @columnname ) = 0 BEGIN
    SET @columnName = '[' + @columnName + ']'
  END

  --close the cursor
END
CLOSE @deleteData;
DEALLOCATE @deleteData
