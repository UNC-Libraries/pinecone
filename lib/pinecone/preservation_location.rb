require 'yaml'
require 'pathname'
require_relative 'environment'

module Pinecone
  class PreservationLocation
    attr_accessor :path
    attr_reader :info, :loc_key
    :loc_pathname
    
    def initialize(path)
      @path = path
      @loc_pathname = Pathname.new path
      info_file = File.join(path, "tps-info.yaml")
      if File.exist? info_file
        @info = YAML.load_file(info_file)
        @loc_key = @info["name"]
      else
        @loc_key = @path.rpartition("/").last
      end
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
      
      Dir.entries(@path).each do |entry|
        abs_path = File.join(@path, entry)
        if !(File.directory? abs_path) || entry == "." || entry == ".."
          next
        end
  
        bag_paths.push abs_path
      end
      
      return bag_paths
    end
    
    # Returns the replica path for this location
    def get_replica_path
      return File.join(Pinecone::Environment.get_replica_path, @loc_key)
    end
  end
end