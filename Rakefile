require 'rake/testtask'
require_relative 'lib/pinecone/setup'
require_relative 'lib/pinecone/environment'
require_relative 'lib/pinecone/validate_new'

Pinecone::Environment.setup_env(ENV["PINECONE_DATA"] || ".")

task :validate_new do
  Pinecone::validate_new_bags
end

task :setup do
  Pinecone::setup_database
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end