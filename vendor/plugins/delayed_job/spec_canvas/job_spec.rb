require File.expand_path("../spec_helper", __FILE__)

describe Delayed::Job do
  before(:all) do
    @backend = Delayed::Job
  end

  before(:each) do
    Delayed::Job.delete_all
    SimpleJob.runs = 0
  end

  it_should_behave_like 'a backend'

  it "should fail on job creation if an unsaved AR object is used" do
    story = Story.new :text => "Once upon..."
    lambda { story.send_later(:text) }.should raise_error

    reader = StoryReader.new
    lambda { reader.send_later(:read, story) }.should raise_error

    lambda { [story, 1, story, false].send_later(:first) }.should raise_error
  end
end
