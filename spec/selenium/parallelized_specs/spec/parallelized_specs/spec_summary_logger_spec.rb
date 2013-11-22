require 'spec_helper'

describe ParallelizedSpecs::SpecSummaryLogger do
  let(:output){ OutputLogger.new([]) }
  let(:logger){ ParallelizedSpecs::SpecSummaryLogger.new(output) }

  # TODO somehow generate a real example with an exception to test this
  xit "prints failing examples" do
    logger.example_failed XXX
    logger.example_failed XXX
    logger.dump_failures
    output.output.should == [
      "bundle exec rspec ./spec/path/to/example.rb:123 # should do stuff",
      "bundle exec rspec ./spec/path/to/example.rb:125 # should not do stuff"
    ]
  end

  it "does not print anything for passing examples" do
    logger.example_passed mock(:location => "/my/spec/foo.rb:123")
    logger.dump_failures
    output.output.should == []
    logger.dump_summary(1,2,3,4)
    output.output.should == ["\nFinished in 1 seconds\n", "\e[31m2 examples, 3 failures, 4 pending\e[0m"]
  end

  it "does not print anything for pending examples" do
    logger.example_pending mock(:location => "/my/spec/foo.rb:123")
    logger.dump_failures
    output.output.should == []
    logger.dump_summary(1,2,3,4)
    output.output.should == ["\nFinished in 1 seconds\n", "\e[31m2 examples, 3 failures, 4 pending\e[0m"]
  end
end
