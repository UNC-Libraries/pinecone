require "test/unit"
require_relative '../lib/pinecone/preservation_location_manager'

class TestPreservationLocationManager < Test::Unit::TestCase
  @@simple_abs = File.absolute_path "test-data/simple-loc"
  @@invalid_abs = File.absolute_path "test-data/invalid-loc"
  
  def test_find_locations
    manager = Pinecone::PreservationLocationManager.new ["test-data/simple-loc", "test-data/invalid-loc"]
    
    assert_equal(2, manager.pres_locs.length)
    assert_true(manager.pres_locs.key? @@invalid_abs)
    assert_true(manager.pres_locs.key? @@simple_abs)
  end
  
  def test_duplicate_location_keys
    assert_raise do
      Pinecone::PreservationLocationManager.new ["test-data/simple-loc", "test-data/simple-loc"]
    end
  end
  
  def test_get_location_by_path
    manager = Pinecone::PreservationLocationManager.new ["test-data/simple-loc", "test-data/invalid-loc"]
    
    # Verify that it can find the location for a real bag
    loc = manager.get_location_by_path File.join(@@invalid_abs, "incomplete_bag")
    assert_not_nil(loc)
    assert_equal(@@invalid_abs, loc.path)
    
    # Verify that a location comes back even if the bag doesn't exist
    loc = manager.get_location_by_path File.join(@@invalid_abs, "non-existent")
    assert_not_nil(loc)
    assert_equal(@@invalid_abs, loc.path)
  end
  
  def test_get_location_by_path_invalid_location
    manager = Pinecone::PreservationLocationManager.new ["test-data/simple-loc"]
    
    loc = manager.get_location_by_path File.absolute_path "test-data/non-existent-location/basic_bag"
    assert_nil(loc)
  end
    
  def test_get_bag_paths
    manager = Pinecone::PreservationLocationManager.new ["test-data/simple-loc"]
    
    bag_paths = manager.get_bag_paths
    assert_equal(1, bag_paths.length)
    assert_true(bag_paths[0].end_with? "/basic_bag")
  end
  
  def test_get_bag_paths_multiple_locations
    manager = Pinecone::PreservationLocationManager.new ["test-data/simple-loc", "test-data/invalid-loc"]
    
    bag_paths = manager.get_bag_paths
    assert_equal(4, bag_paths.length)
  end
end