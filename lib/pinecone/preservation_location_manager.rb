require 'yaml'
require 'set'
require_relative 'preservation_location'
require_relative 'environment'

module Pinecone
  class PreservationLocationManager
    attr_reader :pres_locs
    
    def initialize(paths)
      @pres_locs = Hash.new
      
      loc_keys = Set.new []
      paths.each do |path|
        abs_path = File.absolute_path path
        loc = Pinecone::PreservationLocation.new(abs_path)
        @pres_locs[abs_path] = loc
        
        # End program if there are multiple locations with the same key
        if loc_keys.include? loc.loc_key
          raise "Duplicate preservation location key #{loc.loc_key} for path #{abs_path}"
        end
        loc_keys.add loc.loc_key
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
      @pres_locs.each do |loc_path, loc|
        
        if bag_path.start_with? loc_path
          return loc
        end
      end
      
      return nil
    end
  end
end
