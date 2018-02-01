#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe AccountNotification do

  before :once do
    account_notification
    user_factory
  end

  it "should find notifications" do
    expect(AccountNotification.for_user_and_account(@user, @account)).to eq [@announcement]
  end

  it "should find site admin announcements" do
    @announcement.destroy
    account_notification(:account => Account.site_admin)
    expect(AccountNotification.for_user_and_account(@user, Account.default)).to eq [@announcement]
  end

  it "should find announcements only if user has a role in the list of roles to which the announcement is restricted" do
    @announcement.destroy
    role_ids = ["TeacherEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
    account_notification(:role_ids => role_ids, :message => "Announcement 1")
    @a1 = @announcement
    account_notification(:account => @account, :role_ids => [nil], :message => "Announcement 2") #students not currently taking a course
    @a2 = @announcement
    account_notification(:account => @account, :message => "Announcement 3") # no roles, should go to all
    @a3 = @announcement

    @unenrolled = @user
    course_with_teacher(:account => @account)
    @teacher = @user
    account_admin_user(:account => @account)
    @admin = @user
    course_with_student(:course => @course)
    @student = @user

    expect(AccountNotification.for_user_and_account(@teacher, @account).map(&:id).sort).to eq [@a1.id, @a3.id]
    expect(AccountNotification.for_user_and_account(@admin, @account).map(&:id).sort).to eq [@a1.id, @a2.id, @a3.id]
    expect(AccountNotification.for_user_and_account(@student, @account).map(&:id).sort).to eq [@a3.id]
    expect(AccountNotification.for_user_and_account(@unenrolled, @account).map(&:id).sort).to eq [@a2.id, @a3.id]

    account_notification(:account => Account.site_admin, :role_ids => role_ids, :message => "Announcement 1")
    @a4 = @announcement
    account_notification(:account => Account.site_admin, :role_ids => [nil], :message => "Announcement 2") #students not currently taking a course
    @a5 = @announcement
    account_notification(:account => Account.site_admin, :message => "Announcement 3") # no roles, should go to all
    @a6 = @announcement

    expect(AccountNotification.for_user_and_account(@teacher, Account.site_admin).map(&:id).sort).to eq [@a4.id, @a6.id]
    expect(AccountNotification.for_user_and_account(@admin, Account.site_admin).map(&:id).sort).to eq [@a4.id, @a5.id, @a6.id]
    expect(AccountNotification.for_user_and_account(@student, Account.site_admin).map(&:id).sort).to eq [@a6.id]
    expect(AccountNotification.for_user_and_account(@unenrolled, Account.site_admin).map(&:id).sort).to eq [@a5.id, @a6.id]
  end

  it "should allow closing an announcement" do
    @user.close_announcement(@announcement)
    expect(@user.preferences[:closed_notifications]).to eq [@announcement.id]
    expect(AccountNotification.for_user_and_account(@user, Account.default)).to eq []
  end

  it "should remove non-applicable announcements from user preferences" do
    @user.close_announcement(@announcement)
    expect(@user.preferences[:closed_notifications]).to eq [@announcement.id]
    @announcement.destroy
    expect(AccountNotification.for_user_and_account(@user, Account.default)).to eq []
    expect(@user.preferences[:closed_notifications]).to eq []
  end

  describe "sub accounts" do
    before :once do
      @sub_account = Account.default.sub_accounts.create!
    end

    it "should find announcements where user is enrolled" do
      params = {
        subject: 'sub account notification',
        account: @sub_account,
        role_ids: [Role.get_built_in_role("StudentEnrollment").id]
      }
      sub_account_announcement = sub_account_notification(params)
      unenrolled = @user
      course_with_student(account: @sub_account, active_all: true)
      students_notifications = AccountNotification.for_user_and_account(@student, Account.default)
      unenrolled_notifications = AccountNotification.for_user_and_account(unenrolled, Account.default)
      expect(students_notifications).to include(@announcement)
      expect(students_notifications).to include(sub_account_announcement)
      expect(unenrolled_notifications).not_to include(sub_account_announcement)
    end

    it "should find announcements from parent accounts to sub-accounts where user is enrolled" do
      params = {
        subject: 'sub account notification',
        account: @sub_account,
        role_ids: [Role.get_built_in_role("StudentEnrollment").id]
      }
      sub_account_announcement = sub_account_notification(params)

      sub_sub_account = @sub_account.sub_accounts.create!
      course_with_student(account: sub_sub_account, active_all: true)
      students_notifications = AccountNotification.for_user_and_account(@student, Account.default)
      expect(students_notifications).to include(sub_account_announcement)
    end

    it "should find announcements where user is an account admin" do
      params = {
        subject: 'sub account notification',
        account: @sub_account,
        role_ids: [Role.get_built_in_role("AccountAdmin").id]
      }
      sub_account_announcement = sub_account_notification(params)
      non_admin_user = @user
      account_admin_user(account: @sub_account)
      admin_notifications = AccountNotification.for_user_and_account(@admin, Account.default)
      non_admin_notifications = AccountNotification.for_user_and_account(non_admin_user, Account.default)
      expect(admin_notifications).to include(@announcement)
      expect(admin_notifications).to include(sub_account_announcement)
      expect(non_admin_notifications).not_to include(sub_account_announcement)
    end

    it "should find announcements with no specified roles if users has any sub account role" do
      params = {
        subject: 'sub account notification',
        account: @sub_account,
      }
      sub_account_announcement = sub_account_notification(params)
      unenrolled_user = @user
      account_admin_user(account: @sub_account)
      course_with_student(account: @sub_account, active_all: true)
      student_notifications = AccountNotification.for_user_and_account(@student, Account.default)
      admin_notifications = AccountNotification.for_user_and_account(@admin, Account.default)
      unenrolled_notifications = AccountNotification.for_user_and_account(unenrolled_user, Account.default)
      expect(student_notifications).to include(sub_account_announcement)
      expect(admin_notifications).to include(sub_account_announcement)
      expect(unenrolled_notifications).not_to include(sub_account_announcement)
    end

    it "should cache based on sub_account_ids" do
      params = {
        subject: 'sub account notification',
        account: @sub_account,
      }
      sub_account_notification(params)
      enable_cache do
        root_and_sub_account = AccountNotification.for_account(Account.default, [@sub_account.id])
        expect(root_and_sub_account.count).to eq 2

        root_account_only = AccountNotification.for_account(Account.default)
        expect(root_account_only.count).to eq 1
      end
    end

    it "scopes to active enrollment accounts" do
      sub_announcement = sub_account_notification(subject: 'blah', account: @sub_account)
      course_with_student(user: @user, account: @sub_account, active_all: true)
      other_root_account = Account.create!
      other_announcement = account_notification(account: other_root_account)
      course_with_student(user: @user, account: other_root_account, active_all: true)
      nother_root_account = Account.create!(name: 'nother account')
      nother_announcement = account_notification(account: nother_root_account)
      # not an active course and will be excluded
      course_with_student(user: @user, account: nother_root_account)

      notes = AccountNotification.for_user_and_account(@user, Account.default)
      expect(notes).to include sub_announcement
      expect(notes).to include other_announcement
      expect(notes).not_to include nother_announcement

      other_notes = AccountNotification.for_user_and_account(@user, other_root_account)
      expect(other_notes).to include sub_announcement
      expect(other_notes).to include other_announcement
      expect(other_notes).not_to include nother_announcement

      nother_notes = AccountNotification.for_user_and_account(@user, nother_root_account)
      expect(nother_notes).to include sub_announcement
      expect(nother_notes).to include other_announcement
      expect(nother_notes).to include nother_announcement
    end
  end

  describe "survey notifications" do
    it "should only display for flagged accounts" do
      flag = AccountNotification::ACCOUNT_SERVICE_NOTIFICATION_FLAGS.first
      account_notification(:required_account_service => flag, :account => Account.site_admin)
      @a1 = account_model
      @a2 = account_model
      @a2.enable_service(flag)
      @a2.save!
      expect(AccountNotification.for_account(@a1)).to eq []
      expect(AccountNotification.for_account(@a2)).to eq [@announcement]
    end

    describe "display_for_user?" do
      it "should select each mod value once throughout the cycle" do
        expect(AccountNotification.display_for_user?(5, 3, Time.zone.parse('2012-04-02'))).to eq false
        expect(AccountNotification.display_for_user?(6, 3, Time.zone.parse('2012-04-02'))).to eq false
        expect(AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-04-02'))).to eq true

        expect(AccountNotification.display_for_user?(5, 3, Time.zone.parse('2012-05-05'))).to eq true
        expect(AccountNotification.display_for_user?(6, 3, Time.zone.parse('2012-05-05'))).to eq false
        expect(AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-05-05'))).to eq false

        expect(AccountNotification.display_for_user?(5, 3, Time.zone.parse('2012-06-04'))).to eq false
        expect(AccountNotification.display_for_user?(6, 3, Time.zone.parse('2012-06-04'))).to eq true
        expect(AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-06-04'))).to eq false
      end

      it "should shift the mod values each new cycle" do
        expect(AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-04-02'))).to eq true
        expect(AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-07-02'))).to eq false
        expect(AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-09-02'))).to eq true
      end
    end

    describe "dexclude students for surveys?" do
      before(:each) do
        flag = AccountNotification::ACCOUNT_SERVICE_NOTIFICATION_FLAGS.first
        @survey = account_notification(:required_account_service => flag, :account => Account.site_admin)
        @a1 = account_model
        @a1.enable_service(flag)
        @a1.save!

        @unenrolled = @user
        course_with_teacher(account: @a1)
        @student_teacher = @user
        course_with_student(course: @course, user: @student_teacher)
        course_with_teacher(course: @course, :account => @a1)
        @teacher = @user
        account_admin_user(:account => @a1)
        @admin = @user
        course_with_student(:course => @course)
        @student = @user
      end

      it "should exclude students on surveys if the account restricts a student" do
        @a1.settings[:include_students_in_global_survey] = false
        @a1.save!

        expect(AccountNotification.for_user_and_account(@teacher, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@admin, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@student, @a1).map(&:id).sort).to eq []
        expect(AccountNotification.for_user_and_account(@student_teacher, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@unenrolled, @a1).map(&:id).sort).to eq [@survey.id]
      end

      it "should exclude students on surveys by default" do
        expect(AccountNotification.for_user_and_account(@teacher, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@admin, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@student, @a1).map(&:id).sort).to eq []
        expect(AccountNotification.for_user_and_account(@student_teacher, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@unenrolled, @a1).map(&:id).sort).to eq [@survey.id]
      end

      it "should include students on surveys when checked" do
        @a1.settings[:include_students_in_global_survey] = true
        @a1.save!

        expect(AccountNotification.for_user_and_account(@teacher, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@admin, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@student, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@student_teacher, @a1).map(&:id).sort).to eq [@survey.id]
        expect(AccountNotification.for_user_and_account(@unenrolled, @a1).map(&:id).sort).to eq [@survey.id]
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should always find notifications for site admin" do
      account_notification(:account => Account.site_admin)

      @shard1.activate do
        @account = Account.create!
        user_factory
        expect(AccountNotification.for_user_and_account(@user, @account)).to eq [@announcement]
      end

      @shard2.activate do
        expect(AccountNotification.for_user_and_account(@user, @account)).to eq [@announcement]
      end
    end

    it "should respect preferences regardless of current shard" do
      @shard1.activate do
        @user.close_announcement(@announcement)
      end
      expect(@user.preferences[:closed_notifications]).to eq [@announcement.id]
      @shard1.activate do
        expect(AccountNotification.for_user_and_account(@user, Account.default)).to eq []
      end
    end

    it "should properly adjust for built in roles across shards" do
      @announcement.destroy

      @shard2.activate do
        @my_frd_account = Account.create!
      end

      Account.site_admin.shard.activate do
        @site_admin_announcement = account_notification(account: Account.site_admin, role_ids: [Role.get_built_in_role("TeacherEnrollment").id])
      end

      @my_frd_account.shard.activate do
        @local_announcement = account_notification(account: @my_frd_account, role_ids: [Role.get_built_in_role("TeacherEnrollment").id])
        course_with_teacher(account: @my_frd_account)
      end

      # announcements should show to teachers, regardless of combination of
      # current shard, association shard, and notification shard
      [Account.site_admin.shard, @my_frd_account.shard, @shard1].each do |shard|
        shard.activate do
          expect(AccountNotification.for_user_and_account(@teacher, Account.site_admin)).to include(@site_admin_announcement)
          expect(AccountNotification.for_user_and_account(@teacher, @my_frd_account)).to include(@site_admin_announcement)
          expect(AccountNotification.for_user_and_account(@teacher, @my_frd_account)).to include(@local_announcement)
        end
      end
    end

    context "announcements across multiple root accounts" do
      before :once do
        @account1 = Account.create!
        @subaccount1 = @account1.sub_accounts.create!
        @course1 = course_with_teacher(:account => @subaccount1, :active_all => true)
        @account2 = Account.create!
        @course2 = course_with_ta(:account => @account2, :user => @user, :active_all => true)
        @shard2.activate do
          @shard2_account = Account.create!
          @shard2_course = course_with_student(:account => @shard2_account, :user => @user, :active_all => true)
        end
      end

      it "should use the correct roles for the respective root accounts" do
        # visible notifications
        @visible1 = account_notification(:account => @subaccount1, :role_ids => [teacher_role.id])
        @visible2 = account_notification(:account => @account2, :role_ids => [ta_role.id])
        @shard2.activate do
          @visible3 = account_notification(:account => @shard2_account, :role_ids => [student_role.id])
        end

        # notifications for roles that the user doesn't have in their root accounts
        @not_visible1 = account_notification(:account => @subaccount1, :role_ids => [student_role.id])
        @not_visible2 = account_notification(:account => @account2, :role_ids => [teacher_role.id])
        @shard2.activate do
          @not_visible3 = account_notification(:account => @shard2_account, :role_ids => [ta_role.id])
        end

        expected = [@visible1, @visible2, @visible3]
        expect(AccountNotification.for_user_and_account(@user, @account1)).to match_array(expected)
        expect(AccountNotification.for_user_and_account(@user, @account2)).to match_array(expected)
        expect(AccountNotification.for_user_and_account(@user, @shard2_account)).to match_array(expected)
      end

      it "should be able to set notifications to be restricted to own domain" do
        expected = []
        expected << account_notification(:account => @account1, :domain_specific => true)
        expected << account_notification(:account => @subaccount1, :domain_specific => true)

        expect(AccountNotification.for_user_and_account(@user, @account1)).to match_array(expected)
        expect(AccountNotification.for_user_and_account(@user, @account2)).to eq []
        expect(AccountNotification.for_user_and_account(@user, @shard2_account)).to eq []
      end

      it "should find notifications on cross-sharded sub-accounts properly" do
        # and perhaps more importantly, don't find notifications for accounts the user doesn't belong in
        id = 1
        while [Shard.default, @shard2].any?{|s| s.activate { Account.where(:id => id).exists? }} # make sure this id is free
          id += 1 #
        end

        @tricky_sub_acc = @account1.sub_accounts.create!(:id => id) # create it with the id
        # they don't belong to this sub-account so they shouldn't see this notification
        @not_visible = account_notification(:account => @tricky_sub_acc)

        @shard2.activate do
          @shard2_subaccount = @shard2_account.sub_accounts.create!(:id => id) # create with same local id
          @shard2_course2 = course_with_student(:account => @shard2_subaccount, :user => @user, :active_all => true)
          @visible = account_notification(:account => @shard2_subaccount, :role_ids => [student_role.id])
        end
        expect(AccountNotification.for_user_and_account(@user, @account1)).to eq [@visible]
      end
    end
  end
end
