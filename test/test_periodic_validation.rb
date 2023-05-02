require "test/unit"
require 'fileutils'
require 'tmpdir'
require 'mocha/test_unit'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'
require_relative '../lib/pinecone/preservation_actions'

class TestPeriodicValidation < Test::Unit::TestCase
  :tmp_test_dir
  :test_data
  :db
  :replica_path
  :pres_actions
  :loc_manager
  
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
    Pinecone::Environment.set_replica_paths([@replica_path])
    
    Pinecone::setup_database
    
    @db = Pinecone::Environment.get_db
    
    @pres_actions = Pinecone::PreservationActions.new
    @pres_actions.mailer = mock()
    
    @loc_manager = Pinecone::PreservationLocationManager.new(Pinecone::Environment.get_preservation_locations,
        Pinecone::Environment.get_replica_paths)
  end
  
  def teardown
    FileUtils.rm_r @tmp_test_dir
  end
  
  def test_validation
    bag_path = File.join(@test_data, "simple-loc/basic_bag")
    @db.execute("insert into bags (path, valid, lastValidated, isReplica) values (?, 1, 0, 0)", [bag_path])

    @pres_actions.mailer.expects(:send_periodic_bag_valid_report).once

    @pres_actions.periodic_validate

    results = @db.get_first_row("select valid, lastValidated from bags where path = ?", bag_path)
    assert_equal(1, results[0], "Validation status incorrectly changed")
    assert_true(results[1] > '1990', "Validation timestamp not updated")
  end

  def test_validation_no_candidates
    bag_path = File.join(@test_data, "invalid-loc/inconsistent_bag")
    @db.execute("insert into bags (path, valid, lastValidated) values (?, ?, CURRENT_TIMESTAMP)", [bag_path, 1])
    timestamp = @db.get_first_row("select lastValidated from bags where path = ?", bag_path)

    @pres_actions.mailer.expects(:send_invalid_bag_report).never

    @pres_actions.periodic_validate

    results = @db.get_first_row("select valid, lastValidated from bags where path = ?", bag_path)
    assert_equal(1, results[0], "Validation status should not have changed")
    assert_equal(timestamp[0], results[1], "Validation timestamp should not have changed")
  end

  def test_validation_invalid
    bag_path = File.join(@test_data, "invalid-loc/inconsistent_bag")
    @db.execute("insert into bags (path, valid, lastValidated, isReplica) values (?, 1, 0 ,0)", [bag_path])

    @pres_actions.mailer.expects(:send_invalid_bag_report).once

    @pres_actions.periodic_validate

    results = @db.get_first_row("select valid, lastValidated from bags where path = ?", bag_path)
    assert_equal(0, results[0], "Validation status did not get changed to false")
    assert_true(results[1] > '1990', "Validation timestamp not updated")
  end
  
  def test_validation_with_replica
    bag_path = File.join(@test_data, "simple-loc/basic_bag")
    @db.execute("insert into bags (path, valid, lastValidated, isReplica) values (?, 1, 0 ,0)", bag_path)
    FileUtils.cp_r("test-data/simple-loc", File.join(@replica_path, "simple-tps-loc"))
    replica_bag_path = File.join(@replica_path, "simple-tps-loc/basic_bag")
    @db.execute("insert into bags (path, valid, lastValidated, isReplica, originalPath) values (?, 1, 0, 1, ?)",
        [replica_bag_path, bag_path])

    @pres_actions.mailer.expects(:send_periodic_bag_valid_report).once

    @pres_actions.periodic_validate

    results = @db.execute("select valid, lastValidated from bags order by isReplica asc")
    assert_equal(1, results[0][0], "Validation status incorrectly changed")
    assert_true(results[0][1] > '1990', "Validation timestamp not updated")

    # Replicas do not get validated here
    assert_equal(1, results[1][0], "Replica validation status incorrectly changed")
    assert_equal(0, results[1][1], "Replica should not have been validated")
  end
  
  # Since replicas are no longer getting verified in periodic validation, this test is mostly moot
  def test_validation_with_invalid_replica
    bag_path = File.join(@test_data, "simple-loc/basic_bag")
    @db.execute("insert into bags (path, valid, lastValidated, isReplica) values (?, 1, 0, 0)", [bag_path])
    FileUtils.cp_r("test-data/simple-loc", File.join(@replica_path, "simple-tps-loc"))
    replica_bag_path = File.join(@replica_path, "simple-tps-loc/basic_bag")
    FileUtils.rm(File.join(replica_bag_path, "data/test_file"))
    @db.execute("insert into bags (path, valid, lastValidated, isReplica, originalPath) values (?, 1, 0, 1, ?)",
        [replica_bag_path, bag_path])
  
    @pres_actions.mailer.expects(:send_periodic_bag_valid_report).once
  
    @pres_actions.periodic_validate
  
    results = @db.execute("select valid, lastValidated from bags order by isReplica asc")
    assert_equal(1, results[0][0], "Validation status incorrectly changed")
    assert_true(results[0][1] > '1990', "Validation timestamp not updated")
    # Replicas do not get validated here
    assert_equal(1, results[1][0], "Replica does not get validated here")
    assert_equal(0, results[1][1], "Replica should not have been validated")
  end
end