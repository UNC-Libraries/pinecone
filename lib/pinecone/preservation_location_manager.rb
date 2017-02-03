require 'yaml'
require 'set'
require_relative 'preservation_location'
require_relative 'environment'

module Pinecone
  class PreservationLocationManager
    attr_reader :pres_locs
    :replica_paths
    :logger
    
    def initialize(loc_configs, replica_paths)
      @logger = Pinecone::Environment.logger
      
      @replica_paths = replica_paths
      @pres_locs = Hash.new
      
      loc_configs.each do |name, config|
        loc = Pinecone::PreservationLocation.new(name, config)
        @pres_locs[loc.base_path] = loc
        if !loc.is_available
          raise ArgumentError, "Preservation location #{loc.loc_key} at #{loc.base_path} is unavailable"
        end
      end
    end
    
    def get_bag_paths
      bag_paths = Array.new

      @pres_locs.each do |path, loc|
        bag_paths = bag_paths + loc.get_bag_paths
      end
      
      return bag_paths
    end
    
    def get_location_by_path(bag_path)
      @pres_locs.each do |loc_base, loc|
        if File.fnmatch loc.path, bag_path
          return loc
        end
      end
      
      @replica_paths.each do |replica_path|
        @pres_locs.each do |loc_base, loc|
          if bag_path.start_with? loc.get_replica_path(replica_path)
            return loc
          end
        end
      end
      
      return nil
    end
  end
end
