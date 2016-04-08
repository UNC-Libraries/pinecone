require "test/unit"
require_relative '../lib/pinecone/preservation_location'

class TestPreservationLocation < Test::Unit::TestCase
  def test_get_contact_emails
    loc = Pinecone::PreservationLocation.new "test-data/simple-loc"
    contacts = loc.get_contact_emails
    
    assert_equal(1, contacts.length)
    assert_equal("test@example.com", contacts[0])
  end
  
  def test_get_contact_emails_no_yaml
    loc = Pinecone::PreservationLocation.new "test-data/invalid-loc"
    contacts = loc.get_contact_emails
    
    assert_equal(0, contacts.length)
  end
  
  def test_get_bag_paths
    loc = Pinecone::PreservationLocation.new "test-data/simple-loc"
    paths = loc.get_bag_paths
    
    assert_equal(1, paths.length)
    assert_true(File.exist? paths[0])
    assert_true(paths[0].end_with? "/basic_bag")
  end
  
  def test_get_bag_paths_multiple
    loc = Pinecone::PreservationLocation.new "test-data/invalid-loc"
    paths = loc.get_bag_paths
    
    assert_equal(3, paths.length)
  end
end