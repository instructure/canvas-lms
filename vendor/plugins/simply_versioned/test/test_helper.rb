ENV["RAILS_ENV"] = "test"
TEST_FOLDER = File.dirname( __FILE__ )

$:.unshift( File.join( TEST_FOLDER, '..', 'lib' ) )

HOST_APP_FOLDER = File.expand_path( ENV['HOST_APP'] || File.join( TEST_FOLDER, '..', '..', '..', '..' ) )
puts "Host application: #{HOST_APP_FOLDER}"

require 'test/unit'
require File.expand_path( File.join( HOST_APP_FOLDER, 'config', 'environment.rb' ) )
require 'test_help'
require 'turn' unless ENV['NO_TURN']

ActiveRecord::Base.logger = Logger.new( File.join( TEST_FOLDER, 'test.log' ) )
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :dbfile => File.join( TEST_FOLDER, 'test.db' ) )

class FixturedTestSuite < Test::Unit::TestSuite
  def run( result, &progress_block )
    @tests.first.class.__send__( :suite_setup )
    yield(STARTED, name)
    @tests.each do |test|
      test.run(result, &progress_block)
    end
    yield(FINISHED, name)
    @tests.first.class.__send__( :suite_teardown )
  end
end

class FixturedTestCase < Test::Unit::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  
  def suite_setup
  end
  
  def suite_teardown
  end
  
  # Rolls up all of the test* methods in the fixture into
  # one suite, creating a new instance of the fixture for
  # each method.
  def self.suite
    method_names = public_instance_methods(true)
    tests = method_names.delete_if {|method_name| method_name !~ /^test./}
    suite = FixturedTestSuite.new(name)
    tests.sort.each do
      |test|
      catch(:invalid_test) do
        suite << new(test)
      end
    end
    return suite
  end
end


