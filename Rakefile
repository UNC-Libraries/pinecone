require 'rake/testtask'
require_relative 'lib/pinecone/setup'

task :setup do
  Pinecone::setup_database
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end