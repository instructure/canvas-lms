require File.expand_path(File.dirname(__FILE__)+'/../../../../spec/apis/api_spec_helper')

class Woozel< ActiveRecord::Base
  simply_versioned :explicit => true
end

Woozel.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

describe 'simply_versioned' do
  describe "explicit versions" do
    before do
      Woozel.connection.create_table :woozels, :force => true do |t|
        t.string :name
      end
    end
    after do
      Woozel.connection.drop_table :woozels
    end

    it "should create the first version on save" do
      woozel = Woozel.new(:name => 'Eeyore')
      woozel.should_not be_versioned
      woozel.save!
      woozel.should be_versioned
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')
    end

    it "should keep the last version up to date for each save" do
      woozel = Woozel.create!(:name => 'Eeyore')
      woozel.should be_versioned
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')
      woozel.name = 'Piglet'
      woozel.save!
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Piglet')
    end

    it "should create a new version when asked to" do
      woozel = Woozel.create!(:name => 'Eeyore')
      woozel.name = 'Piglet'
      woozel.with_versioning(:explicit => true, &:save!)
      woozel.versions.length.should eql(2)
      woozel.versions.first.model.name.should eql('Eeyore')
      woozel.versions.current.model.name.should eql('Piglet')
    end

    it 'should not create a new version when not explicitly asked to' do
      woozel = Woozel.create!(:name => 'Eeyore')
      woozel.name = 'Piglet'
      woozel.with_versioning(&:save!)
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Piglet')
    end

    it 'should not update the last version when not versioning' do
      woozel = Woozel.create!(:name => 'Eeyore')
      woozel.name = 'Piglet'
      woozel.without_versioning(&:save!)
      woozel.versions.length.should eql(1)
      woozel.versions.current.model.name.should eql('Eeyore')
    end
  end
end