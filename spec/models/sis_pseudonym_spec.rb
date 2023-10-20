# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe SisPseudonym do
  let_once(:course1) { course_factory active_all: true, account: Account.default }
  let_once(:course2) { course_factory active_all: true, account: account2 }
  let_once(:account1) { account_model }
  let_once(:account2) { account_model }
  let_once(:u) { User.create! }

  def pseud_params(unique_id, account = Account.default)
    {
      account:,
      unique_id:,
      password: "asdfasdf",
      password_confirmation: "asdfasdf"
    }
  end

  context "when there is a deleted pseudonym" do
    before do
      @deleted_pseudonym = u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
        x.workflow_state = "deleted"
        x.sis_user_id = "user2"
      end
    end

    it "returns active pseudonyms only" do
      expect(SisPseudonym.for(u, course1)).to be_nil
      active_pseudonym = u.pseudonyms.create!(pseud_params("user1@example.com")) do |x|
        x.workflow_state = "active"
        x.sis_user_id = "user1"
      end
      expect(SisPseudonym.for(u, course1)).to eq(active_pseudonym)
    end

    it "does not return deleted pseudonyms from enrollments unless @include_deleted" do
      e = course1.enroll_user(u)
      e.sis_pseudonym_id = @deleted_pseudonym
      e.save!
      expect(SisPseudonym.for(u, course1)).to be_nil
      active_pseudonym = u.pseudonyms.create!(pseud_params("user1@example.com")) do |x|
        x.workflow_state = "active"
        x.sis_user_id = "user1"
      end
      expect(SisPseudonym.for(u, course1)).to eq(active_pseudonym)
      expect(SisPseudonym.for(u, course1, include_deleted: true)).to eq @deleted_pseudonym
    end

    it "returns only active pseudonyms when loading from user collection too" do
      u.pseudonyms # make sure user collection is loaded
      expect(SisPseudonym.for(u, course1)).to be_nil
    end
  end

  it "returns pseudonyms in the right account" do
    other_account = account_model
    u.pseudonyms.create!(pseud_params("user1@example.com", other_account)) do |x|
      x.workflow_state = "active"
      x.sis_user_id = "user1"
    end
    expect(SisPseudonym.for(u, course1)).to be_nil
    @p = u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
      x.workflow_state = "active"
      x.sis_user_id = "user2"
    end
    expect(SisPseudonym.for(u, course1)).to eq @p
  end

  it "returns pseudonyms with a sis id only" do
    u.pseudonyms.create!(pseud_params("user1@example.com")) do |x|
      x.workflow_state = "active"
    end
    expect(SisPseudonym.for(u, course1)).to be_nil
    @p = u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
      x.workflow_state = "active"
      x.sis_user_id = "user2"
    end
    expect(SisPseudonym.for(u, course1)).to eq @p
  end

  it "returns pseudonym for specfic enrollment" do
    @p = u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
      x.workflow_state = "active"
      x.sis_user_id = "user2"
    end
    @p2 = u.pseudonyms.create!(pseud_params("user2b@example.com")) do |x|
      x.workflow_state = "active"
      x.sis_user_id = "user2b"
    end
    e = course1.enroll_user(u, "StudentEnrollment", enrollment_state: "active")
    e.sis_pseudonym_id = @p.id
    e.save!
    section = course1.course_sections.create
    e2 = course1.enroll_user(u, "StudentEnrollment", enrollment_state: "active", section:, allow_multiple_enrollments: true)
    e2.sis_pseudonym_id = @p2.id
    e2.save!
    expect(SisPseudonym.for(u, e)).to eq @p
    expect(SisPseudonym.for(u, e2)).to eq @p2
  end

  it "follows ths sis_user_id if it moves between pseudonyms" do
    pseudonym1 = u.pseudonyms.create!(pseud_params("testuser41@example.com")) do |x|
      x.workflow_state = "active"
      x.sis_user_id = "user2"
    end
    pseudonym2 = u.pseudonyms.create!(pseud_params("testuser42@example.com")) do |x|
      x.workflow_state = "active"
      x.sis_user_id = nil
    end
    enrollment = course1.enroll_user(u, "StudentEnrollment", enrollment_state: "active")
    enrollment.sis_pseudonym_id = pseudonym1.id
    enrollment.save!
    expect(SisPseudonym.for(u, course1)).to eq(pseudonym1)
    pseudonym1.sis_user_id = nil
    pseudonym1.save!
    pseudonym2.sis_user_id = "user2"
    pseudonym2.save!
    expect(SisPseudonym.for(u, course1)).to eq(pseudonym2)
  end

  it "finds the right root account for a course" do
    pseudonym = account2.pseudonyms.create!(user: u, unique_id: "user") do |p|
      p.sis_user_id = "abc"
    end
    expect(SisPseudonym.for(u, course2)).to eq(pseudonym)
  end

  it "finds the right root account for a group" do
    @group = group group_context: course2
    pseudonym = account2.pseudonyms.create!(user: u, unique_id: "user") { |p| p.sis_user_id = "abc" }
    expect(SisPseudonym.for(u, @group)).to eq(pseudonym)
  end

  it "finds the right root account for a non-root-account" do
    @root_account = account1
    @account = @root_account.sub_accounts.create!
    pseudonym = @root_account.pseudonyms.create!(user: u, unique_id: "user") { |p| p.sis_user_id = "abc" }
    expect(SisPseudonym.for(u, @account)).to eq(pseudonym)
  end

  it "finds the right root account for a root account" do
    pseudonym = account1.pseudonyms.create!(user: u, unique_id: "user") { |p| p.sis_user_id = "abc" }
    expect(SisPseudonym.for(u, account1)).to eq(pseudonym)
  end

  it "bails if it can't find a root account" do
    context = Course.new # some context that doesn't have an account
    expect { SisPseudonym.for(u, context) }.to raise_error("could not resolve root account")
  end

  it "includes a pseudonym from a trusted account" do
    pseudonym = account2.pseudonyms.create!(user: u, unique_id: "user") { |p| p.sis_user_id = "abc" }
    allow(account1).to receive_messages(trust_exists?: true, trusted_account_ids: [account2.id])
    expect(SisPseudonym.for(u, account1)).to be_nil
    expect(SisPseudonym.for(u, account1, type: :trusted)).to eq(pseudonym)
  end

  context "with multiple acceptable sis pseudonyms" do
    before do
      ldap_ap = Account.default.authentication_providers.create!(auth_type: "ldap")
      cas_ap = Account.default.authentication_providers.create!(auth_type: "cas")

      u.pseudonyms.create!(pseud_params("alphabet@example.com")) do |p|
        p.workflow_state = "active"
        p.sis_user_id = "SIS1"
        p.authentication_provider = cas_ap
      end
      u.pseudonyms.create!(pseud_params("zebra@example.com")) do |p|
        p.workflow_state = "active"
        p.sis_user_id = "SIS2"
      end
      u.pseudonyms.create!(pseud_params("alphabet@example.com")) do |p|
        p.workflow_state = "active"
        p.sis_user_id = "SIS3"
        p.authentication_provider = ldap_ap
      end
      u.reload # to clear psuedonyms collection for sure
    end

    context "when association cache is not loaded" do
      it "finds the alphabetically first pseudonym" do
        found_pseudonym = SisPseudonym.for(u, Account.default)
        expect(found_pseudonym.unique_id).to eq("alphabet@example.com")
      end

      it "sorts pseudonyms with matching unique_ids by position" do
        found_pseudonym = SisPseudonym.for(u, Account.default)
        expect(found_pseudonym.unique_id).to eq("alphabet@example.com")
        expect(found_pseudonym.position).to eq(1)
        expect(found_pseudonym.authentication_provider.auth_type).to eq("cas")
      end
    end

    context "when association cache is loaded" do
      before do
        u.pseudonyms # to get pseudonyms collection pre-loaded
      end

      it "finds the same alphabetically first pseudonym as if the cache was not primed" do
        found_pseudonym = SisPseudonym.for(u, Account.default)
        expect(found_pseudonym.unique_id).to eq("alphabet@example.com")
      end

      it "sorts pseudonyms with matching unique_ids by position" do
        found_pseudonym = SisPseudonym.for(u, Account.default)
        expect(found_pseudonym.unique_id).to eq("alphabet@example.com")
        expect(found_pseudonym.position).to eq(1)
        expect(found_pseudonym.authentication_provider.auth_type).to eq("cas")
      end
    end
  end

  context "with multiple acceptable pseudonyms" do
    let_once(:non_sis_pseudo) { u.pseudonyms.create!(pseud_params("a")) }
    let_once(:sis_pseudo) { u.pseudonyms.create!(pseud_params("user").merge(sis_user_id: "abc")) }

    it "finds the SIS pseudonym first from db" do
      u.reload
      expect(SisPseudonym.for(u, Account.default, require_sis: false)).to eq sis_pseudo
    end

    it "finds the SIS pseudonym first from collection" do
      u.reload
      u.pseudonyms.to_a
      expect(SisPseudonym.for(u, Account.default, require_sis: false)).to eq sis_pseudo
    end
  end

  context "no SIS pseudos" do
    before(:once) do
      u.pseudonyms.create!(pseud_params("a"))
    end

    context "db" do
      it "finds the non-SIS pseudonym when allowed" do
        u.reload
        expect(SisPseudonym.for(u, Account.default, require_sis: false)).not_to be_nil
      end

      it "doesn't find the non-SIS pseudonym when not allowed" do
        u.reload
        expect(SisPseudonym.for(u, Account.default)).to be_nil
      end
    end

    context "preloaded" do
      it "finds the non-SIS pseudonym when allowed" do
        u.reload
        u.pseudonyms.to_a
        expect(SisPseudonym.for(u, Account.default, require_sis: false)).not_to be_nil
      end

      it "doesn't find the non-SIS pseudonym when not allowed" do
        u.reload
        u.pseudonyms.to_a
        expect(SisPseudonym.for(u, Account.default)).to be_nil
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "finds a pseudonym on a different shard" do
      @shard1.activate do
        @user = User.create!
      end
      @pseudonym = Account.default.pseudonyms.create!(user: @user, unique_id: "user") do |p|
        p.sis_user_id = "abc"
      end
      @shard2.activate do
        expect(SisPseudonym.for(@user, Account.default)).to eq @pseudonym
      end
      @shard1.activate do
        expect(SisPseudonym.for(@user, Account.default)).to eq @pseudonym
      end
    end

    it "looks in other accounts" do
      @shard1.activate do
        @s1root = account_model
        @user = User.create!
        @pseudonym = @s1root.pseudonyms.create!(user: @user, unique_id: "user") do |p|
          p.sis_user_id = "abc"
        end
        allow_any_instantiation_of(@pseudonym).to receive(:works_for_account?).with(Account.default, true).and_return(true)
      end
      expect(SisPseudonym.for(@user, Account.default, type: :implicit)).to eq @pseudonym
      expect(SisPseudonym.for(@user, Account.default, type: :implicit, in_region: true)).to eq @pseudonym
    end

    it "returns a collection of all relevant pseudonyms" do
      @shard1.activate { @user = User.create! }
      @pseudonym =
        Account
        .default
        .pseudonyms
        .create!(user: @user, unique_id: "user") { |p| p.sis_user_id = "abc" }
      @shard2.activate do
        expect(
          SisPseudonym.for(@user, Account.default, type: :implicit, include_all_pseudonyms: true)
        ).to eq [@pseudonym]
      end
    end

    it "returns a collection of all relevant pre-loaded pseudonyms" do
      @shard1.activate { @user = User.create! }
      @pseudonym = Account.default.pseudonyms.create!(user: @user, unique_id: "user")
      @shard2.activate do
        @user.pseudonyms.to_a
        expect(
          SisPseudonym.for(
            @user,
            Account.default,
            type: :implicit,
            require_sis: false,
            include_all_pseudonyms: true
          )
        ).to eq [@pseudonym]
      end
    end

    it "returns a collection of all relevant non-duplicated pseudonyms" do
      @user = u
      p1 = @user.pseudonyms.create!(pseud_params("a"))
      p2 = @user.pseudonyms.create!(pseud_params("b"))
      @shard1.activate do
        account = account_model
        course = account.courses.create!
        course.enroll_student(@user)
        @user.pseudonyms.create!(pseud_params("a", account))
        @user.pseudonyms.create!(pseud_params("b", account))
        @user.pseudonyms.create!(pseud_params("c", account))
      end
      expect(
        SisPseudonym.for(
          @user,
          Account.default,
          type: :implicit,
          require_sis: false,
          include_all_pseudonyms: true
        )
      ).to eq [p1, p2]
    end
  end
end
