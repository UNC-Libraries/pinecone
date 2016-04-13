module Pinecone
  class ReplicationError < StandardError
    attr_reader :replica_path, :errors
  
    def initialize(replica_path, errors)
      @replica_path = replica_path
      @errors = errors
    end
  end
end