#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
    user
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
        user
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
  end
end
