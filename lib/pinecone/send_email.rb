require_relative 'email_handler'
require_relative 'preservation_bag'

bag = Pinecone::PreservationBag.new("/Users/bbpennel/Desktop/pinecone/bag_characters", nil)

email = Pinecone::EmailHandler.new
email.from_address = "cdr-tps@unc.edu"
email.send_invalid_bag_report(bag, "bbpennel@email.unc.edu")
#
# mail = Mail.new do
#   from    'bbpennel@email.unc.edu'
#   to      'bbpennel@email.unc.edu'
#   subject 'This is a test email'
#   body    "File.read('body.txt')"
# end
#
# puts File.absolute_path("lib/pinecone/reports/invalid_bag.html.mustache")
#
# report = Pinecone::InvalidBag.new
# report.errors = ["One", "Two"]
# report.bag_path = "kaboom"
# puts report.render(File.read("data/templates/invalid_bag.html.mustache"))

#mail.deliver!

# email = Pinecone::EmailHandler.invalid_bag_report
# email.deliver