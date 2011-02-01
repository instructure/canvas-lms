require 'spec_helper'

describe "A story" do

  before(:all) do
    @story = Story.create :text => "Once upon a time..."
  end

  it "should be shared" do
    @story.tell.should == 'Once upon a time...'
  end

  it "should not return its result if it storytelling is delayed" do
    @story.send_later(:tell).should_not == 'Once upon a time...'
  end

end