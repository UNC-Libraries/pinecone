require 'sqlite3'

module Pinecone
  def Pinecone.setup_database
    Pinecone::Environment.logger.unknown "Initializing pinecone database in #{File.absolute_path Pinecone::Environment.get_data_dir}"
    
    db = Pinecone::Environment.get_db

    db.execute( "drop table if exists bags" )
    rows = db.execute <<-SQL
      create table bags (
        path TEXT PRIMARY KEY,
        valid BOOLEAN,
        lastValidated INTEGER,
        complete BOOLEAN,
        completeProgress NUMERIC,
        replicated BOOLEAN,
        isReplica BOOLEAN,
        originalPath TEXT,
        capturedTime INTEGER
      );
    SQL
    
    return db
  end
end