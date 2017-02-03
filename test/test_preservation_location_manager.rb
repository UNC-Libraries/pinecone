require "test/unit"
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
  
  def test_unreachable_location
    simple_loc = File.join(@test_data, "simple-loc")
    FileUtils.rm_rf simple_loc

    assert_raise ArgumentError do
      manager = Pinecone::PreservationLocationManager.new(@loc_config, ["./replicas"])
    end
  end
end