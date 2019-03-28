  declare @year nvarchar(max)
  set @year =( select year(getdate()) )

  delete from securityUsers
  where LEFT(UserName, 4)= cast(@year as nvarchar)
