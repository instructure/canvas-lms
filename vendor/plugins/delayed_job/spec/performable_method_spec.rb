require 'spec_helper'

class StoryReader
  def read(story)
    "Epilog: #{story.tell}"
  end
end

describe Delayed::PerformableMethod do
  
  it "should not ignore ActiveRecord::RecordNotFound errors because they are not always permanent" do
    story = Story.create :text => 'Once upon...'
    p = Delayed::PerformableMethod.new(story, :tell, [])
    story.destroy
    lambda { YAML.load(p.to_yaml) }.should raise_error
  end
  
  it "should store the object using native YAML even if its an active record" do
    story = Story.create :text => 'Once upon...'
    p = Delayed::PerformableMethod.new(story, :tell, [])
    p.class.should   == Delayed::PerformableMethod
    p.object.should  == story
    p.method.should  == :tell
    p.args.should    == []
    p.perform.should == 'Once upon...'
  end
  
  it "should allow class methods to be called on ActiveRecord models" do
    p = Delayed::PerformableMethod.new(Story, :count, [])
    lambda { p.send(:load, p.object) }.should_not raise_error
  end
  
  it "should store arguments as native YAML if they are active record objects" do
    story = Story.create :text => 'Once upon...'
    reader = StoryReader.new
    p = Delayed::PerformableMethod.new(reader, :read, [story])
    p.class.should   == Delayed::PerformableMethod
    p.method.should  == :read
    p.args.should    == [story]
    p.perform.should == 'Epilog: Once upon...'
  end                 
  
  
  
end
