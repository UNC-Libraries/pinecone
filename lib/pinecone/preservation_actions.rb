require 'sqlite3'
require 'bagit'
require 'rsync'
require 'shellwords'
require_relative 'preservation_bag'
require_relative 'email_handler'
require_relative 'replication_error'
require_relative 'preservation_location_manager'

module Pinecone
  class PreservationActions
    :db
    :logger
    attr_accessor :mailer, :loc_manager
    
    def initialize
      @db = Pinecone::Environment.get_db
      @logger = Pinecone::Environment.logger
      
      # Setup email handler for sending results
      @mailer = Pinecone::EmailHandler.new
      @mailer.from_address = Pinecone::Environment.get_from_email_address
      @mailer.email_on_error = Pinecone::Environment.get_admin_email_addresses
      
      @loc_manager = Pinecone::PreservationLocationManager.new(Pinecone::Environment.get_preservation_locations)
    end
    
    # Validate bags in all configured locations that have not previously been validated or attempted to validate
    # If a bag is incomplete, attempts to allow for the fact it may still be in the process of being added to the location
    def validate_new_bags
      known_validated = Array.new
      # Retrieve list of bags that have been validated
      @db.execute( "select path from bags where valid is not null" ) do |row|
        known_validated.push row[0]
      end

      # Get a list of potential bag directories from all preservation locations
      bag_paths = @loc_manager.get_bag_paths

      #validate all of the previously unvalidated bags
      unvalidated_bags = bag_paths - known_validated
      unvalidated_bags.each do |bag_path|
        bag = Pinecone::PreservationBag.new(bag_path)
  
        @logger.info "Checking on unvalidated bag #{bag_path}"
  
        validation_result = bag.validate_if_complete
        if validation_result == true
          @logger.info "Bag #{bag_path} was valid"
        elsif validation_result == "inprogress"
          @logger.warn "Bag #{bag_path} was incomplete but may still be in progress of being added"
        else
          @logger.warn "Bag #{bag_path} was invalid, sending report"
          pres_loc = @loc_manager.get_location_by_path(bag_path)
          @mailer.send_invalid_bag_report(bag, pres_loc.get_contact_emails)
        end
      end
    end
    
    # Replicate all bags that have not previously been replicated
    def replicate_new_bags
      unreplicated = Array.new
      # Retrieve list of bags that have been replicated
      @db.execute( "select path from bags where (replicated is null or replicated == 'false') and valid == 'true'" ) do |row|
        unreplicated.push row[0]
      end
      
      @logger.debug("Preparing to replicate #{unreplicated.length} previously validated bags")
      
      # Get a list of potential bag directories from all preservation locations
      bag_paths = @loc_manager.get_bag_paths

      #replicate bags that have been validated but not yet replicated
      unreplicated.each do |bag_path|
        bag = Pinecone::PreservationBag.new(bag_path)
        @logger.debug("Replicate bag #{bag_path}")
        
        replica_path = nil
        begin
          replica_path = replicate_bag(bag)
          @db.execute("update bags set replicaPath = ?, replicated = 'true' where path = ?", replica_path, bag.bag_path)
        rescue Pinecone::ReplicationError => e
          @logger.error e
          @mailer.send_replication_failed_report(bag, e.replica_path, e.errors)
          next
        end
        
        # Quick verification that the replication was successful by checking the filesizes and number of files
        if bag.valid_oxum?
          @logger.info("Replica passed 0xum validation: #{replica_path}")
        else
          @logger.error("Replica for #{bag_path} failed 0xum validation: #{replica_path}")
          @mailer.send_replication_failed_report(bag, replica_path, ["Replica failed oxum validation"])
        end
      end
    end
  
    # Replicates the given bag to the configured replica destination.  Replicas are placed into subdirectories
    # based on the name attribute or directory name of the preservation location they came from
    def replicate_bag(bag)
      puts bag.bag_path
      puts @loc_manager.pres_locs
      pres_loc = @loc_manager.get_location_by_path(bag.bag_path)
      
      # Build the path for replicas from this preservation location
      replica_path = pres_loc.get_replica_path
      if !(File.exist? replica_path)
        @logger.info("Creating new replica location #{replica_path}")
        FileUtils.mkdir replica_path
      end
    
      Rsync.run(Shellwords.shellescape(bag.bag_path), Shellwords.shellescape(replica_path), "-r") do |result|
        @logger.info("Successfully replicated bag #{bag.bag_path} to #{replica_path}")
        if result.success?
          return File.join(replica_path, bag.bag_name)
        end
        
        raise Pinecone::ReplicationError.new(replica_path, result.error), "Failed to replicate bag #{bag.bag_path} to #{replica_path}"
      end
    end
  end
end
