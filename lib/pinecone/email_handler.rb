require 'bagit'
require 'mail'
require_relative 'reports/report_views.rb'

module Pinecone
  class EmailHandler
    attr_accessor :from_address
    attr_accessor :email_on_error
    :invalid_bag_template
    
    def initialize
      @invalid_bag_template = File.read("data/templates/invalid_bag.html.mustache")
      @invalid_bag_template = File.read("data/templates/replication_failed.html.mustache")
    end
    
    def send_invalid_bag_report(bag, to_addresses)
      report = Pinecone::Reports::InvalidBag.new
      report.errors = bag.get_all_errors
      report.bag_path = bag.bag_path
      
      to_address = build_error_to_address(to_addresses)
      
      mail = Mail.new do
        subject "Invalid bag #{bag.bag_name}"
        content_type 'text/html; charset=UTF-8'
      end
      mail.to = to_address
      mail.from = @from_address
      mail.body = report.render(@invalid_bag_template)
      
      mail.deliver!
    end
    
    def send_replication_failed_report(bag, replica_path, errors)
      report = Pinecone::Reports::ReplicationFailure.new
      report.errors = errors
      report.bag_path = bag.bag_path
      report.destination = replica_path
      
      mail = Mail.new do
        subject "Failed to replicate bag #{bag.bag_name}"
        content_type 'text/html; charset=UTF-8'
      end
      mail.to = @email_on_error
      mail.from = @from_address
      mail.body = report.render(@invalid_bag_template)
      
      mail.deliver!
    end
    
    def build_error_to_address(local_tos)
      return @email_on_error + local_tos
      
      mail = Mail.new do
        subject "Failed to replicate bag #{bag.bag_name}"
        content_type 'text/html; charset=UTF-8'
      end
      mail.to = to_address
      mail.from = @from_address
      mail.body = report.render(@invalid_bag_template)
      
      mail.deliver!
    end
  end
end
