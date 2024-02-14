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

require "rotp"
require "timecop"
require_relative "../helpers/k5_common"

describe User do
  include K5Common

  context "validation" do
    it "creates a new instance given valid attributes" do
      expect(user_model).to be_valid
    end

    context "on update" do
      let(:user) { user_model }

      it "fails validation if lti_id changes" do
        user.short_name = "chewie"
        user.lti_id = "changedToThis"
        expect(user).to_not be_valid
      end

      it "passes validation if lti_id is not changed" do
        user
        user.short_name = "chewie"
        expect(user).to be_valid
      end
    end
  end

  describe "notifications" do
    describe "#daily_notification_time" do
      it "returns the users 6pm local time" do
        Time.use_zone("UTC") do
          @central = ActiveSupport::TimeZone.us_zones.find { |zone| zone.name == "Central Time (US & Canada)" }
          # set up user in central time (different than the specific time zones
          # referenced in set_send_at)
          @account = Account.create!(name: "new acct")
          @user = user_with_pseudonym(account: @account)
          @user.time_zone = @central.name
          @user.pseudonym.update_attribute(:account, @account)
          @user.save

          Timecop.freeze(Time.zone.local(2021, 9, 22, 1, 0, 0)) do
            expect(@user.daily_notification_time).to  eq(@central.now.change(day: 22, hour: 18))
          end
        end
      end
    end
  end

  it "adds an lti_id on creation" do
    user = User.new
    expect(user.lti_id).to be_blank
    user.save!
    expect(user.lti_id).to_not be_blank
  end

  it "gets the first email from communication_channel" do
    @user = User.create
    @cc1 = double("CommunicationChannel")
    allow(@cc1).to receive(:path).and_return("cc1")
    @cc2 = double("CommunicationChannel")
    allow(@cc2).to receive(:path).and_return("cc2")
    allow(@user).to receive_messages(communication_channels: [@cc1, @cc2],
                                     communication_channel: @cc1)
    expect(@user.communication_channel).to eql(@cc1)
  end

  it "is able to assert a name" do
    @user = User.create
    @user.assert_name(nil)
    expect(@user.name).to eql("User")
    @user.assert_name("david")
    expect(@user.name).to eql("david")
    @user.assert_name("bill")
    expect(@user.name).to eql("bill")
    @user.assert_name(nil)
    expect(@user.name).to eql("bill")
    @user = User.find(@user.id)
    expect(@user.name).to eql("bill")
  end

  it "identifies active courses correctly when there are no active groups" do
    user = User.create(name: "longname1", short_name: "shortname1")
    expect(user.current_active_groups?).to be(false)
  end

  it "identifies active courses correctly when there are active groups" do
    account1 = account_model
    course_with_student(account: account1)
    group_model(group_category: @communities, is_public: true, context: @course)
    group.add_user(@student)
    expect(@student.current_active_groups?).to be(true)
  end

  it "updates account associations when a course account changes" do
    account1 = account_model
    account2 = account_model
    course_with_student
    expect(@user.associated_accounts.length).to be(1)
    expect(@user.associated_accounts.first).to eql(Account.default)

    @course.account = account1
    @course.save!
    @course.reload
    @user.reload

    expect(@user.associated_accounts.length).to be(1)
    expect(@user.associated_accounts.first).to eql(account1)

    @course.account = account2
    @course.save!
    @user.reload

    expect(@user.associated_accounts.length).to be(1)
    expect(@user.associated_accounts.first).to eql(account2)
  end

  it "updates account associations when a course account moves in the hierachy" do
    account1 = account_model

    @enrollment = course_with_student(account: account1)
    @course.account = account1
    @course.save!
    @course.reload
    @user.reload

    expect(@user.associated_accounts.length).to be(1)
    expect(@user.associated_accounts.first).to eql(account1)

    account2 = account_model(root_account: account1)
    @course.update(account: account2)
    @user.reload

    expect(@user.associated_accounts.length).to be(2)
    expect(@user.associated_accounts[0]).to eql(account2)
    expect(@user.associated_accounts[1]).to eql(account1)
  end

  it "updates account associations when a user is associated to an account just by pseudonym" do
    account1 = account_model
    account2 = account_model
    user = user_with_pseudonym

    pseudonym = user.pseudonyms.first
    pseudonym.account = account1
    pseudonym.save

    user.reload
    expect(user.associated_accounts.length).to be(1)
    expect(user.associated_accounts.first).to eql(account1)

    # Make sure that multiple sequential updates also work
    pseudonym.account = account2
    pseudonym.save
    pseudonym.account = account1
    pseudonym.save
    user.reload
    expect(user.associated_accounts.length).to be(1)
    expect(user.associated_accounts.first).to eql(account1)
  end

  it "updates account associations when a user is associated to an account just by account_users" do
    account = account_model
    @user = User.create
    account.account_users.create!(user: @user)

    @user.reload
    expect(@user.associated_accounts.length).to be(1)
    expect(@user.associated_accounts.first).to eql(account)
  end

  it "excludes deleted enrollments from all courses list" do
    account1 = account_model

    enrollment1 = course_with_student(account: account1)
    enrollment2 = course_with_student(account: account1)
    enrollment1.user = @user
    enrollment2.user = @user
    enrollment1.save!
    enrollment2.save!
    @user.reload

    expect(@user.all_courses_for_active_enrollments.length).to be(2)

    expect { enrollment1.destroy! }
      .to change {
        @user.reload.all_courses_for_active_enrollments.size
      }.from(2).to(1)
  end

  it "populates dashboard_messages" do
    Notification.create(name: "Assignment Created")
    course_with_teacher(active_all: true)
    expect(@user.stream_item_instances).to be_empty
    @a = @course.assignments.new(title: "some assignment")
    @a.workflow_state = "available"
    @a.save
    expect(@user.stream_item_instances.reload).not_to be_empty
  end

  it "ignores orphaned stream item instances" do
    course_with_student(active_all: true)
    google_docs_collaboration_model(user_id: @user.id)
    expect(@user.recent_stream_items.size).to eq 1
    StreamItem.delete_all
    expect(@user.recent_stream_items.size).to eq 0
  end

  it "ignores stream item instances from concluded courses" do
    course_with_teacher(active_all: true)
    google_docs_collaboration_model(user_id: @user.id)
    expect(@user.recent_stream_items.size).to eq 1
    @course.soft_conclude!
    @course.save
    expect(@user.recent_stream_items.size).to eq 0
  end

  it "ignores stream item instances from courses the user is no longer participating in" do
    course_with_student(active_all: true)
    google_docs_collaboration_model(user_id: @user.id)
    expect(@user.recent_stream_items.size).to eq 1
    @enrollment.end_at = @enrollment.start_at = Time.now - 1.day
    @enrollment.save!
    @user = User.find(@user.id)
    expect(@user.recent_stream_items.size).to eq 0
  end

  describe "#adminable_accounts_scope" do
    specs_require_sharding

    subject { user.adminable_accounts_scope }

    let(:shard_one_account) { @shard1.activate { Account.create!(name: "Shard One Account") } }
    let(:shard_two_account) { @shard2.activate { Account.create!(name: "Shard Two Account") } }
    let(:user) { user_model }

    context "when the user has no account users" do
      before do
        user.account_users.map(&:destroy)
        user.clear_adminable_accounts_cache!
      end

      it "returns an empty scope" do
        expect(subject).to be_empty
      end
    end

    context "when the user has account users on multiple shards" do
      before do
        user.associate_with_shard(shard_one_account.shard)
        user.associate_with_shard(shard_two_account.shard)

        shard_one_account.shard.activate do
          AccountUser.create!(account: shard_one_account, user:)
        end

        shard_two_account.shard.activate do
          AccountUser.create!(account: shard_two_account, user:)
        end
      end

      it "returns the adminable accounts on all shards" do
        expect(subject).to match_array [shard_one_account, shard_two_account]
      end

      context "and a shard scope is provided" do
        subject { user.adminable_accounts_scope(shard_scope: [shard_one_account.shard]) }

        it "limits results to the specified shard scope" do
          expect(subject).to eq [shard_one_account]
        end
      end
    end
  end

  describe "#recent_stream_items" do
    it "skips submission stream items" do
      course_with_teacher(active_all: true)
      course_with_student(active_all: true, course: @course)
      assignment = @course.assignments.create!(title: "some assignment", submission_types: ["online_text_entry"])
      sub = assignment.submit_homework @student, body: "submission"
      sub.add_comment author: @teacher, comment: "lol"
      item = StreamItem.last
      expect(item.asset).to eq sub
      expect(@student.visible_stream_item_instances.map(&:stream_item)).to include item
      expect(@student.recent_stream_items).not_to include item
    end
  end

  describe "#public_lti_id" do
    subject { User.public_lti_id }

    it { is_expected.to eq "https://canvas.instructure.com/public_user" }
  end

  describe "#cached_recent_stream_items" do
    before(:once) do
      @contexts = []
      # create stream item 1
      course_with_teacher(active_all: true)
      @contexts << @course
      discussion_topic_model(context: @course)
      # create stream item 2
      course_with_teacher(active_all: true, user: @teacher)
      @contexts << @course
      discussion_topic_model(context: @course)

      @dashboard_key = StreamItemCache.recent_stream_items_key(@teacher)
    end

    let(:context_keys) do
      @contexts.map do |context|
        StreamItemCache.recent_stream_items_key(@teacher, context.class.base_class.name, context.id)
      end
    end

    it "creates cache keys for each context" do
      enable_cache do
        @teacher.cached_recent_stream_items(contexts: @contexts)
        expect(Rails.cache.read(@dashboard_key)).to be_blank
        context_keys.each do |context_key|
          expect(Rails.cache.read(context_key)).not_to be_blank
        end
      end
    end

    it "creates one cache key when there are no contexts" do
      enable_cache do
        @teacher.cached_recent_stream_items # cache the dashboard items
        expect(Rails.cache.read(@dashboard_key)).not_to be_blank
        context_keys.each do |context_key|
          expect(Rails.cache.read(context_key)).to be_blank
        end
      end
    end
  end

  it "is able to remove itself from a root account" do
    account1 = Account.create
    account2 = Account.create
    sub = account2.sub_accounts.create!

    user = User.create
    user.register!
    p1 = user.pseudonyms.create(unique_id: "user1")
    p2 = user.pseudonyms.create(unique_id: "user2")
    p1.account = account1
    p2.account = account2
    p1.save!
    p2.save!
    account1.account_users.create!(user:)
    account2.account_users.create!(user:)
    sub.account_users.create!(user:)

    course1 = account1.courses.create
    course2 = account2.courses.create
    course1.offer!
    course2.offer!
    enrollment1 = course1.enroll_student(user)
    enrollment2 = course2.enroll_student(user)
    enrollment1.workflow_state = "active"
    enrollment2.workflow_state = "active"
    enrollment1.save!
    enrollment2.save!
    expect(user.associated_account_ids.include?(account1.id)).to be_truthy
    expect(user.associated_account_ids.include?(account2.id)).to be_truthy

    user.remove_from_root_account(account2)
    user.reload
    expect(user.associated_account_ids.include?(account1.id)).to be_truthy
    expect(user.associated_account_ids.include?(account2.id)).to be_falsey
    expect(user.account_users.active.where(account_id: [account2, sub])).to be_empty
  end

  it "searches by multiple fields" do
    @account = Account.create!
    user1 = User.create! name: "longname1", short_name: "shortname1"
    user1.register!
    user2 = User.create! name: "longname2", short_name: "shortname2"
    user2.register!

    expect(User.name_like("longname1").map(&:id)).to eq [user1.id]
    expect(User.name_like("shortname2").map(&:id)).to eq [user2.id]
    expect(User.name_like("sisid1").map(&:id)).to eq []
    expect(User.name_like("uniqueid2").map(&:id)).to eq []

    p1 = user1.pseudonyms.new unique_id: "uniqueid1", account: @account
    p1.sis_user_id = "sisid1"
    p1.save!
    p2 = user2.pseudonyms.new unique_id: "uniqueid2", account: @account
    p2.sis_user_id = "sisid2"
    p2.save!

    expect(User.name_like("longname1").map(&:id)).to eq [user1.id]
    expect(User.name_like("shortname2").map(&:id)).to eq [user2.id]
    expect(User.name_like("sisid1").map(&:id)).to eq [user1.id]
    expect(User.name_like("uniqueid2").map(&:id)).to eq [user2.id]

    p3 = user1.pseudonyms.new unique_id: "uniqueid3", account: @account
    p3.sis_user_id = "sisid3"
    p3.save!

    expect(User.name_like("longname1").map(&:id)).to eq [user1.id]
    expect(User.name_like("shortname2").map(&:id)).to eq [user2.id]
    expect(User.name_like("sisid1").map(&:id)).to eq [user1.id]
    expect(User.name_like("uniqueid2").map(&:id)).to eq [user2.id]
    expect(User.name_like("uniqueid3").map(&:id)).to eq [user1.id]

    p4 = user1.pseudonyms.new unique_id: "uniqueid4", account: @account
    p4.sis_user_id = "sisid3 2"
    p4.save!

    expect(User.name_like("longname1").map(&:id)).to eq [user1.id]
    expect(User.name_like("shortname2").map(&:id)).to eq [user2.id]
    expect(User.name_like("sisid1").map(&:id)).to eq [user1.id]
    expect(User.name_like("uniqueid2").map(&:id)).to eq [user2.id]
    expect(User.name_like("uniqueid3").map(&:id)).to eq [user1.id]
    expect(User.name_like("sisid3").map(&:id)).to eq [user1.id]

    user3 = User.create! name: "longname1", short_name: "shortname3"
    user3.register!

    expect(User.name_like("longname1").map(&:id).sort).to eq [user1.id, user3.id].sort
    expect(User.name_like("shortname2").map(&:id)).to eq [user2.id]
    expect(User.name_like("sisid1").map(&:id)).to eq [user1.id]
    expect(User.name_like("uniqueid2").map(&:id)).to eq [user2.id]
    expect(User.name_like("uniqueid3").map(&:id)).to eq [user1.id]
    expect(User.name_like("sisid3").map(&:id)).to eq [user1.id]

    expect(User.name_like("sisid3").map(&:id)).to eq [user1.id]
    expect(User.name_like("uniqueid4").map(&:id)).to eq [user1.id]
    p4.destroy
    expect(User.name_like("sisid3").map(&:id)).to eq [user1.id]
    expect(User.name_like("uniqueid4").map(&:id)).to eq []
  end

  it "is able to be removed from a root account with non-Canvas auth" do
    account1 = account_with_cas
    account2 = Account.create!
    user = User.create!
    user.register!
    p1 = user.pseudonyms.new unique_id: "id1", account: account1
    p1.sis_user_id = "sis_id1"
    p1.save!
    user.pseudonyms.create! unique_id: "id2", account: account2
    user.remove_from_root_account account1
    expect(user.associated_root_accounts.to_a).to eql [account2]
  end

  describe "update_root_account_ids" do
    let_once(:root_account) { Account.default }
    let_once(:sub_account) { Account.create(parent_account: root_account, name: "sub") }

    let(:user) { user_model }

    before do
      user.user_account_associations.create!(account: root_account)
      user.user_account_associations.create!(account: sub_account)
    end

    context "when there is a single root account association" do
      it "updates root_account_ids with the root account" do
        expect do
          user.update_root_account_ids
        end.to change {
          user.root_account_ids
        }.from([]).to([root_account.global_id])
      end

      it "includes soft deleted associations" do
        user.user_account_associations.scope.delete_all
        p = user.pseudonyms.create!(account: root_account, unique_id: "p")
        p.destroy
        user.update_root_account_ids
        expect(user.user_account_associations).not_to exist
        expect(user.root_account_ids).to eq [root_account.global_id]
      end

      context "and communication channels for the user exist" do
        let(:communication_channel) { user.communication_channels.create!(path: "test@test.com") }

        before { communication_channel.update(root_account_ids: nil) }

        it "updates root_account_ids on associated communication channels" do
          expect do
            user.update_root_account_ids
          end.to change {
            user.communication_channels.first.root_account_ids
          }.from([]).to([root_account.id])
        end
      end
    end

    context "when there cross-shard root account associations" do
      specs_require_sharding

      let(:shard_two_root_account) { account_model }

      before do
        @shard2.activate do
          user.user_account_associations.create!(
            account: shard_two_root_account
          )
          user.associate_with_shard(@shard2)
        end
      end

      it "updates root_account_ids with all root accounts" do
        expect do
          user.update_root_account_ids
        end.to change {
          user.root_account_ids&.sort
        }.from([]).to(
          [root_account.id, shard_two_root_account.global_id].sort
        )
      end
    end

    context "student_view user" do
      it "does create root_account_ids for student view student" do
        course_with_teacher(active_all: true)
        @fake_student = @course.student_view_student
        expect(@fake_student.reload.root_account_ids).to eq([root_account.global_id])
      end
    end
  end

  describe "update_account_associations" do
    it "supports incrementally adding to account associations" do
      user = User.create!
      expect(user.user_account_associations).to eq []
      account1, account2, account3 = Account.create!, Account.create!, Account.create!

      sort_account_associations = ->(a, b) { a.keys.first <=> b.keys.first }

      User.update_account_associations([user], incremental: true, precalculated_associations: { account1.id => 0 })
      expect(user.user_account_associations.reload.map { |aa| { aa.account_id => aa.depth } }).to eq [{ account1.id => 0 }]

      User.update_account_associations([user], incremental: true, precalculated_associations: { account2.id => 1 })
      expect(user.user_account_associations.reload.map { |aa| { aa.account_id => aa.depth } }.sort(&sort_account_associations)).to eq [{ account1.id => 0 }, { account2.id => 1 }].sort(&sort_account_associations)

      User.update_account_associations([user], incremental: true, precalculated_associations: { account3.id => 1, account1.id => 2, account2.id => 0 })
      expect(user.user_account_associations.reload.map { |aa| { aa.account_id => aa.depth } }.sort(&sort_account_associations)).to eq [{ account1.id => 0 }, { account2.id => 0 }, { account3.id => 1 }].sort(&sort_account_associations)
    end

    it "does not have account associations for creation_pending or deleted" do
      user = User.create! { |u| u.workflow_state = "creation_pending" }
      expect(user).to be_creation_pending
      course = Course.create!
      course.offer!
      enrollment = course.enroll_student(user)
      expect(enrollment).to be_invited
      expect(user.user_account_associations).to eq []
      Account.default.account_users.create!(user:)
      expect(user.user_account_associations.reload).to eq []
      user.pseudonyms.create!(unique_id: "test@example.com")
      expect(user.user_account_associations.reload).to eq []
      user.update_account_associations
      expect(user.user_account_associations.reload).to eq []
      user.register!
      expect(user.user_account_associations.reload.map(&:account)).to eq [Account.default]
      user.destroy
      expect(user.user_account_associations.reload).to eq []
    end

    it "does not create/update account associations for student view student" do
      account1 = account_model
      account2 = account_model
      course_with_teacher(active_all: true)
      @fake_student = @course.student_view_student
      expect(@fake_student.reload.user_account_associations).to be_empty

      @course.account_id = account1.id
      @course.save!
      expect(@fake_student.reload.user_account_associations).to be_empty

      account1.parent_account = account2
      account1.save!
      @course.root_account = account2
      @course.save!
      expect(@fake_student.reload.user_account_associations).to be_empty

      @course.complete!
      expect(@fake_student.reload.user_account_associations).to be_empty

      @fake_student = @course.reload.student_view_student
      expect(@fake_student.reload.user_account_associations).to be_empty

      @section2 = @course.course_sections.create!(name: "Other Section")
      @fake_student = @course.reload.student_view_student
      expect(@fake_student.reload.user_account_associations).to be_empty
    end

    it "removes account associations for rejected enrollments" do
      subaccount = Account.default.sub_accounts.create!
      enrollment = course_with_student(active_all: true, account: subaccount)
      expect(@student.user_account_associations.pluck(:account_id)).to(
        match_array([Account.default, subaccount].map(&:id))
      )

      enrollment.reject
      @student.update_account_associations
      expect(@student.user_account_associations.pluck(:account_id)).to be_empty
    end

    it "does not remove account associations for inactive enrollments" do
      subaccount = Account.default.sub_accounts.create!
      enrollment = course_with_student(active_all: true, account: subaccount, user: @student)
      expect(@student.user_account_associations.pluck(:account_id)).to(
        match_array([Account.default, subaccount].map(&:id))
      )

      enrollment.update workflow_state: "inactive"
      @student.update_account_associations
      expect(@student.user_account_associations.pluck(:account_id)).to(
        match_array([Account.default, subaccount].map(&:id))
      )
    end

    context "sharding" do
      specs_require_sharding

      it "creates associations for a user in multiple shards" do
        user_factory
        Account.site_admin.account_users.create!(user: @user)
        expect(@user.user_account_associations.map(&:account)).to eq [Account.site_admin]

        @shard1.activate do
          @account = Account.create!
          au = @account.account_users.create!(user: @user)
          expect(@user.user_account_associations.shard(@user).map(&:account).sort_by(&:id)).to eq(
            [Account.site_admin, @account].sort_by(&:id)
          )
          expect(@account.user_account_associations.map(&:user)).to eq [@user]

          au.destroy

          expect(@user.user_account_associations.shard(@user).map(&:account)).to eq [Account.site_admin]
          expect(@account.reload.user_account_associations.map(&:user)).to eq []

          @account.account_users.create!(user: @user)

          expect(@user.user_account_associations.shard(@user).map(&:account).sort_by(&:id)).to eq(
            [Account.site_admin, @account].sort_by(&:id)
          )
          expect(@account.reload.user_account_associations.map(&:user)).to eq [@user]

          UserAccountAssociation.delete_all
        end
        UserAccountAssociation.delete_all

        @shard2.activate do
          @user.update_account_associations

          expect(@user.user_account_associations.shard(@user).map(&:account).sort_by(&:id)).to eq(
            [Account.site_admin, @account].sort_by(&:id)
          )
          expect(@account.reload.user_account_associations.map(&:user)).to eq [@user]
        end
        UserAccountAssociation.delete_all

        @shard1.activate do
          # check sharding for when we pass user IDs into update_account_associations, rather than user objects themselves
          User.update_account_associations([@user.id], all_shards: true)
          expect(@account.reload.all_users).to eq [@user]
        end
        @shard2.activate { expect(@account.reload.all_users).to eq [@user] }
      end
    end
  end

  def create_course_with_student_and_assignment
    @course = course_model
    @course.offer!
    @student = user_model
    @course.enroll_student @student
    @assignment = @course.assignments.create title: "Test Assignment", points_possible: 10
  end

  describe "#recent_feedback" do
    let_once(:post_policies_course) { Course.create!(workflow_state: :available) }
    let_once(:auto_posted_assignment) { post_policies_course.assignments.create!(points_possible: 10) }
    let_once(:manual_posted_assignment) do
      assignment = post_policies_course.assignments.create!(points_possible: 10)
      assignment.post_policy.update!(post_manually: true)
      assignment
    end

    let_once(:student) { User.create! }
    let_once(:teacher) { User.create! }

    before(:once) do
      post_policies_course.enroll_student(student, enrollment_state: :active)
      post_policies_course.enroll_teacher(teacher, enrollment_state: :active)
    end

    context "for a course with Post Policies enabled" do
      it "does not include assignments for which there is no feedback" do
        expect(student.recent_feedback).to be_empty
      end

      it "includes recent posted feedback" do
        auto_posted_assignment.grade_student(student, grader: teacher, score: 10)
        expect(student.recent_feedback).to contain_exactly(auto_posted_assignment.submission_for_student(student))
      end

      it "includes feedback that was posted after being initially hidden" do
        manual_posted_assignment.grade_student(student, grader: teacher, score: 10)
        manual_posted_assignment.post_submissions

        expect(student.recent_feedback).to contain_exactly(manual_posted_assignment.submission_for_student(student))
      end

      it "does not include recent unposted feedback" do
        manual_posted_assignment.grade_student(student, grader: teacher, score: 10)
        expect(student.recent_feedback).to be_empty
      end

      it "does not include recent feedback that was posted but subsequently hidden" do
        auto_posted_assignment.grade_student(student, grader: teacher, score: 10)
        auto_posted_assignment.hide_submissions

        expect(student.recent_feedback).to be_empty
      end
    end

    it "only returns feedback for posted submissions" do
      auto_posted_assignment.grade_student(student, grader: teacher, score: 10)
      manual_posted_assignment.grade_student(student, grader: teacher, score: 10)

      expect(student.recent_feedback).to contain_exactly(
        auto_posted_assignment.submission_for_student(student)
      )
    end

    it "only returns feedback for specific courses if specified" do
      other_course = Course.create!(workflow_state: :available)
      other_course.enroll_student(student, enrollment_state: :active)
      other_course.enroll_teacher(teacher, enrollment_state: :active)
      auto_assignment = other_course.assignments.create!(points_possible: 10)
      manual_assignment = other_course.assignments.create!(points_possible: 10)
      manual_assignment.post_policy.update!(post_manually: true)

      auto_assignment.grade_student(student, grader: teacher, score: 10)

      expect(student.recent_feedback(contexts: [other_course])).to contain_exactly(
        auto_assignment.submission_for_student(student)
      )
    end

    it "includes recent feedback for student view users" do
      test_student = post_policies_course.student_view_student
      auto_posted_assignment.grade_student(test_student, grade: 9, grader: teacher)
      expect(test_student.recent_feedback).not_to be_empty
    end

    it "does not include recent feedback for unpublished assignments" do
      auto_posted_assignment.grade_student(student, grade: 9, grader: teacher)
      auto_posted_assignment.unpublish
      expect(student.recent_feedback(contexts: [post_policies_course])).to be_empty
    end

    it "does not include recent feedback for other students in admin feedback" do
      other_teacher = post_policies_course.enroll_teacher(User.create!, enrollment_state: :active).user
      submission = auto_posted_assignment.grade_student(student, grade: 9, grader: teacher).first
      submission.add_comment(author: other_teacher, comment: "hi :)")

      expect(teacher.recent_feedback(contexts: [post_policies_course])).to be_empty
    end

    it "does not include non-recent feedback via old submission comments" do
      submission = auto_posted_assignment.grade_student(student, grade: 9, grader: teacher).first
      submission.add_comment(author: teacher, comment: "hooray")

      Timecop.travel(1.year.from_now) do
        expect(student.recent_feedback(contexts: [post_policies_course])).not_to include submission
      end
    end

    it "does include recent feedback for auto posted assignment that has last_comment_at but has no posted_at date" do
      submission = auto_posted_assignment.submissions.find_by!(user: student)
      submission.update!(last_comment_at: 1.day.ago, posted_at: nil)
      expect(student.recent_feedback(contexts: [post_policies_course])).not_to be_empty
    end
  end

  describe "#alternate_account_for_course_creation?" do
    let(:sub_account) { Account.create!(parent_account: Account.default) }
    let(:sub_sub_account) { Account.create!(parent_account: sub_account) }
    let(:sub_sub_admin) { account_admin_user(account: sub_sub_account) }

    it "return appropriately for lower level admins" do
      expect(sub_sub_admin.alternate_account_for_course_creation).to eq sub_sub_account
    end

    it "caches the account properly" do
      enable_cache(:redis_cache_store) do
        @user = sub_sub_admin
        expect(@user).to receive(:account_users).and_return(double(active: [])).once
        2.times { @user.alternate_account_for_course_creation }
      end
    end
  end

  describe "enrollments for course creating" do
    it "caches the accounts properly" do
      user_factory
      course_factory(course_name: "course_factory", active_course: true).enroll_user(@user, "StudentEnrollment", enrollment_state: "active")
      enable_cache(:redis_cache_store) do
        expect(Account).to receive(:where).with(id: nil).and_call_original.once # update_account_associations from enrollment deletion
        expect(Account).to receive(:where).with(id: []).and_call_original.exactly(3).times
        3.times { @user.course_creating_teacher_enrollment_accounts }
        3.times { @user.course_creating_student_enrollment_accounts }
        Enrollment.last.destroy
        @user.course_creating_student_enrollment_accounts
      end
    end
  end

  describe "#courses_with_primary_enrollment" do
    it "returns appropriate courses with primary enrollment" do
      user_factory
      @course1 = course_factory(course_name: "course_factory", active_course: true)
      @course1.enroll_user(@user, "StudentEnrollment", enrollment_state: "active")

      @course2 = course_factory(course_name: "other course_factory", active_course: true)
      @course2.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")

      @course3 = course_factory(course_name: "yet another course", active_course: true)
      @course3.enroll_user(@user, "StudentEnrollment", enrollment_state: "active")
      @course3.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")

      @course4 = course_factory(course_name: "not yet active")
      @course4.enroll_user(@user, "StudentEnrollment")

      @course5 = course_factory(course_name: "invited")
      @course5.enroll_user(@user, "TeacherEnrollment")

      @course6 = course_factory(course_name: "active but date restricted", active_course: true)
      @course6.restrict_student_future_view = true
      @course6.save!
      e = @course6.enroll_user(@user, "StudentEnrollment")
      e.accept!
      e.start_at = 1.day.from_now
      e.end_at = 2.days.from_now
      e.save!

      @course7 = course_factory(course_name: "soft concluded", active_course: true)
      e = @course7.enroll_user(@user, "StudentEnrollment")
      e.accept!
      e.start_at = 2.days.ago
      e.end_at = 1.day.ago
      e.save!

      # only four, in the right order (type, then name), and with the top type per course
      expect(@user.courses_with_primary_enrollment.map { |c| [c.id, c.primary_enrollment_type] }).to eq [
        [@course5.id, "TeacherEnrollment"],
        [@course2.id, "TeacherEnrollment"],
        [@course3.id, "TeacherEnrollment"],
        [@course1.id, "StudentEnrollment"]
      ]
    end

    describe "should filter by associated_user if provided" do
      before(:once) do
        @student = user_model
        @observer = user_model

        @observer_course = course_factory(course_name: "Physics", active_course: true)
        @observer_course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        observer_enrollment = @observer_course.enroll_user(@user, "ObserverEnrollment", enrollment_state: "active")
        observer_enrollment.associated_user_id = @student.id
        observer_enrollment.save!

        @observer_course2 = course_factory(course_name: "Math", active_course: true)
        @observer_course2.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        observer_enrollment2 = @observer_course2.enroll_user(@user, "ObserverEnrollment", enrollment_state: "active")
        observer_enrollment2.associated_user_id = @student.id
        observer_enrollment2.save!

        @teacher_course = course_factory(course_name: "English", active_course: true)
        @teacher_enrollment = @teacher_course.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
        @teacher_enrollment.save!

        @student_course = course_factory(course_name: "Leadership", active_course: true)
        student_enrollment = @student_course.enroll_user(@user, "StudentEnrollment", enrollment_state: "active")
        student_enrollment.save!
      end

      it "returns observed courses related to the associated_user" do
        expect(@observer.courses_with_primary_enrollment(:current_and_invited_courses, nil, observee_user: @student)
        .map { |c| [c.id, c.primary_enrollment_type] }).to eq [
          [@observer_course2.id, "ObserverEnrollment"],
          [@observer_course.id, "ObserverEnrollment"]
        ]
      end

      it "returns only own courses if the associated_user is the current user" do
        expect(@observer
        .courses_with_primary_enrollment(:current_and_invited_courses, nil, observee_user: @observer)
        .map { |c| [c.id, c.primary_enrollment_type] }).to eq [
          [@teacher_course.id, "TeacherEnrollment"],
          [@student_course.id, "StudentEnrollment"]
        ]
      end

      it "returns only own courses with active enrollments if the associated_user is the current user when there are other active enrollments" do
        # In some cases, courses would be returned if there was at least one active enrollment
        # even if the enrollment under test was not active.
        # Ensure there is at least one active enrollment in the course.
        @teacher_course.enroll_user(user_model, "StudentEnrollment", enrollment_state: "active")

        # Marking the enrollment_state as completed instead of @teacher_enrollment.complete! because
        # the query is done on enrollment_state
        @teacher_enrollment.enrollment_state.update(state: "completed")
        expect(@observer
         .courses_with_primary_enrollment(:current_and_invited_courses, nil, observee_user: @observer)
         .map { |c| [c.id, c.primary_enrollment_type] }).to eq [
           [@student_course.id, "StudentEnrollment"]
         ]
      end

      it "includes only unlinked observer enrollments if the associated_user is the current user" do
        user_factory(active_all: true)
        @observer_course.enroll_user(@user, "ObserverEnrollment", enrollment_state: :active)
        @observer_course2.enroll_user(@user, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student.id)

        expect(@user
                 .courses_with_primary_enrollment(:current_and_invited_courses, nil, observee_user: @user)
                 .pluck(:id)).to eq([@observer_course.id])
      end

      describe "with cross sharding" do
        specs_require_sharding

        before(:once) do
          @shard2.activate do
            account = Account.create!
            course_with_teacher(account:, active_all: true)

            observer_enrollment = @observer_course.enroll_user(@teacher, "ObserverEnrollment", enrollment_state: "active")
            observer_enrollment.associated_user_id = @student.id
            observer_enrollment.save!
          end
        end

        it "returns the user's courses across shards when they are the observee" do
          own_courses = @teacher.courses_with_primary_enrollment(:current_and_invited_courses, nil, observee_user: @teacher)
          expect(own_courses.count).to be 1
          expect(own_courses.first.id).to be @course.id
        end

        it "returns the observer's courses across shards when observing someone else" do
          observed_courses = @teacher.courses_with_primary_enrollment(:current_and_invited_courses, nil, observee_user: @student)
          expect(observed_courses.count).to be 1
          expect(observed_courses.first.id).to be @observer_course.id
        end
      end
    end

    it "includes invitations to temporary users" do
      user1 = user_factory
      user2 = user_factory
      c1 = course_factory(name: "a", active_course: true)
      e = c1.enroll_teacher(user1)
      allow(user2).to receive(:temporary_invitations).and_return([e])
      c2 = course_factory(name: "b", active_course: true)
      c2.enroll_user(user2)

      expect(user2.courses_with_primary_enrollment.map(&:id)).to eq [c1.id, c2.id]
    end

    it "filters out enrollments for deleted courses" do
      student_in_course(active_course: true)
      expect(@user.current_and_invited_courses.count).to eq 1
      Course.where(id: @course).update_all(workflow_state: "deleted")
      expect(@user.current_and_invited_courses.count).to eq 0
    end

    it "excludes deleted courses in cached_invitations" do
      student_in_course(active_course: true)
      expect(@user.cached_invitations.count).to eq 1
      Course.where(id: @course).update_all(workflow_state: "deleted")
      expect(@user.cached_invitations.count).to eq 0
    end

    describe "with cross sharding" do
      specs_require_sharding

      it "pulls the enrollments that are completed with global ids" do
        alice = bob = bobs_enrollment = alices_enrollment = nil

        duped_enrollment_id = 0

        @shard1.activate do
          alice = User.create!(name: "alice")
          bob = User.create!(name: "bob")
          account = Account.create!
          courseX = account.courses.build
          courseX.workflow_state = "available"
          courseX.save!
          bobs_enrollment = StudentEnrollment.create!(course: courseX, user: bob, workflow_state: "completed")
          duped_enrollment_id = bobs_enrollment.id
        end

        @shard2.activate do
          account = Account.create!
          courseY = account.courses.build
          courseY.workflow_state = "available"
          courseY.save!
          alices_enrollment = StudentEnrollment.new(course: courseY, user: alice, workflow_state: "active")
          alices_enrollment.id = duped_enrollment_id
          alices_enrollment.save!
        end

        expect(alice.courses_with_primary_enrollment.size).to eq 1
      end

      it "still filters out completed enrollments for the correct user" do
        alice = nil
        @shard1.activate do
          alice = User.create!(name: "alice")
          account = Account.create!
          courseX = account.courses.build
          courseX.workflow_state = "available"
          courseX.save!
          StudentEnrollment.create!(course: courseX, user: alice, workflow_state: "completed")
        end
        expect(alice.courses_with_primary_enrollment.size).to eq 0
      end

      it "filters out completed-by-date enrollments for the correct user" do
        @shard1.activate do
          @user = User.create!(name: "user")
          account = Account.create!
          courseX = account.courses.build
          courseX.workflow_state = "available"
          courseX.start_at = 7.days.ago
          courseX.conclude_at = 2.days.ago
          courseX.restrict_enrollments_to_course_dates = true
          courseX.save!
          StudentEnrollment.create!(course: courseX, user: @user, workflow_state: "active")
        end
        expect(@user.courses_with_primary_enrollment.count).to eq 0
        expect(@user.courses_with_primary_enrollment(:current_and_invited_courses, nil, include_completed_courses: true).count).to eq 1
      end

      it "works with favorite_courses" do
        @user = User.create!(name: "user")
        @shard1.activate do
          account = Account.create!
          @course = account.courses.build
          @course.workflow_state = "available"
          @course.save!
          StudentEnrollment.create!(course: @course, user: @user, workflow_state: "active")
        end
        @user.favorites.create!(context: @course)
        expect(@user.courses_with_primary_enrollment(:favorite_courses)).to eq [@course]
      end

      it "loads the roles correctly" do
        @user = User.create!(name: "user")
        @shard1.activate do
          account = Account.create!
          @course = account.courses.create!(workflow_state: "available")
          @role = account.roles.create!(name: "custom student", base_role_type: "StudentEnrollment")
          StudentEnrollment.create!(course: @course, user: @user, workflow_state: "active", role: @role)
        end
        fetched_courses = @user.courses_with_primary_enrollment(:current_and_invited_courses, nil, include_completed_courses: true)
        expect(fetched_courses.count).to eq 1
        expect(fetched_courses.first.primary_enrollment_role).to eq @role
      end
    end
  end

  it "deletes system generated pseudonyms on delete" do
    user_with_managed_pseudonym
    expect(@pseudonym).to be_managed_password
    expect(@user.workflow_state).to eq "pre_registered"
    @user.destroy
    expect(@user.workflow_state).to eq "deleted"
    @user.reload
    expect(@user.workflow_state).to eq "deleted"
  end

  it "destroys associated active eportfolios upon soft-deletion" do
    user = User.create
    user.eportfolios.create!
    expect { user.destroy }.to change {
      user.reload.eportfolios.active.count
    }.from(1).to(0)
  end

  it "destroys associated active eportfolios when removed from root account" do
    user = User.create
    user.eportfolios.create!
    expect { user.remove_from_root_account(Account.default) }.to change {
      user.reload.eportfolios.active.count
    }.from(1).to(0)
  end

  it "records deleted_at" do
    user = User.create
    user.destroy
    expect(user.deleted_at).not_to be_nil
  end

  describe "can_masquerade?" do
    it "allows self" do
      user = user_with_pseudonym(username: "nobody1@example.com")
      expect(user.can_masquerade?(user, Account.default)).to be_truthy
    end

    it "does not allow other users" do
      user1 = user_with_pseudonym(username: "nobody1@example.com")
      user2 = user_with_pseudonym(username: "nobody2@example.com")

      expect(user1.can_masquerade?(user2, Account.default)).to be_falsey
      expect(user2.can_masquerade?(user1, Account.default)).to be_falsey
    end

    context "when course admin role masquerade permission check feature preview is enabled" do
      before(:once) do
        @account = Account.default
        @account.enable_feature!(:course_admin_role_masquerade_permission_check)
      end

      it "calls #includes_subset_of_course_admin_permissions? if self is a course admin user" do
        course_admin = user_with_pseudonym(username: "nobody@example.com")
        course_with_user("TeacherEnrollment", user: course_admin)
        admin = user_with_pseudonym(username: "nobody2@example.com")
        @account.account_users.create!(user: admin)
        expect(course_admin).to receive(:includes_subset_of_course_admin_permissions?).once.and_return(false)
        expect(course_admin).not_to receive(:has_subset_of_account_permissions?)
        expect(course_admin.can_masquerade?(admin, @account)).to be false
      end

      it "checks both account and course permissions if masquerade target is a teacher and an account admin" do
        super_teacher = user_with_pseudonym(username: "nobody@example.com")
        course_with_user("TeacherEnrollment", user: super_teacher)
        @account.account_users.create!(user: super_teacher)
        admin = user_with_pseudonym(username: "nobody2@example.com")
        @account.account_users.create!(user: admin)
        expect(super_teacher).to receive(:includes_subset_of_course_admin_permissions?).once.and_return(true)
        expect(super_teacher).to receive(:has_subset_of_account_permissions?).once.and_return(false)
        expect(super_teacher.can_masquerade?(admin, @account)).to be false
      end

      it "does not allow restricted admins to become course admins with elevated permissions" do
        user = user_with_pseudonym(username: "nobody1@example.com")
        course_admin = course_with_user("TeacherEnrollment").user
        restricted_admin = user_with_pseudonym(username: "nobody2@example.com")
        role = custom_account_role("Restricted", account: @account)
        account_admin_user_with_role_changes(
          user: restricted_admin,
          role:,
          role_changes: { become_user: true, view_all_grades: false }
        )
        expect(user.can_masquerade?(restricted_admin, @account)).to be_truthy
        expect(course_admin.can_masquerade?(restricted_admin, @account)).to be_falsey
      end

      describe ".all_course_admin_type_permissions_for" do
        let(:user) { user_factory }
        let(:role1) { custom_teacher_role("Custom Teacher Role", account: @account) }
        let(:role2) { custom_designer_role("Custom Designer Role", account: @account) }

        it "handles multiple course admin type roles" do
          course_with_user("TeacherEnrollment", user:, active_all: true)
          course_with_user("TeacherEnrollment", user:, role: role1, active_all: true)
          course_with_user("DesignerEnrollment", user:, role: role2, active_all: true)

          permissions = User.all_course_admin_type_permissions_for(user)

          # Teacher roles
          expect(permissions[:view_all_grades]).to be_truthy
          expect(permissions[:read_sis]).to be_truthy
          # Teacher + Designer roles
          expect(permissions[:manage_wiki_create]).to be_truthy
          expect(permissions[:manage_wiki_delete]).to be_truthy
        end

        it "excludes course admin enrollments that are not active" do
          course_with_user("TeacherEnrollment", user:)

          permissions = User.all_course_admin_type_permissions_for(user)
          expect(permissions.values.all?(&:empty?)).to be_truthy
        end

        it "excludes non course admin type roles" do
          course_with_user("StudentEnrollment", user:, active_all: true)

          permissions = User.all_course_admin_type_permissions_for(user)
          expect(permissions.values.all?(&:empty?)).to be_truthy
        end

        it "returns an initialized permission hash even if no enrollments are present" do
          permissions = User.all_course_admin_type_permissions_for(user)

          expect(permissions.values.all?(&:empty?)).to be_truthy
        end
      end

      describe "#includes_subset_of_course_admin_permissions?" do
        let(:masquerader) { User.new }
        let(:masqueradee) { User.new }

        it "returns true if masqueradee is the masquerader" do
          expect(masqueradee.includes_subset_of_course_admin_permissions?(masqueradee, nil)).to be_truthy
        end

        it "returns false if the account is not a root account" do
          account = double(root_account?: false)
          expect(masqueradee.includes_subset_of_course_admin_permissions?(masquerader, account)).to be_falsey
        end

        it "is true when all permissions for current user are subsets of target user" do
          account = double(root_account?: true)
          masquerader_permissions = { become_user: [true], view_all_grades: [true] }
          masqueradee_permissions = { view_all_grades: [true] }
          allow(AccountUser).to receive(:all_permissions_for).and_return(masquerader_permissions)
          allow(User).to receive(:all_course_admin_type_permissions_for).and_return(masqueradee_permissions)

          expect(masqueradee.includes_subset_of_course_admin_permissions?(masquerader, account)).to be_truthy
        end

        it "is false when any permission for current user is not a subset of target user" do
          account = double(root_account?: true)
          masquerader_permissions = { become_user: [true], view_all_grades: [] }
          masqueradee_permissions = { view_all_grades: [true] }
          allow(AccountUser).to receive(:all_permissions_for).and_return(masquerader_permissions)
          allow(User).to receive(:all_course_admin_type_permissions_for).and_return(masqueradee_permissions)

          expect(masqueradee.includes_subset_of_course_admin_permissions?(masquerader, account)).to be_falsey
        end
      end
    end

    it "allows site and account admins" do
      user = user_with_pseudonym(username: "nobody1@example.com")
      @admin = user_with_pseudonym(username: "nobody2@example.com")
      @site_admin = user_with_pseudonym(username: "nobody3@example.com", account: Account.site_admin)
      Account.site_admin.account_users.create!(user: @site_admin)
      Account.default.account_users.create!(user: @admin)
      expect(user.can_masquerade?(@site_admin, Account.default)).to be_truthy
      expect(@admin.can_masquerade?(@site_admin, Account.default)).to be_truthy
      expect(user.can_masquerade?(@admin, Account.default)).to be_truthy
      expect(@admin.can_masquerade?(@admin, Account.default)).to be_truthy
      expect(@admin.can_masquerade?(user, Account.default)).to be_falsey
      expect(@site_admin.can_masquerade?(@site_admin, Account.default)).to be_truthy
      expect(@site_admin.can_masquerade?(user, Account.default)).to be_falsey
      expect(@site_admin.can_masquerade?(@admin, Account.default)).to be_falsey
    end

    it "does not allow restricted admins to become full admins" do
      user = user_with_pseudonym(username: "nobody1@example.com")
      @restricted_admin = user_with_pseudonym(username: "nobody3@example.com")
      role = custom_account_role("Restricted", account: Account.default)
      account_admin_user_with_role_changes(user: @restricted_admin, role:, role_changes: { become_user: true })
      @admin = user_with_pseudonym(username: "nobody2@example.com")
      Account.default.account_users.create!(user: @admin)
      expect(user.can_masquerade?(@restricted_admin, Account.default)).to be_truthy
      expect(@admin.can_masquerade?(@restricted_admin, Account.default)).to be_falsey
      expect(@restricted_admin.can_masquerade?(@admin, Account.default)).to be_truthy
    end

    it "allows to admin even if user is in multiple accounts" do
      user = user_with_pseudonym(username: "nobody1@example.com")
      @account2 = Account.create!
      user.pseudonyms.create!(unique_id: "nobodyelse@example.com", account: @account2)
      @admin = user_with_pseudonym(username: "nobody2@example.com")
      @site_admin = user_with_pseudonym(username: "nobody3@example.com")
      Account.default.account_users.create!(user: @admin)
      Account.site_admin.account_users.create!(user: @site_admin)
      expect(user.can_masquerade?(@admin, Account.default)).to be_truthy
      expect(user.can_masquerade?(@admin, @account2)).to be_falsey
      expect(user.can_masquerade?(@site_admin, Account.default)).to be_truthy
      expect(user.can_masquerade?(@site_admin, @account2)).to be_truthy
      @account2.account_users.create!(user: @admin)
    end

    it "allows site admin when they don't otherwise qualify for :create_courses" do
      user_with_pseudonym(username: "nobody1@example.com")
      @admin = user_with_pseudonym(username: "nobody2@example.com")
      @site_admin = user_with_pseudonym(username: "nobody3@example.com", account: Account.site_admin)
      Account.default.account_users.create!(user: @admin)
      Account.site_admin.account_users.create!(user: @site_admin)
      course_factory
      @course.enroll_teacher(@admin)
      Account.default.update_attribute(:settings, { teachers_can_create_courses: true })
      expect(@admin.can_masquerade?(@site_admin, Account.default)).to be_truthy
    end

    it "allows teacher to become student view student" do
      course_with_teacher(active_all: true)
      @fake_student = @course.student_view_student
      expect(@fake_student.can_masquerade?(@teacher, Account.default)).to be_truthy
    end

    it "doesn't allow teacher to become student view of random student" do
      course_with_teacher(active_all: true)
      @fake_student = user_factory
      expect(@fake_student.can_masquerade?(@teacher, Account.default)).to be_falsey
    end

    it "doesn't allow fake student to become teacher" do
      course_with_teacher(active_all: true)
      @fake_student = @course.student_view_student
      expect(@teacher.can_masquerade?(@fake_student, Account.default)).to be_falsey
    end
  end

  describe "#has_subset_of_account_permissions?" do
    let(:user) { User.new }
    let(:other_user) { User.new }

    it "returns true for self" do
      expect(user.has_subset_of_account_permissions?(user, nil)).to be_truthy
    end

    it "is false if the account is not a root account" do
      expect(user.has_subset_of_account_permissions?(other_user, double(root_account?: false))).to be_falsey
    end

    it "is true if there are no account users for this root account" do
      account = double(root_account?: true, cached_all_account_users_for: [])
      expect(user.has_subset_of_account_permissions?(other_user, account)).to be_truthy
    end

    it "is true when all account_users for current user are subsets of target user" do
      account = double(root_account?: true, cached_all_account_users_for: [double(is_subset_of?: true)])
      expect(user.has_subset_of_account_permissions?(other_user, account)).to be_truthy
    end

    it "is false when any account_user for current user is not a subset of target user" do
      account = double(root_account?: true, cached_all_account_users_for: [double(is_subset_of?: false)])
      expect(user.has_subset_of_account_permissions?(other_user, account)).to be_falsey
    end
  end

  context "check_courses_right?" do
    before :once do
      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_all: true)
      @teacher1 = @teacher
      @student1 = @student
      @active_course = @course

      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_all: true)
      @teacher2 = @teacher
      @student2 = @student
      @concluded_course = @course
      @concluded_course.complete!
    end

    it "requires parameters" do
      expect(@student1.check_courses_right?(nil, :some_right)).to be_falsey
      expect(@student1.check_courses_right?(@teacher1, nil)).to be_falsey
    end

    it "checks both active and concluded courses" do
      expect(@student1.check_courses_right?(@teacher1, :manage_wiki_create)).to be_truthy
      expect(@student1.check_courses_right?(@teacher1, :manage_wiki_update)).to be_truthy
      expect(@student1.check_courses_right?(@teacher1, :manage_wiki_delete)).to be_truthy
      expect(@student2.check_courses_right?(@teacher2, :read_forum)).to be_truthy
      @concluded_course.grants_right?(@teacher2, :manage_wiki)
    end

    it "allows for narrowing courses by enrollments" do
      expect(@student2.check_courses_right?(@teacher2, :manage_account_memberships, @student2.enrollments.concluded)).to be_falsey
    end

    context "sharding" do
      specs_require_sharding

      it "works cross-shard" do
        @shard1.activate do
          account = Account.create!
          course_with_teacher(account:, active_all: true)
          course_with_student(course: @course, user: @student1, active_all: true)
          expect(@student1.check_courses_right?(@teacher, :read_forum)).to be true
        end
      end
    end
  end

  context "search_messageable_users" do
    before(:once) do
      @admin = user_model
      @student = user_model
      tie_user_to_account(@admin, role: admin_role)
      role = custom_account_role("CustomStudent", account: Account.default)
      tie_user_to_account(@student, role:)
      set_up_course_with_users
    end

    def set_up_course_with_users
      @course = course_model(name: "the course")
      @this_section_teacher = @teacher
      @course.offer!

      @this_section_user = user_model
      @this_section_user_enrollment = @course.enroll_user(@this_section_user, "StudentEnrollment", enrollment_state: "active")

      @other_section_user = user_model
      @other_section = @course.course_sections.create
      @course.enroll_user(@other_section_user, "StudentEnrollment", enrollment_state: "active", section: @other_section)
      @other_section_teacher = user_model
      @course.enroll_user(@other_section_teacher, "TeacherEnrollment", enrollment_state: "active", section: @other_section)

      @group = @course.groups.create(name: "the group")
      @group.users = [@this_section_user]

      @unrelated_user = user_model

      @deleted_user = user_model(name: "deleted")
      @course.enroll_user(@deleted_user, "StudentEnrollment", enrollment_state: "active")
      @deleted_user.destroy
    end

    # convenience to search and then get the first page. none of these specs
    # should be putting more than a handful of users into the search results...
    # right?
    def search_messageable_users(viewing_user, *args)
      viewing_user.address_book.search_users(*args).paginate(page: 1, per_page: 20)
    end

    it "does not include users from other sections if visibility is limited to sections" do
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active", limit_privileges_to_course_section: true)
      messageable_users = search_messageable_users(@student).map(&:id)
      expect(messageable_users).to include @this_section_user.id
      expect(messageable_users).not_to include @other_section_user.id

      messageable_users = search_messageable_users(@student, context: "course_#{@course.id}").map(&:id)
      expect(messageable_users).to include @this_section_user.id
      expect(messageable_users).not_to include @other_section_user.id

      messageable_users = search_messageable_users(@student, context: "section_#{@other_section.id}").map(&:id)
      expect(messageable_users).to be_empty
    end

    it "lets students message the entire class by default" do
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

      expect(search_messageable_users(@student, context: "course_#{@course.id}").map(&:id).sort)
        .to eql [@student, @this_section_user, @this_section_teacher, @other_section_user, @other_section_teacher].map(&:id).sort
    end

    it "does not let users message the entire class if they cannot send_messages" do
      RoleOverride.create!(context: @course.account,
                           permission: "send_messages",
                           role: student_role,
                           enabled: false)
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

      # can only message self or the admins
      expect(search_messageable_users(@student, context: "course_#{@course.id}").map(&:id).sort)
        .to eql [@student, @this_section_teacher, @other_section_teacher].map(&:id).sort
    end

    it "does not include deleted users" do
      expect(search_messageable_users(@student).map(&:id)).not_to include(@deleted_user.id)
      expect(search_messageable_users(@student, search: @deleted_user.name).map(&:id)).to be_empty
      expect(search_messageable_users(@student, strict_checks: false).map(&:id)).not_to include(@deleted_user.id)
      expect(search_messageable_users(@student, strict_checks: false, search: @deleted_user.name).map(&:id)).to be_empty
    end

    it "includes deleted iff strict_checks=false" do
      expect(@student.load_messageable_user(@deleted_user.id, strict_checks: false)).not_to be_nil
      expect(@student.load_messageable_user(@deleted_user.id)).to be_nil
    end

    it "only includes users from the specified section" do
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
      messageable_users = search_messageable_users(@student, context: "section_#{@course.default_section.id}").map(&:id)
      expect(messageable_users).to include @this_section_user.id
      expect(messageable_users).not_to include @other_section_user.id

      messageable_users = search_messageable_users(@student, context: "section_#{@other_section.id}").map(&:id)
      expect(messageable_users).not_to include @this_section_user.id
      expect(messageable_users).to include @other_section_user.id
    end

    it "returns users for a specified group if the receiver can access the group" do
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

      expect(search_messageable_users(@this_section_user, context: "group_#{@group.id}").map(&:id)).to eql [@this_section_user.id]
      # student can see it too, even though he's not in the group (since he can view the roster)
      expect(search_messageable_users(@student, context: "group_#{@group.id}").map(&:id)).to eql [@this_section_user.id]
    end

    it "respects section visibility when returning users for a specified group" do
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active", limit_privileges_to_course_section: true)

      @group.users << @other_section_user

      expect(search_messageable_users(@this_section_user, context: "group_#{@group.id}").map(&:id).sort).to eql [@this_section_user.id, @other_section_user.id]
      expect(@this_section_user.count_messageable_users_in_group(@group)).to be 2
      # student can only see people in his section
      expect(search_messageable_users(@student, context: "group_#{@group.id}").map(&:id)).to eql [@this_section_user.id]
      expect(@student.count_messageable_users_in_group(@group)).to be 1
    end

    it "only shows admins and the observed if the receiver is an observer" do
      @course.enroll_user(@admin, "TeacherEnrollment", enrollment_state: "active")
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

      observer = user_model

      enrollment = @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
      enrollment.associated_user_id = @student.id
      enrollment.save

      messageable_users = search_messageable_users(observer).map(&:id)
      expect(messageable_users).to include @admin.id
      expect(messageable_users).to include @student.id
      expect(messageable_users).not_to include @this_section_user.id
      expect(messageable_users).not_to include @other_section_user.id
    end

    it "does not show non-linked observers to students" do
      @course.enroll_user(@admin, "TeacherEnrollment", enrollment_state: "active")
      student1, student2 = user_model, user_model
      @course.enroll_user(student1, "StudentEnrollment", enrollment_state: "active")
      @course.enroll_user(student2, "StudentEnrollment", enrollment_state: "active")

      observer = user_model
      enrollment = @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
      enrollment.associated_user_id = student1.id
      enrollment.save

      expect(search_messageable_users(student1).map(&:id)).to include observer.id
      expect(student1.count_messageable_users_in_course(@course)).to be 8
      expect(search_messageable_users(student2).map(&:id)).not_to include observer.id
      expect(student2.count_messageable_users_in_course(@course)).to be 7
    end

    it "includes all shared contexts and enrollment information" do
      @first_course = @course
      @first_course.enroll_user(@this_section_user, "TaEnrollment", enrollment_state: "active")
      @first_course.enroll_user(@admin, "TeacherEnrollment", enrollment_state: "active")

      @other_course = course_model
      @other_course.offer!
      @other_course.enroll_user(@admin, "TeacherEnrollment", enrollment_state: "active")
      # other_section_user is a teacher in one course, student in another
      @other_course.enroll_user(@other_section_user, "TeacherEnrollment", enrollment_state: "active")

      address_book = @admin.address_book
      search_messageable_users(@admin)
      common_courses = address_book.common_courses(@this_section_user)
      expect(common_courses.keys).to include @first_course.id
      expect(common_courses[@first_course.id].sort).to eql ["StudentEnrollment", "TaEnrollment"]

      common_courses = address_book.common_courses(@other_section_user)
      expect(common_courses.keys).to include @first_course.id
      expect(common_courses[@first_course.id].sort).to eql ["StudentEnrollment"]
      expect(common_courses.keys).to include @other_course.id
      expect(common_courses[@other_course.id].sort).to eql ["TeacherEnrollment"]
    end

    it "includes users with no shared contexts iff admin" do
      expect(search_messageable_users(@admin).map(&:id)).to include(@student.id)
      expect(search_messageable_users(@student).map(&:id)).not_to include(@admin.id)
    end

    it "does not do admin catch-all if specific contexts requested" do
      course1 = course_model
      course2 = course_model
      course2.offer!

      enrollment = course2.enroll_teacher(@admin)
      enrollment.workflow_state = "active"
      enrollment.save
      @admin.reload

      enrollment = course2.enroll_student(@student)
      enrollment.workflow_state = "active"
      enrollment.save

      expect(search_messageable_users(@admin, context: "course_#{course1.id}").map(&:id)).not_to include(@student.id)
      expect(search_messageable_users(@admin, context: "course_#{course2.id}").map(&:id)).to include(@student.id)
      expect(search_messageable_users(@student, context: "course_#{course2.id}").map(&:id)).to include(@admin.id)
    end

    it "does not rank results by default" do
      @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

      # ordered by name (all the same), then id
      expect(search_messageable_users(@student).map(&:id))
        .to eql [@student.id, @this_section_teacher.id, @this_section_user.id, @other_section_user.id, @other_section_teacher.id]
    end

    context "concluded enrollments" do
      it "returns concluded enrollments" do # i.e. you can do a bare search for people who used to be in your class
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        @this_section_user_enrollment.conclude

        expect(search_messageable_users(@this_section_user).map(&:id)).to include @this_section_user.id
        expect(search_messageable_users(@student).map(&:id)).to include @this_section_user.id
      end

      it "does not return concluded student enrollments in the course" do # when browsing a course you should not see concluded enrollments
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        @course.complete!

        expect(search_messageable_users(@this_section_user, context: "course_#{@course.id}").map(&:id)).not_to include @this_section_user.id
        # if the course was a concluded, a student should be able to browse it and message an admin (if if the admin's enrollment concluded too)
        expect(search_messageable_users(@this_section_user, context: "course_#{@course.id}").map(&:id)).to include @this_section_teacher.id
        expect(@this_section_user.count_messageable_users_in_course(@course)).to be 2 # just the admins
        expect(search_messageable_users(@student, context: "course_#{@course.id}").map(&:id)).not_to include @this_section_user.id
        expect(search_messageable_users(@student, context: "course_#{@course.id}").map(&:id)).to include @this_section_teacher.id
        expect(@student.count_messageable_users_in_course(@course)).to be 2
      end

      it "users with concluded enrollments should not be messageable" do
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        expect(search_messageable_users(@student, context: "group_#{@group.id}").map(&:id)).to eql [@this_section_user.id]
        expect(@student.count_messageable_users_in_group(@group)).to be 1
        @this_section_user_enrollment.conclude

        expect(search_messageable_users(@this_section_user, context: "group_#{@group.id}").map(&:id)).to eql []
        expect(@this_section_user.count_messageable_users_in_group(@group)).to be 0
        expect(search_messageable_users(@student, context: "group_#{@group.id}").map(&:id)).to eql []
        expect(@student.count_messageable_users_in_group(@group)).to be 0
      end
    end

    context "weak_checks" do
      it "optionally shows invited enrollments" do
        course_factory(active_all: true)
        student_in_course(user_state: "creation_pending")
        expect(search_messageable_users(@teacher, weak_checks: true).map(&:id)).to include @student.id
      end

      it "optionally shows pending enrollments in unpublished courses" do
        course_factory
        teacher_in_course(active_all: true)
        student_in_course
        expect(search_messageable_users(@teacher, weak_checks: true, context: @course.asset_string).map(&:id)).to include @student.id
      end
    end
  end

  context "tabs_available" do
    before(:once) { Account.default }

    it "does not include unconfigured external tools" do
      tool = Account.default.context_external_tools.new(consumer_key: "bob", shared_secret: "bob", name: "bob", domain: "example.com")
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:user_navigation)).to be false
      user_model
      tabs = @user.profile.tabs_available(@user, root_account: Account.default)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)
    end

    it "includes configured external tools" do
      tool = Account.default.context_external_tools.new(consumer_key: "bob", shared_secret: "bob", name: "bob", domain: "example.com")
      tool.user_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:user_navigation)).to be true
      user_model
      tabs = @user.profile.tabs_available(@user, root_account: Account.default)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:href]).to eq :user_external_tool_path
      expect(tab[:args]).to eq [@user.id, tool.id]
      expect(tab[:label]).to eq "Example URL"
    end
  end

  context "avatars" do
    before :once do
      user_model
    end

    it "finds only users with avatars set" do
      @user.avatar_state = "submitted"
      @user.save!
      expect(User.with_avatar_state("submitted").count).to eq 0
      expect(User.with_avatar_state("any").count).to eq 0
      @user.avatar_image_url = "http://www.example.com"
      @user.save!
      expect(User.with_avatar_state("submitted").count).to eq 1
      expect(User.with_avatar_state("any").count).to eq 1
    end

    it "clears avatar state when assigning by service that no longer exists" do
      @user.avatar_image_url = "http://www.example.com"
      @user.avatar_image = { "type" => "twitter" }
      expect(@user.avatar_image_url).to be_nil
    end

    it "does not allow external urls to be assigned" do
      @user.avatar_image = { "type" => "external", "url" => "http://www.example.com/image.jpg" }
      @user.save!
      expect(@user.reload.avatar_image_url).to be_nil
    end

    it "allows external urls that match avatar_external_url_patterns to be assigned" do
      @user.avatar_image = { "type" => "external", "url" => "https://www.instructure.com/image.jpg" }
      @user.save!
      expect(@user.reload.avatar_image_url).to eq "https://www.instructure.com/image.jpg"
    end

    it "does not allow external urls that do not match avatar_external_url_patterns to be assigned (apple.com)" do
      @user.avatar_image = { "type" => "external", "url" => "https://apple.com/image.jpg" }
      @user.save!
      expect(@user.reload.avatar_image_url).to be_nil
    end

    it "does not allow external urls that do not match avatar_external_url_patterns to be assigned (ddinstructure.com)" do
      @user.avatar_image = { "type" => "external", "url" => "https://ddinstructure.com/image" }
      @user.save!
      expect(@user.reload.avatar_image_url).to be_nil
    end

    it "does not allow external urls that do not match avatar_external_url_patterns to be assigned (3510111291#instructure.com)" do
      @user.avatar_image = { "type" => "external", "url" => "https://3510111291#sdf.instructure.com/image" }
      @user.save!
      expect(@user.reload.avatar_image_url).to be_nil
    end

    it "allows gravatar urls to be assigned" do
      @user.avatar_image = { "type" => "gravatar", "url" => "http://www.gravatar.com/image.jpg" }
      @user.save!
      expect(@user.reload.avatar_image_url).to eq "http://www.gravatar.com/image.jpg"
    end

    it "does not allow non gravatar urls to be assigned (ddgravatar.com)" do
      @user.avatar_image = { "type" => "external", "url" => "http://ddgravatar.com/@google.com" }
      @user.save!
      expect(@user.reload.avatar_image_url).to be_nil
    end

    it "does not allow non gravatar external urls to be assigned (3510111291#secure.gravatar.com)" do
      @user.avatar_image = { "type" => "external", "url" => "http://3510111291#secure.gravatar.com/@google.com" }
      @user.save!
      expect(@user.reload.avatar_image_url).to be_nil
    end

    it "returns a useful avatar_fallback_url" do
      allow(HostUrl).to receive(:protocol).and_return("https")

      expect(User.avatar_fallback_url).to eq(
        "https://#{HostUrl.default_host}/images/messages/avatar-50.png"
      )
      expect(User.avatar_fallback_url("/somepath")).to eq(
        "https://#{HostUrl.default_host}/somepath"
      )
      expect(HostUrl).to receive(:default_host).and_return("somedomain:3000")
      expect(User.avatar_fallback_url("/path")).to eq(
        "https://somedomain:3000/path"
      )
      expect(User.avatar_fallback_url("//somedomain/path")).to eq(
        "https://somedomain/path"
      )
      expect(User.avatar_fallback_url("http://somedomain/path")).to eq(
        "http://somedomain/path"
      )
      expect(User.avatar_fallback_url("http://somedomain:3000/path")).to eq(
        "http://somedomain:3000/path"
      )
      expect(User.avatar_fallback_url(nil, OpenObject.new(host: "foo", protocol: "http://"))).to eq(
        "http://foo/images/messages/avatar-50.png"
      )
      expect(User.avatar_fallback_url("/somepath", OpenObject.new(host: "bar", protocol: "https://"))).to eq(
        "https://bar/somepath"
      )
      expect(User.avatar_fallback_url("//somedomain/path", OpenObject.new(host: "bar", protocol: "https://"))).to eq(
        "https://somedomain/path"
      )
      expect(User.avatar_fallback_url("http://somedomain/path", OpenObject.new(host: "bar", protocol: "https://"))).to eq(
        "http://somedomain/path"
      )
      expect(User.avatar_fallback_url("http://localhost/path", OpenObject.new(host: "bar", protocol: "https://"))).to eq(
        "https://bar/path"
      )
    end

    describe "#clear_avatar_image_url_with_uuid" do
      before :once do
        @user.avatar_image_url = "1234567890ABCDEF"
        @user.save!
      end

      it "raises ArgumentError when uuid nil or blank" do
        expect { @user.clear_avatar_image_url_with_uuid(nil) }.to raise_error(ArgumentError, "'uuid' is required and cannot be blank")
        expect { @user.clear_avatar_image_url_with_uuid("") }.to raise_error(ArgumentError, "'uuid' is required and cannot be blank")
        expect { @user.clear_avatar_image_url_with_uuid("  ") }.to raise_error(ArgumentError, "'uuid' is required and cannot be blank")
      end

      it "clears avatar_image_url when uuid matches" do
        @user.clear_avatar_image_url_with_uuid("1234567890ABCDEF")
        expect(@user.avatar_image_url).to be_nil
        expect(@user.changed?).to be false # should be saved
      end

      it "does not clear avatar_image_url when no match" do
        @user.clear_avatar_image_url_with_uuid("NonMatchingText")
        expect(@user.avatar_image_url).to eq "1234567890ABCDEF"
      end

      it "does not error when avatar_image_url is nil" do
        @user.avatar_image_url = nil
        @user.save!
        expect { @user.clear_avatar_image_url_with_uuid("something") }.not_to raise_error
        expect(@user.avatar_image_url).to be_nil
      end
    end
  end

  it "finds sections for course" do
    course_with_student
    expect(@student.sections_for_course(@course)).to include @course.default_section
  end

  describe "name_parts" do
    it "infers name parts" do
      expect(User.name_parts("Cody Cutrer")).to eq ["Cody", "Cutrer", nil]
      expect(User.name_parts("  Cody  Cutrer   ")).to eq ["Cody", "Cutrer", nil]
      expect(User.name_parts("Cutrer, Cody")).to eq ["Cody", "Cutrer", nil]
      expect(User.name_parts("Cutrer, Cody",
                             likely_already_surname_first: true)).to eq ["Cody", "Cutrer", nil]
      expect(User.name_parts("Cutrer, Cody Houston")).to eq ["Cody Houston", "Cutrer", nil]
      expect(User.name_parts("Cutrer, Cody Houston",
                             likely_already_surname_first: true)).to eq ["Cody Houston", "Cutrer", nil]
      expect(User.name_parts("St. Clair, John")).to eq ["John", "St. Clair", nil]
      expect(User.name_parts("St. Clair, John",
                             likely_already_surname_first: true)).to eq ["John", "St. Clair", nil]
      # sorry, can't figure this out
      expect(User.name_parts("John St. Clair")).to eq ["John St.", "Clair", nil]
      expect(User.name_parts("Jefferson Thomas Cutrer IV")).to eq ["Jefferson Thomas", "Cutrer", "IV"]
      expect(User.name_parts("Jefferson Thomas Cutrer, IV")).to eq ["Jefferson Thomas", "Cutrer", "IV"]
      expect(User.name_parts("Cutrer, Jefferson, IV")).to eq %w[Jefferson Cutrer IV]
      expect(User.name_parts("Cutrer, Jefferson, IV",
                             likely_already_surname_first: true)).to eq %w[Jefferson Cutrer IV]
      expect(User.name_parts("Cutrer, Jefferson IV")).to eq %w[Jefferson Cutrer IV]
      expect(User.name_parts("Cutrer, Jefferson IV",
                             likely_already_surname_first: true)).to eq %w[Jefferson Cutrer IV]
      expect(User.name_parts(nil)).to eq [nil, nil, nil]
      expect(User.name_parts("Bob")).to eq ["Bob", nil, nil]
      expect(User.name_parts("Ho, Chi, Min")).to eq ["Chi Min", "Ho", nil]
      expect(User.name_parts("Ho, Chi, Min")).to eq ["Chi Min", "Ho", nil]
      # sorry, don't understand cultures that put the surname first
      # they should just manually specify their sort name
      expect(User.name_parts("Ho Chi Min")).to eq ["Ho Chi", "Min", nil]
      expect(User.name_parts("")).to eq [nil, nil, nil]
      expect(User.name_parts("John Doe")).to eq ["John", "Doe", nil]
      expect(User.name_parts("Junior")).to eq ["Junior", nil, nil]
      expect(User.name_parts("John St. Clair", prior_surname: "St. Clair")).to eq ["John", "St. Clair", nil]
      expect(User.name_parts("John St. Clair", prior_surname: "Cutrer")).to eq ["John St.", "Clair", nil]
      expect(User.name_parts("St. Clair", prior_surname: "St. Clair")).to eq [nil, "St. Clair", nil]
      expect(User.name_parts("St. Clair,")).to eq [nil, "St. Clair", nil]
      # don't get confused by given names that look like suffixes
      expect(User.name_parts("Duing, Vi")).to eq ["Vi", "Duing", nil]
      # we can't be perfect. don't know what to do with this
      expect(User.name_parts("Duing Chi Min, Vi")).to eq ["Duing Chi", "Min", "Vi"]
      # unless we thought it was already last name first
      expect(User.name_parts("Duing Chi Min, Vi",
                             likely_already_surname_first: true)).to eq ["Vi", "Duing Chi Min", nil]
    end

    it "keeps the sortable_name up to date if all that changed is the name" do
      u = User.new
      u.name = "Cody Cutrer"
      u.save!
      expect(u.sortable_name).to eq "Cutrer, Cody"

      u.name = "Bracken Mosbacker"
      u.save!
      expect(u.sortable_name).to eq "Mosbacker, Bracken"

      u.name = "John St. Clair"
      u.sortable_name = "St. Clair, John"
      u.save!
      expect(u.sortable_name).to eq "St. Clair, John"

      u.name = "Matthew St. Clair"
      u.save!
      expect(u.sortable_name).to eq "St. Clair, Matthew"

      u.name = "St. Clair"
      u.save!
      expect(u.sortable_name).to eq "St. Clair,"
    end
  end

  context "group_member_json" do
    before :once do
      @account = Account.default
      @enrollment = course_with_student(active_all: true)
      @section = @enrollment.course_section
      @student.sortable_name = "Doe, John"
      @student.short_name = "Johnny"
      @student.save
    end

    it "includes user_id, name, and display_name" do
      expect(@student.group_member_json(@account)).to eq({
                                                           user_id: @student.id,
                                                           name: "Doe, John",
                                                           display_name: "Johnny"
                                                         })
    end

    it "includes course section (section_id and section_code) if appropriate" do
      expect(@student.group_member_json(@account)).to eq({
                                                           user_id: @student.id,
                                                           name: "Doe, John",
                                                           display_name: "Johnny"
                                                         })

      expect(@student.group_member_json(@course)).to eq({
                                                          user_id: @student.id,
                                                          name: "Doe, John",
                                                          display_name: "Johnny",
                                                          sections: [{
                                                            section_id: @section.id,
                                                            section_code: @section.section_code
                                                          }]
                                                        })
    end
  end

  describe "menu_courses" do
    it "includes temporary invitations" do
      user_with_pseudonym(active_all: 1)
      @user1 = @user
      user_factory
      @user2 = @user
      @user2.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user2, { username: @cc.path })
      course_factory(active_all: true)
      @course.enroll_user(@user2)

      expect(@user1.menu_courses).to eq [@course]
    end

    context "with favoriting" do
      before :once do
        k5_account = Account.create!(name: "Elementary")
        toggle_k5_setting(k5_account)
        @user = user_factory(active_all: true)

        @classic1 = course_factory(course_name: "Classic 1", active_all: true)
        @classic2 = course_factory(course_name: "Classic 2", active_all: true)
        @k51 = course_factory(course_name: "K5 1", active_all: true, account: k5_account)
        @k52 = course_factory(course_name: "K5 2", active_all: true, account: k5_account)
        @k52.homeroom_course = true
        @k52.save!
        @courses = [@classic1, @classic2, @k51, @k52]
      end

      def assert_has_courses(courses)
        menu_courses = @user.menu_courses
        expect(menu_courses.length).to eq courses.length
        courses.each do |course|
          expect(menu_courses.any? { |mc| mc.name == course.name }).to be_truthy
        end
      end

      shared_examples_for "all enrollments" do
        it "returns all courses when nothing is favorited" do
          assert_has_courses(@courses)
        end

        it "returns all courses when everything is favorited" do
          @courses.each { |c| @user.favorites.create!(context: c) }
          assert_has_courses(@courses)
        end
      end

      context "as a student" do
        before :once do
          @courses.each { |c| c.enroll_student(@user, enrollment_state: "active") }
        end

        it_behaves_like "all enrollments"

        it "returns all k5 courses even if not favorited" do
          @user.favorites.create!(context: @classic1)
          @user.favorites.create!(context: @classic2)
          assert_has_courses(@courses)
        end

        it "returns favorited classic and all k5 courses if some classic courses are favorited" do
          @user.favorites.create!(context: @classic1)
          assert_has_courses([@classic1, @k51, @k52])
        end

        it "still returns all courses if a k5 subject is favorited (ignores k5 favorites)" do
          @user.favorites.create!(context: @k51)
          assert_has_courses(@courses)
        end
      end

      context "as a teacher" do
        before :once do
          @courses.each { |c| c.enroll_teacher(@user, enrollment_state: "active") }
        end

        it_behaves_like "all enrollments"

        it "does not return unfavorited k5 courses if there's other favorited courses" do
          @user.favorites.create!(context: @classic1)
          assert_has_courses([@classic1])
        end

        it "does not return unfavorited classic courses if there's other favorited courses" do
          @user.favorites.create!(context: @k52)
          assert_has_courses([@k52])
        end
      end

      context "with mixed enrollment types" do
        it "returns favorited classic and all k5 courses where user is a student" do
          @classic1.enroll_student(@user, enrollment_state: "active")
          @k51.enroll_student(@user, enrollment_state: "active")
          @user.favorites.create!(context: @classic1)

          assert_has_courses([@classic1, @k51])
        end

        it "returns all k5 courses if user only has teacher enrollment in a classic course" do
          @classic1.enroll_teacher(@user, enrollment_state: "active")
          @classic2.enroll_student(@user, enrollment_state: "active")
          @k51.enroll_student(@user, enrollment_state: "active")
          @k52.enroll_student(@user, enrollment_state: "active")
          @user.favorites.create!(context: @classic1)

          assert_has_courses([@classic1, @k51, @k52])
        end

        it "allows users with TA enrollment to favorite a k5 course" do
          @classic1.enroll_student(@user, enrollment_state: "active")
          @classic2.enroll_student(@user, enrollment_state: "active")
          @k51.enroll_ta(@user, enrollment_state: "active")
          @k52.enroll_ta(@user, enrollment_state: "active")
          @user.favorites.create!(context: @classic1)
          @user.favorites.create!(context: @k51)

          assert_has_courses([@classic1, @k51])
        end

        it "allows users with designer enrollment to favorite a k5 course" do
          @classic1.enroll_student(@user, enrollment_state: "active")
          @classic2.enroll_student(@user, enrollment_state: "active")
          @k51.enroll_designer(@user, enrollment_state: "active")
          @k52.enroll_student(@user, enrollment_state: "active")
          @user.favorites.create!(context: @classic2)

          assert_has_courses([@classic2])
        end
      end
    end
  end

  describe "favorites" do
    before :once do
      @user = User.create!

      @courses = []
      (1..3).each do |x|
        course = course_with_student(course_name: "Course #{x}", user: @user, active_all: true).course
        @courses << course
        @user.favorites.first_or_create!(context_type: "Course", context_id: course)
      end

      @user.save!
    end

    it "defaults favorites to enrolled courses when favorite courses do not exist" do
      @user.favorites.by("Course").destroy_all
      expect(@user.menu_courses.to_set).to eq @courses.to_set
    end

    it "only includes favorite courses when set" do
      course = @courses.shift
      @user.favorites.where(context_type: "Course", context_id: course).first.destroy
      expect(@user.menu_courses.to_set).to eq @courses.to_set
    end

    context "sharding" do
      specs_require_sharding

      before do
        account2 = @shard1.activate { account_model }
        (4..6).each do |x|
          course = course_with_student(course_name: "Course #{x}", user: @user, active_all: true, account: account2).course
          @courses << course
          @user.favorites.first_or_create!(context_type: "Course", context_id: course)
        end
      end

      it "includes cross shard favorite courses" do
        expect(@user.menu_courses).to match_array(@courses)
      end

      it "works for shadow records" do
        @shard1.activate do
          @user.save_shadow_record
          # rubocop:disable Rails/WhereEquals
          @shadow = User.where("id = ?", @user.global_id).first
          # rubocop:enable Rails/WhereEquals
        end
        expect(@shadow.favorites.exists?).to be_truthy
      end
    end
  end

  describe "adding to favorites on enrollment" do
    it "doesn't add a favorite if no course favorites already exist" do
      course_with_student(active_all: true)
      expect(@student.favorites.count).to eq 0
    end

    it "adds a favorite if any course favorites already exist" do
      u = User.create!

      c1 = course_with_student(active_all: true, user: u).course
      u.favorites.create!(context_type: "Course", context_id: c1)

      c2 = course_with_student(active_all: true, user: u).course
      expect(u.favorites.where(context_type: "Course", context_id: c2).exists?).to be true
    end
  end

  describe "cached_currentish_enrollments" do
    it "includes temporary invitations" do
      user_with_pseudonym(active_all: 1)
      @user1 = @user
      user_factory
      @user2 = @user
      @user2.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user2, { username: @cc.path })
      course_factory(active_all: true)
      @enrollment = @course.enroll_user(@user2)

      expect(@user1.cached_currentish_enrollments).to eq [@enrollment]
    end

    context "sharding" do
      specs_require_sharding

      it "includes enrollments from all shards" do
        user = User.create!
        course1 = Account.default.courses.create!
        course1.offer!
        e1 = course1.enroll_student(user)
        e2 = @shard1.activate do
          account2 = Account.create!
          course2 = account2.courses.create!
          course2.offer!
          course2.enroll_student(user)
        end
        expect(user.cached_currentish_enrollments).to eq [e1, e2]
      end

      it "properly updates when using new redis cache keys" do
        skip("requires redis") unless Canvas.redis_enabled?
        enable_cache(:redis_cache_store) do
          user = User.create!
          course1 = Account.default.courses.create!(workflow_state: "available")
          e1 = course1.enroll_student(user, enrollment_state: "active")
          expect(user.cached_currentish_enrollments).to eq [e1]
          e2 = @shard1.activate do
            account2 = Account.create!
            course2 = account2.courses.create!(workflow_state: "available")
            course2.enroll_student(user, enrollment_state: "active")
          end
          expect(user.cached_currentish_enrollments).to eq [e1, e2]
        end
      end
    end
  end

  describe "#find_or_initialize_pseudonym_for_account" do
    before :once do
      @account1 = Account.create!
      @account2 = Account.create!
      @account3 = Account.create!
    end

    it "creates a copy of an existing pseudonym" do
      # from unrelated account
      user_with_pseudonym(active_all: 1, account: @account2, username: "unrelated@example.com", password: "abcdefgh")
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1)
      expect(new_pseudonym).not_to be_nil
      expect(new_pseudonym).to be_new_record
      expect(new_pseudonym.unique_id).to eq "unrelated@example.com"

      # from default account
      @user.pseudonyms.create!(unique_id: "default@example.com", password: "abcdefgh", password_confirmation: "abcdefgh")
      @user.pseudonyms.create!(account: @account3, unique_id: "preferred@example.com", password: "abcdefgh", password_confirmation: "abcdefgh")
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1)
      expect(new_pseudonym).not_to be_nil
      expect(new_pseudonym).to be_new_record
      expect(new_pseudonym.unique_id).to eq "default@example.com"

      # from site admin account
      site_admin_pseudo = @user.pseudonyms.create!(account: Account.site_admin, unique_id: "siteadmin@example.com", password: "abcdefgh", password_confirmation: "abcdefgh")
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1)
      expect(new_pseudonym).not_to be_nil
      expect(new_pseudonym).to be_new_record
      expect(new_pseudonym.unique_id).to eq "siteadmin@example.com"

      site_admin_pseudo.destroy
      @user.reload
      # from preferred account
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1, @account3)
      expect(new_pseudonym).not_to be_nil
      expect(new_pseudonym).to be_new_record
      expect(new_pseudonym.unique_id).to eq "preferred@example.com"

      # from unrelated account, if other options are not viable
      user2 = User.create!
      @account1.pseudonyms.create!(user: user2, unique_id: "preferred@example.com", password: "abcdefgh", password_confirmation: "abcdefgh")
      @user.pseudonyms.detect { |p| p.account == Account.site_admin }.update_attribute(:password_auto_generated, true)
      Account.default.authentication_providers.create!(auth_type: "cas")
      Account.default.authentication_providers.first.move_to_bottom
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1, @account3)
      expect(new_pseudonym).not_to be_nil
      expect(new_pseudonym).to be_new_record
      expect(new_pseudonym.unique_id).to eq "unrelated@example.com"
      new_pseudonym.save!
      expect(new_pseudonym.valid_password?("abcdefgh")).to be_truthy
    end

    it "does not create a new one when there are no viable candidates" do
      # no pseudonyms
      user_factory
      expect(@user.find_or_initialize_pseudonym_for_account(@account1)).to be_nil

      # auto-generated password
      @user.pseudonyms.create!(account: @account2, unique_id: "bracken@instructure.com")
      expect(@user.find_or_initialize_pseudonym_for_account(@account1)).to be_nil

      # delegated auth
      @account3.authentication_providers.create!(auth_type: "cas")
      @account3.authentication_providers.first.move_to_bottom
      expect(@account3).to be_delegated_authentication
      @user.pseudonyms.create!(account: @account3, unique_id: "jacob@instructure.com", password: "abcdefgh", password_confirmation: "abcdefgh")
      expect(@user.find_or_initialize_pseudonym_for_account(@account1)).to be_nil

      # conflict
      @user2 = User.create! { |u| u.workflow_state = "registered" }
      @user2.pseudonyms.create!(account: @account1, unique_id: "jt@instructure.com", password: "abcdefgh", password_confirmation: "abcdefgh")
      @user.pseudonyms.create!(unique_id: "jt@instructure.com", password: "ghijklmn", password_confirmation: "ghijklmn")
      expect(@user.find_or_initialize_pseudonym_for_account(@account1)).to be_nil
    end

    context "sharding" do
      specs_require_sharding

      before :once do
        @shard1.activate do
          account = Account.create!
          user_with_pseudonym(active_all: 1, account:, password: "qwertyuiop")
        end
      end

      it "copies a pseudonym from another shard" do
        p = @user.find_or_initialize_pseudonym_for_account(Account.site_admin)
        expect(p).to be_new_record
        p.save!
        expect(p.valid_password?("qwertyuiop")).to be_truthy
      end
    end
  end

  describe "can_be_enrolled_in_course?" do
    before :once do
      course_factory active_all: true
    end

    it "allows a user with a pseudonym in the course's root account" do
      user_with_pseudonym account: @course.root_account, active_all: true
      expect(@user.can_be_enrolled_in_course?(@course)).to be_truthy
    end

    it "allows a temporary user with an existing enrollment but no pseudonym" do
      @user = User.create! { |u| u.workflow_state = "creation_pending" }
      @course.enroll_student(@user)
      expect(@user.can_be_enrolled_in_course?(@course)).to be_truthy
    end

    it "does not allow a registered user with an existing enrollment but no pseudonym" do
      user_factory active_all: true
      @course.enroll_student(@user)
      expect(@user.can_be_enrolled_in_course?(@course)).to be_falsey
    end

    it "does not allow a user with neither an enrollment nor a pseudonym" do
      user_factory active_all: true
      expect(@user.can_be_enrolled_in_course?(@course)).to be_falsey
    end
  end

  describe "email_channel" do
    it "does not return retired channels" do
      u = User.create!
      communication_channel(u, { username: "retired@example.com", cc_state: "retired" })
      expect(u.email_channel).to be_nil
      active = communication_channel(u, { username: "active@example.com", active_cc: true })
      expect(u.email_channel).to eq active
    end
  end

  describe "email=" do
    it "works" do
      @user = User.create!
      @user.email = "john@example.com"
      expect(@user.communication_channels.map(&:path)).to eq ["john@example.com"]
      expect(@user.email).to eq "john@example.com"
    end

    it "doesn't create channels with empty paths" do
      @user = User.create!
      expect { @user.email = "" }.to raise_error("Validation failed: Path can't be blank, Email is invalid")
      expect(@user.communication_channels.any?).to be_falsey
    end

    it "restores retired channels" do
      @user = User.create!
      path = "john@example.com"
      communication_channel(@user, { username: path, cc_state: "retired" })
      @user.email = path
      expect(@user.communication_channels.first).to be_unconfirmed
      expect(@user.email).to eq "john@example.com"
    end

    it "allows the email casing to be updated" do
      @user = User.create!
      @user.email = "EMAIL@example.com"
      expect(@user.communication_channels.map(&:path)).to eq ["EMAIL@example.com"]
      expect(@user.email).to eq "EMAIL@example.com"
      @user.email = "email@example.com"
      expect(@user.communication_channels.map(&:path)).to eq ["email@example.com"]
      expect(@user.email).to eq "email@example.com"
    end
  end

  describe "event methods" do
    describe "upcoming_events" do
      before(:once) { course_with_teacher(active_all: true) }

      it "handles assignments where the applied due_at is nil" do
        assignment = @course.assignments.create!(title: "Should not throw",
                                                 due_at: 2.days.from_now)
        assignment2 = @course.assignments.create!(title: "Should not throw2",
                                                  due_at: 1.day.from_now)
        section = @course.course_sections.create!(name: "VDD Section")
        override = assignment.assignment_overrides.build
        override.set = section
        override.due_at = nil
        override.due_at_overridden = true
        override.save!

        events = []
        # handles comparison of nil due dates if that is what applies to the
        # user instead of failing.
        expect do
          events = @user.upcoming_events(end_at: 1.week.from_now)
        end.to_not raise_error

        expect(events.first).to eq assignment2
        expect(events.second).to eq assignment
      end

      it "doesn't show unpublished assignments" do
        assignment = @course.assignments.create!(title: "not published", due_at: 1.day.from_now)
        assignment.unpublish
        assignment2 = @course.assignments.create!(title: "published", due_at: 1.day.from_now)
        assignment2.publish
        events = @user.upcoming_events(end_at: 1.week.from_now)
        expect(events.first).to eq assignment2
      end

      it "doesn't include events for enrollments that are inactive due to date" do
        @enrollment.start_at = 1.day.ago
        @enrollment.end_at = 2.days.from_now
        @enrollment.save!
        event = @course.calendar_events.create!(title: "published", start_at: 4.days.from_now)
        expect(@user.upcoming_events).to include(event)
        Timecop.freeze(3.days.from_now) do
          EnrollmentState.recalculate_expired_states # runs periodically in background
          expect(User.find(@user.id).upcoming_events).not_to include(event) # re-find user to clear cached_contexts
        end
      end

      it "shows assignments assigned to a section in correct order" do
        assignment1 = @course.assignments.create!(title: "A1",
                                                  due_at: 1.day.from_now)
        assignment2 = @course.assignments.create!(title: "A2",
                                                  due_at: 3.days.from_now)
        assignment3 = @course.assignments.create!(title: "A3 - for a section",
                                                  due_at: 4.days.from_now)
        section = @course.course_sections.create!(name: "Section 1")
        override = assignment3.assignment_overrides.build
        override.set = section
        override.due_at = 2.days.from_now
        override.due_at_overridden = true
        override.save!

        events = @user.upcoming_events(end_at: 1.week.from_now)
        expect(events.first).to eq assignment1
        expect(events.second).to eq assignment3
        expect(events.third).to eq assignment2
      end

      context "after db section context_code filtering" do
        before do
          course_with_teacher(active_all: true)
          @student = user_factory(active_user: true)
          @sections = []
          @events = []
          3.times { @sections << @course.course_sections.create! }
          start_at = 1.day.from_now
          # create three sections and three child events that will be retrieved in the same order
          data = {}
          @sections.each_with_index do |section, i|
            data[i] = { start_at:, end_at: start_at + 1.day, context_code: section.asset_string }
            start_at += 1.day
          end
          event = @course.calendar_events.build(title: "event", child_event_data: data)
          event.updating_user = @teacher
          event.save!
          @events = event.child_events.sort_by(&:context_code)
        end

        it "is able to filter section events after fetching" do
          # trigger the after db filtering
          allow(Setting).to receive(:get).with(anything, anything).and_return("")
          allow(Setting).to receive(:get).with("filter_events_by_section_code_threshold", anything).and_return(0)
          @course.enroll_student(@student, section: @sections[1], enrollment_state: "active", allow_multiple_enrollments: true)
          expect(@student.upcoming_events(limit: 2)).to eq [@events[1]]
        end

        it "uses the old behavior as a fallback" do
          allow(Setting).to receive(:get).with(anything, anything).and_return("")
          allow(Setting).to receive(:get).with("filter_events_by_section_code_threshold", anything).and_return(0)
          # the optimized call will retrieve the first two events, and then filter them out
          # since it didn't retrieve enough events it will use the old code as a fallback
          @course.enroll_student(@student, section: @sections[2], enrollment_state: "active", allow_multiple_enrollments: true)
          expect(@student.upcoming_events(limit: 2)).to eq [@events[2]]
        end
      end
    end
  end

  describe "select_upcoming_assignments" do
    it "filters based on assignment date for asignments the user cannot delete" do
      time = Time.now + 1.day
      context = double
      assignments = [double, double, double]
      user = User.new
      allow(context).to receive(:grants_any_right?).with(user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS).and_return false
      assignments.each do |assignment|
        allow(assignment).to receive_messages(due_at: time)
        allow(assignment).to receive(:context).and_return(context)
      end
      expect(user.select_upcoming_assignments(assignments, { end_at: time })).to eq assignments
    end

    it "returns assignments that have an override between now and end_at opt" do
      assignments = [double, double, double, double]
      context = double
      Timecop.freeze(Time.utc(2013, 3, 13, 0, 0)) do
        user = User.new
        allow(context).to receive(:grants_any_right?).with(user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS).and_return true
        due_date1 = { due_at: Time.now + 1.day }
        due_date2 = { due_at: Time.now + 1.week }
        due_date3 = { due_at: 2.weeks.from_now }
        due_date4 = { due_at: nil }
        assignments.each do |assignment|
          allow(assignment).to receive(:context).and_return(context)
        end
        expect(assignments.first).to receive(:dates_hash_visible_to).with(user)
                                                                    .and_return [due_date1]
        expect(assignments.second).to receive(:dates_hash_visible_to).with(user)
                                                                     .and_return [due_date2]
        expect(assignments.third).to receive(:dates_hash_visible_to).with(user)
                                                                    .and_return [due_date3]
        expect(assignments[3]).to receive(:dates_hash_visible_to).with(user)
                                                                 .and_return [due_date4]
        upcoming_assignments = user.select_upcoming_assignments(assignments, {
                                                                  end_at: 1.week.from_now
                                                                })
        expect(upcoming_assignments).to include assignments.first
        expect(upcoming_assignments).to include assignments.second
        expect(upcoming_assignments).not_to include assignments.third
        expect(upcoming_assignments).not_to include assignments[3]
      end
    end
  end

  describe "avatar_key" do
    it "returns a valid avatar key for a valid user id" do
      expect(User.avatar_key(1)).to eq "1-#{Canvas::Security.hmac_sha1("1")[0, 10]}"
      expect(User.avatar_key("1")).to eq "1-#{Canvas::Security.hmac_sha1("1")[0, 10]}"
      expect(User.avatar_key("2")).to eq "2-#{Canvas::Security.hmac_sha1("2")[0, 10]}"
      expect(User.avatar_key("161612461246")).to eq "161612461246-#{Canvas::Security.hmac_sha1("161612461246")[0, 10]}"
    end

    it "returns '0' for an invalid user id" do
      expect(User.avatar_key(nil)).to eq "0"
      expect(User.avatar_key("")).to eq "0"
      expect(User.avatar_key(0)).to eq "0"
    end
  end

  describe "user_id_from_avatar_key" do
    it "returns a valid user id for a valid avatar key" do
      expect(User.user_id_from_avatar_key("1-#{Canvas::Security.hmac_sha1("1")[0, 10]}")).to eq "1"
      expect(User.user_id_from_avatar_key("2-#{Canvas::Security.hmac_sha1("2")[0, 10]}")).to eq "2"
      expect(User.user_id_from_avatar_key("1536394658-#{Canvas::Security.hmac_sha1("1536394658")[0, 10]}")).to eq "1536394658"
    end

    it "returns nil for an invalid avatar key" do
      expect(User.user_id_from_avatar_key("1-#{Canvas::Security.hmac_sha1("1")}")).to be_nil
      expect(User.user_id_from_avatar_key("1")).to be_nil
      expect(User.user_id_from_avatar_key("2-123456")).to be_nil
      expect(User.user_id_from_avatar_key("a")).to be_nil
      expect(User.user_id_from_avatar_key(nil)).to be_nil
      expect(User.user_id_from_avatar_key("")).to be_nil
      expect(User.user_id_from_avatar_key("-")).to be_nil
      expect(User.user_id_from_avatar_key("-159135")).to be_nil
    end
  end

  describe "order_by_sortable_name" do
    let_once :ids do
      ids = []
      ids << User.create!(name: "John Johnson")
      ids << User.create!(name: "John John")
      ids << User.create!(name: "john john")
    end

    it "sorts lexicographically" do
      ascending_sortable_names = User.order_by_sortable_name.where(id: ids).map(&:sortable_name)
      expect(ascending_sortable_names).to eq(["john, john", "John, John", "Johnson, John"])
    end

    it "sorts support direction toggle" do
      descending_sortable_names = User.order_by_sortable_name(direction: :descending)
                                      .where(id: ids).map(&:sortable_name)
      expect(descending_sortable_names).to eq(["Johnson, John", "John, John", "john, john"])
    end

    it "sorts support direction toggle with a prior select" do
      descending_sortable_names = User.select([:id, :sortable_name]).order_by_sortable_name(direction: :descending)
                                      .where(id: ids).map(&:sortable_name)
      expect(descending_sortable_names).to eq ["Johnson, John", "John, John", "john, john"]
    end

    it "sorts by the current locale" do
      I18n.with_locale(:es) do
        expect(User.sortable_name_order_by_clause).to match(/es-u-kn-true/)
        expect(User.sortable_name_order_by_clause).not_to match(/und-u-kn-true/)
      end
      I18n.with_locale(:en) do
        # english has no specific sorting rules, so use root
        expect(User.sortable_name_order_by_clause).not_to match(/en-u-kn-true/)
        expect(User.sortable_name_order_by_clause).not_to match(/es-u-kn-true/)
        expect(User.sortable_name_order_by_clause).to match(/und-u-kn-true/)
      end
    end

    describe "order_by_name" do
      let_once :ids do
        ids = []
        ids << User.create!(name: "John Johnson")
        ids << User.create!(name: "Jimmy Johns")
        ids << User.create!(name: "Jimmy John")
      end

      it "sorts lexicographically" do
        ascending_names = User.order_by_name.where(id: ids).map(&:name)
        expect(ascending_names).to eq(["Jimmy John", "Jimmy Johns", "John Johnson"])
      end

      it "sorts support direction toggle" do
        descending_names = User.order_by_name(direction: :descending)
                               .where(id: ids).map(&:name)
        expect(descending_names).to eq(["John Johnson", "Jimmy Johns", "Jimmy John"])
      end

      it "sorts support direction toggle with a prior select" do
        descending_names = User.select([:id, :name]).order_by_name(direction: :descending)
                               .where(id: ids).map(&:name)
        expect(descending_names).to eq(["John Johnson", "Jimmy Johns", "Jimmy John"])
      end

      it "sorts by the current locale" do
        I18n.with_locale(:es) do
          expect(User.name_order_by_clause).to match(/es-u-kn-true/)
          expect(User.name_order_by_clause).not_to match(/und-u-kn-true/)
        end
        I18n.with_locale(:en) do
          # english has no specific sorting rules, so use root
          expect(User.name_order_by_clause).not_to match(/en-u-kn-true/)
          expect(User.name_order_by_clause).not_to match(/es-u-kn-true/)
          expect(User.name_order_by_clause).to match(/und-u-kn-true/)
        end
      end
    end

    it "breaks ties with user id" do
      ids = Array.new(5) { User.create!(name: "Abcde").id }.sort
      expect(User.order_by_sortable_name.where(id: ids).map(&:id)).to eq(ids)
    end

    it "breaks ties in the direction of the order" do
      users = [
        User.create!(name: "Gary"),
        User.create!(name: "Gary")
      ]
      ids = users.map(&:id)

      descending_user_ids = User.where(id: ids).order_by_sortable_name(direction: :descending).map(&:id)
      expect(descending_user_ids).to eq(ids.reverse)
    end
  end

  describe "quota" do
    before(:once) { user_factory }

    it "defaults to User.default_storage_quota" do
      expect(@user.quota).to eql User.default_storage_quota
    end

    it "sums up associated root account quotas" do
      @user.associated_root_accounts << Account.create! << (a = Account.create!)
      a.update_attribute :default_user_storage_quota_mb, a.default_user_storage_quota_mb + 10
      expect(@user.quota).to eql((2 * User.default_storage_quota) + 10.megabytes)
    end
  end

  it "builds a profile if one doesn't already exist" do
    user = User.create! name: "John Johnson"
    profile = user.profile
    expect(profile.id).to be_nil
    profile.bio = "bio!"
    profile.save!
    expect(user.profile).to eq profile
  end

  describe "mfa_settings" do
    let_once(:user) { User.create! }

    it "is :disabled for unassociated users" do
      user = User.new
      expect(user.mfa_settings).to eq :disabled
    end

    it "inherits from the account" do
      user.pseudonyms.create!(account: Account.default, unique_id: "user")
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      expect(user.mfa_settings).to eq :required

      Account.default.settings[:mfa_settings] = :optional
      Account.default.save!
      user = User.find(user().id)
      expect(user.mfa_settings).to eq :optional
    end

    it "is the most-restrictive if associated with multiple accounts" do
      disabled_account = Account.create!(settings: { mfa_settings: :disabled })
      optional_account = Account.create!(settings: { mfa_settings: :optional })
      required_account = Account.create!(settings: { mfa_settings: :required })

      p1 = user.pseudonyms.create!(account: disabled_account, unique_id: "user")
      user = User.find(user().id)
      expect(user.mfa_settings).to eq :disabled

      p2 = user.pseudonyms.create!(account: optional_account, unique_id: "user")
      user = User.find(user.id)
      expect(user.mfa_settings).to eq :optional

      user.pseudonyms.create!(account: required_account, unique_id: "user")
      user = User.find(user.id)
      expect(user.mfa_settings).to eq :required

      p1.destroy
      user = User.find(user.id)
      expect(user.mfa_settings).to eq :required

      p2.destroy
      user = User.find(user.id)
      expect(user.mfa_settings).to eq :required
    end

    it "is required if admin and required_for_admins" do
      account = Account.create!(settings: { mfa_settings: :required_for_admins })
      user.pseudonyms.create!(account:, unique_id: "user")

      expect(user.mfa_settings).to eq :optional
      account.account_users.create!(user:)
      user.reload
      expect(user.mfa_settings).to eq :required
    end

    it "required_for_admins shouldn't get confused by admins in other accounts" do
      account = Account.create!(settings: { mfa_settings: :required_for_admins })
      user.pseudonyms.create!(account:, unique_id: "user")
      user.pseudonyms.create!(account: Account.default, unique_id: "user")

      Account.default.account_users.create!(user:)

      expect(user.mfa_settings).to eq :optional
    end

    it "short circuits when a hint is provided" do
      account = Account.create!(settings: { mfa_settings: :required_for_admins })
      p = user.pseudonyms.create!(account:, unique_id: "user")
      account.account_users.create!(user:)

      expect(user).not_to receive(:pseudonyms)
      expect(user.mfa_settings(pseudonym_hint: p)).to eq :required
    end

    it "is required for an auth provider that has it required" do
      account = Account.create(settings: { mfa_settings: :optional })
      ap = account.canvas_authentication_provider
      ap.update!(mfa_required: true)
      p = user.pseudonyms.create!(account:, unique_id: "user", authentication_provider: ap)

      expect(user.mfa_settings).to eq :required

      expect(user).not_to receive(:pseudonyms)
      expect(user.mfa_settings(pseudonym_hint: p)).to eq :required
    end
  end

  context "crocodoc attributes" do
    before :once do
      Setting.set "crocodoc_counter", 998
      @user = User.create! short_name: "Bob"
    end

    it "generates a unique crocodoc_id" do
      expect(@user.crocodoc_id).to be_nil
      expect(@user.crocodoc_id!).to be 999
      expect(@user.crocodoc_user).to eql "999,Bob"
    end

    it "scrubs commas from the user name" do
      @user.short_name = "Smith, Bob"
      @user.save!
      expect(@user.crocodoc_user).to eql "999,Smith Bob"
    end

    it "does not change a user's crocodoc_id" do
      @user.update_attribute :crocodoc_id, 2
      expect(@user.crocodoc_id!).to be 2
      expect(Setting.get("crocodoc_counter", 0).to_i).to be 998
    end
  end

  describe "select_available_assignments" do
    before :once do
      course_with_student active_all: true
      @assignment = @course.assignments.create! title: "blah!", due_at: 1.day.from_now, submission_types: "not_graded"
    end

    it "does not include concluded enrollments by default" do
      expect(@student.select_available_assignments([@assignment]).count).to eq 1
      @course.enrollment_term.update_attribute(:end_at, 1.day.from_now)

      Timecop.travel(2.days) do
        EnrollmentState.recalculate_expired_states
        expect(@student.select_available_assignments([@assignment]).count).to eq 0
      end
    end

    it "includeds concluded enrollments if specified" do
      @course.enrollment_term.update_attribute(:end_at, 1.day.from_now)

      Timecop.travel(2.days) do
        EnrollmentState.recalculate_expired_states
        expect(@student.select_available_assignments([@assignment], include_concluded: true).count).to eq 1
      end
    end
  end

  describe ".initial_enrollment_type_from_type" do
    it "returns supported initial_enrollment_type values" do
      expect(User.initial_enrollment_type_from_text("StudentEnrollment")).to eq "student"
      expect(User.initial_enrollment_type_from_text("StudentViewEnrollment")).to eq "student"
      expect(User.initial_enrollment_type_from_text("TeacherEnrollment")).to eq "teacher"
      expect(User.initial_enrollment_type_from_text("TaEnrollment")).to eq "ta"
      expect(User.initial_enrollment_type_from_text("ObserverEnrollment")).to eq "observer"
      expect(User.initial_enrollment_type_from_text("DesignerEnrollment")).to be_nil
      expect(User.initial_enrollment_type_from_text("UnknownThing")).to be_nil
      expect(User.initial_enrollment_type_from_text(nil)).to be_nil
      # Non-enrollment type strings
      expect(User.initial_enrollment_type_from_text("student")).to eq "student"
      expect(User.initial_enrollment_type_from_text("teacher")).to eq "teacher"
      expect(User.initial_enrollment_type_from_text("ta")).to eq "ta"
      expect(User.initial_enrollment_type_from_text("observer")).to eq "observer"
    end
  end

  describe "adminable_accounts" do
    specs_require_sharding

    it "includes accounts from multiple shards" do
      user_factory
      Account.site_admin.account_users.create!(user: @user)
      @shard1.activate do
        @account2 = Account.create!
        @account2.account_users.create!(user: @user)
      end

      expect(@user.adminable_accounts.map(&:id).sort).to eq [Account.site_admin, @account2].map(&:id).sort
    end

    it "excludes deleted accounts" do
      user_factory
      Account.site_admin.account_users.create!(user: @user)
      @shard1.activate do
        @account2 = Account.create!
        @account2.account_users.create!(user: @user)
        @account2.destroy
      end

      expect(@user.adminable_accounts.map(&:id).sort).to eq [Account.site_admin].map(&:id).sort
    end
  end

  describe "all_pseudonyms" do
    specs_require_sharding

    it "includes pseudonyms from multiple shards" do
      user_with_pseudonym(active_all: 1)
      @p1 = @pseudonym
      @shard1.activate do
        account = Account.create!
        @p2 = account.pseudonyms.create!(user: @user, unique_id: "abcd")
      end

      expect(@user.all_pseudonyms).to eq [@p1, @p2]
    end
  end

  describe "active_pseudonyms" do
    before :once do
      user_with_pseudonym(active_all: 1)
    end

    it "includes active pseudonyms" do
      expect(@user.active_pseudonyms).to eq [@pseudonym]
    end

    it "does not include deleted pseudonyms" do
      @pseudonym.destroy
      expect(@user.active_pseudonyms).to be_empty
    end
  end

  describe "send_scores_in_emails" do
    before :once do
      course_with_student(active_all: true)
    end

    it "returns false if the root account setting is disabled" do
      root_account = @course.root_account
      root_account.settings[:allow_sending_scores_in_emails] = false
      root_account.save!

      expect(@student.send_scores_in_emails?(@course)).to be false
    end

    it "uses the user preference setting if no course overrides are available" do
      @student.preferences[:send_scores_in_emails] = true
      expect(@student.send_scores_in_emails?(@course)).to be true

      @student.preferences[:send_scores_in_emails] = false
      expect(@student.send_scores_in_emails?(@course)).to be false
    end

    it "uses course overrides if available" do
      @student.preferences[:send_scores_in_emails] = false
      @student.set_preference(:send_scores_in_emails_override, "course_" + @course.global_id.to_s, true)
      expect(@student.send_scores_in_emails?(@course)).to be true

      @student.preferences[:send_scores_in_emails] = true
      @student.set_preference(:send_scores_in_emails_override, "course_" + @course.global_id.to_s, false)
      expect(@student.send_scores_in_emails?(@course)).to be false
    end
  end

  describe "preferred_gradebook_version" do
    subject { user.preferred_gradebook_version }

    let(:user) { User.create! }

    it "returns default gradebook when preferred" do
      user.set_preference(:gradebook_version, "default")
      expect(subject).to eq "default"
    end

    it "returns individual gradebook when preferred" do
      user.set_preference(:gradebook_version, "individual")
      expect(subject).to eq "individual"
    end

    it "returns default gradebook when not set" do
      expect(subject).to eq "default"
    end
  end

  describe "manual_mark_as_read" do
    subject { user.manual_mark_as_read? }

    let(:user) { User.new }

    context "default" do
      it { is_expected.to be_falsey }
    end

    context "after being set to true" do
      before { allow(user).to receive_messages(preferences: { manual_mark_as_read: true }) }

      it     { is_expected.to be_truthy }
    end

    context "after being set to false" do
      before { allow(user).to receive_messages(preferences: { manual_mark_as_read: false }) }

      it     { is_expected.to be_falsey }
    end
  end

  describe "create_announcements_unlocked" do
    it "defaults to false if preference not set" do
      user = User.create!
      expect(user.create_announcements_unlocked?).to be_falsey
    end
  end

  describe "things excluded from json serialization" do
    it "excludes collkey" do
      # Ruby 1.9 does not like html that includes the collkey, so
      # don't ship it to the page (even as json).
      User.create!
      users = User.order_by_sortable_name
      expect(users.first.as_json["user"].keys).not_to include("collkey")
    end
  end

  describe "permissions" do
    it "does not allow account admin to modify admin privileges of other account admins" do
      expect(RoleOverride.readonly_for(Account.default, :manage_role_overrides, admin_role)).to be_truthy
      expect(RoleOverride.readonly_for(Account.default, :manage_account_memberships, admin_role)).to be_truthy
      expect(RoleOverride.readonly_for(Account.default, :manage_account_settings, admin_role)).to be_truthy
    end

    describe ":reset_mfa" do
      let(:account1) do
        a = Account.default
        a.settings[:admins_can_view_notifications] = true
        a.save!
        a
      end
      let(:account2) { Account.create! }

      let(:sally) do
        account_admin_user(
          user: student_in_course(account: account2).user,
          account: account1
        )
      end

      let(:bob) do
        student_in_course(
          user: student_in_course(account: account2).user,
          course: course_factory(account: account1)
        ).user
      end

      let(:charlie) { student_in_course(account: account1).user }

      let(:alice) do
        account_admin_user_with_role_changes(
          account: account1,
          role: custom_account_role("StrongerAdmin", account: account1),
          role_changes: { view_notifications: true }
        )
      end

      it "grants non-admins :reset_mfa on themselves" do
        pseudonym(charlie, account: account1)
        expect(charlie).to be_grants_right(charlie, :reset_mfa)
      end

      it "grants admins :reset_mfa on themselves" do
        pseudonym(sally, account: account1)
        expect(sally).to be_grants_right(sally, :reset_mfa)
      end

      it "grants admins :reset_mfa on fully admined users" do
        pseudonym(charlie, account: account1)
        expect(charlie).to be_grants_right(sally, :reset_mfa)
      end

      it "does not grant admins :reset_mfa on partially admined users" do
        account1.settings[:mfa_settings] = :required
        account1.save!
        account2.settings[:mfa_settings] = :required
        account2.save!
        pseudonym(bob, account: account1)
        pseudonym(bob, account: account2)
        expect(bob).not_to be_grants_right(sally, :reset_mfa)
      end

      it "does not grant subadmins :reset_mfa on stronger admins" do
        account1.settings[:mfa_settings] = :required
        account1.save!
        sub = Account.create(root_account_id: account1)
        AccountUser.create(account: sub, user: bob)
        pseudonym(alice, account: account1)
        expect(alice).not_to be_grants_right(bob, :reset_mfa)
      end

      context "MFA is required on the account" do
        before do
          account1.settings[:mfa_settings] = :required
          account1.save!
        end

        it "no longer grants non-admins :reset_mfa on themselves" do
          pseudonym(charlie, account: account1)
          expect(charlie).not_to be_grants_right(charlie, :reset_mfa)
        end

        it "no longer grants admins :reset_mfa on themselves" do
          pseudonym(sally, account: account1)
          expect(sally).not_to be_grants_right(sally, :reset_mfa)
        end

        it "still grants admins :reset_mfa on other fully admined users" do
          pseudonym(charlie, account: account1)
          expect(charlie).to be_grants_right(sally, :reset_mfa)
        end
      end
    end

    describe ":merge" do
      let(:account1) do
        a = Account.default
        a.settings[:admins_can_view_notifications] = true
        a.save!
        a
      end
      let(:account2) { Account.create! }

      let(:sally) do
        account_admin_user(
          user: student_in_course(account: account2).user,
          account: account1
        )
      end

      let(:bob) do
        student_in_course(
          user: student_in_course(account: account2).user,
          course: course_factory(account: account1)
        ).user
      end

      let(:charlie) { student_in_course(account: account2).user }

      let(:alice) do
        account_admin_user_with_role_changes(
          account: account1,
          role: custom_account_role("StrongerAdmin", account: account1),
          role_changes: { view_notifications: true }
        )
      end

      it "grants admins :merge on themselves" do
        pseudonym(sally, account: account1)
        expect(sally).to be_grants_right(sally, :merge)
      end

      it "does not grant non-admins :merge on themselves" do
        pseudonym(bob, account: account1)
        expect(bob).not_to be_grants_right(bob, :merge)
      end

      it "does not grant non-admins :merge on other users" do
        pseudonym(sally, account: account1)
        expect(sally).not_to be_grants_right(bob, :merge)
      end

      it "grants admins :merge on partially admined users" do
        pseudonym(bob, account: account1)
        pseudonym(bob, account: account2)
        expect(bob).to be_grants_right(sally, :merge)
      end

      it "does not grant admins :merge on users from other accounts" do
        pseudonym(charlie, account: account2)
        expect(charlie).not_to be_grants_right(sally, :merge)
      end

      it "does not grant subadmins :merge on stronger admins" do
        pseudonym(alice, account: account1)
        expect(alice).not_to be_grants_right(sally, :merge)
      end
    end

    describe ":manage_user_details" do
      before :once do
        @root_account = Account.default
        @root_admin = account_admin_user(account: @root_account)
        @sub_account = Account.create! root_account: @root_account
        @sub_admin = account_admin_user(account: @sub_account)
        @student = course_with_student(account: @sub_account, active_all: true).user
      end

      it "is granted to root account admins" do
        expect(@student.grants_right?(@root_admin, :manage_user_details)).to be true
      end

      it "is not granted to root account admins w/o :manage_user_logins" do
        @root_account.role_overrides.create!(role: admin_role, enabled: false, permission: :manage_user_logins)
        expect(@student.grants_right?(@root_admin, :manage_user_details)).to be false
      end

      it "is not granted to sub-account admins" do
        expect(@student.grants_right?(@sub_admin, :manage_user_details)).to be false
      end

      it "is not granted to custom sub-account admins with inherited roles" do
        custom_role = custom_account_role("somerole", account: @root_account)
        @root_account.role_overrides.create!(role: custom_role, enabled: true, permission: :manage_user_logins)
        @custom_sub_admin = account_admin_user(account: @sub_account, role: custom_role)
        expect(@student.grants_right?(@custom_sub_admin, :manage_user_details)).to be false
      end

      it "is not granted to root account admins on other root account admins who are invited as students" do
        other_admin = account_admin_user account: Account.create!
        course_with_student account: @root_account, user: other_admin, enrollment_state: "invited"
        expect(@root_admin.grants_right?(other_admin, :manage_user_details)).to be false
      end
    end

    describe ":generate_observer_pairing_code" do
      before :once do
        @root_account = Account.default
        @root_admin = account_admin_user(account: @root_account)
        @sub_account = Account.create! root_account: @root_account
        @sub_admin = account_admin_user(account: @sub_account)
        @student = course_with_student(account: @sub_account, active_all: true).user
      end

      it "is granted to self" do
        expect(@student.grants_right?(@student, :generate_observer_pairing_code)).to be true
      end

      it "is granted to root account admins" do
        expect(@student.grants_right?(@root_admin, :generate_observer_pairing_code)).to be true
      end

      it "is not granted to root account w/o :generate_observer_pairing_code" do
        @root_account.role_overrides.create!(role: admin_role, enabled: false, permission: :generate_observer_pairing_code)
        expect(@student.grants_right?(@root_admin, :generate_observer_pairing_code)).to be false
      end

      it "is granted to sub-account admins" do
        expect(@student.grants_right?(@sub_admin, :generate_observer_pairing_code)).to be true
      end

      it "is not granted to sub-account admins w/o :generate_observer_pairing_code" do
        @root_account.role_overrides.create!(role: admin_role, enabled: false, permission: :generate_observer_pairing_code)
        expect(@student.grants_right?(@sub_admin, :generate_observer_pairing_code)).to be false
      end
    end

    describe ":moderate_user_content" do
      before(:once) do
        root_account = Account.default
        @root_admin = account_admin_user(account: root_account)
        sub_account = Account.create!(root_account:)
        @sub_admin = account_admin_user(account: sub_account)
        @student = course_with_student(account: sub_account, active_all: true).user
      end

      it "cannot moderate your own content" do
        expect(@student.grants_right?(@student, :moderate_user_content)).to be false
      end

      it "cannot moderate content if you are an admin without permission to moderate user content" do
        Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
        expect(@student.grants_right?(@root_admin, :moderate_user_content)).to be false
      end

      it "cannot moderate content if you are a subadmin without permission to moderate user content" do
        Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
        expect(@student.grants_right?(@sub_admin, :moderate_user_content)).to be false
      end

      it "can moderate content if you are an admin with permission to moderate user content" do
        Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
        expect(@student.grants_right?(@root_admin, :moderate_user_content)).to be true
      end

      it "can moderate content if you are a subadmin with permission to moderate user content" do
        Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
        expect(@student.grants_right?(@sub_admin, :moderate_user_content)).to be true
      end
    end
  end

  describe "check_accounts_right?" do
    describe "sharding" do
      specs_require_sharding

      it "checks for associated accounts on shards the user shares with the seeker" do
        # create target user on default shard
        target = user_factory
        # create account on another shard
        account = @shard1.activate { Account.create! }
        # associate target user with that account
        account_admin_user(user: target, account:, role: Role.get_built_in_role("AccountMembership", root_account_id: account.id))
        # create seeking user as admin on that account
        seeker = account_admin_user(account:, role: Role.get_built_in_role("AccountAdmin", root_account_id: account.id))
        # ensure seeking user gets permissions it should on target user
        expect(target.grants_right?(seeker, :view_statistics)).to be_truthy
      end

      it "checks all shards, even if not actually associated" do
        target = user_factory
        # create account on another shard
        account = @shard1.activate { Account.create! }
        # associate target user with that account
        account_admin_user(user: target, account:, role: Role.get_built_in_role("AccountMembership", root_account_id: account.id))
        # create seeking user as admin on that account
        seeker = account_admin_user(account:, role: Role.get_built_in_role("AccountAdmin", root_account_id: account.id))
        allow(seeker).to receive(:associated_shards).and_return([])
        # ensure seeking user gets permissions it should on target user
        expect(target.grants_right?(seeker, :view_statistics)).to be true
      end

      it "falls back to user shard for callsite, if no account associations found for target user" do
        account = Account.default
        target = user_factory
        seeker = account_admin_user(
          account:,
          role: Role.get_built_in_role("AccountAdmin", root_account_id: account.id)
        )
        # ensure seeking user gets permissions it should on target user
        expect(target.grants_right?(seeker, :read_full_profile)).to be true
      end
    end
  end

  describe "cached_course_ids_for_observed_user" do
    before :once do
      @observer = user_factory(active_all: true)
      @student1 = user_factory(active_all: true)
      @student2 = user_factory(active_all: true)
      @course1 = course_factory(active_all: true)
      @course2 = course_factory(active_all: true)
    end

    it "returns course ids where user is observing student" do
      @course1.enroll_student(@student1)
      @course2.enroll_student(@student1)
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)

      course_ids = @observer.cached_course_ids_for_observed_user(@student1)
      expect(course_ids).to contain_exactly(@course1.id, @course2.id)
    end

    it "returns empty array if not observing student" do
      @course2.enroll_student(@observer)
      @course1.enroll_student(@student1)

      course_ids = @observer.cached_course_ids_for_observed_user(@student1)
      expect(course_ids).to eq([])
    end

    it "returns course ids only for passed student, even if observing others" do
      @course1.enroll_student(@student1)
      @course2.enroll_student(@student2)
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student2.id)

      course_ids = @observer.cached_course_ids_for_observed_user(@student1)
      expect(course_ids).to contain_exactly(@course1.id)
      course_ids = @observer.cached_course_ids_for_observed_user(@student2)
      expect(course_ids).to contain_exactly(@course2.id)
    end

    it "does not include completed enrollments" do
      @course1.enroll_student(@student1)
      @course2.enroll_student(@student1)
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id, enrollment_state: :completed)
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)

      course_ids = @observer.cached_course_ids_for_observed_user(@student1)
      expect(course_ids).to contain_exactly(@course2.id)
    end

    it "includes pending enrollments" do
      @course1.enroll_student(@student1, enrollment_state: :invited)
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id, enrollment_state: :invited)

      course_ids = @observer.cached_course_ids_for_observed_user(@student1)
      expect(course_ids).to contain_exactly(@course1.id)
    end

    context "with sharding" do
      specs_require_sharding

      before :once do
        @shard2.activate do
          account2 = Account.create!
          @course3 = course_factory(active_all: true, account: account2)
        end
      end

      it "includes course ids from another shard" do
        @course1.enroll_student(@student1)
        @course3.enroll_student(@student1)
        @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)
        @course3.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)

        course_ids = @observer.cached_course_ids_for_observed_user(@student1)
        expect(course_ids).to contain_exactly(@course1.id, @course3.id)
      end
    end
  end

  describe "#conversation_context_codes" do
    before :once do
      @user = user_factory(active_all: true)
      course_with_student(user: @user, active_all: true)
      group_with_user(user: @user, active_all: true)
    end

    it "includes courses" do
      expect(@user.conversation_context_codes).to include(@course.asset_string)
    end

    it "includes concluded courses" do
      @enrollment.workflow_state = "completed"
      @enrollment.save!
      expect(@user.conversation_context_codes).to include(@course.asset_string)
    end

    it "optionally does not include concluded courses" do
      @enrollment.update_attribute(:workflow_state, "completed")
      expect(@user.conversation_context_codes(false)).not_to include(@course.asset_string)
    end

    it "includes groups" do
      expect(@user.conversation_context_codes).to include(@group.asset_string)
    end

    describe "sharding" do
      specs_require_sharding

      before :once do
        @shard1_account = @shard1.activate { Account.create! }
      end

      it "includes courses on other shards" do
        course_with_student(account: @shard1_account, user: @user, active_all: true)
        expect(@user.conversation_context_codes).to include(@course.asset_string)
      end

      it "includes concluded courses on other shards" do
        course_with_student(account: @shard1_account, user: @user, active_all: true)
        @enrollment.workflow_state = "completed"
        @enrollment.save!
        expect(@user.conversation_context_codes).to include(@course.asset_string)
      end

      it "optionally does not include concluded courses on other shards" do
        course_with_student(account: @shard1_account, user: @user, active_all: true)
        @enrollment.update_attribute(:workflow_state, "completed")
        expect(@user.conversation_context_codes(false)).not_to include(@course.asset_string)
      end

      it "includes groups on other shards" do
        # course is just to associate the get shard1 in @user's associated shards
        course_with_student(account: @shard1_account, user: @user, active_all: true)
        @shard1.activate { group_with_user(user: @user, active_all: true) }
        expect(@user.conversation_context_codes).to include(@group.asset_string)
      end

      it "includes the default shard version of the asset string" do
        course_with_student(account: @shard1_account, user: @user, active_all: true)
        default_asset_string = @course.asset_string
        @shard1.activate { expect(@user.conversation_context_codes).to include(default_asset_string) }
      end
    end
  end

  describe "#stamp_logout_time!" do
    before :once do
      user_model
    end

    it "updates last_logged_out" do
      now = Time.zone.now
      Timecop.freeze(now) { @user.stamp_logout_time! }
      expect(@user.reload.last_logged_out.to_i).to eq now.to_i
    end

    context "sharding" do
      specs_require_sharding

      it "updates regardless of current shard" do
        @shard1.activate { @user.stamp_logout_time! }
        expect(@user.reload.last_logged_out).not_to be_nil
      end
    end
  end

  describe "delete_enrollments" do
    before do
      course_factory
      2.times { @course.course_sections.create! }
      2.times { @course.assignments.create! }
    end

    it "batches SubmissionLifecycleManager jobs" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).twice # sync_enrollments and destroy_enrollments
      test_student = @course.student_view_student
      test_student.destroy
      test_student.reload.enrollments.each { |e| expect(e).to be_deleted }
    end
  end

  describe "otp remember me cookie" do
    before do
      @user = User.new
      @user.otp_secret_key = ROTP::Base32.random
    end

    it "adds an ip to an existing cookie" do
      cookie1 = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, "ip1")
      cookie2 = @user.otp_secret_key_remember_me_cookie(Time.now.utc, cookie1, "ip2")
      expect(@user.validate_otp_secret_key_remember_me_cookie(cookie1, "ip1")).to be_truthy
      expect(@user.validate_otp_secret_key_remember_me_cookie(cookie1, "ip2")).to be_falsey
      expect(@user.validate_otp_secret_key_remember_me_cookie(cookie2, "ip1")).to be_truthy
      expect(@user.validate_otp_secret_key_remember_me_cookie(cookie2, "ip2")).to be_truthy
    end
  end

  it "resets its conversation counter when told to" do
    user = user_model
    allow(user).to receive(:conversations).and_return Struct.new(:unread).new(Array.new(5))
    user.reset_unread_conversations_counter
    expect(user.reload.unread_conversations_count).to eq 5
  end

  describe "group_memberships" do
    before :once do
      course_with_student active_all: true
      @group = Group.create! context: @course, name: "group"
      @group.users << @student
      @group.save!
    end

    it "doesn't include deleted groups in current_group_memberships" do
      expect(@student.current_group_memberships.size).to eq 1
      @group.destroy
      expect(@student.current_group_memberships.size).to eq 0
    end

    it "doesn't include deleted groups in group_memberships_for" do
      expect(@student.group_memberships_for(@course).size).to eq 1
      @group.destroy
      expect(@student.group_memberships_for(@course).size).to eq 0
    end

    it "shows if user has group_membership" do
      expect(@student.current_active_groups?).to be true
    end

    it "excludes groups in concluded courses with current_group_memberships_by_date" do
      ag = Account.default.groups.create! name: "ag"
      ag.users << @student
      ag.save!
      expect(@student.cached_current_group_memberships_by_date.map(&:group)).to match_array([@group, ag])

      @course.start_at = 1.year.ago
      @course.conclude_at = 1.hour.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      expect(User.find(@student.id).cached_current_group_memberships_by_date.map(&:group)).to match_array([ag])
    end

    describe "#has_membership_for_current_group" do
      it "returns true for active group" do
        expect(@student.membership_for_group_id?(@group.id)).to be true
      end

      it "returns false for inactive group" do
        @group.destroy
        expect(@student.membership_for_group_id?(@group.id)).to be false
      end

      it "returns false for non existing group" do
        expect(@student.membership_for_group_id?("fake_id")).to be false
      end
    end
  end

  describe "visible_groups" do
    it "includes groups in published courses" do
      course_with_student active_all: true
      @group = Group.create! context: @course, name: "GroupOne"
      @group.users << @student
      @group.save!
      expect(@student.visible_groups.size).to eq 1
    end

    it "does not include groups that belong to unpublished courses" do
      course_with_student
      @group = Group.create! context: @course, name: "GroupOne"
      @group.users << @student
      @group.save!
      expect(@student.visible_groups.size).to eq 0
    end

    it "excludes groups in courses with concluded enrollments" do
      course_with_student
      @course.conclude_at = 2.days.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @group = Group.create! context: @course, name: "GroupOne"
      @group.users << @student
      @group.save!
      expect(@student.visible_groups.size).to eq 0
    end

    it "includes account groups" do
      account = account_model(parent_account: Account.default)
      student = user_factory active_all: true
      @group = Group.create! context: account, name: "GroupOne"
      @group.users << student
      @group.save!
      expect(student.visible_groups.size).to eq 1
    end
  end

  describe "roles" do
    before(:once) do
      user_factory(active_all: true)
      course_factory(active_course: true)
      @account = Account.default
    end

    it "always includes 'user'" do
      expect(@user.roles(@account)).to eq %w[user]
    end

    it "includes 'student' if the user has a student enrollment" do
      @enrollment = @course.enroll_user(@user, "StudentEnrollment", enrollment_state: "active")
      expect(@user.roles(@account)).to eq %w[user student]
    end

    it "includes 'student' if the user has a student view student enrollment" do
      @user = @course.student_view_student
      expect(@user.roles(@account)).to eq %w[user student fake_student]
    end

    it "includes 'teacher' if the user has a teacher enrollment" do
      @enrollment = @course.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
      expect(@user.roles(@account)).to eq %w[user teacher]
    end

    it "includes 'teacher' if the user has a ta enrollment" do
      @enrollment = @course.enroll_user(@user, "TaEnrollment", enrollment_state: "active")
      expect(@user.roles(@account)).to eq %w[user teacher]
    end

    it "includes 'teacher' if the user has a designer enrollment" do
      @enrollment = @course.enroll_user(@user, "DesignerEnrollment", enrollment_state: "active")
      expect(@user.roles(@account)).to eq %w[user teacher]
    end

    it "includes 'observer' if the user has an observer enrollment" do
      @enrollment = @course.enroll_user(@user, "ObserverEnrollment", enrollment_state: "active")
      expect(@user.roles(@account)).to eq %w[user observer]
    end

    it "includes 'admin' if the user has a sub-account admin user record" do
      sub_account = @account.sub_accounts.create!
      sub_account.account_users.create!(user: @user, role: admin_role)
      expect(@user.roles(@account)).to eq %w[user admin]
    end

    it "includes 'root_admin' if the user has a root account admin user record" do
      @account.account_users.create!(user: @user, role: admin_role)
      expect(@user.roles(@account)).to eq %w[user admin root_admin]
    end

    it "does not include 'root_admin' if the user's root account admin user record is deleted" do
      au = @account.account_users.create!(user: @user, role: admin_role)
      au.destroy
      expect(@user.roles(@account)).to eq %w[user]
    end

    it "caches results" do
      enable_cache do
        sub_account = @account.sub_accounts.create!
        sub_account.account_users.create!(user: @user, role: admin_role)
        result = @user.roles(@account)
        sub_account.destroy!
        expect(@user.roles(@account)).to eq result
      end
    end

    context "exclude_deleted_accounts" do
      it "does not include admin if user has a sub-account admin user record in deleted account" do
        sub_account = @account.sub_accounts.create!
        sub_account.account_users.create!(user: @user, role: admin_role)
        @user.roles(@account)
        sub_account.destroy!
        expect(@user.roles(@account, true)).to eq %w[user]
      end

      it "does not cache results when exclude_deleted_accounts is true" do
        sub_account = @account.sub_accounts.create!
        sub_account.account_users.create!(user: @user, role: admin_role)
        @user.roles(@account, true)
        expect(@user.roles(@account)).to eq %w[user admin]
      end
    end
  end

  describe "root_admin_for?" do
    before(:once) do
      user_factory(active_all: true)
      @account = Account.default
    end

    it "returns false if the user not an admin in a root account" do
      expect(@user.root_admin_for?(@account)).to be false
    end

    it "returns true if the user an admin in a root account" do
      @account.account_users.create!(user: @user, role: admin_role)
      expect(@user.root_admin_for?(@account)).to be true
    end

    it "returns false if the user *was* an admin in a root account" do
      au = @account.account_users.create!(user: @user, role: admin_role)
      au.destroy
      expect(@user.root_admin_for?(@account)).to be false
    end
  end

  it "does not grant user_notes rights to restricted users" do
    course_with_ta(active_all: true)
    student_in_course(course: @course, active_all: true)
    @course.account.role_overrides.create!(role: ta_role, enabled: false, permission: :manage_user_notes)

    expect(@student.grants_right?(@ta, :create_user_notes)).to be_falsey
    expect(@student.grants_right?(@ta, :read_user_notes)).to be_falsey
  end

  it "changes avatar state on reporting" do
    user_factory
    @user.report_avatar_image!
    @user.reload
    expect(@user.avatar_state).to eq :reported
  end

  describe "submissions_folder" do
    before(:once) do
      student_in_course
    end

    it "creates the root submissions folder on demand" do
      f = @user.submissions_folder
      expect(@user.submissions_folders.where(parent_folder_id: Folder.root_folders(@user).first, name: "Submissions").first).to eq f
    end

    it "finds the existing root submissions folder" do
      f = @user.folders.build
      f.parent_folder_id = Folder.root_folders(@user).first
      f.name = "blah"
      f.submission_context_code = "root"
      f.save!
      expect(@user.submissions_folder).to eq f
    end

    it "creates a submissions folder for a course" do
      f = @user.submissions_folder(@course)
      expect(@user.submissions_folders.where(submission_context_code: @course.asset_string, parent_folder_id: @user.submissions_folder, name: @course.name).first).to eq f
    end

    it "finds an existing submissions folder for a course" do
      f = @user.folders.build
      f.parent_folder_id = @user.submissions_folder
      f.name = "bleh"
      f.submission_context_code = @course.asset_string
      f.save!
      expect(@user.submissions_folder(@course)).to eq f
    end
  end

  describe "#authenticate_one_time_password" do
    let(:user) { User.create! }
    let(:otp) { user.one_time_passwords.create! }

    it "marks it as used" do
      expect(user.authenticate_one_time_password(otp.code)).to eq otp
      expect(otp.reload).to be_used
    end

    it "doesn't allow using a used code" do
      otp.update_attribute(:used, true)
      expect(user.authenticate_one_time_password(otp.code)).to be_nil
    end
  end

  describe "#generate_one_time_passwords" do
    let(:user) { User.create! }

    it "generates them" do
      user.generate_one_time_passwords
      expect(user.one_time_passwords.count).to eq 10
    end

    it "doesn't clobber them if they already exist" do
      user.generate_one_time_passwords
      otps = user.one_time_passwords.order(:id).to_a
      user.reload
      user.generate_one_time_passwords
      expect(user.one_time_passwords.order(:id).to_a).to eq otps
    end

    it "does clobber them if you want it to" do
      user.generate_one_time_passwords
      otps = user.one_time_passwords.order(:id).to_a
      user.generate_one_time_passwords(regenerate: true)
      otps.each do |otp|
        expect { otp.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#has_student_enrollment" do
    let(:user) { User.create! }

    it "returns false by default" do
      expect(user.has_student_enrollment?).to be false
    end

    it "returns true when user is student and a course is active" do
      course_with_student(user:, active_all: true)
      expect(user.has_student_enrollment?).to be true
    end

    it "returns true when user is student and no courses are active" do
      course_with_student(user:, active_all: false)
      expect(user.has_student_enrollment?).to be true
    end

    it "returns false when user is teacher" do
      course_with_teacher(user:)
      expect(user.has_student_enrollment?).to be false
    end

    it "returns false when user is TA" do
      course_with_ta(user:)
      expect(user.has_student_enrollment?).to be false
    end

    it "returns false when user is designer" do
      course_with_designer(user:)
      expect(user.has_student_enrollment?).to be false
    end
  end

  describe "#participating_student_current_and_concluded_course_ids" do
    let(:user) { User.create! }

    before do
      course_with_student(user:, active_all: true)
    end

    it "includes courses for current enrollments" do
      expect(user.participating_student_current_and_concluded_course_ids).to include(@course.id)
    end

    it "includes concluded courses" do
      @course.soft_conclude!
      @course.save
      expect(user.participating_student_current_and_concluded_course_ids).to include(@course.id)
    end

    it "includes courses for concluded enrollments" do
      user.enrollments.last.conclude
      expect(user.participating_student_current_and_concluded_course_ids).to include(@course.id)
    end
  end

  describe "#participating_student_current_and_unrestricted_concluded_course_ids" do
    let(:user) { User.create! }

    before do
      # restricts view of this course when it is in the past (it IS in the past)
      @restricted = Account.default.courses.create!(
        start_at: 2.months.ago,
        conclude_at: 1.month.ago,
        restrict_enrollments_to_course_dates: true,
        name: "Restricted",
        restrict_student_past_view: true
      )
      # doesnt restrict view of this course when it is in the past (it IS in the past)
      @unrestricted = Account.default.courses.create!(
        start_at: 2.months.ago,
        conclude_at: 1.month.ago,
        restrict_enrollments_to_course_dates: true,
        name: "Unrestricted",
        restrict_student_past_view: false
      )
      @restricted.offer!
      @unrestricted.offer!
    end

    it "includes unrestricted but not restricted course" do
      course_with_student course: @restricted, user:, active_all: true
      course_with_student course: @unrestricted, user:, active_all: true

      expect(user.participating_student_current_and_unrestricted_concluded_course_ids).to include(@unrestricted.id)
      expect(user.participating_student_current_and_unrestricted_concluded_course_ids).not_to include(@restricted.id)
    end

    it "includes unrestricted concluded and restricted current course" do
      @restricted.update(conclude_at: nil, restrict_enrollments_to_course_dates: false)
      course_with_student course: @restricted, user:, active_all: true
      course_with_student course: @unrestricted, user:, active_all: true

      expect(user.participating_student_current_and_unrestricted_concluded_course_ids)
        .to contain_exactly(@restricted.id, @unrestricted.id)
    end
  end

  describe "from_tokens" do
    specs_require_sharding

    let(:users) { [User.create!, @shard1.activate { User.create! }] }
    let(:tokens) { users.map(&:token) }

    it "generates tokens made of id/hash(uuid) pairs" do
      tokens.each_with_index do |token, i|
        expect(token).to eq "#{users[i].id}_#{Digest::SHA256.hexdigest(users[i].uuid)}"
      end
    end

    it "instantiates users by token" do
      expect(User.from_tokens(tokens)).to match_array(users)
    end

    it "excludes bad tokens" do
      broken_tokens = tokens.map { |token| token + "ff" }
      expect(User.from_tokens(broken_tokens)).to be_empty
    end
  end

  describe "#dashboard_view" do
    before do
      course_factory
      user_factory(active_all: true)
      user_session(@user)
    end

    it "defaults to 'cards' if not set at the user or account level" do
      @user.dashboard_view = nil
      @user.save!
      @user.account.default_dashboard_view = nil
      @user.account.save!
      expect(@user.dashboard_view).to eql("cards")
    end

    it "defaults to account setting if user's isn't set" do
      @user.dashboard_view = nil
      @user.save!
      @user.account.default_dashboard_view = "activity"
      @user.account.save!
      expect(@user.dashboard_view).to eql("activity")
    end

    it "uses the user's setting as precedence" do
      @user.dashboard_view = "cards"
      @user.save!
      @user.account.default_dashboard_view = "activity"
      @user.account.save!
      expect(@user.dashboard_view).to eql("cards")
    end
  end

  describe "user_can_edit_name?" do
    before(:once) do
      user_with_pseudonym
      @pseudonym.account.settings[:users_can_edit_name] = false
      @pseudonym.account.save!
    end

    it "does not allow editing user name by default" do
      expect(@user.user_can_edit_name?).to be false
    end

    it "allows editing user name if the pseudonym allows this" do
      @pseudonym.account.settings[:users_can_edit_name] = true
      @pseudonym.account.save!
      expect(@user.user_can_edit_name?).to be true
    end

    describe "multiple pseudonyms" do
      before(:once) do
        @other_account = Account.create name: "Other Account"
        @other_account.settings[:users_can_edit_name] = true
        @other_account.save!
        user_with_pseudonym(user: @user, account: @other_account)
      end

      it "allows editing if one pseudonym's account allows this" do
        expect(@user.user_can_edit_name?).to be true
      end

      it "doesn't allow editing if only a deleted pseudonym's account allows this" do
        @user.pseudonyms.where(account_id: @other_account).first.destroy
        expect(@user.user_can_edit_name?).to be false
      end
    end
  end

  describe "user_can_edit_profile?" do
    before(:once) do
      user_with_pseudonym
      @pseudonym.account.settings[:users_can_edit_profile] = false
      @pseudonym.account.save!
    end

    it "does not allow editing user name by default" do
      expect(@user.user_can_edit_profile?).to be false
    end

    it "allows editing user name if the pseudonym allows this" do
      @pseudonym.account.settings[:users_can_edit_profile] = true
      @pseudonym.account.save!
      expect(@user.user_can_edit_profile?).to be true
    end

    describe "multiple pseudonyms" do
      before(:once) do
        @other_account = Account.create name: "Other Account"
        @other_account.settings[:users_can_edit_profile] = true
        @other_account.save!
        user_with_pseudonym(user: @user, account: @other_account)
      end

      it "allows editing if one pseudonym's account allows this" do
        expect(@user.user_can_edit_profile?).to be true
      end

      it "doesn't allow editing if only a deleted pseudonym's account allows this" do
        @user.pseudonyms.where(account_id: @other_account).first.destroy
        expect(@user.user_can_edit_profile?).to be false
      end
    end
  end

  describe "user_can_edit_comm_channels?" do
    before(:once) do
      user_with_pseudonym
      @pseudonym.account.settings[:users_can_edit_comm_channels] = false
      @pseudonym.account.save!
    end

    it "does not allow editing user name by default" do
      expect(@user.user_can_edit_comm_channels?).to be false
    end

    it "allows editing user name if the pseudonym allows this" do
      @pseudonym.account.settings[:users_can_edit_comm_channels] = true
      @pseudonym.account.save!
      expect(@user.user_can_edit_comm_channels?).to be true
    end

    describe "multiple pseudonyms" do
      before(:once) do
        @other_account = Account.create name: "Other Account"
        @other_account.settings[:users_can_edit_comm_channels] = true
        @other_account.save!
        user_with_pseudonym(user: @user, account: @other_account)
      end

      it "allows editing if one pseudonym's account allows this" do
        expect(@user.user_can_edit_comm_channels?).to be true
      end

      it "doesn't allow editing if only a deleted pseudonym's account allows this" do
        @user.pseudonyms.where(account_id: @other_account).first.destroy
        expect(@user.user_can_edit_comm_channels?).to be false
      end
    end
  end

  describe "limit_parent_app_web_access?" do
    before(:once) do
      user_with_pseudonym
      @pseudonym.account.settings[:limit_parent_app_web_access] = nil
      @pseudonym.account.save!
    end

    it "does not limit parent app web access by default" do
      expect(@user.limit_parent_app_web_access?).to be false
    end

    it "does limit if the pseudonym limits this" do
      @pseudonym.account.settings[:limit_parent_app_web_access] = true
      @pseudonym.account.save!
      expect(@user.limit_parent_app_web_access?).to be true
    end

    describe "multiple pseudonyms" do
      before(:once) do
        @other_account = Account.create name: "Other Account"
        @other_account.settings[:limit_parent_app_web_access] = true
        @other_account.save!
        user_with_pseudonym(user: @user, account: @other_account)
      end

      it "limits if one pseudonym's account limits this" do
        expect(@user.limit_parent_app_web_access?).to be true
      end

      it "doesn't limit if only a deleted pseudonym's account limits this" do
        @user.pseudonyms.where(account_id: @other_account).first.destroy
        expect(@user.limit_parent_app_web_access?).to be false
      end
    end
  end

  describe "generate_observer_pairing_code" do
    before(:once) do
      course_with_student
    end

    it "doesnt create overlapping active codes" do
      allow(SecureRandom).to receive(:base64).and_return("abc123", "abc123", "123abc")
      @student.generate_observer_pairing_code
      pairing_code = @student.generate_observer_pairing_code
      expect(pairing_code.code).to eq "123abc"
    end
  end

  describe "#custom_colors" do
    context "user has high_contrast enabled" do
      let(:user) { user_model }

      before do
        user.enable_feature!(:high_contrast)
      end

      it "sufficiently darkens colors with a contrast below 4.5" do
        user.preferences[:custom_colors] = {
          user_1: "#5a92de",
          course_1: "#199eb7",
          course_2: "#ffffff",
          course_3: "#c8c8c8",
          course_4: "#767777"
        }
        expect(user.custom_colors.map { |_k, v| WCAGColorContrast.ratio(v.delete("#"), "ffffff") }).to all(be >= 4.5)
      end

      it "doesn't break in the presence of 3 character hashes" do
        user.preferences[:custom_colors] = { user_1: "#fff" }
        expect(user.custom_colors[:user_1]).to eq("#717171")
      end

      it "leaves colors with enough contrast alone" do
        user.preferences[:custom_colors] = { user_1: "#757777" }
        expect(user.custom_colors[:user_1]).to eq("#757777")
      end
    end
  end

  describe "#prefers_no_celebrations?" do
    let(:user) { user_model }

    it "returns false by default" do
      expect(user.prefers_no_celebrations?).to be false
    end

    context "user has opted out of celebrations" do
      before do
        user.enable_feature!(:disable_celebrations)
      end

      it "returns true" do
        expect(user.prefers_no_celebrations?).to be true
      end
    end
  end

  describe "#prefers_no_keyboard_shortcuts?" do
    let(:user) { user_model }

    it "returns false by default" do
      expect(user.prefers_no_keyboard_shortcuts?).to be false
    end

    it "returns true if user disables keyboard shortcuts" do
      user.enable_feature!(:disable_keyboard_shortcuts)
      expect(user.prefers_no_keyboard_shortcuts?).to be true
    end
  end

  describe "with_last_login" do
    it "does not double the users select if select values are already present" do
      expect(User.all.order_by_sortable_name.with_last_login.to_sql.scan(".*").count).to eq 1
    end

    it "still includes it if select values aren't present" do
      expect(User.all.with_last_login.to_sql.scan(".*").count).to eq 1
    end
  end

  describe "#can_create_enrollment_for?" do
    before(:once) do
      course_with_ta
      @course.root_account.enable_feature!(:granular_permissions_manage_users)
    end

    it "checks permissions" do
      expect(@ta.can_create_enrollment_for?(@course, nil, "TeacherEnrollment")).to be_falsey
      expect(@ta.can_create_enrollment_for?(@course, nil, "TaEnrollment")).to be_falsey
      expect(@ta.can_create_enrollment_for?(@course, nil, "DesignerEnrollment")).to be_falsey
      expect(@ta.can_create_enrollment_for?(@course, nil, "StudentEnrollment")).to be_truthy
      expect(@ta.can_create_enrollment_for?(@course, nil, "ObserverEnrollment")).to be_truthy
    end

    it "returns false if :manage_students is enabled" do
      @course.root_account.role_overrides.create!(
        permission: "add_student_to_course",
        role: ta_role,
        enabled: false
      )
      expect(@ta.can_create_enrollment_for?(@course, nil, "StudentEnrollment")).to be_falsey
    end

    it "returns true if :manage_students is disabled" do
      @course.root_account.role_overrides.create!(
        permission: "manage_students",
        role: ta_role,
        enabled: false
      )
      expect(@ta.can_create_enrollment_for?(@course, nil, "StudentEnrollment")).to be_truthy
    end

    context "blueprint courses" do
      before :once do
        @teacher = user_factory(active_all: true)
        @course.enroll_teacher(@teacher, enrollment_state: :active)
        MasterCourses::MasterTemplate.set_as_master_course(@course)
      end

      it "returns false for StudentEnrollment and ObserverEnrollment types" do
        expect(@teacher.can_create_enrollment_for?(@course, nil, "StudentEnrollment")).to be_falsey
        expect(@teacher.can_create_enrollment_for?(@course, nil, "ObserverEnrollment")).to be_falsey
      end

      it "returns true for TeacherEnrollment types" do
        expect(@teacher.can_create_enrollment_for?(@course, nil, "TeacherEnrollment")).to be_truthy
      end
    end
  end

  describe "comment_bank_items" do
    before(:once) do
      course_with_teacher
      @c1 = comment_bank_item_model({ user: @teacher })
      @c2 = comment_bank_item_model({ user: @teacher })
    end

    it "only returns active records" do
      @c2.destroy
      expect(@teacher.comment_bank_items).to eq [@c1]
    end
  end

  describe "create_courses_right" do
    before :once do
      @user = user_factory(active_all: true)
      @account = Account.default
    end

    it "returns :admin for AccountUsers with :manage_courses" do
      account_admin_user(user: @user)
      expect(@user.create_courses_right(@account)).to be(:admin)
    end

    it "returns nil for AccountUsers without :manage_courses" do
      account_admin_user_with_role_changes(user: @user, role_changes: { manage_courses_add: false })
      expect(@user.create_courses_right(@account)).to be_nil
    end

    it "returns nil if fake student" do
      fake_student = course_factory(active_all: true).student_view_student
      expect(fake_student.create_courses_right(@account)).to be_nil
    end

    it "returns :teacher if user has teacher enrollments iff teachers_can_create_courses?" do
      course_with_teacher(user: @user, active_all: true)
      expect(@user.create_courses_right(@account)).to be_nil
      @account.settings[:teachers_can_create_courses] = true
      @account.save!
      expect(@user.create_courses_right(@account)).to be(:teacher)
    end

    it "returns :student if user has student enrollments iff students_can_create_courses?" do
      course_with_student(user: @user, active_all: true)
      expect(@user.create_courses_right(@account)).to be_nil
      @account.settings[:students_can_create_courses] = true
      @account.save!
      expect(@user.create_courses_right(@account)).to be(:student)
    end

    it "returns :no_enrollments if user has teacher enrollments iff no_enrollments_can_create_courses?" do
      expect(@user.create_courses_right(@account)).to be_nil
      @account.settings[:no_enrollments_can_create_courses] = true
      @account.save!
      expect(@user.create_courses_right(@account.manually_created_courses_account)).to be(:no_enrollments)
    end

    it "does not count deleted teacher enrollments" do
      enrollment = course_with_teacher(user: @user)
      enrollment.workflow_state = "deleted"
      enrollment.save!
      @account.settings[:teachers_can_create_courses] = true
      @account.save!
      expect(@user.create_courses_right(@account)).to be_nil
    end

    it "returns :student if user has teacher and student enrollments but teachers_can_create_courses is false" do
      course_with_teacher(user: @user, active_all: true)
      course_with_student(user: @user, active_all: true)
      @account.settings[:students_can_create_courses] = true
      @account.save!
      expect(@user.create_courses_right(@account)).to be(:student)
    end

    context "with teachers_can_create_courses_anywhere and students_can_create_courses_anywhere false" do
      before :once do
        @account.settings[:teachers_can_create_courses_anywhere] = false
        @account.settings[:students_can_create_courses_anywhere] = false
        @account.save!
      end

      context "with teachers_can_create_courses and students_can_create_courses true" do
        before :once do
          @account.settings[:teachers_can_create_courses] = true
          @account.settings[:students_can_create_courses] = true
          @account.save!
        end

        context "when user has no k5 enrollments" do
          before do
            allow(@user).to receive(:active_k5_enrollments?).and_return(false)
          end

          it "returns nil for root account if user has teacher enrollments but teachers_can_create_courses_anywhere is false" do
            course_with_teacher(user: @user, active_all: true)
            expect(@user.create_courses_right(@account)).to be_nil
          end

          it "returns nil for root account if user has student enrollments but students_can_create_courses_anywhere is false" do
            course_with_student(user: @user, active_all: true)
            expect(@user.create_courses_right(@account)).to be_nil
          end

          it "returns :teacher for MCC account if user has teacher enrollments and teachers_can_create_courses_anywhere is false" do
            course_with_teacher(user: @user, active_all: true)
            expect(@user.create_courses_right(@account.manually_created_courses_account)).to be(:teacher)
          end

          it "returns :student for MCC account if user has student enrollments and students_can_create_courses_anywhere is false" do
            course_with_student(user: @user, active_all: true)
            expect(@user.create_courses_right(@account.manually_created_courses_account)).to be(:student)
          end
        end

        context "when user has some k5 enrollments" do
          before do
            allow(@user).to receive(:active_k5_enrollments?).and_return(true)
          end

          it "returns :teacher for root account if user has teacher enrollments even though teachers_can_create_courses_anywhere is false" do
            course_with_teacher(user: @user, active_all: true)
            expect(@user.create_courses_right(@account)).to be(:teacher)
          end

          it "returns :student for root account if user has student enrollments even though students_can_create_courses_anywhere is false" do
            course_with_student(user: @user, active_all: true)
            expect(@user.create_courses_right(@account)).to be(:student)
          end

          it "still returns :teacher for MCC account if user has teacher enrollments and teachers_can_create_courses_anywhere is false" do
            course_with_teacher(user: @user, active_all: true)
            expect(@user.create_courses_right(@account.manually_created_courses_account)).to be(:teacher)
          end

          it "still returns :student for MCC account if user has student enrollments and students_can_create_courses_anywhere is false" do
            course_with_student(user: @user, active_all: true)
            expect(@user.create_courses_right(@account.manually_created_courses_account)).to be(:student)
          end
        end
      end
    end
  end

  it "destroys associated gradebook filters when the user is soft-deleted" do
    course_with_teacher(active_all: true)
    @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })
    @teacher.destroy
    expect(@teacher.gradebook_filters.count).to eq 0
  end

  describe "add_to_visited_tabs" do
    before :once do
      user_factory
    end

    it "adds the tab to the user's visited_tabs preference" do
      @user.add_to_visited_tabs("tab_1")
      expect(@user.reload.get_preference(:visited_tabs)).to eq ["tab_1"]
      @user.add_to_visited_tabs("tab_2")
      expect(@user.reload.get_preference(:visited_tabs)).to eq %w[tab_1 tab_2]
    end

    it "adds a tab only once to the visited_tabs preference" do
      @user.set_preference(:visited_tabs, ["tab_4"])
      @user.add_to_visited_tabs("tab_4")
      expect(@user.reload.get_preference(:visited_tabs)).to eq ["tab_4"]
    end
  end

  context "account_calendars" do
    before :once do
      user_factory(active_all: true)
      @root_account = Account.default
      @root_account.account_calendar_visible = false
      @root_account.save!
      @associated_subaccount = @root_account.sub_accounts.create!(account_calendar_visible: true)
      @random_subaccount = @root_account.sub_accounts.create!(account_calendar_visible: true)
      course_with_student(account: @root_account, user: @user)
      course_with_student(account: @associated_subaccount, user: @user)
    end

    describe "all_account_calendars" do
      it "returns accounts associated to the user where the calendar is visible" do
        expect(@user.all_account_calendars.pluck(:id)).to contain_exactly(@associated_subaccount.id)
      end

      it "returns accounts associated to the user and from active account users where the calendar is visible" do
        @account_user = @root_account.account_users.create!(account_id: @root_account.id, user: @user)
        @account_user_subaccount = @associated_subaccount.sub_accounts.create!(account_calendar_visible: true)
        course_with_student(account: @account_user_subaccount, user: @user)
        expect(@user.all_account_calendars.pluck(:id)).to contain_exactly(@associated_subaccount.id, @account_user_subaccount.id)
      end

      describe "sharding" do
        specs_require_sharding

        before :once do
          @shard2.activate do
            @account2 = Account.create!(account_calendar_visible: true)
          end
          course_with_student(account: @account2, user: @user)
        end

        it "includes cross-shard accounts" do
          expect(@user.all_account_calendars.pluck(:id)).to contain_exactly(@associated_subaccount.id, @account2.id)
        end

        it "includes cross-shard accounts and from active account users where the calendar is visible" do
          @account_user = @root_account.account_users.create!(account_id: @root_account.id, user: @user)
          @account_user_subaccount = @associated_subaccount.sub_accounts.create!(account_calendar_visible: true)
          course_with_student(account: @account_user_subaccount, user: @user)
          expect(@user.all_account_calendars.pluck(:id)).to contain_exactly(@associated_subaccount.id, @account2.id, @account_user_subaccount.id)
        end
      end
    end

    describe "enabled_account_calendars" do
      it "returns subset of all_account_calendars where the user has subscribed" do
        @root_account.account_calendar_visible = true
        @root_account.save!
        @user.set_preference(:enabled_account_calendars, [@root_account.id])
        expect(@user.enabled_account_calendars.pluck(:id)).to contain_exactly(@root_account.id)
      end

      it "returns auto-subscribed account calendars" do
        expect(@user.enabled_account_calendars.pluck(:id)).to be_empty
        @associated_subaccount.account_calendar_subscription_type = "auto"
        @associated_subaccount.save!
        expect(@user.enabled_account_calendars.pluck(:id)).to contain_exactly(@associated_subaccount.id)
      end

      it "returns subscribed and auto-subscribed account calendars" do
        @root_account.account_calendar_visible = true
        @root_account.save!
        @user.set_preference(:enabled_account_calendars, [@root_account.id])

        @associated_subaccount.account_calendar_subscription_type = "auto"
        @associated_subaccount.save!
        expect(@user.enabled_account_calendars.pluck(:id)).to contain_exactly(@root_account.id, @associated_subaccount.id)
      end
    end
  end

  describe "discussions_splitscreen_view" do
    it "returns false for a user without the setting set" do
      u = User.create
      expect(u.discussions_splitscreen_view?).to be(false)
    end

    it "returns false for a user when the setting is false" do
      u = User.create
      u.preferences[:discussions_splitscreen_view] = false
      expect(u.discussions_splitscreen_view?).to be(false)
    end

    it "returns true for a user when the setting is true" do
      u = User.create
      u.preferences[:discussions_splitscreen_view] = true
      expect(u.discussions_splitscreen_view?).to be(true)
    end
  end

  describe "disabled?" do
    before do
      @account = Account.create!
      @user = User.create! name: "longname1", short_name: "shortname1"
    end

    it "if all pseudonyms are suspended then the user is suspended" do
      p1 = @user.pseudonyms.new unique_id: "uniqueid1", account: @account
      p1.workflow_state = "suspended"
      p1.sis_user_id = "sisid1"
      p1.save!
      p2 = @user.pseudonyms.new unique_id: "uniqueid2", account: @account
      p2.workflow_state = "suspended"
      p2.sis_user_id = "sisid2"
      p2.save!

      expect(@user.suspended?).to be_truthy
    end

    it "if only one of the pseudonyms is suspended then the user is not suspended" do
      p1 = @user.pseudonyms.new unique_id: "uniqueid1", account: @account
      p1.workflow_state = "suspended"
      p1.sis_user_id = "sisid1"
      p1.save!
      p2 = @user.pseudonyms.new unique_id: "uniqueid2", account: @account
      p2.sis_user_id = "sisid2"
      p2.save!

      expect(@user.suspended?).to be_falsey
    end

    it "if there are no pseudonyms then the user is not suspended" do
      expect(@user.suspended?).to be_falsey
    end
  end

  describe "#adminable_accounts_recursive and #adminable_account_ids_recursive" do
    let(:root_account) { Account.create!(name: "Root Account") }
    let(:account) { Account.create!(name: "Account", parent_account: root_account) }
    let(:sub_account_a) { Account.create!(name: "Account", parent_account: account) }
    let(:sub_account_b) { Account.create!(name: "Account", parent_account: account) }
    let(:sub_account_b_1) { Account.create!(name: "Account", parent_account: sub_account_b) }
    let(:sub_account_a_1) { Account.create!(name: "Account", parent_account: sub_account_a) }

    let(:root_account2) { Account.create!(name: "Root Account 2") }
    let(:ra2_subaccount) { Account.create!(name: "Account", parent_account: root_account2) }

    let(:user) { User.create! }

    let(:expected_adminable) { [sub_account_b_1, sub_account_a, sub_account_a_1] }

    before do
      # Create all accounts:
      sub_account_b_1
      sub_account_a_1
      ra2_subaccount

      AccountUser.create!(account: sub_account_b_1, user:)
      AccountUser.create!(account: sub_account_a, user:)
      AccountUser.create!(account: ra2_subaccount, user:)
    end

    describe "#adminable_accounts_recursive" do
      subject { user.adminable_accounts_recursive(starting_root_account: root_account) }

      it "returns a scope with all subaccounts" do
        expect(subject).to be_an ActiveRecord::Relation
        expect(subject.to_a).to contain_exactly(*expected_adminable)
      end
    end

    describe "#adminable_accounts_ids_recursive" do
      subject { user.adminable_account_ids_recursive(starting_root_account: root_account) }

      it "returns all subaccount ids" do
        expect(subject).to contain_exactly(*expected_adminable.map(&:id))
      end
    end
  end
end
