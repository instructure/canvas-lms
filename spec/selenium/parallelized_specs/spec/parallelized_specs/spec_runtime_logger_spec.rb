require 'spec_helper'

describe ParallelizedSpecs::SpecRuntimeLogger do
  before do
    # pretend we run in parallel or the logger will log nothing
    ENV['TEST_ENV_NUMBER'] = ''
    @clean_output = %r{^spec/foo.rb:[-\.e\d]+$}m
  end

  after do
    ENV.delete 'TEST_ENV_NUMBER'
  end

  def log_for_a_file(options={})
    Tempfile.open('xxx') do |temp|
      temp.close
      f = File.open(temp.path,'w')
      logger = if block_given?
        yield(f)
      else
        ParallelizedSpecs::SpecRuntimeLogger.new(f)
      end

      example = (mock(:location => "#{Dir.pwd}/spec/foo.rb:123"))
      logger.example_started example
      logger.example_passed example
      if options[:pending]
        logger.example_pending example
        logger.dump_pending
      end
      if options[:failed]
        logger.example_failed example
        logger.dump_failures
      end
      logger.start_dump

      #f.close
      return File.read(f.path)
    end
  end

  it "logs runtime with relative paths" do
    log_for_a_file.should =~ @clean_output
  end

  it "does not log pending" do
    log_for_a_file(:pending => true).should =~ @clean_output
  end

  it "does not log failures" do
    log_for_a_file(:failed => true).should =~ @clean_output
  end

  it "does not log if we do not run in parallel" do
    ENV.delete 'TEST_ENV_NUMBER'
    log_for_a_file.should == ""
  end

  it "appends to a given file" do
    result = log_for_a_file do |f|
      f.write 'FooBar'
      ParallelizedSpecs::SpecRuntimeLogger.new(f)
    end
    result.should include('FooBar')
    result.should include('foo.rb')
  end

  it "overwrites a given path" do
    result = log_for_a_file do |f|
      f.write 'FooBar'
      ParallelizedSpecs::SpecRuntimeLogger.new(f.path)
    end
    result.should_not include('FooBar')
    result.should include('foo.rb')
  end
end
