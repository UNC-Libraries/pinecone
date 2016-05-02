require 'bagit'
require 'mail'
require_relative 'reports/report_views.rb'

module Pinecone
  class EmailHandler
    attr_accessor :from_address
    attr_accessor :email_on_error
    attr_accessor :subject_prefix
    :valid_bag_template
    :invalid_bag_template
    :repl_failed_template
    
    def initialize
      @valid_bag_template = File.read("data/templates/valid_bag.html.mustache")
      @invalid_bag_template = File.read("data/templates/invalid_bag.html.mustache")
      @repl_failed_template = File.read("data/templates/replication_failed.html.mustache")
    end
    
    def send_new_bag_valid_report(bag, to_addresses)
      send_valid_bag_report(bag, to_addresses, "Validation of new bag successful: #{bag.bag_name}")
    end
    
    def send_periodic_bag_valid_report(bag, to_addresses)
      send_valid_bag_report(bag, to_addresses, "Periodic validation of bag successful: #{bag.bag_name}")
    end
    
    def send_valid_bag_report(bag, to_addresses, subject)
      report = Pinecone::Reports::ValidBag.new
      report.bag_path = bag.bag_path
      report.filesize, report.file_count = bag.get_payload_oxum.split(".")
      report.filesize = format_filesize(report.filesize)
      
      mail = Mail.new
      mail.content_type = "text/html; charset=UTF-8"
      mail.subject = "#{add_subject_prefix}#{subject}"
      mail.to = to_addresses
      mail.from = @from_address
      mail.body = report.render(@valid_bag_template)
      
      mail.deliver!
    end
    
    def send_invalid_bag_report(bag, to_addresses)
      report = Pinecone::Reports::InvalidBag.new
      report.errors = bag.get_all_errors
      report.bag_path = bag.bag_path
      
      to_address = build_error_to_address(to_addresses)
      
      mail = Mail.new
      mail.content_type = "text/html; charset=UTF-8"
      mail.subject = "#{add_subject_prefix}Bag failed validation: #{bag.bag_name}"
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
      
      mail = Mail.new
      mail.content_type = "text/html; charset=UTF-8"
      mail.subject = "#{add_subject_prefix}Failed to replicate bag: #{bag.bag_name}"
      mail.to = @email_on_error
      mail.from = @from_address
      mail.body = report.render(@repl_failed_template)
      
      mail.deliver!
    end
    
    def build_error_to_address(local_tos)
      return @email_on_error + local_tos
    end
    
    def add_subject_prefix
      if @subject_prefix == nil
        return
      end
      
      prefix = @subject_prefix.rstrip
      if (prefix.length == 0)
        return
      end
      
      return prefix + ' '
    end


    FILESIZE_SUFFIXES = %W(pb tb gb mb kb b).freeze

    def format_filesize(byte_string)
      bytes = byte_string.to_f
      i = FILESIZE_SUFFIXES.length - 1
      while bytes > 500 && i > 0
        i -= 1
        bytes /= 1000
      end
      return "#{'%.1f' % bytes}#{FILESIZE_SUFFIXES[i]}"
    end
  end
end
