require 'yaml'
require 'set'
require_relative 'preservation_location'
require_relative 'environment'

module Pinecone
  class PreservationLocationManager
    attr_reader :pres_locs
    
    def initialize(loc_configs)
      @pres_locs = Hash.new
      
      loc_configs.each do |name, config|
        loc = Pinecone::PreservationLocation.new(name, config)
        @pres_locs[loc.path] = loc
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
