require 'sqlite3'
require 'bagit'
require_relative 'preservation_bag'

db = SQLite3::Database.new "pinecone.db"

watch_paths = ["/Users/bbpennel/Desktop/pinecone/"]

known_validated = Array.new
# Retrieve list of bags that have been validated
db.execute( "select path from bags where valid is not null" ) do |row|
  known_validated.push row[0]
end

known_unvalidated = Array.new
# Retrieve list of known bags that have not been validated
db.execute( "select path from bags where valid is null" ) do |row|
  known_unvalidated.push row[0]
end

#puts known_unvalidated
# Get a list of directories in the watch folders
bag_paths = Array.new
watch_paths.each do |watch_path|
  Dir.entries(watch_path).each do |entry|
    abs_path = File.join(watch_path, entry)
    if !(File.directory? abs_path) || entry == "." || entry == ".."
      next
    end
    
    bag_paths.push abs_path
  end
end

unvalidated_bags = bag_paths - known_validated
unvalidated_bags.each do |bag_path|
  bag = Pinecone::PreservationBag.new(bag_path, db)
  
  # Create entry for the new bag
  if !known_unvalidated.include? bag_path
    db.execute("insert into bags (path) values (?)", [bag_path])
  end
  
  puts "Checking on unvalidated bag #{bag_path}"
  
  result = bag.validate_if_complete
end
