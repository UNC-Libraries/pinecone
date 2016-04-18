require 'yaml'
require 'logger'
require 'sqlite3'
require 'pathname'
require 'active_support/inflector'

module Pinecone
  class Environment
    @@db = nil
    @@pres_locs = nil
    @@logger = nil
    @@replica_path = nil
    
    def Environment.setup_env(data_dir)
      @@data_dir = data_dir
      @@config = YAML.load_file File.join(data_dir, "config.yaml")
      
      self.set_db
      self.set_logger
      self.set_preservation_locations(@@config["preservation_locations"])
      self.set_replica_paths(@@config["replica_paths"])
    end
    
    def Environment.get_db
      return @@db
    end
    
    def Environment.set_db
      db_file = File.join(@@data_dir, "pinecone.db")
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
        @@logger = Logger.new(File.join(@@data_dir, log_config["filename"]), log_config["max_logs"], log_config["max_size"])
      end
    
      @@logger.sev_threshold = ActiveSupport::Inflector.constantize log_config["level"]
    end
    
    def Environment.get_admin_email_addresses
      return @@config["admin_email"]
    end
    
    def Environment.get_from_email_address
      return @@config["from_email"]
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