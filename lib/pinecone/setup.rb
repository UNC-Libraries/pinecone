require 'sqlite3'

db = SQLite3::Database.new "pinecone.db"

db.execute( "drop table if exists bags" )
rows = db.execute <<-SQL
  create table bags (
    path TEXT PRIMARY KEY,
    lastValidated INTEGER,
    replicated BOOLEAN,
    complete BOOLEAN,
    completeProgress NUMERIC,
    valid BOOLEAN
  );
SQL