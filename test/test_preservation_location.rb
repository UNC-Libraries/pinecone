require "test/unit"
require_relative '../lib/pinecone/preservation_location'

class TestPreservationLocation < Test::Unit::TestCase
  :loc_config
  
  def setup
    config = YAML.load_file("test-data/config.yaml")
    @loc_config = config["preservation_locations"]
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
  
  def test_is_unavailable
    loc_config = @loc_config["simple-tps-loc"]
    loc_config["base_path"] = loc_config["base_path"] + "_bad"
    loc = Pinecone::PreservationLocation.new("simple-tps-loc",
        loc_config)
    
    assert_false(loc.is_available)
  end
end