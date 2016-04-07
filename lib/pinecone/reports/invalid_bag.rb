require 'mustache'

module Pinecone
  class InvalidBag < Mustache
    attr_accessor :errors, :bag_path
  end
end