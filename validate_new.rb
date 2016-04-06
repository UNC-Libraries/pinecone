require 'sqlite3'
require 'bagit'

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
  bag = BagIt::Bag.new bag_path
  
  # Create entry for the new bag
  if !known_unvalidated.include? bag_path
    db.execute("insert into bags (path) values (?)", [bag_path])
  end
  
  puts "Checking on unvalidated bag #{bag_path}"
  
  if bag.complete?
    db.execute("update bags set complete = 'true' where path = '#{bag_path}'")
    
    isValid = bag.valid?
    db.execute("update bags set lastValidated = CURRENT_TIMESTAMP, valid = '#{isValid}' where path = '#{bag_path}'")
    
    if isValid
      puts "Bag was valid"
    else
      puts "OH MY GOD ITS BROKEN"
    end
  else
    errors = bag.errors.on(:completeness)
    if errors.is_a? String
      errors = [errors]
    end
    
    # Fail this bag if it contains any extra files
    if errors.any? { |error| error.end_with? "is present but not manifested" } ||
        errors.any? { |error| error.end_with? "is a manifested tag but not present" }
        
      db.execute("update bags set valid = 'false' where path = '#{bag_path}'")
      
      # Send out a warning that the bag is invalid
      puts "Bag contained extra files, no good"
      puts errors
      next
    end
    
    # If the bag was simply missing files, it may not have finished transfering
    
    # Record how many files were missing, so that later checks can see if this has changed
    missingCount = errors.length
    
    # See if the number of missing objects has changed since the last run
    row = db.get_first_row("select missingCount from bags where path = '#{bag_path}'")
    puts "Hello #{row[0]}"
    if row[0] != nil && missingCount == row[0]
      # No movement, assume that the bag is actually missing files and invalid
      db.execute("update bags set valid = 'false' where path = '#{bag_path}'")
      
      puts errors
    else
      db.execute("update bags set missingCount = '#{missingCount}' where path = '#{bag_path}'")
      puts "Bag #{bag_path} was not complete, carry on: #{bag.errors.on(:completeness).class}"
    end
  end
end
