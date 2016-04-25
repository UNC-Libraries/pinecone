require 'rake/testtask'
require_relative 'lib/pinecone/setup'
require_relative 'lib/pinecone/environment'
require_relative 'lib/pinecone/preservation_actions'

task :default => :test

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

task :reset_bag, [:bag_path] => :init_env do |t, args|
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.clear_bag_record args.bag_path
end

task :validate_bag, [:bag_path] => :init_env do |t, args|
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.validate_bag args.bag_path
end

task :process_new => [:init_env, :validate_new, :replicate_new]

task :periodic_validate => :init_env do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.periodic_validate
end

task :cleanup_removed => :init_env do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.cleanup_removed_bags
end

task :cleanup_replicas => :init_env do
  pres_actions = Pinecone::PreservationActions.new
  pres_actions.cleanup_orphaned_replicas
end

task :setup => :init_env do
  Pinecone::setup_database
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end