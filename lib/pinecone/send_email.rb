require_relative 'email_handler'
require_relative 'environment'
require_relative 'preservation_bag'

Pinecone::Environment.setup_env(".")

bag = Pinecone::PreservationBag.new("/Users/bbpennel/Desktop/pinecone/bag_characters")

email = Pinecone::EmailHandler.new
email.from_address = "cdr-tps@unc.edu"
email.email_on_error = ["bbpennel@email.unc.edu"]
#email.send_invalid_bag_report(bag, ["bbpennel@email.unc.edu"])
errors = ["one", "two"]
email.send_replication_failed_report(bag, "/Users/bbpennel/Desktop/pinecone_replica", errors)