require 'spec_helper'

#require 'canvas_stringex'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "spec/acts_as_url.sqlite3")

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :documents, :force => true do |t|
    t.string :title, :url, :other
  end

  create_table :mocuments, :force => true do |t|
    t.string :title, :url, :other
  end

  create_table :permuments, :force => true do |t|
    t.string :title, :permalink, :other
  end

  create_table :procuments, :force => true do |t|
    t.string :title, :url, :other
  end

  create_table :blankuments, :force => true do |t|
    t.string :title, :url, :other
  end
end
ActiveRecord::Migration.verbose = true

class Document < ActiveRecord::Base
  acts_as_url :title
end

class Mocument < ActiveRecord::Base
  acts_as_url :title, :scope => :other, :sync_url => true
end

class Permument < ActiveRecord::Base
  acts_as_url :title, :url_attribute => :permalink
end

class Procument < ActiveRecord::Base
  acts_as_url :non_attribute_method

  def non_attribute_method
    "#{title} got massaged"
  end
end

class Blankument < ActiveRecord::Base
  acts_as_url :title, :only_when_blank => true
end

describe "ActsAsUrl" do
  it "should_create_url" do
    @doc = Document.create(:title => "Let's Make a Test Title, <em>Okay</em>?")
    expect("lets-make-a-test-title-okay").to eq @doc.url
  end

  it "should_create_unique_url" do
    @doc = Document.create!(:title => "Unique")
    @other_doc = Document.create!(:title => "Unique")
    expect("unique-1").to eq @other_doc.url
  end

  it "should_not_succ_on_repeated_saves" do
    @doc = Document.new(:title => "Continuous or Constant")
    5.times do
      @doc.save!
      expect("continuous-or-constant").to eq @doc.url
    end
  end

  it "should_scope_uniqueness" do
    @moc = Mocument.create!(:title => "Mocumentary", :other => "I dunno why but I don't care if I'm unique")
    @other_moc = Mocument.create!(:title => "Mocumentary")
    expect(@moc.url).to eq @other_moc.url
  end

  it "should_still_create_unique_if_in_same_scope" do
    @moc = Mocument.create!(:title => "Mocumentary", :other => "Suddenly, I care if I'm unique")
    @other_moc = Mocument.create!(:title => "Mocumentary", :other => "Suddenly, I care if I'm unique")
    expect(@moc.url).to_not eq @other_moc.url
  end

  it "should_use_alternate_field_name" do
    @perm = Permument.create!(:title => "Anything at This Point")
    expect("anything-at-this-point").to eq @perm.permalink
  end

  it "should_not_update_url_by_default" do
    @doc = Document.create!(:title => "Stable as Stone")
    @original_url = @doc.url
    @doc.update_attributes :title => "New Unstable Madness"
    expect(@original_url).to eq @doc.url
  end

  it "should_update_url_if_asked" do
    @moc = Mocument.create!(:title => "Original")
    @original_url = @moc.url
    @moc.update_attributes :title => "New and Improved"
    expect(@original_url).to_not eq @moc.url
  end

  it "should_update_url_only_when_blank_if_asked" do
    @original_url = 'the-url-of-concrete'
    @blank = Blankument.create!(:title => "Stable as Stone", :url => @original_url)
    expect(@original_url).to eq @blank.url
    @blank = Blankument.create!(:title => "Stable as Stone")
    expect('stable-as-stone').to eq @blank.url
  end

  it "should override only_when_blank only for instance (not class level)" do
    @blank = Blankument.new(:title => "something Something", :url => @original_url)
    @original_url = 'the-url-of-concrete'
    @blank.only_when_blank = false
    @blank.save!
    expect('something-something').to eq @blank.url

    @blank2 = Blankument.new
    expect(@blank2.only_when_blank).to eq(true)
  end

  it "should_mass_initialize_urls" do
    @doc_1 = Document.create!(:title => "Initial")
    @doc_2 = Document.create!(:title => "Subsequent")
    @doc_1.update_attribute :url, nil
    @doc_2.update_attribute :url, nil
    expect(@doc_1.url).to be_nil
    expect(@doc_2.url).to be_nil
    Document.initialize_urls
    @doc_1.reload
    @doc_2.reload
    expect("initial").to eq @doc_1.url
    expect("subsequent").to eq @doc_2.url
  end

  it "should_mass_initialize_urls_with_custom_url_attribute" do
    @doc_1 = Permument.create!(:title => "Initial")
    @doc_2 = Permument.create!(:title => "Subsequent")
    @doc_1.update_attribute :permalink, nil
    @doc_2.update_attribute :permalink, nil
    expect(@doc_1.permalink).to be_nil
    expect(@doc_2.permalink).to be_nil
    Permument.initialize_urls
    @doc_1.reload
    @doc_2.reload
    expect("initial").to eq @doc_1.permalink
    expect("subsequent").to eq @doc_2.permalink
  end

  it "should_utilize_block_if_given" do
    @doc = Procument.create!(:title => "Title String")
    expect("title-string-got-massaged").to eq @doc.url
  end
end
