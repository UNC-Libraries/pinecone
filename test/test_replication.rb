require "test/unit"
require 'fileutils'
require 'tmpdir'
require 'bagit'
require 'mocha/test_unit'
require_relative '../lib/pinecone/preservation_bag'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'
require_relative '../lib/pinecone/preservation_actions'

class TestReplication < Test::Unit::TestCase
  :tmp_test_dir
  :test_data
  :db
  :replica_path
  :pres_actions
  :loc_manager
  :basic_bag_path
  
  def setup
    @tmp_test_dir = Dir.mktmpdir
    FileUtils.cp("test-data/config.yaml", @tmp_test_dir)
    @test_data = File.join(@tmp_test_dir, "test-data")
    FileUtils.mkdir(@test_data)
    FileUtils.cp_r("test-data/simple-loc", @test_data)
    FileUtils.cp_r("test-data/invalid-loc", @test_data)
    
    Pinecone::Environment.setup_env(@tmp_test_dir)
    
    @replica_path = File.join(@tmp_test_dir, "replicas")
    FileUtils.mkdir @replica_path
    Pinecone::Environment.set_replica_path(@replica_path)
    
    @basic_bag_path = File.join(@test_data, "simple-loc/basic_bag")
    
    Pinecone::setup_database
    
    @db = Pinecone::Environment.get_db
    
    setup_instances
  end
  
  def setup_instances
    @pres_actions = Pinecone::PreservationActions.new
    @pres_actions.mailer = mock()
    
    @loc_manager = Pinecone::PreservationLocationManager.new(Pinecone::Environment.get_preservation_locations)
  end
    
  
  def teardown
    FileUtils.rm_r @tmp_test_dir
  end
  
  def test_replication

    bag = Pinecone::PreservationBag.new(@basic_bag_path)

    @pres_actions.replicate_bag(bag)

    replica_bag = File.join(@replica_path, "simple-tps-loc/basic_bag")
    assert_true(File.exist? replica_bag)
    assert_equal(5, Dir.glob(File.join(replica_bag, "**/*")).length)
  end

  def test_replication_already_exists

    # Add partially populated bag to destination to simulate resumption
    replica_bag = File.join(Pinecone::Environment.get_replica_path, "simple-tps-loc/basic_bag")
    FileUtils.mkdir_p(replica_bag)
    FileUtils.cp("test-data/simple-loc/basic_bag/bagit.txt", replica_bag)

    bag = Pinecone::PreservationBag.new(@basic_bag_path)

    result_path = @pres_actions.replicate_bag(bag)

    assert_true(File.exist? result_path)
    assert_equal(5, Dir.glob(File.join(result_path, "**/*")).length)
  end

  def test_replication_invalid_destination
    # Make the destination unwritteable so that replication will fail
    FileUtils.mkdir File.join(@replica_path, "simple-tps-loc")
    FileUtils.chmod_R("a-w", @replica_path)
    begin

      bag = Pinecone::PreservationBag.new(@basic_bag_path)

      assert_raise Pinecone::ReplicationError do
        @pres_actions.replicate_bag(bag)
      end

      replica_bag = File.join(@replica_path, "simple-tps-loc/basic_bag")
      assert_false(File.exist? replica_bag)
    ensure
      FileUtils.chmod_R("a+w", @replica_path)
    end
  end

  def test_replicate_new
    bag = Pinecone::PreservationBag.new @basic_bag_path

    # Set the bag as having already validated
    @db.execute("update bags set valid = 'true', lastValidated = CURRENT_TIMESTAMP")

    @pres_actions.replicate_new_bags

    replica_bag = File.join(@replica_path, "simple-tps-loc/basic_bag")
    assert_true(File.exist? replica_bag)
    assert_equal(5, Dir.glob(File.join(replica_bag, "**/*")).length)

    result = @db.get_first_row("select replicated, replicaPath from bags where path = ?", bag.bag_path)
    assert_equal("true", result[0])
    assert_equal(replica_bag, result[1])
  end
  
  def test_replicate_new_invalid_bag
    
    #pres_loc = File.join(@test_data, "simple-loc")
    Pinecone::Environment.get_preservation_locations.delete("invalid-loc")
    #Pinecone::Environment.set_preservation_locations [pres_loc]
    setup_instances
    
    bag_path = @basic_bag_path
    
    # Delete the data file so that the replica won't match the oxum
    FileUtils.rm File.join(bag_path, "data/test_file")
    
    # Ensure that the failure email tried to send
    @pres_actions.mailer.expects(:send_replication_failed_report).at_least_once
    
    bag = Pinecone::PreservationBag.new bag_path
    
    # Set the bag as having already validated, which is inaccurate in this case
    @db.execute("update bags set valid = 'true', lastValidated = CURRENT_TIMESTAMP")
    
    @pres_actions.replicate_new_bags

    # Validation failed, but not replication, so the destination should still be populated
    replica_bag = File.join(@replica_path, "simple-tps-loc/basic_bag")
    assert_true(File.exist? replica_bag)
    assert_equal(4, Dir.glob(File.join(replica_bag, "**/*")).length)
    
    result = @db.get_first_row("select replicated, replicaPath from bags where path = ?", bag.bag_path)
    assert_equal("true", result[0])
    assert_equal(replica_bag, result[1])
  end
end