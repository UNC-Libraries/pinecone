require 'sqlite3'

module Pinecone
  def Pinecone.setup_database(base_dir=".")
    db_file = File.join(base_dir, "pinecone.db")
    puts "Creating pinecone database at path #{db_file}"
    db = SQLite3::Database.new File.join(base_dir, "pinecone.db")

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
    
    return db
  end
end