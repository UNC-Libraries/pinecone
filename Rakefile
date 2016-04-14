require 'rake/testtask'
require_relative 'lib/pinecone/setup'
require_relative 'lib/pinecone/environment'
require_relative 'lib/pinecone/preservation_actions'

task :init_env do
  Pinecone::Environment.setup_env(ENV["PINECONE_DATA"] || ".")
end

task :validate_new => :init_env do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.validate_new_bags
end

task :replicate_new => :init_env do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.replicate_new_bags
end

task :setup => :init_env do
  Pinecone::setup_database
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end