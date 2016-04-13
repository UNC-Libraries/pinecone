require 'rake/testtask'
require_relative 'lib/pinecone/setup'
require_relative 'lib/pinecone/environment'
require_relative 'lib/pinecone/preservation_actions'

Pinecone::Environment.setup_env(ENV["PINECONE_DATA"] || ".")

task :validate_new do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.validate_new_bags
end

task :replicate_new do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.replicate_new_bags
end

task :setup do
  Pinecone::setup_database
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end