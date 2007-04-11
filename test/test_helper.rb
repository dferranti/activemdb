require 'test/unit'
  TEST_DB =  File.join(File.dirname(__FILE__), '..', 'db', 'sample.mdb')
  RETREAT_DB =  File.join(File.dirname(__FILE__), '..', 'db', 'retreat.mdb')
  NOT_A_DB =  File.join(File.dirname(__FILE__), '..', 'db', 'not_an_mdb.txt')

class Test::Unit::TestCase
  

  
  protected
  
  def create_mdb(options={})
    excluded = options[:exclude]
    included = options[:include]
    assert_nothing_raised { @db = MDB.new(TEST_DB, :exclude => excluded, :include => included ) }
    assert_not_nil @db
  end
  
end