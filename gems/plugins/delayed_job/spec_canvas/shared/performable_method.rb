shared_examples_for 'Delayed::PerformableMethod' do
  
  it "should not ignore ActiveRecord::RecordNotFound errors because they are not always permanent" do
    story = Story.create :text => 'Once upon...'
    p = Delayed::PerformableMethod.new(story, :tell, [])
    story.destroy
    expect { YAML.load(p.to_yaml) }.to raise_error
  end
  
  it "should store the object using native YAML even if its an active record" do
    story = Story.create :text => 'Once upon...'
    p = Delayed::PerformableMethod.new(story, :tell, [])
    expect(p.class).to   eq Delayed::PerformableMethod
    expect(p.object).to  eq story
    expect(p.method).to  eq :tell
    expect(p.args).to    eq []
    expect(p.perform).to eq 'Once upon...'
  end
  
  it "should allow class methods to be called on ActiveRecord models" do
    Story.create!(:text => 'Once upon a...')
    p = Delayed::PerformableMethod.new(Story, :count, [])
    expect { expect(p.send(:perform)).to eq 1 }.not_to raise_error
  end

  it "should allow class methods to be called" do
    p = Delayed::PerformableMethod.new(StoryReader, :reverse, ["ohai"])
    expect { expect(p.send(:perform)).to eq "iaho" }.not_to raise_error
  end

  it "should allow module methods to be called" do
    p = Delayed::PerformableMethod.new(MyReverser, :reverse, ["ohai"])
    expect { expect(p.send(:perform)).to eq "iaho" }.not_to raise_error
  end
  
  it "should store arguments as native YAML if they are active record objects" do
    story = Story.create :text => 'Once upon...'
    reader = StoryReader.new
    p = Delayed::PerformableMethod.new(reader, :read, [story])
    expect(p.class).to   eq Delayed::PerformableMethod
    expect(p.method).to  eq :read
    expect(p.args).to    eq [story]
    expect(p.perform).to eq 'Epilog: Once upon...'
  end

  it "should deeply de-AR-ize arguments in full name" do
    story = Story.create :text => 'Once upon...'
    reader = StoryReader.new
    p = Delayed::PerformableMethod.new(reader, :read, [['arg1', story, { [:key, 1] => story }]])
    expect(p.full_name).to eq "StoryReader#read([\"arg1\", Story.find(#{story.id}), {[:key, 1] => Story.find(#{story.id})}])"
  end
end
