require "test/unit"
require 'fileutils'
require 'tmpdir'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'
require_relative '../lib/pinecone/preservation_location'

class TestPreservationLocation < Test::Unit::TestCase
  :loc_config
   
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
    @loc_config = Pinecone::Environment.get_preservation_locations
  end

  def teardown
    FileUtils.rm_r @tmp_test_dir
  end
  
  def test_get_contact_emails
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        @loc_config["simple-tps-loc"])
    contacts = loc.get_contact_emails
    
    assert_equal(1, contacts.length)
    assert_equal("test@example.com", contacts[0])
  end
  
  def test_get_contact_emails_no_yaml
    loc = Pinecone::PreservationLocation.new("invalid-loc",
        @loc_config["invalid-loc"])
    contacts = loc.get_contact_emails
    
    assert_equal(0, contacts.length)
  end
  
  def test_get_bag_paths
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        @loc_config["simple-tps-loc"])
    paths = loc.get_bag_paths
    
    assert_equal(1, paths.length)
    assert_true(File.exist? paths[0])
    assert_true(paths[0].end_with? "/basic_bag")
  end
  
  def test_get_bag_paths_multiple
    loc = Pinecone::PreservationLocation.new("invalid-loc",
        @loc_config["invalid-loc"])
    paths = loc.get_bag_paths
    
    assert_equal(3, paths.length)
  end
  
  def test_is_available
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        @loc_config["simple-tps-loc"])
    
    assert_true(loc.is_available)
  end

  def test_assert_available
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        @loc_config["simple-tps-loc"])

    assert_nothing_raised do
      loc.assert_available
    end
  end
  
  def test_is_unavailable
    loc_config = @loc_config["simple-tps-loc"].dup
    loc_config["base_path"] = loc_config["base_path"] + "_bad"
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        loc_config)
    
    assert_false(loc.is_available)
  end

  def test_assert_available_unavailable
    loc_config = @loc_config["simple-tps-loc"].dup
    loc_config["base_path"] = loc_config["base_path"] + "_bad"
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        loc_config)

    error = assert_raise(Pinecone::PreservationLocationUnavailableError) do
      loc.assert_available
    end

    assert_equal("Preservation location simple-tps-loc at #{loc.base_path} is unavailable", error.message)
  end

  def test_is_available_empty_location_with_no_db_contents
    empty_path = File.join(@test_data, "empty-loc")
    FileUtils.mkdir(empty_path)
    loc_config = @loc_config["simple-tps-loc"].dup
    loc_config["base_path"] = empty_path
    loc = Pinecone::PreservationLocation.new("empty-loc", loc_config)

    assert_true(loc.is_available)
  end

  def test_is_unavailable_empty_location_with_db_contents
    empty_path = File.join(@test_data, "empty-loc")
    FileUtils.mkdir(empty_path)
    @db.execute("insert into bags (path, valid, lastValidated, isReplica) values (?, 1, CURRENT_TIMESTAMP, 0)",
        [File.join(empty_path, "missing_bag")])
    loc_config = @loc_config["simple-tps-loc"].dup
    loc_config["base_path"] = empty_path
    loc = Pinecone::PreservationLocation.new("empty-loc", loc_config)

    assert_false(loc.is_available)
  end
end
