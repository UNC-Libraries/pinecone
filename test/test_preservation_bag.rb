require "test/unit"
require 'fileutils'
require 'tmpdir'
require 'bagit'
require_relative '../lib/pinecone/preservation_bag'
require_relative '../lib/pinecone/setup'
require_relative '../lib/pinecone/environment'

class TestPreservationBag < Test::Unit::TestCase
  :tmp_test_dir
  :db
  
  def setup
    @tmp_test_dir = Dir.mktmpdir
    FileUtils.cp("test-data/config.yaml", @tmp_test_dir)
    
    Pinecone::Environment.setup_env(@tmp_test_dir)
    Pinecone::setup_database
    
    @db = Pinecone::Environment.get_db
    puts @tmp_test_dir
  end
  
  def teardown
    FileUtils.rm_r @tmp_test_dir
  end
  
  def test_bag_name
    bag = Pinecone::PreservationBag.new("test-data/simple-loc/basic_bag")
    
    assert_equal("basic_bag", bag.bag_name)
  end
  
  def test_consistent
    bag = Pinecone::PreservationBag.new("test-data/simple-loc/basic_bag")
    
    assert_true(bag.consistent?)
    
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_equal("true", row[1])
    assert_not_nil(row[0])
  end
  
  def test_inconsistent
    bag = Pinecone::PreservationBag.new("test-data/invalid-loc/inconsistent_bag")
    
    assert_false(bag.consistent?)
    
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_equal("false", row[1])
    assert_not_nil(row[0])
    
    assert_equal(1, bag.get_all_errors.length)
  end
  
  def test_invalid_incomplete
    bag = Pinecone::PreservationBag.new("test-data/invalid-loc/incomplete_bag")
    
    assert_false(bag.valid?)
    
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_equal("false", row[1])
    assert_not_nil(row[0])
    
    # One is the missing file, one is the extra, and the third is "is invalid"
    assert_equal(3, bag.get_all_errors.length)
  end
  
  def test_validate_if_complete_unexpected_file
    bag = Pinecone::PreservationBag.new("test-data/invalid-loc/incomplete_bag")
    
    assert_false(bag.validate_if_complete)
    
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_equal("false", row[1])
    # Only 2 errors, since consistency check wasn't run
    assert_equal(2, bag.get_all_errors.length)
  end
  
  def test_validate_if_complete_recover
    bag_path = File.join(@tmp_test_dir, "basic_bag")
    FileUtils.cp_r("test-data/simple-loc/basic_bag", bag_path)
    file_path = File.join(bag_path, "data/test_file")
    FileUtils.rm(file_path)
    
    bag = Pinecone::PreservationBag.new(bag_path)
    
    # Bag does not report that it fail to validate, but also did not succeed.  Limbo
    assert_equal("inprogress", bag.validate_if_complete)
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_nil(row[0])
    assert_nil(row[1])
    
    # Restore the file
    FileUtils.cp("test-data/simple-loc/basic_bag/data/test_file", file_path)
    
    # Make new bag object to reset validation results
    bag = Pinecone::PreservationBag.new(bag_path)
    
    # Bag reports that it is valid after the missing file was restored
    assert_true(bag.validate_if_complete)
    
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_equal("true", row[1])
    assert_not_nil(row[0])
  end
  
  def test_validate_if_complete_no_recover
    bag_path = File.join(@tmp_test_dir, "basic_bag")
    FileUtils.cp_r("test-data/simple-loc/basic_bag", bag_path)
    file_path = File.join(bag_path, "data/test_file")
    FileUtils.rm(file_path)
    
    bag = Pinecone::PreservationBag.new(bag_path)
    
    # Bag does not report that it fail to validate, but also did not succeed.  Limbo
    assert_equal("inprogress", bag.validate_if_complete)
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_nil(row[0])
    assert_nil(row[1])
    
    # Make new bag object to reset validation results
    bag = Pinecone::PreservationBag.new(bag_path)
    
    # Really invalid after second check
    assert_equal(Array, bag.validate_if_complete.class)
    
    row = @db.get_first_row("select lastValidated, valid from bags")
    assert_equal("false", row[1])
    assert_not_nil(row[0])
  end
end
    