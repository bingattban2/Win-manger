using System;
using System.IO;
using Microsoft.Data.Sqlite;
using SQLitePCL;

namespace AlTamam.Infrastructure;

public interface IClock
{
    DateTimeOffset Now { get; }
    DateTime Today { get; }
}

public class SystemClock : IClock
{
    public DateTimeOffset Now => DateTimeOffset.Now;
    public DateTime Today => DateTime.Today;
}

public class DatabaseSetup
{
    private readonly string _connectionString;

    public DatabaseSetup(string databasePath)
    {
        // Initializes the e_sqlcipher bundle
        Batteries_V2.Init();

        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = databasePath,
            Mode = SqliteOpenMode.ReadWriteCreate
        };

        _connectionString = builder.ToString();
    }

    public SqliteConnection CreateEncryptedConnection(string password)
    {
        // Securely pass password to builder instead of PRAGMA injection
        var builder = new SqliteConnectionStringBuilder(_connectionString)
        {
            Password = password
        };

        var connection = new SqliteConnection(builder.ToString());
        connection.Open();

        // Setup configurations
        using (var command = connection.CreateCommand())
        {
            // Enable WAL mode (where supported), foreign keys, etc.
            command.CommandText = "PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000;";
            command.ExecuteNonQuery();
        }

        return connection;
    }

    public void Bootstrap(SqliteConnection connection)
    {
        using var command = connection.CreateCommand();
        // Create basic seed table to verify schema bootstrap
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS Sites (
                SiteId TEXT PRIMARY KEY,
                VisibleName TEXT NOT NULL,
                IsSystemSite INTEGER NOT NULL,
                ActiveFlag INTEGER NOT NULL,
                CreatedAt TEXT NOT NULL
            );

            INSERT OR IGNORE INTO Sites (SiteId, VisibleName, IsSystemSite, ActiveFlag, CreatedAt)
            VALUES ('seed-unspecified', 'غير محدد', 1, 1, datetime('now'));
        ";
        command.ExecuteNonQuery();
    }
}
