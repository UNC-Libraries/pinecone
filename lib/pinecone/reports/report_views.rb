require 'mustache'

module Pinecone
  module Reports
    class InvalidBag < Mustache
      attr_accessor :errors, :bag_path
    end
  
    class ReplicationFailure < Mustache
      attr_accessor :errors, :bag_path, :destination
    end
  end
end