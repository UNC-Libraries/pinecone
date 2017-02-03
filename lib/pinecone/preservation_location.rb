require 'yaml'
require_relative 'environment'

module Pinecone
  class PreservationLocation
    attr_accessor :path
    attr_accessor :bag_pattern
    attr_accessor :base_path
    attr_reader :info, :loc_key
    
    def initialize(name, info)
      @base_path = File.absolute_path info["base_path"]
      @bag_pattern = info["bag_pattern"]
      @path = File.join(@base_path, @bag_pattern)
      @loc_key = name
      @info = info
    end
    
    def is_available()
      return @base_path != nil && File.directory?(@base_path) && File.readable?(@base_path)
    end
    
    # Returns the list of email addresses to contact for this location
    def get_contact_emails
      if @info == nil || !(@info.key? "contacts")
        return Array.new
      end
      
      return @info["contacts"]
    end
    
    # Returns a list of bag paths within this location
    def get_bag_paths
      bag_paths = Array.new
      
      Dir.glob(@path).each do |entry|
        if !(File.directory? entry) || entry == "." || entry == ".."
          next
        end
  
        bag_paths.push entry
      end
      
      return bag_paths
    end
    
    # Returns the replica path for this location
    def get_replica_path(replica_base_path)
      return File.join(replica_base_path, @loc_key)
    end
    
    # Gets the relative path for bag's path versus this location
    def get_relative_path(bag_path_string)
      bag_path = Pathname.new bag_path_string
      loc_path = Pathname.new @base_path
      
      return bag_path.relative_path_from(loc_path)
    end
  end
end