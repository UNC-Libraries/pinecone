require "test/unit"
require 'fileutils'
require 'tmpdir'
require 'mocha/test_unit'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'
require_relative '../lib/pinecone/preservation_actions'

class TestCleanupOrphanedReplicas < Test::Unit::TestCase
  :tmp_test_dir
  :test_data
  :db
  :replica_path
  :pres_actions
  
  def setup
    @tmp_test_dir = Dir.mktmpdir
    FileUtils.cp("test-data/config.yaml", @tmp_test_dir)
    @test_data = File.join(@tmp_test_dir, "test-data")
    FileUtils.mkdir(@test_data)
    
    Pinecone::Environment.setup_env(@tmp_test_dir)
    
    FileUtils.mkdir File.join(@test_data, "simple-loc")
    FileUtils.mkdir File.join(@test_data, "invalid-loc")
    
    @replica_path = File.join(@tmp_test_dir, "replicas")
    FileUtils.mkdir @replica_path
    FileUtils.cp_r("test-data/simple-loc", @replica_path)
    Pinecone::Environment.set_replica_paths([@replica_path])
    
    Pinecone::setup_database
    
    @db = Pinecone::Environment.get_db
    
    @pres_actions = Pinecone::PreservationActions.new
  end
  
  def teardown
    FileUtils.rm_r @tmp_test_dir
  end
  
  def test_cleanup_orphaned_replicas
    bag_path = File.join(@test_data, "non-existent/basic_bag")
    replica_bag_path = File.join(@replica_path, "simple-loc/basic_bag")
    
    assert_true(File.exist? replica_bag_path)
    assert_false(File.exist? bag_path)
    
    @db.execute("insert into bags (path, valid, lastValidated, isReplica, originalPath) values (?, ?, CURRENT_TIMESTAMP, ?, ?)",
        [replica_bag_path, 1, 1, bag_path])
    
    @pres_actions.cleanup_orphaned_replicas
    
    assert_false(File.exist?(replica_bag_path), "Replica was not cleaned up")
    assert_equal(0, @db.execute("select * from bags").length)
  end
  
  def test_cleanup_orphaned_replicas_not_orphaned
    FileUtils.cp_r("test-data/simple-loc", @test_data)
    
    bag_path = File.join(@test_data, "simple-loc/basic_bag")
    replica_bag_path = File.join(@replica_path, "simple-loc/basic_bag")
    
    assert_true(File.exist? replica_bag_path)
    assert_true(File.exist? bag_path)
    
    @db.execute("insert into bags (path, valid, lastValidated) values (?, ?, CURRENT_TIMESTAMP)",
        [bag_path, 1])
    @db.execute("insert into bags (path, valid, lastValidated, isReplica, originalPath) values (?, ?, CURRENT_TIMESTAMP, ?, ?)",
        [replica_bag_path, 1, 1, bag_path])
    
    @pres_actions.cleanup_orphaned_replicas
    
    assert_true(File.exist?(replica_bag_path), "Replica should not have been cleaned up")
    assert_true(File.exist?(bag_path), "Original should not have been cleaned up")
    assert_equal(2, @db.execute("select * from bags").length)
  end
end