require 'yaml'

module Pinecone
  class PreservationLocation
    attr_accessor :path
    attr_reader :info
    
    def initialize(path)
      @path = path
      info_file = File.join(path, "tps-info.yaml")
      if File.exist? info_file
        @info = YAML.load_file(info_file)
      end
    end
    
    def get_contact_emails
      if @info == nil || !(@info.key? "contacts")
        return Array.new
      end
      
      return @info["contacts"]
    end
    
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
    
  end
end