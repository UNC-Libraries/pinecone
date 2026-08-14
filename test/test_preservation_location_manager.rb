require "test/unit"
require 'fileutils'
require 'tmpdir'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'
require_relative '../lib/pinecone/preservation_location_manager'

class TestPreservationLocationManager < Test::Unit::TestCase
  @@simple_abs
  @@invalid_abs
  :loc_config
  
  def setup
    @tmp_test_dir = Dir.mktmpdir
    FileUtils.cp("test-data/config.yaml", @tmp_test_dir)
    @test_data = File.join(@tmp_test_dir, "test-data")
    FileUtils.mkdir(@test_data)
    
    @@simple_abs = File.join(@test_data, "simple-loc")
    @@invalid_abs = File.join(@test_data, "invalid-loc")
    FileUtils.cp_r("test-data/simple-loc", @@simple_abs)
    FileUtils.cp_r("test-data/invalid-loc", @@invalid_abs)
    
    Pinecone::Environment.setup_env(@tmp_test_dir)
    Pinecone::setup_database
    
    #config = YAML.load_file(File.join(@tmp_test_dir, "config.yaml"))
    #@loc_config = config["preservation_locations"]
    @loc_config = Pinecone::Environment.get_preservation_locations
  end
  
  def test_find_locations
    manager = Pinecone::PreservationLocationManager.new @loc_config, []
    
    assert_equal(2, manager.pres_locs.length)
    assert_true(manager.pres_locs.key? @@invalid_abs)
    assert_true(manager.pres_locs.key? @@simple_abs)
  end
  
  def test_get_location_by_path
    manager = Pinecone::PreservationLocationManager.new @loc_config, []
    
    # Verify that it can find the location for a real bag
    loc = manager.get_location_by_path File.join(@@invalid_abs, "incomplete_bag")
    assert_not_nil(loc)
    assert_equal(@@invalid_abs, loc.base_path)
    
    # Verify that a location comes back even if the bag doesn't exist
    loc = manager.get_location_by_path File.join(@@invalid_abs, "non-existent")
    assert_not_nil(loc)
    assert_equal(@@invalid_abs, loc.base_path)
  end

  def test_get_location_by_path_unavailable_location
    manager = Pinecone::PreservationLocationManager.new @loc_config, []
    FileUtils.rm_rf @@invalid_abs

    error = assert_raise(Pinecone::PreservationLocationUnavailableError) do
      manager.get_location_by_path File.join(@@invalid_abs, "incomplete_bag")
    end

    assert_equal("Preservation location invalid-loc at #{@@invalid_abs} is unavailable", error.message)
  end
  
  def test_get_location_by_path_invalid_location
    @loc_config.delete("invalid-loc")
    manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    
    loc = manager.get_location_by_path File.absolute_path "test-data/non-existent-location/basic_bag"
    assert_nil(loc)
  end
  
  def test_get_location_by_path_replica
    @loc_config.delete("invalid-loc")
    manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    
    loc = manager.get_location_by_path File.absolute_path "test-data/non-existent-location/basic_bag"
    assert_nil(loc)
  end
    
  def test_get_bag_paths
    @loc_config.delete("invalid-loc")
    manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    
    bag_paths = manager.get_bag_paths
    assert_equal(1, bag_paths.length)
    assert_true(bag_paths[0].end_with? "/basic_bag")
  end
  
  def test_get_bag_paths_multiple_locations
    manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    
    bag_paths = manager.get_bag_paths
    assert_equal(4, bag_paths.length)
  end

  def test_get_bag_paths_unavailable_location
    manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    FileUtils.rm_rf @@simple_abs

    error = assert_raise(Pinecone::PreservationLocationUnavailableError) do
      manager.get_bag_paths
    end

    assert_equal("Preservation location simple-tps-loc at #{@@simple_abs} is unavailable", error.message)
  end
  
  def test_unreachable_location
    simple_loc = File.join(@test_data, "simple-loc")
    FileUtils.rm_rf simple_loc

    assert_raise ArgumentError do
      manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    end
  end

  def test_empty_location_with_db_contents_unavailable
    empty_loc = File.join(@test_data, "empty-loc")
    FileUtils.mkdir(empty_loc)
    @db = Pinecone::Environment.get_db
    @db.execute("insert into bags (path, valid, lastValidated, isReplica) values (?, 1, CURRENT_TIMESTAMP, 0)",
        [File.join(empty_loc, "missing_bag")])

    loc_config = @loc_config.transform_values(&:dup)
    loc_config["simple-tps-loc"]["base_path"] = empty_loc

    assert_raise ArgumentError do
      manager = Pinecone::PreservationLocationManager.new(loc_config, ["./replicas"])
    end
  end
end
