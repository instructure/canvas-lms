#
# Copyright (C) 2011 - 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

class TestApiInstance
  include Api
  def initialize(root_account, current_user)
    @domain_root_account = root_account
    @current_user = current_user
  end

  def account_url(account)
    URI.encode("http://www.example.com/accounts/#{account}")
  end

  def course_assignment_url(course, assignment)
    URI.encode("http://www.example.com/courses/#{course}/assignments/#{assignment}")
  end
end

describe Api do
  context 'api_find' do
    before do
      @user = user
      @api = TestApiInstance.new Account.default, nil
    end

    it 'should find a simple record' do
      @user.should == @api.api_find(User, @user.id)
    end

    it 'should not find a missing record' do
      (lambda {@api.api_find(User, (User.all.map(&:id).max + 1))}).should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should find an existing sis_id record' do
      @user = user_with_pseudonym :username => "sis_user_1@example.com"
      @api.api_find(User, "sis_login_id:sis_user_1@example.com").should == @user
    end

    it 'should not find record from other account' do
      account = Account.create(name: 'new')
      @user = user_with_pseudonym username: "sis_user_1@example.com", account: account
      (lambda {@api.api_find(User, "sis_login_id:sis_user_2@example.com")}).should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should find record from other root account explicitly' do
      account = Account.create(name: 'new')
      @user = user_with_pseudonym username: "sis_user_1@example.com", account: account
      Api.expects(:sis_parse_id).with("root_account:school:sis_login_id:sis_user_1@example.com", anything, anything).
          returns(['pseudonyms.unique_id', ["sis_user_1@example.com", account]])
      @api.api_find(User, "root_account:school:sis_login_id:sis_user_1@example.com").should == @user
    end

    it 'should allow passing account param and find record' do
      account = Account.create(name: 'new')
      @user = user_with_pseudonym username: "sis_user_1@example.com", account: account
      @api.api_find(User, "sis_login_id:sis_user_1@example.com", account: account).should == @user
    end

    it 'should not find a missing sis_id record' do
      @user = user_with_pseudonym :username => "sis_user_1@example.com"
      (lambda {@api.api_find(User, "sis_login_id:sis_user_2@example.com")}).should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should find user id "self" when a current user is provided' do
      @user.should == TestApiInstance.new(Account.default, @user).api_find(User, 'self')
    end

    it 'should not find user id "self" when a current user is not provided' do
      (lambda {TestApiInstance.new(Account.default, nil).api_find(User, "self")}).should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should find account id "self"' do
      account = Account.create!
      account.should == TestApiInstance.new(account, nil).api_find(Account, 'self')
    end

    it 'should find account id "default"' do
      account = Account.create!
      Account.default.should == TestApiInstance.new(account, nil).api_find(Account, 'default')
    end

    it 'should find account id "site_admin"' do
      account = Account.create!
      Account.site_admin.should == TestApiInstance.new(account, nil).api_find(Account, 'site_admin')
    end

    it 'should find term id "default"' do
      account = Account.create!
      TestApiInstance.new(account, nil).api_find(account.enrollment_terms, 'default').should == account.default_enrollment_term
    end

    it 'should find term id "current"' do
      account = Account.create!
      term = account.enrollment_terms.create!(start_at: 1.week.ago, end_at: 1.week.from_now)
      TestApiInstance.new(account, nil).api_find(account.enrollment_terms, 'current').should == term
    end

    it 'should not find a "current" term if there is more than one candidate' do
      account = Account.create!
      account.enrollment_terms.create!(start_at: 1.week.ago, end_at: 1.week.from_now)
      account.enrollment_terms.create!(start_at: 2.weeks.ago, end_at: 2.weeks.from_now)
      TestApiInstance.new(account, nil).api_find_all(account.enrollment_terms, ['current']).should == []
    end

    it 'should find an open ended "current" term' do
      account = Account.create!
      term = account.enrollment_terms.create!(start_at: 1.week.ago)
      TestApiInstance.new(account, nil).api_find(account.enrollment_terms, 'current').should == term
    end


    it 'should not find a user with an invalid AR id' do
      (lambda {@api.api_find(User, "a1")}).should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      api1 = TestApiInstance.new account1, nil
      api2 = TestApiInstance.new account2, nil
      user1 = user_with_pseudonym :username => "sis_user_1@example.com", :account => account1
      user2 = user_with_pseudonym :username => "sis_user_2@example.com", :account => account2
      user3 = user_with_pseudonym :username => "sis_user_3@example.com", :account => account1
      user4 = user_with_pseudonym :username => "sis_user_3@example.com", :account => account2
      api1.api_find(User, "sis_login_id:sis_user_1@example.com").should == user1
      (lambda {api2.api_find(User, "sis_login_id:sis_user_1@example.com")}).should raise_error(ActiveRecord::RecordNotFound)
      (lambda {api1.api_find(User, "sis_login_id:sis_user_2@example.com")}).should raise_error(ActiveRecord::RecordNotFound)
      api2.api_find(User, "sis_login_id:sis_user_2@example.com").should == user2
      api1.api_find(User, "sis_login_id:sis_user_3@example.com").should == user3
      api2.api_find(User, "sis_login_id:sis_user_3@example.com").should == user4
      [user1, user2, user3, user4].each do |user|
        [api1, api2].each do |api|
          api.api_find(User, user.id).should == user
        end
      end
    end

    it "should find user by lti_context_id" do
      @user.lti_context_id = Canvas::Security.hmac_sha1(@user.asset_string.to_s, 'key')
      @user.save!
      @api.api_find(User, "lti_context_id:#{@user.lti_context_id}").should == @user
    end

    it "should find course by lti_context_id" do
      lti_course = course
      lti_course.lti_context_id = Canvas::Security.hmac_sha1(lti_course.asset_string.to_s, 'key')
      lti_course.save!
      @api.api_find(Course, "lti_context_id:#{lti_course.lti_context_id}").should == lti_course
    end

    it "should find account by lti_context_id" do
      account = Account.create!(name: 'account')
      account.lti_context_id = Canvas::Security.hmac_sha1(account.asset_string.to_s, 'key')
      account.save!
      @api.api_find(Account, "lti_context_id:#{account.lti_context_id}").should == account
    end
  end

  context 'api_find_all' do
    before do
      @user = user
      @api = TestApiInstance.new Account.default, nil
    end

    it 'should find no records' do
      @api.api_find_all(User, []).should == []
    end

    it 'should find a simple record' do
      @api.api_find_all(User, [@user.id]).should == [@user]
    end

    it 'should not find a missing record' do
      @api.api_find_all(User, [(User.all.map(&:id).max + 1)]).should == []
    end

    it 'should find an existing sis_id record' do
      @user = user_with_pseudonym :username => "sis_user_1@example.com"
      @api.api_find_all(User, ["sis_login_id:sis_user_1@example.com"]).should == [@user]
    end

    it 'should find existing records with different lookup strategies' do
      @user1 = user
      @user2 = user_with_pseudonym :username => "sis_user_1@example.com"
      @user3 = user_with_pseudonym
      @pseudonym.sis_user_id = "sis_user_2"
      @pseudonym.save!
      @user4 = user_with_pseudonym :username => "sis_user_3@example.com"
      @api.api_find_all(User, [@user1.id.to_s, "sis_login_id:sis_user_1@example.com", (User.all.map(&:id).max + 1), "sis_user_id:sis_user_2", "sis_login_id:nonexistent@example.com", "sis_login_id:sis_user_3@example.com", "sis_invalid_column:4", "a1"]).sort_by(&:id).should == [@user1, @user2, @user3, @user4].sort_by(&:id)
    end

    it 'should filter out duplicates' do
      @other_user = user
      @user = user_with_pseudonym :username => "sis_user_1@example.com"
      @api.api_find_all(User, [@user.id, "sis_login_id:sis_user_1@example.com", @other_user.id, @user.id]).sort_by(&:id).should == [@user, @other_user].sort_by(&:id)
    end

    it "should find user id 'self' when a current user is provided" do
      @current_user = user
      @other_user = user
      TestApiInstance.new(Account.default, @current_user).api_find_all(User, [@other_user.id, 'self']).sort_by(&:id).should == [@current_user, @other_user].sort_by(&:id)
    end

    it 'should not find user id "self" when a current user is not provided' do
      @current_user = user
      @other_user = user
      TestApiInstance.new(Account.default, nil).api_find_all(User, ["self", @other_user.id]).should == [@other_user]
    end

    it "should not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      api1 = TestApiInstance.new account1, nil
      api2 = TestApiInstance.new account2, nil
      user1 = user_with_pseudonym :username => "sis_user_1@example.com", :account => account1
      user2 = user_with_pseudonym :username => "sis_user_2@example.com", :account => account2
      user3 = user_with_pseudonym :username => "sis_user_3@example.com", :account => account1
      user4 = user_with_pseudonym :username => "sis_user_3@example.com", :account => account2
      user5 = user :account => account1
      user6 = user :account => account2
      api1.api_find_all(User, ["sis_login_id:sis_user_1@example.com", "sis_login_id:sis_user_2@example.com", "sis_login_id:sis_user_3@example.com", user5.id, user6.id]).sort_by(&:id).should == [user1, user3, user5, user6].sort_by(&:id)
      api2.api_find_all(User, ["sis_login_id:sis_user_1@example.com", "sis_login_id:sis_user_2@example.com", "sis_login_id:sis_user_3@example.com", user5.id, user6.id]).sort_by(&:id).should == [user2, user4, user5, user6].sort_by(&:id)
    end

    it "should limit results if a limit is provided" do
      collection = mock()
      collection.stubs(:table_name).returns("courses")
      collection.expects(:all).with({:conditions => { 'id' => [1, 2, 3]}}).returns("result")
      @api.api_find_all(collection, [1,2,3]).should == "result"
      collection.expects(:all).with({:conditions => { 'id' => [1, 2, 3]}, :limit => 3}).returns("result")
      @api.api_find_all(collection, [1,2,3], limit: 3).should == "result"
    end

    it 'should limit results if a limit is provided - unmocked' do
      users = 0.upto(9).map{|x| user}
      result = @api.api_find_all(User, 0.upto(9).map{|i| users[i].id}, limit: 5)
      result.count.should == 5
      result.each { |user| users.include?(user).should be_true }
    end

    it "should not hit the database if no valid conditions were found" do
      collection = mock()
      collection.stubs(:table_name).returns("courses")
      @api.api_find_all(collection, ["sis_invalid:1"]).should == []
    end

    context "sharding" do
      specs_require_sharding

      it "should find users from other shards" do
        @shard1.activate { @user2 = User.create! }
        @shard2.activate { @user3 = User.create! }

        @api.api_find_all(User, [@user2.id, @user3.id]).sort_by(&:global_id).should == [@user2, @user3].sort_by(&:global_id)
      end
    end
  end

  context 'map_ids' do
    it 'should map an empty list' do
      Api.map_ids([], User, Account.default).should == []
    end

    it 'should map a list of AR ids' do
      Api.map_ids([1, 2, '3', '4'], User, Account.default).sort.should == [1, 2, 3, 4]
    end

    it "should bail on ids it can't figure out" do
      Api.map_ids(["nonexistentcolumn:5", "sis_nonexistentcolumn:6", 7], User, Account.default).should == [7]
    end

    it "should filter out sis ids that don't exist, but not filter out AR ids" do
      Api.map_ids(["sis_user_id:1", "2"], User, Account.default).should == [2]
    end

    it "should find sis ids that exist" do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym :username => "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym :username => "sisuser3@example.com"
      @user3 = @user
      Api.map_ids(["sis_user_id:sisuser1", "sis_login_id:sisuser2@example.com",
        "hex:sis_login_id:7369737573657233406578616d706c652e636f6d", "sis_user_id:sisuser4",
        "5123"], User, Account.default).sort.should == [
        @user1.id, @user2.id, @user3.id, 5123].sort
    end

    it 'should work when only provided sis_ids' do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym :username => "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym :username => "sisuser3@example.com"
      @user3 = @user
      Api.map_ids(["sis_user_id:sisuser1", "sis_login_id:sisuser2@example.com",
        "hex:sis_login_id:7369737573657233406578616d706c652e636f6d", "sis_user_id:sisuser4"], User, Account.default).sort.should == [
        @user1.id, @user2.id, @user3.id].sort
    end

    it "should not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      user1 = user_with_pseudonym :username => "sisuser1@example.com", :account => account1
      user2 = user_with_pseudonym :username => "sisuser2@example.com", :account => account2
      user3 = user_with_pseudonym :username => "sisuser3@example.com", :account => account1
      user4 = user_with_pseudonym :username => "sisuser3@example.com", :account => account2
      user5 = user :account => account1
      user6 = user :account => account2
      Api.map_ids(["sis_login_id:sisuser1@example.com", "sis_login_id:sisuser2@example.com", "sis_login_id:sisuser3@example.com", user5.id, user6.id], User, account1).sort.should == [user1.id, user3.id, user5.id, user6.id].sort
    end

    it 'should try and make params when non-ar_id columns have returned with ar_id columns' do
      collection = mock()
      Api.expects(:sis_find_sis_mapping_for_collection).with(collection).returns({:lookups => {"id" => "test-lookup"}})
      Api.expects(:sis_parse_ids).with("test-ids", {"id" => "test-lookup"}, anything).returns({"test-lookup" => ["thing1", "thing2"], "other-lookup" => ["thing2", "thing3"]})
      Api.expects(:sis_make_params_for_sis_mapping_and_columns).with({"other-lookup" => ["thing2", "thing3"]}, {:lookups => {"id" => "test-lookup"}}, "test-root-account").returns({"find-params" => "test"})
      collection.expects(:scoped).with("find-params" => "test").returns(collection)
      collection.expects(:pluck).with(:id).returns(["thing2", "thing3"])
      Api.map_ids("test-ids", collection, "test-root-account").should == ["thing1", "thing2", "thing3"]
    end

    it 'should try and make params when non-ar_id columns have returned without ar_id columns' do
      collection = mock()
      Api.expects(:sis_find_sis_mapping_for_collection).with(collection).returns({:lookups => {"id" => "test-lookup"}})
      Api.expects(:sis_parse_ids).with("test-ids", {"id" => "test-lookup"}, anything).returns({"other-lookup" => ["thing2", "thing3"]})
      Api.expects(:sis_make_params_for_sis_mapping_and_columns).with({"other-lookup" => ["thing2", "thing3"]}, {:lookups => {"id" => "test-lookup"}}, "test-root-account").returns({"find-params" => "test"})
      collection.expects(:scoped).with("find-params" => "test").returns(collection)
      collection.expects(:pluck).with(:id).returns(["thing2", "thing3"])
      Api.map_ids("test-ids", collection, "test-root-account").should == ["thing2", "thing3"]
    end

    it 'should not try and make params when no non-ar_id columns have returned with ar_id columns' do
      collection = mock()
      Api.expects(:sis_find_sis_mapping_for_collection).with(collection).returns({:lookups => {"id" => "test-lookup"}})
      Api.expects(:sis_parse_ids).with("test-ids", {"id" => "test-lookup"}, anything).returns({"test-lookup" => ["thing1", "thing2"]})
      Api.expects(:sis_make_params_for_sis_mapping_and_columns).at_most(0)
      Api.map_ids("test-ids", collection, "test-root-account").should == ["thing1", "thing2"]
    end

    it 'should not try and make params when no non-ar_id columns have returned without ar_id columns' do
      collection = mock()
      object1 = mock()
      object2 = mock()
      Api.expects(:sis_find_sis_mapping_for_collection).with(collection).returns({:lookups => {"id" => "test-lookup"}})
      Api.expects(:sis_parse_ids).with("test-ids", {"id" => "test-lookup"}, anything).returns({})
      Api.expects(:sis_make_params_for_sis_mapping_and_columns).at_most(0)
      Api.map_ids("test-ids", collection, "test-root-account").should == []
    end

  end

  context 'sis_parse_id' do
    before do
      @lookups = Api::SIS_MAPPINGS['users'][:lookups]
    end

    it 'should handle numeric ids' do
      Api.sis_parse_id(1, @lookups).should == ["users.id", 1]
      Api.sis_parse_id(10, @lookups).should == ["users.id", 10]
    end

    it 'should handle numeric ids as strings' do
      Api.sis_parse_id("1", @lookups).should == ["users.id", 1]
      Api.sis_parse_id("10", @lookups).should == ["users.id", 10]
    end

    it 'should handle hex_encoded sis_fields' do
      Api.sis_parse_id("hex:sis_login_id:7369737573657233406578616d706c652e636f6d", @lookups).should == ["pseudonyms.unique_id", "sisuser3@example.com"]
      Api.sis_parse_id("hex:sis_user_id:7369737573657234406578616d706c652e636f6d", @lookups).should == ["pseudonyms.sis_user_id", "sisuser4@example.com"]
    end

    it 'should not handle invalid hex fields' do
      Api.sis_parse_id("hex:sis_user_id:7369737573657234406578616g706c652e636f6d", @lookups).should == [nil, nil]
      Api.sis_parse_id("hex:sis_user_id:7369737573657234406578616d06c652e636f6d", @lookups).should == [nil, nil]
    end

    it 'should not handle hex_encoded non-sis fields' do
      Api.sis_parse_id("hex:id:7369737573657233406578616d706c652e636f6d", @lookups).should == [nil, nil]
      Api.sis_parse_id("hex:1234", @lookups).should == [nil, nil]
    end

    it 'should handle plain sis_fields' do
      Api.sis_parse_id("sis_login_id:sisuser3@example.com", @lookups).should == ["pseudonyms.unique_id", "sisuser3@example.com"]
      Api.sis_parse_id("sis_user_id:sisuser4", @lookups).should == ["pseudonyms.sis_user_id", "sisuser4"]
    end

    it "should not handle plain sis_fields that don't exist" do
      Api.sis_parse_id("sis_nonexistent_column:1", @lookups).should == [nil, nil]
      Api.sis_parse_id("sis_nonexistent:a", @lookups).should == [nil, nil]
    end

    it 'should not handle other things' do
      Api.sis_parse_id("id:1", @lookups).should == [nil, nil]
      Api.sis_parse_id("a1", @lookups).should == [nil, nil]
      Api.sis_parse_id("\t10\n11 ", @lookups).should == [nil, nil]
    end

    it 'should handle surrounding whitespace' do
      Api.sis_parse_id("\t10  ", @lookups).should == ["users.id", 10]
      Api.sis_parse_id("\t10\n", @lookups).should == ["users.id", 10]
      Api.sis_parse_id("  hex:sis_login_id:7369737573657233406578616d706c652e636f6d     ", @lookups).should == ["pseudonyms.unique_id", "sisuser3@example.com"]
      Api.sis_parse_id("  sis_login_id:sisuser3@example.com\t", @lookups).should == ["pseudonyms.unique_id", "sisuser3@example.com"]
    end
  end

  context 'sis_parse_ids' do
    before do
      @lookups = Api::SIS_MAPPINGS['users'][:lookups]
    end

    it 'should handle a list of ar_ids' do
      Api.sis_parse_ids([1,2,3], @lookups).should == { "users.id" => [1,2,3] }
      Api.sis_parse_ids(["1","2","3"], @lookups).should == { "users.id" => [1,2,3] }
    end

    it 'should handle a list of sis ids' do
      Api.sis_parse_ids(["sis_user_id:U1","sis_user_id:U2","sis_user_id:U3"], @lookups).should == { "pseudonyms.sis_user_id" => ["U1","U2","U3"] }
    end

    it 'should remove duplicates' do
      Api.sis_parse_ids([1,2,3,2], @lookups).should == { "users.id" => [1,2,3] }
      Api.sis_parse_ids([1,2,2,3], @lookups).should == { "users.id" => [1,2,3] }
      Api.sis_parse_ids(["sis_user_id:U1","sis_user_id:U2","sis_user_id:U2","sis_user_id:U3"], @lookups).should == { "pseudonyms.sis_user_id" => ["U1","U2","U3"] }
      Api.sis_parse_ids(["sis_user_id:U1","sis_user_id:U2","sis_user_id:U3","sis_user_id:U2"], @lookups).should == { "pseudonyms.sis_user_id" => ["U1","U2","U3"] }
    end

    it 'should work with mixed sis id types' do
      Api.sis_parse_ids([1,2,"sis_user_id:U1",3,"sis_user_id:U2","sis_user_id:U3","sis_login_id:A1"], @lookups).should == { "users.id" => [1, 2, 3], "pseudonyms.sis_user_id" => ["U1", "U2", "U3"], "pseudonyms.unique_id" => ["A1"] }
    end

    it 'should skip invalid things' do
      Api.sis_parse_ids([1,2,3,"a1","invalid","sis_nonexistent:3"], @lookups).should == { "users.id" => [1,2,3] }
    end
  end

  context 'sis_find_sis_mapping_for_collection' do
    it 'should find the appropriate sis mapping' do
      [Course, EnrollmentTerm, User, Account, CourseSection].each do |collection|
        Api.sis_find_sis_mapping_for_collection(collection).should == Api::SIS_MAPPINGS[collection.table_name]
        Api::SIS_MAPPINGS[collection.table_name].is_a?(Hash).should be_true
      end
    end

    it 'should raise an error otherwise' do
      [StreamItem, PluginSetting].each do |collection|
        (lambda {Api.sis_find_sis_mapping_for_collection(collection)}).should raise_error("need to add support for table name: #{collection.table_name}")
      end
    end
  end

  context 'sis_find_params_for_collection' do
    it 'should pass along the sis_mapping to sis_find_params_for_sis_mapping' do
      root_account = account_model
      Api.expects(:sis_find_params_for_sis_mapping).with(Api::SIS_MAPPINGS['users'], [1,2,3], root_account, anything).returns(1234)
      Api.expects(:sis_find_sis_mapping_for_collection).with(User).returns(Api::SIS_MAPPINGS['users'])
      Api.sis_find_params_for_collection(User, [1,2,3], root_account).should == 1234
    end
  end

  context 'sis_find_params_for_sis_mapping' do
    it 'should pass along the parsed ids to sis_make_params_for_sis_mapping_and_columns' do
      root_account = account_model
      Api.expects(:sis_parse_ids).with([1,2,3], "lookups", anything).returns({"users.id" => [4,5,6]})
      Api.expects(:sis_make_params_for_sis_mapping_and_columns).with({"users.id" => [4,5,6]}, {:lookups => "lookups"}, root_account).returns("params")
      Api.sis_find_params_for_sis_mapping({:lookups => "lookups"}, [1,2,3], root_account).should == "params"
    end
  end

  context 'sis_make_params_for_sis_mapping_and_columns' do
    it 'should fail when not given a root account' do
      Api.sis_make_params_for_sis_mapping_and_columns({}, {}, Account.default).should == :not_found
      (lambda {Api.sis_make_params_for_sis_mapping_and_columns({}, {}, user)}).should raise_error("sis_root_account required for lookups")
    end

    it 'should properly generate an escaped arg string' do
      Api.sis_make_params_for_sis_mapping_and_columns({"id" => ["1",2,3]}, {:scope => "scope"}, Account.default).should == { :conditions => ["(scope = #{Account.default.id} AND id IN (?))", ["1", 2, 3]] }
    end

    it 'should work with no columns' do
      Api.sis_make_params_for_sis_mapping_and_columns({}, {}, Account.default).should == :not_found
    end

    it 'should add in joins if the sis_mapping has some with columns' do
      Api.sis_make_params_for_sis_mapping_and_columns({"id" => ["1",2,3]}, {:scope => "scope", :joins => 'some joins'}, Account.default).should == { :conditions => ["(scope = #{Account.default.id} AND id IN (?))", ["1", 2, 3]], :include => 'some joins' }
    end

    it 'should work with a few different column types and account scopings' do
      Api.sis_make_params_for_sis_mapping_and_columns({"id1" => [1,2,3], "id2" => ["a","b","c"], "id3" => ["s1", "s2", "s3"]}, {:scope => "some_scope", :is_not_scoped_to_account => ['id3'].to_set}, Account.default).should == { :conditions => ["(some_scope = #{Account.default.id} AND id1 IN (?)) OR (some_scope = #{Account.default.id} AND id2 IN (?)) OR id3 IN (?)", [1, 2, 3], ["a", "b", "c"], ["s1", "s2", "s3"]]}
    end

    it "should scope to accounts by default if :is_not_scoped_to_account doesn't exist" do
      Api.sis_make_params_for_sis_mapping_and_columns({"id" => ["1",2,3]}, {:scope => "scope"}, Account.default).should == { :conditions => ["(scope = #{Account.default.id} AND id IN (?))", ["1", 2, 3]] }
    end

    it "should fail if we're scoping to an account and the scope isn't provided" do
      (lambda {Api.sis_make_params_for_sis_mapping_and_columns({"id" => ["1",2,3]}, {}, Account.default)}).should raise_error("missing scope for collection")
    end
  end

  context 'sis_mappings' do
    it 'should correctly capture course lookups' do
      lookups = Api.sis_find_sis_mapping_for_collection(Course)[:lookups]
      Api.sis_parse_id("sis_course_id:1", lookups).should == ["sis_source_id", "1"]
      Api.sis_parse_id("sis_term_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_user_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_login_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_account_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_section_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("1", lookups).should == ["id", 1]
    end

    it 'should correctly capture enrollment_term lookups' do
      lookups = Api.sis_find_sis_mapping_for_collection(EnrollmentTerm)[:lookups]
      Api.sis_parse_id("sis_term_id:1", lookups).should == ["sis_source_id", "1"]
      Api.sis_parse_id("sis_course_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_user_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_login_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_account_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_section_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("1", lookups).should == ["id", 1]
    end

    it 'should correctly capture user lookups' do
      lookups = Api.sis_find_sis_mapping_for_collection(User)[:lookups]
      Api.sis_parse_id("sis_user_id:1", lookups).should == ["pseudonyms.sis_user_id", "1"]
      Api.sis_parse_id("sis_login_id:1", lookups).should == ["pseudonyms.unique_id", "1"]
      Api.sis_parse_id("sis_course_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_term_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_account_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_section_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("1", lookups).should == ["users.id", 1]
    end

    it 'should correctly capture account lookups' do
      lookups = Api.sis_find_sis_mapping_for_collection(Account)[:lookups]
      Api.sis_parse_id("sis_account_id:1", lookups).should == ["sis_source_id", "1"]
      Api.sis_parse_id("sis_course_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_term_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_user_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_login_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_section_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("1", lookups).should == ["id", 1]
    end

    it 'should correctly capture course_section lookups' do
      lookups = Api.sis_find_sis_mapping_for_collection(CourseSection)[:lookups]
      Api.sis_parse_id("sis_section_id:1", lookups).should == ["sis_source_id", "1"]
      Api.sis_parse_id("sis_course_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_term_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_user_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_login_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("sis_account_id:1", lookups).should == [nil, nil]
      Api.sis_parse_id("1", lookups).should == ["id", 1]
    end

    it 'should correctly query the course table' do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(Course)
      Api.sis_make_params_for_sis_mapping_and_columns({"sis_source_id" => ["1"], "id" => ["1"]}, sis_mapping, Account.default).should == { :conditions => ["id IN (?) OR (root_account_id = #{Account.default.id} AND sis_source_id IN (?))", ["1"], ["1"]] }
    end

    it 'should correctly query the enrollment_term table' do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(EnrollmentTerm)
      Api.sis_make_params_for_sis_mapping_and_columns({"sis_source_id" => ["1"], "id" => ["1"]}, sis_mapping, Account.default).should == { :conditions => ["id IN (?) OR (root_account_id = #{Account.default.id} AND sis_source_id IN (?))", ["1"], ["1"]] }
    end

    it 'should correctly query the user table' do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(User)
      Api.sis_make_params_for_sis_mapping_and_columns({"pseudonyms.sis_user_id" => ["1"], "pseudonyms.unique_id" => ["1"], "users.id" => ["1"]}, sis_mapping, Account.default).should == { :include => [:pseudonym], :conditions => ["(pseudonyms.account_id = #{Account.default.id} AND pseudonyms.sis_user_id IN (?)) OR (pseudonyms.account_id = #{Account.default.id} AND pseudonyms.unique_id IN (?)) OR users.id IN (?)", ["1"], ["1"], ["1"]]}
    end

    it 'should correctly query the account table' do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(Account)
      Api.sis_make_params_for_sis_mapping_and_columns({"sis_source_id" => ["1"], "id" => ["1"]}, sis_mapping, Account.default).should == { :conditions => ["id IN (?) OR (root_account_id = #{Account.default.id} AND sis_source_id IN (?))", ["1"], ["1"]] }
    end

    it 'should correctly query the course_section table' do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(CourseSection)
      Api.sis_make_params_for_sis_mapping_and_columns({"sis_source_id" => ["1"], "id" => ["1"]}, sis_mapping, Account.default).should == { :conditions => ["id IN (?) OR (root_account_id = #{Account.default.id} AND sis_source_id IN (?))", ["1"], ["1"]] }
    end

  end

  context "map_non_sis_ids" do
    it 'should return an array of numeric ids' do
      Api.map_non_sis_ids([1, 2, 3, 4]).should == [1, 2, 3, 4]
    end

    it 'should convert string ids to numeric' do
      Api.map_non_sis_ids(%w{5 4 3 2}).should == [5, 4, 3, 2]
    end

    it "should exclude things that don't look like ids" do
      Api.map_non_sis_ids(%w{1 2 lolrus 4chan 5 6!}).should == [1, 2, 5]
    end

    it "should strip whitespace" do
      Api.map_non_sis_ids(["  1", "2  ", " 3 ", "4\n"]).should == [1, 2, 3, 4]
    end
  end

  context 'ISO8601 regex' do
    it 'should not allow invalid dates' do
      !!('10/01/2014' =~ Api::ISO8601_REGEX).should == false
    end

    it 'should not allow non ISO8601 dates' do
      !!('2014-10-01' =~ Api::ISO8601_REGEX).should == false
    end

    it 'should not allow garbage dates' do
      !!('bad_data' =~ Api::ISO8601_REGEX).should == false
    end

    it 'should allow valid dates' do
      !!('2014-10-01T00:00:00-06:00' =~ Api::ISO8601_REGEX).should == true
    end

    it 'should not allow valid dates BC' do
      !!('-2014-10-01T00:00:00-06:00' =~ Api::ISO8601_REGEX).should == false
    end
  end

  context ".api_user_content" do
    class T
      extend Api
    end
    it "should ignore non-kaltura instructure_inline_media_comment links" do
      student_in_course
      html = %{<div>This is an awesome youtube:
<a href="http://www.example.com/" class="instructure_inline_media_comment">here</a>
</div>}
      res = T.api_user_content(html, @course, @student)
      res.should == html
    end
  end

  context ".process_incoming_html_content" do
    class T
      extend Api
    end

    it "should add context to files and remove verifier parameters" do
      course
      attachment_model(:context => @course)

      html = %{<div>
        Here are some bad links
        <a href="/files/#{@attachment.id}/download">here</a>
        <a href="/files/#{@attachment.id}/download?verifier=lollercopter&amp;anotherparam=something">here</a>
        <a href="/files/#{@attachment.id}/preview?sneakyparam=haha&amp;verifier=lollercopter&amp;another=blah">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/preview?noverifier=here">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=lol&amp;a=1">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?b=2&amp;verifier=something&amp;c=2">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/notdownload?b=2&amp;verifier=shouldstay&amp;c=2">but not here</a>
      </div>}
      fixed_html = T.process_incoming_html_content(html)
      fixed_html.should == %{<div>
        Here are some bad links
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/download">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?anotherparam=something">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/preview?sneakyparam=haha&amp;another=blah">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/preview?noverifier=here">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?a=1">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?b=2&amp;c=2">here</a>
        <a href="/courses/#{@course.id}/files/#{@attachment.id}/notdownload?b=2&amp;verifier=shouldstay&amp;c=2">but not here</a>
      </div>}
    end
  end

  context ".paginate" do
    let(:request) { stub('request', query_parameters: {}) }
    let(:response) { stub('response', headers: {}) }
    let(:controller) { stub('controller', request: request, response: response, params: {}) }

    describe "ordinal collection" do
      let(:collection) { [1, 2, 3] }

      it "should not raise Folio::InvalidPage for pages past the end" do
        Api.paginate(collection, controller, 'example.com', page: collection.size + 1, per_page: 1).
          should == []
      end

      it "should not raise Folio::InvalidPage for integer-equivalent non-Integer pages" do
        Api.paginate(collection, controller, 'example.com', page: '1').
          should == collection
      end

      it "should raise Folio::InvalidPage for pages <= 0" do
        lambda{ Api.paginate(collection, controller, 'example.com', page: 0) }.
          should raise_error(Folio::InvalidPage)

        lambda{ Api.paginate(collection, controller, 'example.com', page: -1) }.
          should raise_error(Folio::InvalidPage)
      end

      it "should raise Folio::InvalidPage for non-integer pages" do
        lambda{ Api.paginate(collection, controller, 'example.com', page: 'abc') }.
          should raise_error(Folio::InvalidPage)
      end
    end
  end

  context ".build_links" do
    it "should not build links if not pagination is provided" do
      Api.build_links("www.example.com").should be_empty
    end

    it "should not build links for empty pages" do
      Api.build_links("www.example.com/", {
        :per_page => 10,
        :current => "",
        :next => "",
        :prev => "",
        :first => "",
        :last => "",
      }).should be_empty
    end

    it "should build current, next, prev, first, and last links if provided" do
      links = Api.build_links("www.example.com/", {
        :per_page => 10,
        :current => 8,
        :next => 4,
        :prev => 2,
        :first => 1,
        :last => 10,
      })
      links.all?{ |l| l =~ /www.example.com\/\?/ }.should be_true
      links.find{ |l| l.match(/rel="current"/)}.should =~ /page=8&per_page=10>/
      links.find{ |l| l.match(/rel="next"/)}.should =~ /page=4&per_page=10>/
      links.find{ |l| l.match(/rel="prev"/)}.should =~ /page=2&per_page=10>/
      links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1&per_page=10>/
      links.find{ |l| l.match(/rel="last"/)}.should =~ /page=10&per_page=10>/
    end

    it "should maintain query parameters" do
      links = Api.build_links("www.example.com/", {
        :query_parameters => { :search => "hihi" },
        :per_page => 10,
        :next => 2,
      })
      links.first.should == "<www.example.com/?search=hihi&page=2&per_page=10>; rel=\"next\""
    end

    it "should maintain array query parameters" do
      links = Api.build_links("www.example.com/", {
        :query_parameters => { :include => ["enrollments"] },
        :per_page => 10,
        :next => 2,
      })
      qs = "#{CGI.escape("include[]")}=enrollments"
      links.first.should == "<www.example.com/?#{qs}&page=2&per_page=10>; rel=\"next\""
    end

    it "should not include certain sensitive params in the link headers" do
      links = Api.build_links("www.example.com/", {
        :query_parameters => { :access_token => "blah", :api_key => "xxx", :page => 3, :per_page => 10 },
        :per_page => 10,
        :next => 4,
      })
      links.first.should == "<www.example.com/?page=4&per_page=10>; rel=\"next\""
    end
  end

  describe "#accepts_jsonapi?" do
    class TestApiController
      include Api
    end

    it "returns true when application/vnd.api+json in the Accept header" do
      controller = TestApiController.new
      controller.stubs(:request).returns stub(headers: {
        'Accept' => 'application/vnd.api+json'
      })
      controller.accepts_jsonapi?.should == true
    end

    it "returns false when application/vnd.api+json not in the Accept header" do
      controller = TestApiController.new
      controller.stubs(:request).returns stub(headers: {
        'Accept' => 'application/json'
      })
      controller.accepts_jsonapi?.should == false
    end
  end

  describe ".value_to_array" do
    it "splits comma delimited strings" do
      Api.value_to_array('1,2,3').should == ['1', '2', '3']
    end

    it "does nothing to arrays" do
      Api.value_to_array(['1', '2', '3']).should == ['1', '2', '3']
    end

    it "returns an empty array for nil" do
      Api.value_to_array(nil).should == []
    end
  end

  describe "#templated_url" do
    before do
      @api = TestApiInstance.new Account.default, nil
    end

    it "should return url with a single item" do
      url = @api.templated_url(:account_url, "{courses.account}")
      url.should == "http://www.example.com/accounts/{courses.account}"
    end

    it "should return url with multiple items" do
      url = @api.templated_url(:course_assignment_url, "{courses.id}", "{courses.assignment}")
      url.should == "http://www.example.com/courses/{courses.id}/assignments/{courses.assignment}"
    end

    it "should return url with no template items" do
      url = @api.templated_url(:account_url, "1}")
      url.should == "http://www.example.com/accounts/1%7D"
    end

    it "should return url with a combination of items" do
      url = @api.templated_url(:course_assignment_url, "{courses.id}", "1}")
      url.should == "http://www.example.com/courses/{courses.id}/assignments/1%7D"
    end
  end
end
