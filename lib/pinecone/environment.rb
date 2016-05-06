require 'yaml'
require 'logger'
require 'sqlite3'
require 'pathname'

module Pinecone
  class Environment
    @@db = nil
    @@pres_locs = nil
    @@logger = nil
    @@replica_path = nil
    
    def Environment.setup_env(data_dir)
      @@data_dir = data_dir
      @@config = YAML.load_file File.join(data_dir, "config.yaml")
      
      self.set_db(@@config["database_path"])
      self.set_logger
      self.set_preservation_locations(@@config["preservation_locations"])
      self.set_replica_paths(@@config["replica_paths"])
    end
    
    def Environment.get_db
      return @@db
    end
    
    def Environment.set_db(db_path=nil)
      if db_path == nil
        db_file = File.join(@@data_dir, "pinecone.db")
      else
        db_file = db_path
      end
      @@db = SQLite3::Database.new db_file
    end
    
    def Environment.logger
      return @@logger
    end
  
    def Environment.set_logger()
      log_config = @@config["activity_log"]
      if log_config["filename"] == nil
        @@logger = Logger.new STDOUT
      else
        filename = log_config["filename"]
        if Pathname.new(filename).relative?
          filename = File.join(@@data_dir, log_config["filename"])
        end
        @@logger = Logger.new(filename, log_config["max_logs"], log_config["max_size"])
      end
      @@logger.sev_threshold = Object.const_get(log_config["level"])
    end
    
    def Environment.get_admin_email_addresses
      return @@config["admin_email"]
    end
    
    def Environment.get_from_email_address
      return @@config["from_email"]
    end
    
    def Environment.get_email_subject_prefix
      return @@config["email_subject_prefix"] || ""
    end
    
    def Environment.get_preservation_locations
      return @@pres_locs
    end
    
    def Environment.set_preservation_locations(pres_locs)
      @@pres_locs = pres_locs
      
      if @@pres_locs != nil
        # Resolve preservation locations relative to the data directory
        @@pres_locs.each do |name, info|
          if Pathname.new(info["path"]).relative?
            abs_path = File.join(@@data_dir, info["path"])
            @@logger.debug("Resolving relative preservation location #{info["path"]} to #{abs_path}")
            info["path"] = abs_path
          end
        end
      end
    end
    
    def Environment.get_data_dir
      return @@data_dir
    end
    
    def Environment.get_replica_paths
      return @@replica_paths
    end
    
    def Environment.set_replica_paths(replica_paths)
      @@replica_paths = replica_paths
      
      if @@replica_paths != nil
        # Resolve preservation locations relative to the data directory
        @@replica_paths.each do |name|
          if Pathname.new(name).relative?
            abs_path = File.join(@@data_dir, name)
            name = abs_path
          end
        end
      end
    end
    
    def Environment.get_periodic_validation_period
      time_diff = @@config["periodic_validation_period"]
      if !(time_diff.start_with? "-")
        time_diff = "-#{time_diff}"
      end
      return time_diff
    end
  end
end