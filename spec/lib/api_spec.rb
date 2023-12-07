# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class TestApiInstance
  include Api
  def initialize(root_account, current_user)
    @domain_root_account = root_account
    @current_user = current_user
  end

  def account_url(account)
    URI::DEFAULT_PARSER.escape("http://www.example.com/accounts/#{account}")
  end

  def course_assignment_url(course, assignment)
    URI::DEFAULT_PARSER.escape("http://www.example.com/courses/#{course}/assignments/#{assignment}")
  end
end

module TestNamespace
  class TestClass
    include Api
  end
end

describe Api do
  context "api_find" do
    before do
      @user = user_factory
      @api = TestApiInstance.new Account.default, nil
    end

    it "finds a simple record" do
      expect(@user).to eq @api.api_find(User, @user.id)
    end

    it "does not find a missing record" do
      expect { @api.api_find(User, (User.all.map(&:id).max + 1)) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finds an existing sis_id record" do
      @user = user_with_pseudonym username: "sis_user_1@example.com"
      expect(@api.api_find(User, "sis_login_id:sis_user_1@example.com")).to eq @user
    end

    it "looks for login ids case insensitively" do
      @user = user_with_pseudonym username: "sis_user_1@example.com"
      expect(@api.api_find(User, "sis_login_id:SIS_USER_1@example.com")).to eq @user
    end

    it "properly quotes login ids" do
      user = user_factory
      user.pseudonyms.create(unique_id: "user 'a'", account: Account.default)
      expect(@api.api_find(User, "sis_login_id:user 'a'")).to eq user
    end

    it "does not find record from other account" do
      account = Account.create(name: "new")
      @user = user_with_pseudonym(username: "sis_user_1@example.com", account:)
      expect { @api.api_find(User, "sis_login_id:sis_user_2@example.com") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finds record from other root account explicitly" do
      account = Account.create(name: "new")
      @user = user_with_pseudonym(username: "sis_user_1@example.com", account:)
      expect(Api).to receive(:sis_parse_id).with("root_account:school:sis_login_id:sis_user_1@example.com", anything, anything)
                                           .and_return(["sis_login_id", ["sis_user_1@example.com", account]])
      expect(@api.api_find(User, "root_account:school:sis_login_id:sis_user_1@example.com")).to eq @user
    end

    it "allows passing account param and find record" do
      account = Account.create(name: "new")
      @user = user_with_pseudonym(username: "sis_user_1@example.com", account:)
      expect(@api.api_find(User, "sis_login_id:sis_user_1@example.com", account:)).to eq @user
    end

    it "does not find a missing sis_id record" do
      @user = user_with_pseudonym username: "sis_user_1@example.com"
      expect { @api.api_find(User, "sis_login_id:sis_user_2@example.com") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'finds user id "self" when a current user is provided' do
      expect(@user).to eq TestApiInstance.new(Account.default, @user).api_find(User, "self")
    end

    it 'does not find user id "self" when a current user is not provided' do
      expect { TestApiInstance.new(Account.default, nil).api_find(User, "self") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'finds account id "self"' do
      account = Account.create!
      expect(account).to eq TestApiInstance.new(account, nil).api_find(Account, "self")
    end

    it 'finds account id "default"' do
      account = Account.create!
      expect(Account.default).to eq TestApiInstance.new(account, nil).api_find(Account, "default")
    end

    it 'finds account id "site_admin"' do
      account = Account.create!
      expect(Account.site_admin).to eq TestApiInstance.new(account, nil).api_find(Account, "site_admin")
    end

    it "finds group_category with sis_id" do
      account = Account.create!
      gc = GroupCategory.create(sis_source_id: "gc_sis", account:, name: "gc")
      expect(gc).to eq TestApiInstance.new(account, nil).api_find(GroupCategory, "sis_group_category_id:gc_sis")
    end

    it 'finds term id "default"' do
      account = Account.create!
      expect(TestApiInstance.new(account, nil).api_find(account.enrollment_terms, "default")).to eq account.default_enrollment_term
    end

    it 'finds term id "current"' do
      account = Account.create!
      term = account.enrollment_terms.create!(start_at: 1.week.ago, end_at: 1.week.from_now)
      expect(TestApiInstance.new(account, nil).api_find(account.enrollment_terms, "current")).to eq term
    end

    it 'does not find a "current" term if there is more than one candidate' do
      account = Account.create!
      account.enrollment_terms.create!(start_at: 1.week.ago, end_at: 1.week.from_now)
      account.enrollment_terms.create!(start_at: 2.weeks.ago, end_at: 2.weeks.from_now)
      expect(TestApiInstance.new(account, nil).api_find_all(account.enrollment_terms, ["current"])).to eq []
    end

    it 'finds an open ended "current" term' do
      account = Account.create!
      term = account.enrollment_terms.create!(start_at: 1.week.ago)
      expect(TestApiInstance.new(account, nil).api_find(account.enrollment_terms, "current")).to eq term
    end

    it "does not find a user with an invalid AR id" do
      expect { @api.api_find(User, "a1") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      api1 = TestApiInstance.new account1, nil
      api2 = TestApiInstance.new account2, nil
      user1 = user_with_pseudonym username: "sis_user_1@example.com", account: account1
      user2 = user_with_pseudonym username: "sis_user_2@example.com", account: account2
      user3 = user_with_pseudonym username: "sis_user_3@example.com", account: account1
      user4 = user_with_pseudonym username: "sis_user_3@example.com", account: account2
      expect(api1.api_find(User, "sis_login_id:sis_user_1@example.com")).to eq user1
      expect { api2.api_find(User, "sis_login_id:sis_user_1@example.com") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { api1.api_find(User, "sis_login_id:sis_user_2@example.com") }.to raise_error(ActiveRecord::RecordNotFound)
      expect(api2.api_find(User, "sis_login_id:sis_user_2@example.com")).to eq user2
      expect(api1.api_find(User, "sis_login_id:sis_user_3@example.com")).to eq user3
      expect(api2.api_find(User, "sis_login_id:sis_user_3@example.com")).to eq user4
      [user1, user2, user3, user4].each do |user|
        [api1, api2].each do |api|
          expect(api.api_find(User, user.id)).to eq user
        end
      end
    end

    it "finds user by lti_context_id" do
      @user.lti_context_id = Canvas::Security.hmac_sha1(@user.asset_string.to_s, "key")
      @user.save!
      expect(@api.api_find(User, "lti_context_id:#{@user.lti_context_id}")).to eq @user
    end

    it "finds user by lti_context_id, aliased to lti_user_id" do
      @user.lti_context_id = Canvas::Security.hmac_sha1(@user.asset_string.to_s, "key")
      @user.save!
      expect(@api.api_find(User, "lti_user_id:#{@user.lti_context_id}")).to eq @user
    end

    it "finds merged user by their previous lti_context_id" do
      @user.update!(lti_context_id: Canvas::Security.hmac_sha1(@user.asset_string.to_s, "key"))

      user2 = User.create!
      user2_lti_context_id = Canvas::Security.hmac_sha1(user2.asset_string.to_s, "key")
      user2.update!(lti_context_id: user2_lti_context_id)

      course = course_factory(active_all: true)
      course.enroll_user(@user)
      course2 = course_factory(active_all: true)
      course2.enroll_user(user2)

      UserMerge.from(user2).into(@user)

      expect(@api.api_find(User, "lti_user_id:#{user2_lti_context_id}")).to eq @user
    end

    it "finds user by lti_context_id, aliased to lti_1_1_id" do
      @user.lti_context_id = Canvas::Security.hmac_sha1(@user.asset_string.to_s, "key")
      @user.save!
      expect(@api.api_find(User, "lti_1_1_id:#{@user.lti_context_id}")).to eq @user
    end

    it "finds user by lti_1_3_id" do
      expect(@api.api_find(User, "lti_1_3_id:#{@user.lti_id}")).to eq @user
    end

    it "finds course by lti_context_id" do
      lti_course = course_factory
      lti_course.lti_context_id = Canvas::Security.hmac_sha1(lti_course.asset_string.to_s, "key")
      lti_course.save!
      expect(@api.api_find(Course, "lti_context_id:#{lti_course.lti_context_id}")).to eq lti_course
    end

    it "finds group by lti_context_id" do
      lti_group = Group.create!(context: course_factory)
      Lti::Asset.opaque_identifier_for(lti_group)
      expect(@api.api_find(Group, "lti_context_id:#{lti_group.lti_context_id}")).to eq lti_group
    end

    it "finds account by lti_context_id" do
      account = Account.create!(name: "account")
      account.lti_context_id = Canvas::Security.hmac_sha1(account.asset_string.to_s, "key")
      account.save!
      expect(@api.api_find(Account, "lti_context_id:#{account.lti_context_id}")).to eq account
    end

    it "finds account by uuid" do
      account = Account.create!(name: "account")
      expect(@api.api_find(Account, "uuid:#{account.uuid}")).to eq account
    end

    it "finds user by uuid" do
      expect(@api.api_find(User, "uuid:#{@user.uuid}")).to eq @user
    end

    it "finds course by uuid" do
      lti_course = course_factory
      lti_course.uuid = Canvas::Security.hmac_sha1(lti_course.asset_string.to_s, "key")
      lti_course.save!
      expect(@api.api_find(Course, "uuid:#{lti_course.uuid}")).to eq lti_course
    end

    it "finds assignment by id" do
      assignment = assignment_model
      expect(@api.api_find(Assignment, assignment.id.to_s)).to eq assignment
    end

    it "finds assignment by sis_assignment_id" do
      assignment = assignment_model(sis_assignment_id: "LTI_CTX_ID1")
      expect(@api.api_find(Assignment, "sis_assignment_id:#{assignment.sis_assignment_id}")).to eq assignment
    end

    it "finds assignment by lti_context_id" do
      assignment = assignment_model(lti_context_id: "LTI_CTX_ID1")
      expect(@api.api_find(Assignment, "lti_context_id:#{assignment.lti_context_id}")).to eq assignment
    end

    context "sharding" do
      specs_require_sharding

      before :once do
        @shard1.activate { @cs_user = User.create! }
        @cs_ps = managed_pseudonym(@cs_user, account: Account.default, sis_user_id: "cross_shard_user")
      end

      it "finds the shadow record" do
        user = @api.api_find(User, "sis_user_id:cross_shard_user")
        expect(user).to eq @cs_user
        expect(user).to be_shadow_record
        expect(user).to be_readonly
      end

      it "finds the primary record if given `writable`" do
        user = @api.api_find(User, "sis_user_id:cross_shard_user", writable: true)
        expect(user).to eq @cs_user
        expect(user).not_to be_shadow_record
        expect(user).not_to be_readonly
      end

      it "infers `writable: false` from read-only request method" do
        expect(@api).to receive(:request).and_return(double(method: "GET"))
        user = @api.api_find(User, "sis_user_id:cross_shard_user")
        expect(user).to be_shadow_record
      end

      it "infers `writable: true` from writable request method" do
        expect(@api).to receive(:request).and_return(double(method: "POST"))
        user = @api.api_find(User, "sis_user_id:cross_shard_user")
        expect(user).not_to be_shadow_record
      end
    end
  end

  context "api_find_all" do
    before do
      @user = user_factory
      @api = TestApiInstance.new Account.default, nil
    end

    it "finds no records" do
      expect(@api.api_find_all(User, [])).to eq []
    end

    it "finds a simple record" do
      expect(@api.api_find_all(User, [@user.id])).to eq [@user]
    end

    it "finds a simple record with uuid" do
      expect(@api.api_find_all(User, ["uuid:#{@user.uuid}"])).to eq [@user]
    end

    it "does not find a missing record" do
      expect(@api.api_find_all(User, [(User.all.map(&:id).max + 1)])).to eq []
    end

    it "finds an existing sis_id record" do
      @user = user_with_pseudonym username: "sis_user_1@example.com"
      expect(@api.api_find_all(User, ["sis_login_id:sis_user_1@example.com"])).to eq [@user]
    end

    it "finds existing records with different lookup strategies" do
      @user1 = user_factory
      @user2 = user_with_pseudonym username: "sis_user_1@example.com"
      @user3 = user_with_pseudonym
      @pseudonym.sis_user_id = "sis_user_2"
      @pseudonym.save!
      @user4 = user_with_pseudonym username: "sis_user_3@example.com"
      expect(@api.api_find_all(User, [@user1.id.to_s, "sis_login_id:sis_user_1@example.com", (User.all.map(&:id).max + 1), "sis_user_id:sis_user_2", "sis_login_id:nonexistent@example.com", "sis_login_id:sis_user_3@example.com", "sis_invalid_column:4", "a1"]).sort_by(&:id)).to eq [@user1, @user2, @user3, @user4].sort_by(&:id)
    end

    it "filters out duplicates" do
      @other_user = user_factory
      @user = user_with_pseudonym username: "sis_user_1@example.com"
      expect(@api.api_find_all(User, [@user.id, "sis_login_id:sis_user_1@example.com", @other_user.id, @user.id]).sort_by(&:id)).to eq [@user, @other_user].sort_by(&:id)
    end

    it "finds user id 'self' when a current user is provided" do
      @current_user = user_factory
      @other_user = user_factory
      expect(TestApiInstance.new(Account.default, @current_user).api_find_all(User, [@other_user.id, "self"]).sort_by(&:id)).to eq [@current_user, @other_user].sort_by(&:id)
    end

    it 'does not find user id "self" when a current user is not provided' do
      @current_user = user_factory
      @other_user = user_factory
      expect(TestApiInstance.new(Account.default, nil).api_find_all(User, ["self", @other_user.id])).to eq [@other_user]
    end

    it "does not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      api1 = TestApiInstance.new account1, nil
      api2 = TestApiInstance.new account2, nil
      user1 = user_with_pseudonym username: "sis_user_1@example.com", account: account1
      user2 = user_with_pseudonym username: "sis_user_2@example.com", account: account2
      user3 = user_with_pseudonym username: "sis_user_3@example.com", account: account1
      user4 = user_with_pseudonym username: "sis_user_3@example.com", account: account2
      user5 = user_factory account: account1
      user6 = user_factory account: account2
      expect(api1.api_find_all(User, ["sis_login_id:sis_user_1@example.com", "sis_login_id:sis_user_2@example.com", "sis_login_id:sis_user_3@example.com", user5.id, user6.id]).sort_by(&:id)).to eq [user1, user3, user5, user6].sort_by(&:id)
      expect(api2.api_find_all(User, ["sis_login_id:sis_user_1@example.com", "sis_login_id:sis_user_2@example.com", "sis_login_id:sis_user_3@example.com", user5.id, user6.id]).sort_by(&:id)).to eq [user2, user4, user5, user6].sort_by(&:id)
    end

    it "does not hit the database if no valid conditions were found" do
      collection = double
      allow(collection).to receive(:table_name).and_return("courses")
      expect(collection).to receive(:none).once
      relation = @api.api_find_all(collection, ["sis_invalid:1"])
      expect(relation.to_a).to eq []
    end

    context "sharding" do
      specs_require_sharding

      it "finds users from other shards" do
        @shard1.activate { @user2 = User.create! }
        @shard2.activate { @user3 = User.create! }

        expect(@api.api_find_all(User, [@user2.id, @user3.id]).sort_by(&:global_id)).to eq [@user2, @user3].sort_by(&:global_id)
      end

      it "find users from other shards via SIS ID" do
        @shard1.activate do
          @account = Account.create(name: "new")
          @user = user_with_pseudonym username: "sis_user_1@example.com", account: @account
        end
        expect(Api).to receive(:sis_parse_id)
          .with("root_account:school:sis_login_id:sis_user_1@example.com", anything, anything)
          .twice
          .and_return(["sis_login_id", ["sis_user_1@example.com", @account]])
        # TODO: make sure there is a test for if the MRA sis_parse_id adds an acct to the
        # sis_id, and then a transform is also called on it.
        expect(@api.api_find(User, "root_account:school:sis_login_id:sis_user_1@example.com")).to eq @user
        # works through an association, too
        account2 = Account.create!
        course = account2.courses.create!
        course.enroll_student(@user)
        expect(@api.api_find(course.students, "root_account:school:sis_login_id:sis_user_1@example.com")).to eq @user
      end
    end
  end

  context "map_ids" do
    it "maps an empty list" do
      expect(Api.map_ids([], User, Account.default)).to eq([])
    end

    it "maps a list of AR ids" do
      expect(Api.map_ids([1, 2, "3", "4"], User, Account.default).sort).to eq([1, 2, 3, 4])
    end

    it "bails on ids it can't figure out" do
      expect(Api.map_ids(["nonexistentcolumn:5", "sis_nonexistentcolumn:6", 7], User, Account.default)).to eq([7])
    end

    it "filters out sis ids that don't exist, but not filter out AR ids" do
      expect(Api.map_ids(["sis_user_id:1", "2"], User, Account.default)).to eq([2])
    end

    it "finds sis ids that exist" do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym username: "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym username: "sisuser3@example.com"
      @user3 = @user
      expect(Api.map_ids(["sis_user_id:sisuser1",
                          "sis_login_id:sisuser2@example.com",
                          "hex:sis_login_id:7369737573657233406578616d706c652e636f6d",
                          "sis_user_id:sisuser4",
                          "5123"],
                         User,
                         Account.default).sort).to eq [
                           @user1.id, @user2.id, @user3.id, 5123
                         ].sort
    end

    it "works when only provided sis_ids" do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym username: "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym username: "sisuser3@example.com"
      @user3 = @user
      expect(Api.map_ids(["sis_user_id:sisuser1",
                          "sis_login_id:sisuser2@example.com",
                          "hex:sis_login_id:7369737573657233406578616d706c652e636f6d",
                          "sis_user_id:sisuser4"],
                         User,
                         Account.default).sort).to eq [
                           @user1.id, @user2.id, @user3.id
                         ].sort
    end

    it "does not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      user1 = user_with_pseudonym username: "sisuser1@example.com", account: account1
      user_with_pseudonym username: "sisuser2@example.com", account: account2
      user3 = user_with_pseudonym username: "sisuser3@example.com", account: account1
      user_with_pseudonym username: "sisuser3@example.com", account: account2
      user5 = user_factory account: account1
      user6 = user_factory account: account2
      expect(Api.map_ids(["sis_login_id:sisuser1@example.com", "sis_login_id:sisuser2@example.com", "sis_login_id:sisuser3@example.com", user5.id, user6.id], User, account1).sort).to eq [user1.id, user3.id, user5.id, user6.id].sort
    end

    it "tries and make params when non-ar_id columns have returned with ar_id columns" do
      collection = double
      pluck_result = ["thing2", "thing3"]
      relation_result = double(eager_load_values: nil, pluck: pluck_result)
      expect(Api).to receive(:sis_find_sis_mapping_for_collection).with(collection).and_return({ lookups: { "id" => "test-lookup" } })
      expect(Api).to receive(:sis_parse_ids).with("test-ids", { "id" => "test-lookup" }, anything, root_account: "test-root-account")
                                            .and_return({ "test-lookup" => { ids: ["thing1", "thing2"] }, "other-lookup" => { ids: ["thing2", "thing3"] } })
      expect(Api).to receive(:relation_for_sis_mapping_and_columns).with(collection, { "other-lookup" => { ids: ["thing2", "thing3"] } }, { lookups: { "id" => "test-lookup" } }, "test-root-account").and_return(relation_result)
      expect(Api.map_ids("test-ids", collection, "test-root-account")).to eq %w[thing1 thing2 thing3]
    end

    it "tries and make params when non-ar_id columns have returned without ar_id columns" do
      collection = double
      pluck_result = ["thing2", "thing3"]
      relation_result = double(eager_load_values: nil, pluck: pluck_result)
      expect(Api).to receive(:sis_find_sis_mapping_for_collection).with(collection).and_return({ lookups: { "id" => "test-lookup" } })
      expect(Api).to receive(:sis_parse_ids).with("test-ids", { "id" => "test-lookup" }, anything, root_account: "test-root-account")
                                            .and_return({ "other-lookup" => ["thing2", "thing3"] })
      expect(Api).to receive(:relation_for_sis_mapping_and_columns).with(collection, { "other-lookup" => ["thing2", "thing3"] }, { lookups: { "id" => "test-lookup" } }, "test-root-account").and_return(relation_result)
      expect(Api.map_ids("test-ids", collection, "test-root-account")).to eq ["thing2", "thing3"]
    end

    it "does not try and make params when no non-ar_id columns have returned with ar_id columns" do
      collection = double
      expect(Api).to receive(:sis_find_sis_mapping_for_collection).with(collection).and_return({ lookups: { "id" => "test-lookup" } })
      expect(Api).to receive(:sis_parse_ids).with("test-ids", { "id" => "test-lookup" }, anything, root_account: "test-root-account")
                                            .and_return({ "test-lookup" => { ids: ["thing1", "thing2"] } })
      expect(Api).not_to receive(:relation_for_sis_mapping_and_columns)
      expect(Api.map_ids("test-ids", collection, "test-root-account")).to eq ["thing1", "thing2"]
    end

    it "does not try and make params when no non-ar_id columns have returned without ar_id columns" do
      collection = double
      expect(Api).to receive(:sis_find_sis_mapping_for_collection).with(collection).and_return({ lookups: { "id" => "test-lookup" } })
      expect(Api).to receive(:sis_parse_ids).with("test-ids", { "id" => "test-lookup" }, anything, root_account: "test-root-account")
                                            .and_return({})
      expect(Api).to receive(:sis_make_params_for_sis_mapping_and_columns).at_most(0)
      expect(Api.map_ids("test-ids", collection, "test-root-account")).to eq []
    end
  end

  context "sis_parse_id" do
    before do
      @lookups = Api::SIS_MAPPINGS["users"][:lookups]
    end

    it "handles numeric ids" do
      # TODO: check for the "users.id" part in a separate sis_parse_ids test
      expect(Api.sis_parse_id(1)).to eq ["id", 1]
      expect(Api.sis_parse_id(10)).to eq ["id", 10]
    end

    it "handles numeric ids as strings" do
      expect(Api.sis_parse_id("1")).to eq ["id", 1]
      expect(Api.sis_parse_id("10")).to eq ["id", 10]
    end

    it "handles hex_encoded sis_fields" do
      expect(Api.sis_parse_id("hex:sis_login_id:7369737573657233406578616d706c652e636f6d")).to eq ["sis_login_id", "sisuser3@example.com"]
      expect(Api.sis_parse_id("hex:sis_user_id:7369737573657234406578616d706c652e636f6d")).to eq ["sis_user_id", "sisuser4@example.com"]
    end

    it "does not handle invalid hex fields" do
      expect(Api.sis_parse_id("hex:sis_user_id:7369737573657234406578616g706c652e636f6d")).to eq [nil, nil]
      expect(Api.sis_parse_id("hex:sis_user_id:7369737573657234406578616d06c652e636f6d")).to eq [nil, nil]
    end

    it "does not handle hex_encoded non-sis fields" do
      expect(Api.sis_parse_id("hex:id:7369737573657233406578616d706c652e636f6d")).to eq [nil, nil]
      expect(Api.sis_parse_id("hex:1234")).to eq [nil, nil]
    end

    it "handles plain sis_fields" do
      expect(Api.sis_parse_id("sis_login_id:sisuser3@example.com")).to eq ["sis_login_id", "sisuser3@example.com"]
      expect(Api.sis_parse_id("sis_user_id:sisuser4")).to eq ["sis_user_id", "sisuser4"]
    end

    it "does not handle plain sis_fields that don't exist" do
      # TODO: make sure this is the same behavior before
      expect(Api.sis_parse_id("sis_nonexistent_column:1")).to eq(["sis_nonexistent_column", "1"])
      expect(Api.sis_parse_id("sis_nonexistent:a")).to eq(["sis_nonexistent", "a"])

      expect(Api.sis_parse_ids(["sis_nonexistent_column:1"], @lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_nonexistent:1"], @lookups)).to eq({})
    end

    it "does not handle other things" do
      expect(Api.sis_parse_id("id:1")).to eq [nil, nil]
      expect(Api.sis_parse_id("a1")).to eq [nil, nil]
      expect(Api.sis_parse_id("\t10\n11 ")).to eq [nil, nil]
    end

    it "handles surrounding whitespace" do
      expect(Api.sis_parse_id("\t10  ")).to eq ["id", 10]
      expect(Api.sis_parse_id("\t10\n")).to eq ["id", 10]

      expect(Api.sis_parse_id("  hex:sis_login_id:7369737573657233406578616d706c652e636f6d     ")).to eq ["sis_login_id", "sisuser3@example.com"]
      expect(Api.sis_parse_ids(["  hex:sis_login_id:7369737573657233406578616d706c652e636f6d     "], @lookups)).to eq({ "LOWER(pseudonyms.unique_id)" => { ids: ["LOWER('sisuser3@example.com')"] } })

      expect(Api.sis_parse_id("  sis_login_id:sisuser3@example.com\t")).to eq ["sis_login_id", "sisuser3@example.com"]
      expect(Api.sis_parse_ids(["  sis_login_id:sisuser3@example.com\t"], @lookups)).to eq({ "LOWER(pseudonyms.unique_id)" => { ids: ["LOWER('sisuser3@example.com')"] } })
    end

    it "handles user uuid" do
      expect(Api.sis_parse_id("uuid:tExtjERcuxGKFLO6XxwIBCeXZvZXLdXzs8LV0gK0"))
        .to eq ["uuid", "tExtjERcuxGKFLO6XxwIBCeXZvZXLdXzs8LV0gK0"]
      expect(Api.sis_parse_ids(["uuid:tExtjERcuxGKFLO6XxwIBCeXZvZXLdXzs8LV0gK0"], @lookups)).to \
        eq({ "users.uuid" => { ids: ["tExtjERcuxGKFLO6XxwIBCeXZvZXLdXzs8LV0gK0"] } })
    end
  end

  context "sis_parse_ids" do
    before do
      @lookups = Api::SIS_MAPPINGS["users"][:lookups]
    end

    it "handles a list of ar_ids" do
      expect(Api.sis_parse_ids([1, 2, 3], @lookups)).to eq({ "users.id" => { ids: [1, 2, 3] } })
      expect(Api.sis_parse_ids(%w[1 2 3], @lookups)).to eq({ "users.id" => { ids: [1, 2, 3] } })
    end

    it "handles a list of sis ids" do
      expect(Api.sis_parse_ids(["sis_user_id:U1", "sis_user_id:U2", "sis_user_id:U3"], @lookups)).to eq({ "pseudonyms.sis_user_id" => { ids: %w[U1 U2 U3] } })
    end

    it "removes duplicates" do
      expect(Api.sis_parse_ids([1, 2, 3, 2], @lookups)).to eq({ "users.id" => { ids: [1, 2, 3] } })
      expect(Api.sis_parse_ids([1, 2, 2, 3], @lookups)).to eq({ "users.id" => { ids: [1, 2, 3] } })
      expect(Api.sis_parse_ids(["sis_user_id:U1", "sis_user_id:U2", "sis_user_id:U2", "sis_user_id:U3"], @lookups)).to eq({ "pseudonyms.sis_user_id" => { ids: %w[U1 U2 U3] } })
      expect(Api.sis_parse_ids(["sis_user_id:U1", "sis_user_id:U2", "sis_user_id:U3", "sis_user_id:U2"], @lookups)).to eq({ "pseudonyms.sis_user_id" => { ids: %w[U1 U2 U3] } })
    end

    it "works with mixed sis id types" do
      expect(Api.sis_parse_ids([1, 2, "sis_user_id:U1", 3, "sis_user_id:U2", "sis_user_id:U3", "sis_login_id:A1"], @lookups)).to eq({ "users.id" => { ids: [1, 2, 3] }, "pseudonyms.sis_user_id" => { ids: %w[U1 U2 U3] }, "LOWER(pseudonyms.unique_id)" => { ids: ["LOWER('A1')"] } })
    end

    it "skips invalid things" do
      expect(Api.sis_parse_ids([1, 2, 3, "a1", "invalid", "sis_nonexistent:3"], @lookups)).to eq({ "users.id" => { ids: [1, 2, 3] } })
    end
  end

  context "sis_find_sis_mapping_for_collection" do
    it "finds the appropriate sis mapping" do
      [Course, EnrollmentTerm, User, Account, CourseSection].each do |collection|
        expect(Api.sis_find_sis_mapping_for_collection(collection)).to eq Api::SIS_MAPPINGS[collection.table_name]
        expect(Api::SIS_MAPPINGS[collection.table_name].is_a?(Hash)).to be_truthy
      end
    end

    it "raises an error otherwise" do
      [StreamItem, PluginSetting].each do |collection|
        expect { Api.sis_find_sis_mapping_for_collection(collection) }.to raise_error("need to add support for table name: #{collection.table_name}")
      end
    end
  end

  context "sis_relation_for_collection" do
    it "passes along the sis_mapping to sis_find_params_for_sis_mapping" do
      root_account = account_model
      expect(Api).to receive(:relation_for_sis_mapping).with(User, Api::SIS_MAPPINGS["users"], [1, 2, 3], root_account, anything).and_return(1234)
      expect(Api).to receive(:sis_find_sis_mapping_for_collection).with(User).and_return(Api::SIS_MAPPINGS["users"])
      expect(Api.sis_relation_for_collection(User, [1, 2, 3], root_account)).to eq 1234
    end
  end

  context "relation_for_sis_mapping" do
    it "passes along the parsed ids to sis_make_params_for_sis_mapping_and_columns" do
      root_account = account_model
      expect(Api).to receive(:sis_parse_ids).with([1, 2, 3], "lookups", anything, root_account:).and_return({ "users.id" => [4, 5, 6] })
      expect(Api).to receive(:relation_for_sis_mapping_and_columns).with(User, { "users.id" => [4, 5, 6] }, { lookups: "lookups" }, root_account).and_return("params")
      expect(Api.relation_for_sis_mapping(User, { lookups: "lookups" }, [1, 2, 3], root_account)).to eq "params"
    end
  end

  context "relation_for_sis_mapping_and_columns" do
    it "fails when not given a root account" do
      expect(Api.relation_for_sis_mapping_and_columns(User, {}, {}, Account.default)).to eq User.none
      expect { Api.relation_for_sis_mapping_and_columns(User, {}, {}, user_factory) }.to raise_error("sis_root_account required for lookups")
    end

    it "properly generates an escaped arg string" do
      expect(Api.relation_for_sis_mapping_and_columns(User, { "id" => { ids: ["1", 2, 3] } }, { scope: "scope" }, Account.default).to_sql).to match(/\(scope = #{Account.default.id} AND \(id IN \('1',2,3\)\)\)/)
    end

    it "works with no columns" do
      expect(Api.relation_for_sis_mapping_and_columns(User, {}, {}, Account.default)).to eq User.none
    end

    it "adds in joins if the sis_mapping has some with columns" do
      expect(Api.relation_for_sis_mapping_and_columns(User, { "id" => { ids: ["1", 2, 3] } }, { scope: "scope", joins: "some joins" }, Account.default).eager_load_values).to eq ["some joins"]
    end

    it "works with a few different column types and account scopings" do
      expect(Api.relation_for_sis_mapping_and_columns(User, { "id1" => { ids: [1, 2, 3] }, "id2" => { ids: %w[a b c] }, "id3" => { ids: %w[s1 s2 s3] } }, { scope: "some_scope", is_not_scoped_to_account: ["id3"] }, Account.default).to_sql).to match(/\(\(some_scope = #{Account.default.id} AND \(id1 IN \(1,2,3\)\)\) OR \(some_scope = #{Account.default.id} AND \(id2 IN \('a','b','c'\)\)\) OR id3 IN \('s1','s2','s3'\)\)/)
    end

    it "fails if we're scoping to an account and the scope isn't provided" do
      expect { Api.relation_for_sis_mapping_and_columns(User, { "id" => { ids: ["1", 2, 3] } }, {}, Account.default) }.to raise_error("missing scope for collection")
    end
  end

  context "sis_mappings" do
    it "captures course lookups correctly" do
      lookups = Api.sis_find_sis_mapping_for_collection(Course)[:lookups]
      expect(Api.sis_parse_ids(["sis_course_id:1"], lookups)).to eq({ "sis_source_id" => { ids: ["1"] } })
      expect(Api.sis_parse_ids(["sis_term_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_user_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_login_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_account_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_section_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["1"], lookups)).to eq({ "id" => { ids: [1] } })
    end

    it "captures enrollment_term lookups correctly" do
      lookups = Api.sis_find_sis_mapping_for_collection(EnrollmentTerm)[:lookups]
      expect(Api.sis_parse_ids(["sis_term_id:1"], lookups)).to eq("sis_source_id" => { ids: ["1"] })
      expect(Api.sis_parse_ids(["sis_course_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_user_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_login_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_account_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_section_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["1"], lookups)).to eq("id" => { ids: [1] })
    end

    it "capture user lookups correctly" do
      lookups = Api.sis_find_sis_mapping_for_collection(User)[:lookups]
      expect(Api.sis_parse_ids(["sis_user_id:1"], lookups)).to eq({ "pseudonyms.sis_user_id" => { ids: ["1"] } })
      expect(Api.sis_parse_ids(["sis_login_id:1"], lookups)).to eq({ "LOWER(pseudonyms.unique_id)" => { ids: ["LOWER('1')"] } })
      expect(Api.sis_parse_ids(["sis_course_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_term_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_account_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_section_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["1"], lookups)).to eq({ "users.id" => { ids: [1] } })
      expect(Api.sis_parse_ids(["uuid:tExtjERcuxGKFLO6XxwIBCeXZvZXLdXzs8LV0gK0"], lookups)).to \
        eq({ "users.uuid" => { ids: ["tExtjERcuxGKFLO6XxwIBCeXZvZXLdXzs8LV0gK0"] } })
    end

    it "captures account lookups correctly" do
      lookups = Api.sis_find_sis_mapping_for_collection(Account)[:lookups]
      expect(Api.sis_parse_ids(["sis_account_id:1"], lookups)).to eq({ "sis_source_id" => { ids: ["1"] } })
      expect(Api.sis_parse_ids(["sis_course_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_term_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_user_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_login_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_section_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["1"], lookups)).to eq({ "id" => { ids: [1] } })
    end

    it "captures course_section lookups correctly" do
      lookups = Api.sis_find_sis_mapping_for_collection(CourseSection)[:lookups]
      expect(Api.sis_parse_ids(["sis_section_id:1"], lookups)).to eq({ "sis_source_id" => { ids: ["1"] } })
      expect(Api.sis_parse_ids(["sis_course_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_term_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_user_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_login_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_account_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["1"], lookups)).to eq({ "id" => { ids: [1] } })
    end

    it "captures group_categories lookups correctly" do
      lookups = Api.sis_find_sis_mapping_for_collection(GroupCategory)[:lookups]
      expect(Api.sis_parse_ids(["sis_group_category_id:1"], lookups)).to eq({ "sis_source_id" => { ids: ["1"] } })
      expect(Api.sis_parse_ids(["sis_section_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_course_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_term_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_user_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_login_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["sis_account_id:1"], lookups)).to eq({})
      expect(Api.sis_parse_ids(["1"], lookups)).to eq({ "id" => { ids: [1] } })
    end

    it "queries the course table correctly" do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(Course)
      expect(Api.relation_for_sis_mapping_and_columns(Course, { "sis_source_id" => { ids: ["1"] }, "id" => { ids: ["1"] } }, sis_mapping, Account.default).to_sql).to match(/\(root_account_id = #{Account.default.id} AND \(sis_source_id IN \('1'\)\)\) OR id IN \('1'\)/)
    end

    it "queries the enrollment_term table correctly" do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(EnrollmentTerm)
      expect(Api.relation_for_sis_mapping_and_columns(EnrollmentTerm, { "sis_source_id" => { ids: ["1"] }, "id" => { ids: ["1"] } }, sis_mapping, Account.default).to_sql).to match(/\(root_account_id = #{Account.default.id} AND \(sis_source_id IN \('1'\)\)\) OR id IN \('1'\)/)
    end

    it "queries the user table correctly" do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(User)
      expect(Api.relation_for_sis_mapping_and_columns(User, { "pseudonyms.sis_user_id" => { ids: ["1"] }, "pseudonyms.unique_id" => { ids: ["1"] }, "users.id" => { ids: ["1"] } }, sis_mapping, Account.default).to_sql).to match(/\(pseudonyms.account_id = #{Account.default.id} AND \(pseudonyms.sis_user_id IN \('1'\)\)\) OR \(pseudonyms.account_id = #{Account.default.id} AND \(pseudonyms.unique_id IN \('1'\)\)\) OR users.id IN \('1'\)/)
    end

    it "queries the account table correctly" do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(Account)
      expect(Api.relation_for_sis_mapping_and_columns(Account, { "sis_source_id" => { ids: ["1"] }, "id" => { ids: ["1"] } }, sis_mapping, Account.default).to_sql).to match(/\(root_account_id = #{Account.default.id} AND \(sis_source_id IN \('1'\)\)\) OR id IN \('1'\)/)
    end

    it "queries the course_section table correctly" do
      sis_mapping = Api.sis_find_sis_mapping_for_collection(CourseSection)
      expect(Api.relation_for_sis_mapping_and_columns(CourseSection, { "sis_source_id" => { ids: ["1"] }, "id" => { ids: ["1"] } }, sis_mapping, Account.default).to_sql).to match(/\(root_account_id = #{Account.default.id} AND \(sis_source_id IN \('1'\)\)\) OR id IN \('1'\)/)
    end
  end

  context "map_non_sis_ids" do
    it "returns an array of numeric ids" do
      expect(Api.map_non_sis_ids([1, 2, 3, 4])).to eq [1, 2, 3, 4]
    end

    it "converts string ids to numeric" do
      expect(Api.map_non_sis_ids(%w[5 4 3 2])).to eq [5, 4, 3, 2]
    end

    it "excludes things that don't look like ids" do
      expect(Api.map_non_sis_ids(%w[1 2 lolrus 4chan 5 6!])).to eq [1, 2, 5]
    end

    it "strips whitespace" do
      expect(Api.map_non_sis_ids(["  1", "2  ", " 3 ", "4\n"])).to eq [1, 2, 3, 4]
    end
  end

  context "ISO8601 regex" do
    it "does not allow invalid dates" do
      expect("10/01/2014").to_not match Api::ISO8601_REGEX
    end

    it "does not allow non ISO8601 dates" do
      expect("2014-10-01").to_not match Api::ISO8601_REGEX
    end

    it "does not allow garbage dates" do
      expect("bad_data").to_not match Api::ISO8601_REGEX
    end

    it "allows valid dates" do
      expect("2014-10-01T00:00:00-06:00").to match Api::ISO8601_REGEX
    end

    it "does not allow valid dates BC" do
      expect("-2014-10-01T00:00:00-06:00").to_not match Api::ISO8601_REGEX
    end
  end

  context ".api_user_content" do
    let(:klass) do
      Class.new do
        include Api
      end
    end

    it "ignores non-kaltura instructure_inline_media_comment links" do
      student_in_course
      html = <<~HTML
        <div>This is an awesome youtube:
          <a href="http://www.example.com/" class="instructure_inline_media_comment">here</a>
        </div>
      HTML
      res = klass.new.api_user_content(html, @course, @student)
      expect(res).to eq html
    end

    context "mobile css/js" do
      before do
        student_in_course
        account = @course.root_account
        bc = BrandConfig.create(mobile_css_overrides: "somewhere.css")
        account.brand_config_md5 = bc.md5
        account.save!

        @html = "<p>a</p><p>b</p>"

        @k = klass.new
      end

      it "prepends mobile css when not coming from a web browser" do
        res = @k.api_user_content(@html, @course, @student)
        expect(res).to eq <<~HTML.strip
          <link rel="stylesheet" href="somewhere.css"><p>a</p><p>b</p>
        HTML
      end

      it "does not prepend mobile css when coming from a web browser" do
        allow(@k).to receive(:in_app?).and_return(true)
        res = @k.api_user_content(@html, @course, @student)
        expect(res).to eq "<p>a</p><p>b</p>"
      end

      it "does not prepend mobile css when coming from a web browser, even if it is a mobile browser" do
        allow(@k).to receive_messages(in_app?: true, mobile_device?: true)
        res = @k.api_user_content(@html, @course, @student)
        expect(res).to eq "<p>a</p><p>b</p>"
      end
    end

    context "sharding" do
      specs_require_sharding

      shared_examples_for "proxy classes that define #url_for" do
        let(:proxy_instance) { raise "set in contexts" }

        before do
          proxy_instance.instance_variable_set(:@domain_root_account, Account.default)
          proxy_instance.extend Rails.application.routes.url_helpers
          proxy_instance.extend ActionDispatch::Routing::UrlFor

          allow(proxy_instance).to receive_messages(
            request: nil,
            get_host_and_protocol_from_request: ["school.instructure.com", "https"],
            url_options: {}
          )
        end

        it "transposes ids in urls, leaving equation images alone" do
          html = @shard1.activate do
            a = Account.create!
            student_in_course(account: a, active_all: true)
            @file = attachment_model(context: @course, folder: Folder.root_folders(@course).first)
            <<~HTML
              <img src="/equation_images/1%2520%252B%25201%2520%252B%2520n%2520%252B%25202%250A2%2520%252B%25201n%2520%252B%25202n%250A3%2520%252B%2520n%250Ax%2520%252B%250A4%2520%252B%250An?scale=1">
              <img src="/courses/#{@course.id}/files/#{@file.id}/download?wrap=1" data-api-returntype="File" data-api-endpoint="https://canvas.vanity.edu/api/v1/courses/#{@course.id}/files/#{@file.id}">
              <a href="/courses/#{@course.id}/pages/module-1" data-api-returntype="Page" data-api-endpoint="https://canvas.vanity.edu/api/v1/courses/#{@course.id}/pages/module-1">link</a>
            HTML
          end

          res = proxy_instance.api_user_content(html, @course, @student)
          expect(res).to eq <<~HTML
            <img src="https://school.instructure.com/equation_images/1%2520%252B%25201%2520%252B%2520n%2520%252B%25202%250A2%2520%252B%25201n%2520%252B%25202n%250A3%2520%252B%2520n%250Ax%2520%252B%250A4%2520%252B%250An?scale=1">
            <img src="https://school.instructure.com/courses/#{@shard1.id}~#{@course.local_id}/files/#{@shard1.id}~#{@file.local_id}/download?verifier=#{@file.uuid}&amp;wrap=1" data-api-returntype="File" data-api-endpoint="https://school.instructure.com/api/v1/courses/#{@shard1.id}~#{@course.local_id}/files/#{@shard1.id}~#{@file.local_id}">
            <a href="https://school.instructure.com/courses/#{@shard1.id}~#{@course.local_id}/pages/module-1" data-api-returntype="Page" data-api-endpoint="https://school.instructure.com/api/v1/courses/#{@shard1.id}~#{@course.local_id}/pages/module-1">link</a>
          HTML
        end
      end

      context "with non-namespaced proxy class" do
        it_behaves_like "proxy classes that define #url_for" do
          let(:proxy_instance) { klass.new }
        end
      end

      context "with namespaced proxy class" do
        it_behaves_like "proxy classes that define #url_for" do
          let(:proxy_instance) { TestNamespace::TestClass.new }
        end
      end
    end
  end

  context ".process_incoming_html_content" do
    let(:klass) do
      Class.new do
        extend Api

        def self.request
          OpenStruct.new({ host: "some-host.com", port: 80 })
        end
      end
    end

    it "adds context to files and remove verifier parameters" do
      course_factory
      attachment_model(context: @course)

      html = <<~HTML
        <div>
          Here are some bad links
          <a href="/files/#{@attachment.id}/download">here</a>
          <a href="/files/#{@attachment.id}/download?verifier=lollercopter&amp;anotherparam=something">here</a>
          <a href="/files/#{@attachment.id}/preview?sneakyparam=haha&amp;verifier=lollercopter&amp;another=blah">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/preview?noverifier=here">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=lol&amp;a=1">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?b=2&amp;verifier=something&amp;c=2">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/notdownload?b=2&amp;verifier=shouldstay&amp;c=2">but not here</a>
          <a href="http://some-host.com/courses/#{@course.id}/assignments">absolute!</a>
        </div>
      HTML
      fixed_html = klass.process_incoming_html_content(html)
      expect(fixed_html).to eq <<~HTML
        <div>
          Here are some bad links
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/download">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?anotherparam=something">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/preview?sneakyparam=haha&amp;another=blah">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/preview?noverifier=here">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?a=1">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/download?b=2&amp;c=2">here</a>
          <a href="/courses/#{@course.id}/files/#{@attachment.id}/notdownload?b=2&amp;verifier=shouldstay&amp;c=2">but not here</a>
          <a href="/courses/#{@course.id}/assignments">absolute!</a>
        </div>
      HTML
    end

    it "passes host and port to Content.process_incoming" do
      expect(Api::Html::Content).to receive(:process_incoming).with(anything, host: "some-host.com", port: 80)
      klass.process_incoming_html_content("<div/>")
    end

    it "doesn't explode with invalid mailtos" do
      html = %(<a href="mailto:spamme%20example.com">beep</a>http://some-host.com/linktotricktheparserintoparsinglinks)
      expect(klass.process_incoming_html_content(html)).to eq html
    end
  end

  context ".paginate" do
    let(:request) { double("request", query_parameters: {}) }
    let(:response) { double("response", headers: {}) }
    let(:controller) { double("controller", request:, response:, params: {}) }

    describe "#ordered_colection" do
      it "orders a relation" do
        ordered = Api.ordered_collection(Course.all)
        expect(ordered.to_sql).to include('ORDER BY "courses"."id"')
      end
    end

    describe "ordinal collection" do
      let(:collection) { [1, 2, 3] }

      it "does not raise Folio::InvalidPage for pages past the end" do
        controller = double("controller", request:, response:, params: { per_page: 1 })
        expect(Api.paginate(collection, controller, "example.com", page: collection.size + 1))
          .to eq []
      end

      it "does not raise Folio::InvalidPage for integer-equivalent non-Integer pages" do
        expect(Api.paginate(collection, controller, "example.com", page: "1"))
          .to eq collection
      end

      it "raises Folio::InvalidPage for pages <= 0" do
        expect { Api.paginate(collection, controller, "example.com", page: 0) }
          .to raise_error(Folio::InvalidPage)

        expect { Api.paginate(collection, controller, "example.com", page: -1) }
          .to raise_error(Folio::InvalidPage)
      end

      it "raises Folio::InvalidPage for non-integer pages" do
        expect { Api.paginate(collection, controller, "example.com", page: "abc") }
          .to raise_error(Folio::InvalidPage)
      end
    end

    describe "page size limits" do
      let(:collection) { (1..101).to_a }

      context "with no max_per_page argument" do
        it "limits to the default max_per_page" do
          controller = double("controller", request:, response:, params: { per_page: Api::MAX_PER_PAGE + 5 })
          expect(Api.paginate(collection, controller, "example.com").size)
            .to eq Api::MAX_PER_PAGE
        end
      end

      context "with no per_page parameter" do
        it "limits to the default per_page" do
          controller = double("controller", request:, response:, params: {})
          expect(Api.paginate(collection, controller, "example.com").size)
            .to eq Api::PER_PAGE
        end
      end

      context "with per_page parameter > max_per_page argument" do
        let(:controller) { double("controller", request:, response:, params: { per_page: 100 }) }

        it "takes the smaller of the max_per_page arugment and the per_page param" do
          expect(Api.paginate(collection, controller, "example.com", { max_per_page: 75 }).size)
            .to eq 75
        end
      end

      context "with per_page parameter < max_per_page argument" do
        let(:controller) { double("controller", request:, response:, params: { per_page: 75 }) }

        it "takes the smaller of the max_per_page arugment and the per_page param" do
          expect(Api.paginate(collection, controller, "example.com", { max_per_page: 100 }).size)
            .to eq 75
        end
      end
    end
  end

  context ".jsonapi_paginate" do
    let(:request) { double("request", query_parameters: {}) }
    let(:response) { double("response", headers: {}) }
    let(:controller) { double("controller", request:, response:, params: {}) }
    let(:collection) { [1, 2, 3] }

    it "returns the links in the headers" do
      Api.jsonapi_paginate(collection, controller, "example.com", page: 1, per_page: 1)
      link = controller.response.headers["Link"]
      expect(link).not_to be_empty
      expect(link).to include('<example.com?page=1&per_page=1>; rel="current"')
      expect(link).to include(',<example.com?page=2&per_page=1>; rel="next"')
      expect(link).to include(',<example.com?page=1&per_page=1>; rel="first"')
      expect(link).to include(',<example.com?page=3&per_page=1>; rel="last"')
    end

    it "returns the links in the meta" do
      (data, meta) = Api.jsonapi_paginate(collection, controller, "example.com", page: 1, per_page: 1)
      expect(meta).not_to be_empty
      expect(meta[:pagination][:current]).to eq("example.com?page=1&per_page=1")
      expect(meta[:pagination][:next]).to eq("example.com?page=2&per_page=1")
      expect(meta[:pagination][:last]).to eq("example.com?page=3&per_page=1")
      expect(data).to eq [1]
    end
  end

  context ".build_links" do
    it "does not build links if not pagination is provided" do
      expect(Api.build_links("www.example.com")).to be_empty
    end

    it "does not build links for empty pages" do
      expect(Api.build_links("www.example.com/", {
                               per_page: 10,
                               current: "",
                               next: "",
                               prev: "",
                               first: "",
                               last: "",
                             })).to be_empty
    end

    it "builds current, next, prev, first, and last links if provided" do
      links = Api.build_links("www.example.com/", {
                                per_page: 10,
                                current: 8,
                                next: 4,
                                prev: 2,
                                first: 1,
                                last: 10,
                              })
      expect(links.all? { |l| l =~ %r{www.example.com/\?} }).to be_truthy
      expect(links.find { |l| l.include?('rel="current"') }).to match(/page=8&per_page=10>/)
      expect(links.find { |l| l.include?('rel="next"') }).to match(/page=4&per_page=10>/)
      expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=10>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=10>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=10&per_page=10>/)
    end

    it "maintains query parameters" do
      links = Api.build_links("www.example.com/", {
                                query_parameters: { search: "hihi" },
                                per_page: 10,
                                next: 2,
                              })
      expect(links.first).to eq "<www.example.com/?search=hihi&page=2&per_page=10>; rel=\"next\""
    end

    it "maintains array query parameters" do
      links = Api.build_links("www.example.com/", {
                                query_parameters: { include: ["enrollments"] },
                                per_page: 10,
                                next: 2,
                              })
      qs = "#{CGI.escape("include[]")}=enrollments"
      expect(links.first).to eq "<www.example.com/?#{qs}&page=2&per_page=10>; rel=\"next\""
    end

    it "does not include certain sensitive params in the link headers" do
      links = Api.build_links("www.example.com/", {
                                query_parameters: { access_token: "blah", api_key: "xxx", page: 3, per_page: 10 },
                                per_page: 10,
                                next: 4,
                              })
      expect(links.first).to eq "<www.example.com/?page=4&per_page=10>; rel=\"next\""
    end

    it "prevents link headers from consuming more than 6K of header space" do
      links = Api.build_links("www.example.com/", {
                                query_parameters: { blah: "a" * 2000 },
                                per_page: 10,
                                current: 8,
                                next: 4,
                                prev: 2,
                                first: 1,
                                last: 10,
                              })
      expect(links.all? { |l| l =~ %r{www.example.com/\?} }).to be_truthy
      expect(links.find { |l| l.include?('rel="current"') }).to be_nil
      expect(links.find { |l| l.include?('rel="next"') }).to match(/page=4&per_page=10>/)
      expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=10>/)
      expect(links.find { |l| l.include?('rel="first"') }).to be_nil
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=10&per_page=10>/)
    end
  end

  describe "#accepts_jsonapi?" do
    let(:test_api_controller) { Class.new { include Api } }

    it "returns true when application/vnd.api+json in the Accept header" do
      controller = test_api_controller.new
      allow(controller).to receive(:request).and_return double(headers: {
                                                                 "Accept" => "application/vnd.api+json"
                                                               })
      expect(controller.accepts_jsonapi?).to be true
    end

    it "returns false when application/vnd.api+json not in the Accept header" do
      controller = test_api_controller.new
      allow(controller).to receive(:request).and_return double(headers: {
                                                                 "Accept" => "application/json"
                                                               })
      expect(controller.accepts_jsonapi?).to be false
    end
  end

  describe ".value_to_array" do
    it "splits comma delimited strings" do
      expect(Api.value_to_array("1,2,3")).to eq %w[1 2 3]
    end

    it "does nothing to arrays" do
      expect(Api.value_to_array(%w[1 2 3])).to eq %w[1 2 3]
    end

    it "returns an empty array for nil" do
      expect(Api.value_to_array(nil)).to eq []
    end
  end

  describe "#templated_url" do
    before do
      @api = TestApiInstance.new Account.default, nil
    end

    it "returns url with a single item" do
      url = @api.templated_url(:account_url, "{courses.account}")
      expect(url).to eq "http://www.example.com/accounts/{courses.account}"
    end

    it "returns url with multiple items" do
      url = @api.templated_url(:course_assignment_url, "{courses.id}", "{courses.assignment}")
      expect(url).to eq "http://www.example.com/courses/{courses.id}/assignments/{courses.assignment}"
    end

    it "returns url with no template items" do
      url = @api.templated_url(:account_url, "1}")
      expect(url).to eq "http://www.example.com/accounts/1%7D"
    end

    it "returns url with a combination of items" do
      url = @api.templated_url(:course_assignment_url, "{courses.id}", "1}")
      expect(url).to eq "http://www.example.com/courses/{courses.id}/assignments/1%7D"
    end
  end
end
