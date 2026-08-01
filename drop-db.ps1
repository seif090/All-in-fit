Write-Host "Dropping obsolete AllInFit database..."
sqlcmd -S localhost -E -Q "IF DB_ID('AllInFit') IS NOT NULL BEGIN ALTER DATABASE [AllInFit] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [AllInFit]; END" -W 2>&1
Write-Host "Verifying drop..."
sqlcmd -S localhost -E -Q "SELECT name FROM sys.databases WHERE name='AllInFit'" -W 2>&1
Write-Host "Drop complete (no rows above means database removed)."

