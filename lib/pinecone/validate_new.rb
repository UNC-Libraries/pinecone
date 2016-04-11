require 'sqlite3'
require 'bagit'
require_relative 'preservation_bag'
require_relative 'email_handler'
require_relative 'preservation_location_manager'

module Pinecone
  def Pinecone.validate_new_bags
    db = Pinecone::Environment.get_db
    logger = Pinecone::Environment.logger

    known_validated = Array.new
    # Retrieve list of bags that have been validated
    db.execute( "select path from bags where valid is not null" ) do |row|
      known_validated.push row[0]
    end

    # Setup email handler for sending results
    mailer = Pinecone::EmailHandler.new
    mailer.from_address = Pinecone::Environment.get_from_email_address
    mailer.email_on_error = Pinecone::Environment.get_admin_email_addresses

    # Get a list of potential bag directories from all preservation locations
    loc_manager = Pinecone::PreservationLocationManager.new(Pinecone::Environment.get_preservation_locations)
    bag_paths = loc_manager.get_bag_paths

    #validate all of the previously unvalidated bags
    unvalidated_bags = bag_paths - known_validated
    unvalidated_bags.each do |bag_path|
      bag = Pinecone::PreservationBag.new(bag_path)
  
      logger.info "Checking on unvalidated bag #{bag_path}"
  
      if bag.validate_if_complete
        logger.info "Bag #{bag_path} was valid"
      else
        logger.info "Bag #{bag_path} was invalid, sending report"
        pres_loc = loc_manager.get_location_by_path(bag_path)
        puts pres_loc.get_contact_emails
        mailer.send_invalid_bag_report(bag, pres_loc.get_contact_emails)
      end
    end
  end
  
  def Pinecone.replicate_bag(bag)
    # replica_path = 
  end
end
