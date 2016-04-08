require 'bagit'

module Pinecone
  class PreservationBag
    attr_accessor :bag, :db, :bag_path
    
    def initialize(bag_path, db)
      if !(File.exist? bag_path)
        raise "Bag path #{bag_path} did not exist, cannot create PreservationBag"
      end
      @bag_path = bag_path
      @bag = BagIt::Bag.new bag_path
      @db = db
      
      @db.execute("insert or ignore into bags (path) values (?) ", [bag_path])
    end
    
    def bag_name
      return @bag_path.rpartition("/").last
    end
    
    # Validates the bag, returning true if valid, or an array of errors if not
    def report_validity(success)
      @db.execute("update bags set lastValidated = CURRENT_TIMESTAMP, valid = '#{success}' where path = '#{bag_path}'")
  
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
    
    # Verifies that a bag is complete, if so then performs consistency checks.
    # If the bag was incomplete, attempts to determine if the bag is still being added to instead of failing
    def validate_if_complete
      if @bag.complete?
        # Bag was complete, proceed with the more intensive parts 
        @db.execute("update bags set complete = 'true' where path = '#{@bag_path}'")
    
        return consistent?
      end
      
      # Check that the bag has a manifest before checking completeness further
      if @bag.manifest_files.length == 0
        fileCount = Dir[File.join(bag_path, "**", "*")].length
        return completeness_progress(fileCount)? true : errors
      end
  
      # Errors come back as a string if there is only one of them, normalize that
      errors = get_errors(:completeness)
  
      # Fail this @bag if it contains any extra files
      if errors.any? { |error| error.end_with? "is present but not manifested" } ||
          errors.any? { |error| error.end_with? "is a manifested tag but not present" }
    
        @db.execute("update bags set valid = 'false' where path = '#{@bag_path}'")
  
        # Send out a warning that the bag is invalid
        return false
      end
  
      # If the @bag was simply missing files, it may not have finished transfering
      return completeness_progress(errors.length)
    end
    
    # Determines and tracks if the bag appears to be in progress of being created
    def completeness_progress(count)
      # See if the number of missing objects has changed since the last run
      row = @db.get_first_row("select completeProgress from bags where path = '#{@bag_path}'")

      # No movement, assume that the bag is actually incomplete
      if row[0] != nil && count == row[0]
        @db.execute("update bags set lastValidated = CURRENT_TIMESTAMP, valid = 'false' where path = '#{@bag_path}'")
        return false
      end
      
      # Things are still moving, give it more time
      db.execute("update bags set completeProgress = '#{count}' where path = '#{@bag_path}'")
      puts "Bag #{bag_path} was not complete, carry on: #{bag.errors.on(:completeness).class}"
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
    
    # Replicates the bag to a second location
    def replicate
      
    end
  end
end