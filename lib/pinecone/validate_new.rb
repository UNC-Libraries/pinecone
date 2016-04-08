require 'sqlite3'
require 'bagit'
require_relative 'preservation_bag'
require_relative 'email_handler'
require_relative 'preservation_location_manager'

db = SQLite3::Database.new "pinecone.db"

watch_paths = ["/Users/bbpennel/Desktop/pinecone/"]

known_validated = Array.new
# Retrieve list of bags that have been validated
db.execute( "select path from bags where valid is not null" ) do |row|
  known_validated.push row[0]
end

# Setup email handler for sending results
mailer = Pinecone::EmailHandler.new
mailer.from_address = "bbpennel@email.unc.edu"
mailer.to_addresses = ["bbpennel@email.unc.edu"]

# Get a list of potential bag directories from all preservation locations
loc_manager = Pinecone::PreservationLocationManager.new(watch_paths)
bag_paths = loc_manager.get_bag_paths

unvalidated_bags = bag_paths - known_validated
unvalidated_bags.each do |bag_path|
  bag = Pinecone::PreservationBag.new(bag_path, db)
  
  puts "Checking on unvalidated bag #{bag_path}"
  
  if bag.validate_if_complete
    puts "Bag #{bag_path} was valid"
  else
    puts "Bag #{bag_path} was invalid, sending report"
    pres_loc = loc_manager.get_location_by_path(bag_path)
    puts pres_loc.get_contact_emails
    # mailer.send_invalid_bag_report(bag, pres_loc.get_contact_emails)
  end
end
