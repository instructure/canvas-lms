require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe AddressBook::Empty do
  before :each do
    @address_book = AddressBook::Empty.new(user_model)
  end

  describe "known_users" do
    it "returns an empty array" do
      other_user = user_model
      expect(@address_book.known_users([other_user])).to eql([])
    end
  end

  describe "known_user" do
    it "returns nil" do
      other_user = user_model
      expect(@address_book.known_user(other_user)).to be_nil
    end
  end

  describe "common_courses" do
    it "returns an empty hash" do
      other_user = user_model
      expect(@address_book.common_courses(other_user)).to eql({})
    end
  end

  describe "common_groups" do
    it "returns an empty hash" do
      other_user = user_model
      expect(@address_book.common_courses(other_user)).to eql({})
    end
  end

  describe "known_in_context" do
    it "returns an empty array" do
      course = course(active_all: true)
      expect(@address_book.known_in_context(course.asset_string)).to eql([])
    end
  end

  describe "count_in_context" do
    it "returns zero" do
      course = course(active_all: true)
      expect(@address_book.count_in_context(course.asset_string)).to eql(0)
    end
  end

  describe "search_users" do
    it "returns an empty but paginatable collection" do
      known_users = @address_book.search_users(search: 'Bob')
      expect(known_users).to respond_to(:paginate)
      expect(known_users.paginate(per_page: 1).size).to eql(0)
    end
  end

  describe "sections" do
    it "returns an empty array" do
      expect(@address_book.sections).to eql([])
    end
  end

  describe "groups" do
    it "returns an empty array" do
      expect(@address_book.groups).to eql([])
    end
  end
end
