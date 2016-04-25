require 'bagit'
require_relative 'environment'

module Pinecone
  class PreservationBag
    attr_accessor :bag, :bag_path
    :db
    :env
    attr_reader :is_replica
    
    def initialize(bag_path, is_replica=nil)
      if !(File.exist? bag_path)
        raise "Bag path #{bag_path} did not exist, cannot create PreservationBag"
      end
      @bag_path = File.absolute_path bag_path
      @bag = BagIt::Bag.new @bag_path
      @db = Pinecone::Environment.get_db
      @is_replica = is_replica
      
      # Create database entry for this bag if it does not already exist
      @db.execute("insert or ignore into bags (path, isReplica, capturedTime) values (?, ?, CURRENT_TIMESTAMP) ",
          @bag_path, "#{(@is_replica == true)? 1 : 0}")
    end
    
    def bag_name
      return @bag_path.rpartition("/").last
    end
    
    # Validates the bag, returning true if valid, or an array of errors if not
    def report_validity(success)
      @db.execute("update bags set lastValidated = CURRENT_TIMESTAMP, valid = '#{(success)? 1 : 0}' where path = '#{@bag_path}'")
  
      return success
    end
    
    # Checks that the bag is consistent (checksums match)
    def consistent?
      return report_validity(@bag.consistent?)
    end
    
    # Checks that the bag is both complete and consistent.
    def valid?
      return report_validity(@bag.valid?)
    end
    
    # Checks that the size of the data and number of files matches expected values
    def valid_oxum?
      return report_validity(@bag.valid_oxum?)
    end
    
    def is_replica?
      if @is_replica == nil
        @is_replica = @db.get_first_row("select isReplica from bags where path = ?", @bag_path)[0] == 1
      end
      return @is_replica
    end
    
    # Verifies that a bag is complete, if so then performs consistency checks.
    # If the bag was incomplete, attempts to determine if the bag is still being added to instead of failing
    def validate_if_complete
      if @bag.complete?
        # Bag was complete, proceed with the more intensive parts 
        @db.execute("update bags set complete = 1 where path = '#{@bag_path}'")
    
        return consistent?
      end
      
      # Check that the bag has a manifest before checking completeness further
      if @bag.manifest_files.length == 0
        fileCount = Dir[File.join(bag_path, "**", "*")].length
        return completeness_progress(fileCount)? "inprogress" : errors
      end
  
      # Errors come back as a string if there is only one of them, normalize that
      errors = get_errors(:completeness)
  
      # Fail this @bag if it contains any extra files
      if errors.any? { |error| error.end_with? "is present but not manifested" } ||
          errors.any? { |error| error.end_with? "is a manifested tag but not present" }
    
        @db.execute("update bags set valid = 0 where path = '#{@bag_path}'")
        return false
      end
      
      return completeness_progress(errors.length)? "inprogress" : errors
    end
    
    # Determines and tracks if the bag appears to be in progress of being created
    def completeness_progress(count)
      # See if the number of missing objects has changed since the last run
      row = @db.get_first_row("select completeProgress from bags where path = '#{@bag_path}'")

      # No movement, assume that the bag is actually incomplete
      if row[0] != nil && count == row[0]
        @db.execute("update bags set lastValidated = CURRENT_TIMESTAMP, valid = 0 where path = '#{@bag_path}'")
        return false
      end
      
      # Things are still moving, give it more time
      @db.execute("update bags set completeProgress = '#{count}' where path = '#{@bag_path}'")
      return true
    end
    
    def get_errors(type)
      errors = @bag.errors.on(type)
      if errors.is_a? String
        errors = [errors]
      end
      return errors
    end
    
    def get_all_errors
      completeness = get_errors(:completeness)
      consistency = get_errors(:consistency)
      
      result = []
      if completeness != nil
        result = result + completeness
      end
      
      if consistency != nil
        result = result + consistency
      end
      
      return result
    end
  end
end