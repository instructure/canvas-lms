require File.expand_path(File.dirname(__FILE__)+'/../../../../spec/apis/api_spec_helper')

class Woozel < ActiveRecord::Base
  simply_versioned :explicit => true
end

Woozel.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

describe 'simply_versioned' do
  before do
    Woozel.connection.create_table :woozels, :force => true do |t|
      t.string :name
    end
  end
  after do
    Woozel.connection.drop_table :woozels
  end

  describe "explicit versions" do
    let(:woozel) { Woozel.create!(:name => 'Eeyore') }
    it "should create the first version on save" do
      woozel = Woozel.new(:name => 'Eeyore')
      woozel.should_not be_versioned
      woozel.save!
      woozel.should be_versioned
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')
    end

    it "should keep the last version up to date for each save" do
      woozel.should be_versioned
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')
      woozel.name = 'Piglet'
      woozel.save!
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Piglet')
    end

    it "should create a new version when asked to" do
      woozel.name = 'Piglet'
      woozel.with_versioning(:explicit => true, &:save!)
      woozel.versions.length.should eql(2)
      woozel.versions.first.model.name.should eql('Eeyore')
      woozel.versions.current.model.name.should eql('Piglet')
    end

    it 'should not create a new version when not explicitly asked to' do
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Piglet')
    end

    it 'should not update the last version when not versioning' do
      woozel.name = 'Piglet'
      woozel.without_versioning(&:save!)
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')
    end

    it 'should not reload one versionable association from the database' do
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      woozel.versions.loaded?.should == false
      first = woozel.versions.first
      Woozel.connection.expects(:select_all).never
      first.versionable.should == woozel
    end

    it 'should not reload any versionable associations from the database' do
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      woozel.versions.loaded?.should == false
      all = woozel.versions.all
      Woozel.connection.expects(:select_all).never
      all.each do |version|
        version.versionable.should == woozel
      end
    end
  end

  describe "#model=" do
    let(:woozel) { Woozel.create!(:name => 'Eeyore') }

    it "should assign the model for the version" do
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')

      woozel.name = 'Piglet'
      woozel.with_versioning(:explicit => true, &:save!)

      woozel.versions.length.should eql(2)

      first_version = woozel.versions.first
      first_model   = first_version.model
      first_model.name.should eql('Eeyore')

      first_model.name = 'Foo'
      first_version.model = first_model
      first_version.save!

      versions = woozel.reload.versions
      versions.first.model.name.should eql('Foo')
    end
  end

  describe "#current_version?" do
    before do
      @woozel = Woozel.create! name: 'test'
      @woozel.with_versioning(explicit: true, &:save!)
    end

    it "should always be true for models loaded directly from AR" do
      @woozel.should be_current_version
      @woozel = Woozel.find(@woozel.id)
      @woozel.should be_current_version
      @woozel.reload
      @woozel.should be_current_version
      Woozel.new(name: 'test2').should be_current_version
    end

    it "should be false for the #model of any version" do
      @woozel.versions.current.model.should_not be_current_version
      @woozel.versions.map { |v| v.model.current_version? }.should == [false, false]
    end
  end

  context "callbacks" do
    let(:woozel) { Woozel.create!(name: 'test') }
    context "on_load" do
      let(:on_load) do
        lambda { |model, version| model.name = 'test override' }
      end
      before do
        woozel.simply_versioned_options[:on_load] = on_load
        woozel.reload
      end
      it "can modify a version after loading" do
        YAML::load(woozel.current_version.yaml)['name'].should == 'test'
        woozel.current_version.model.name.should == 'test override'
      end
    end
  end
  
  # INSTRUCTURE: shim for quizzes namespacing
  describe '.versionable_type' do
    it 'returns the correct representation of a quiz submission' do
      submission = quiz_model.quiz_submissions.create
      submission.with_versioning(explicit: true, &:save!)
      version = Version.where(:versionable_id => submission.id, :versionable_type => 'Quizzes::QuizSubmission').first
      version.should_not be_nil

      Version.where(id: version).update_all(versionable_type: 'QuizSubmission')
      Version.find(version.id).versionable_type.should == 'Quizzes::QuizSubmission'
    end

    it 'returns the correct representation of a quiz' do
      quiz = quiz_model
      quiz.with_versioning(explicit: true, &:save!)
      version = Version.where(:versionable_id => quiz.id, :versionable_type => 'Quizzes::Quiz').first

      version.versionable_type = 'Quiz'
      version.send(:save_without_callbacks)
      Version.find(version.id).versionable_type.should == 'Quizzes::Quiz'
    end

    it 'returns the versionable type attribute if not a quiz' do
      assignment = assignment_model
      assignment.with_versioning(explicit: true, &:save!)
      assignment.versions.each do |version|
        version.versionable_type.should == 'Assignment'
      end
    end
  end

end
