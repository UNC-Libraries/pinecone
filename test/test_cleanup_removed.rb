require "test/unit"
require 'fileutils'
require 'tmpdir'
require 'mocha/test_unit'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'
require_relative '../lib/pinecone/preservation_actions'

class TestCleanupRemoved < Test::Unit::TestCase
  :tmp_test_dir
  :test_data
  :db
  :pres_actions
  
  def setup
    @tmp_test_dir = Dir.mktmpdir
    FileUtils.cp("test-data/config.yaml", @tmp_test_dir)
    @test_data = File.join(@tmp_test_dir, "test-data")
    FileUtils.mkdir(@test_data)
    FileUtils.cp_r("test-data/simple-loc", @test_data)
    FileUtils.cp_r("test-data/invalid-loc", @test_data)
    
    Pinecone::Environment.setup_env(@tmp_test_dir)
    
    Pinecone::setup_database
    
    @db = Pinecone::Environment.get_db
    
    @pres_actions = Pinecone::PreservationActions.new
  end
  
  def teardown
    FileUtils.rm_r @tmp_test_dir
  end
  
  def test_cleanup_removed_bags
    bag_path = File.join(@test_data, "simple-loc/a_bag")
    @db.execute("insert into bags (path, valid, lastValidated) values (?, ?, CURRENT_TIMESTAMP)", bag_path, 1)
    
    @pres_actions.cleanup_removed_bags
    
    assert_equal(0, @db.execute("select * from bags where path = ?", bag_path).length, "Bag entry was not cleaned up")
  end
  
  def test_cleanup_removed_bags_none_to_remove
    FileUtils.cp_r("test-data/simple-loc", @test_data)
    
    bag_path = File.join(@test_data, "simple-loc/basic_bag")
    @db.execute("insert into bags (path, valid, lastValidated) values (?, ?, CURRENT_TIMESTAMP)", bag_path, 1)
    
    @pres_actions.cleanup_removed_bags
    
    assert_equal(1, @db.execute("select * from bags where path = ?", bag_path).length, "Bag entry should not have been cleaned up")
  end
end