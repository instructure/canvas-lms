require File.expand_path(File.dirname(__FILE__)+'/../../../../spec/apis/api_spec_helper')

describe 'simply_versioned' do
  before :all do
    class Woozel < ActiveRecord::Base
      simply_versioned :explicit => true
    end
    Woozel.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

    Woozel.connection.create_table :woozels, :force => true do |t|
      t.string :name
    end
  end

  after :all do
    Woozel.connection.drop_table :woozels
    Woozel.remove_connection
    ActiveSupport::DescendantsTracker.class_variable_get(:@@direct_descendants)[ActiveRecord::Base].delete(Woozel)
    Object.send(:remove_const, :Woozel)
    GC.start
  end

  describe "explicit versions" do
    let(:woozel) { Woozel.create!(:name => 'Eeyore') }
    it "should create the first version on save" do
      woozel = Woozel.new(:name => 'Eeyore')
      expect(woozel).not_to be_versioned
      woozel.save!
      expect(woozel).to be_versioned
      expect(woozel.versions.length).to eql(1)
      expect(woozel.versions.current.model.name).to eql('Eeyore')
    end

    it "should keep the last version up to date for each save" do
      expect(woozel).to be_versioned
      expect(woozel.versions.length).to eql(1)
      expect(woozel.versions.current.model.name).to eql('Eeyore')
      woozel.name = 'Piglet'
      woozel.save!
      expect(woozel.versions.length).to eql(1)
      expect(woozel.versions.current.model.name).to eql('Piglet')
    end

    it "should create a new version when asked to" do
      woozel.name = 'Piglet'
      woozel.with_versioning(:explicit => true, &:save!)
      expect(woozel.versions.length).to eql(2)
      expect(woozel.versions.first.model.name).to eql('Eeyore')
      expect(woozel.versions.current.model.name).to eql('Piglet')
    end

    it 'should not create a new version when not explicitly asked to' do
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      expect(woozel.versions.length).to eql(1)
      expect(woozel.versions.current.model.name).to eql('Piglet')
    end

    it 'should not update the last version when not versioning' do
      woozel.name = 'Piglet'
      woozel.without_versioning(&:save!)
      expect(woozel.versions.length).to eql(1)
      expect(woozel.versions.current.model.name).to eql('Eeyore')
    end

    it 'should not reload one versionable association from the database' do
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      expect(woozel.versions.loaded?).to eq false
      first = woozel.versions.first
      Woozel.connection.expects(:select_all).never
      expect(first.versionable).to eq woozel
    end

    it 'should not reload any versionable associations from the database' do
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      expect(woozel.versions.loaded?).to eq false
      all = woozel.versions.to_a
      Woozel.connection.expects(:select_all).never
      all.each do |version|
        expect(version.versionable).to eq woozel
      end
    end
  end

  describe "#model=" do
    let(:woozel) { Woozel.create!(:name => 'Eeyore') }

    it "should assign the model for the version" do
      expect(woozel.versions.length).to eql(1)
      expect(woozel.versions.current.model.name).to eql('Eeyore')

      woozel.name = 'Piglet'
      woozel.with_versioning(:explicit => true, &:save!)

      expect(woozel.versions.length).to eql(2)

      first_version = woozel.versions.first
      first_model   = first_version.model
      expect(first_model.name).to eql('Eeyore')

      first_model.name = 'Foo'
      first_version.model = first_model
      first_version.save!

      versions = woozel.reload.versions
      expect(versions.first.model.name).to eql('Foo')
    end
  end

  describe "#current_version?" do
    before do
      @woozel = Woozel.create! name: 'test'
      @woozel.with_versioning(explicit: true, &:save!)
    end

    it "should always be true for models loaded directly from AR" do
      expect(@woozel).to be_current_version
      @woozel = Woozel.find(@woozel.id)
      expect(@woozel).to be_current_version
      @woozel.reload
      expect(@woozel).to be_current_version
      expect(Woozel.new(name: 'test2')).to be_current_version
    end

    it "should be false for the #model of any version" do
      expect(@woozel.versions.current.model).not_to be_current_version
      expect(@woozel.versions.map { |v| v.model.current_version? }).to eq [false, false]
    end
  end

  describe "#versions.current_version" do
    before do
      @woozel = Woozel.new name: 'test'
    end

    it "should return nil when no current version is available" do
      expect(@woozel.versions.current_version).to be_nil

      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.current_version).not_to be_nil
    end

    it "should return the latest version" do
      @woozel.with_versioning(explicit: true, &:save!)
      @woozel.name = 'testier'
      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.current_version.model.name).to eq 'testier'
    end
  end

  describe "#versions.previous_version" do
    before do
      @woozel = Woozel.new name: 'test'
    end

    it "should return nil when no previous version is available" do
      expect(@woozel.versions.previous_version).to be_nil

      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.previous_version).to be_nil

      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.previous_version).not_to be_nil
    end

    context "with previous versions" do
      before do
        @woozel.with_versioning(explicit: true, &:save!)
        @woozel.name = 'testier'
        @woozel.with_versioning(explicit: true, &:save!)
        @woozel.name = 'testiest'
        @woozel.with_versioning(explicit: true, &:save!)
      end

      it "should return the previous version" do
        expect(@woozel.versions.previous_version.model.name).to eq 'testier'
      end

      it "should return the previous version for a specific number" do
        expect(@woozel.versions.previous_version(1)).to be_nil
        expect(@woozel.versions.previous_version(2).model.name).to eq 'test'
      end
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

      after do
        woozel.simply_versioned_options[:on_load] = nil
      end

      it "can modify a version after loading" do
        expect(YAML::load(woozel.current_version.yaml)['name']).to eq 'test'
        expect(woozel.current_version.model.name).to eq 'test override'
      end
    end
  end
end
