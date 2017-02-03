require 'mustache'

module Pinecone
  module Reports
    class InvalidBag < Mustache
      attr_accessor :errors, :bag_path
    end
    
    class ValidBag < Mustache
      attr_accessor :bag_path, :file_count, :filesize
    end
  
    class ReplicationFailure < Mustache
      attr_accessor :errors, :bag_path, :destination
    end
    
    class InvalidConfiguration < Mustache
      attr_accessor :error
    end
  end
end