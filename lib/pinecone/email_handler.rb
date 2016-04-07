require 'bagit'
require 'mail'
require_relative 'reports/invalid_bag.rb'

module Pinecone
  class EmailHandler
    attr_accessor :from_address
    :invalid_bag_template
    
    def initialize
      @invalid_bag_template = File.read("data/templates/invalid_bag.html.mustache")
    end
    
    def send_invalid_bag_report(bag, to_address)
      report = Pinecone::InvalidBag.new
      report.errors = bag.get_all_errors
      report.bag_path = bag.bag_path
      
      mail = Mail.new do
        to      to_address
        subject "Invalid bag #{bag.bag_name}"
        content_type 'text/html; charset=UTF-8'
      end
      mail.from = @from_address
      mail.body = report.render(@invalid_bag_template)
      
      mail.deliver!
    end
  end
end
