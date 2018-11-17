#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe SplitUsers do
  describe 'user splitting' do
    let!(:user1) { user_model }
    let!(:user2) { user_model }
    let(:user3) { user_model }
    let(:course1) { course_factory(active_all: true) }
    let(:course2) { course_factory(active_all: true) }
    let(:course3) { course_factory(active_all: true) }
    let(:account1) { Account.default }
    let(:sub_account) { account1.sub_accounts.create! }

    it 'should restore pseudonyms to the original user' do
      pseudonym1 = user1.pseudonyms.create!(unique_id: 'sam1@example.com')
      pseudonym2 = user2.pseudonyms.create!(unique_id: 'sam2@example.com')
      pseudonym3 = user2.pseudonyms.create!(unique_id: 'sam3@example.com')
      UserMerge.from(user2).into(user1)
      SplitUsers.split_db_users(user1)

      user1.reload
      user2.reload
      expect(pseudonym1.user).to eq user1
      expect(pseudonym2.user).to eq user2
      expect(pseudonym3.user).to eq user2
    end

    it 'should not split if the data is too old' do
      pseudonym1 = user1.pseudonyms.create!(unique_id: 'sam1@example.com')
      pseudonym2 = user2.pseudonyms.create!(unique_id: 'sam2@example.com')
      Timecop.travel(183.days.ago) do
        UserMerge.from(user2).into(user1)
      end

      expect(SplitUsers.split_db_users(user1)).to eq []

      expect(user2.workflow_state).to eq 'deleted'
      expect(pseudonym1.reload.user).to eq user1
      expect(pseudonym2.reload.user).to eq user1
    end

    it 'should use the setting for split time.' do
      pseudonym1 = user1.pseudonyms.create!(unique_id: 'sam1@example.com')
      pseudonym2 = user2.pseudonyms.create!(unique_id: 'sam2@example.com')
      Setting.set('user_merge_to_split_time', '12')
      Timecop.travel(15.days.ago) do
        UserMerge.from(user2).into(user1)
      end

      expect(SplitUsers.split_db_users(user1)).to eq []

      Setting.set('user_merge_to_split_time', '30')

      SplitUsers.split_db_users(user1)
      expect(pseudonym1.reload.user).to eq user1
      expect(pseudonym2.reload.user).to eq user2
    end

    describe 'with merge data' do

      it 'should split multiple users if no merge_data is specified' do
        enrollment1 = course1.enroll_student(user1, enrollment_state: 'active')
        enrollment2 = course1.enroll_student(user2, enrollment_state: 'active')
        enrollment3 = course2.enroll_student(user1, enrollment_state: 'active')
        enrollment4 = course3.enroll_teacher(user1)
        enrollment5 = course1.enroll_teacher(user3)
        UserMerge.from(user1).into(user2)
        UserMerge.from(user3).into(user2)
        SplitUsers.split_db_users(user2)

        user1.reload
        user2.reload
        user3.reload
        expect(user1).not_to be_deleted
        expect(user2).not_to be_deleted
        expect(user3).not_to be_deleted
        expect(enrollment1.reload.user).to eq user1
        expect(enrollment1.workflow_state).to eq 'active'
        expect(enrollment2.reload.user).to eq user2
        expect(enrollment3.reload.user).to eq user1
        expect(enrollment4.reload.user).to eq user1
        expect(enrollment5.reload.user).to eq user3
      end

      it 'should handle conflicting enrollments' do
        enrollment1 = course1.enroll_student(user1, enrollment_state: 'active')
        UserMerge.from(user1).into(user2)
        enrollment2 = course1.enroll_student(user1, enrollment_state: 'active')
        SplitUsers.split_db_users(user2)

        user1.reload
        user2.reload
        expect(user1).not_to be_deleted
        expect(user2).not_to be_deleted
        expect(enrollment1.reload.user).to eq user2
        expect(enrollment2.reload.user).to eq user1
      end

      it 'should handle user_observers' do
        observer1 = user_model
        observer2 = user_model
        user1.linked_observers << observer1
        user2.linked_observers << observer2
        UserMerge.from(user1).into(user2)

        SplitUsers.split_db_users(user2)

        expect(user1.linked_observers).to eq [observer1]
        expect(user2.linked_observers).to eq [observer2]
      end

      it 'should handle attachments' do
        attachment1 = Attachment.create!(user: user1,
          context: user1,
          filename: "test.txt",
          uploaded_data: StringIO.new("first"))
        attachment2 = Attachment.create!(user: user2,
          context: user2,
          filename: "test2.txt",
          uploaded_data: StringIO.new("second"))

        UserMerge.from(user1).into(user2)
        run_jobs

        expect(attachment1.reload.context).to eq user2
        expect(user1.reload.attachments).to eq []

        SplitUsers.split_db_users(user2)
        expect(user1.reload.attachments).to eq [attachment1]
        expect(user2.reload.attachments).to eq [attachment2]
      end

      it 'should handle when observing merged user' do
        user2.linked_observers << user1
        UserMerge.from(user1).into(user2)

        SplitUsers.split_db_users(user2)

        expect(user1.as_observer_observation_links).to eq UserObservationLink.where(user_id: user2, observer_id: user1)
        expect(user2.as_student_observation_links).to eq UserObservationLink.where(user_id: user2, observer_id: user1)
      end


      it 'should handle as_observer_observation_links' do
        observee1 = user_model
        observee2 = user_model
        observee1.linked_observers << user1
        observee2.linked_observers << user2
        UserMerge.from(user1).into(user2)

        SplitUsers.split_db_users(user2)

        expect(user1.as_observer_observation_links).to eq observee1.as_student_observation_links
        expect(user2.as_observer_observation_links).to eq observee2.as_student_observation_links
      end

      it 'should handle duplicate user_observers' do
        observer1 = user_model
        observee1 = user_model
        observee1.linked_observers << user1
        observee1.linked_observers << user2
        user1.linked_observers << observer1
        user2.linked_observers << observer1
        UserMerge.from(user1).into(user2)
        SplitUsers.split_db_users(user2)

        expect(user1.as_observer_observation_links.count).to eq 1
        expect(user2.as_observer_observation_links.count).to eq 1
        expect(user1.linked_observers).to eq [observer1]
        expect(user2.linked_observers).to eq [observer1]

        expect(user1.as_observer_observation_links.first.workflow_state).to eq 'active'
        expect(user2.as_observer_observation_links.first.workflow_state).to eq 'active'
        expect(user1.as_student_observation_links.first.workflow_state).to eq 'active'
        expect(user2.as_student_observation_links.first.workflow_state).to eq 'active'
      end

      it 'should only split users from merge_data when specified' do
        enrollment1 = course1.enroll_user(user1)
        enrollment2 = course1.enroll_student(user2, enrollment_state: 'active')
        enrollment3 = course2.enroll_student(user1, enrollment_state: 'active')
        enrollment4 = course3.enroll_teacher(user1)
        enrollment5 = course1.enroll_teacher(user3)
        UserMerge.from(user1).into(user2)
        UserMerge.from(user3).into(user2)
        merge_data = UserMergeData.where(user_id: user2, from_user: user1).first
        SplitUsers.split_db_users(user2, merge_data)

        user1.reload
        user2.reload
        user3.reload
        expect(user1).not_to be_deleted
        expect(user2).not_to be_deleted
        expect(user3).to be_deleted
        expect(enrollment1.reload.user).to eq user1
        expect(enrollment2.reload.user).to eq user2
        expect(enrollment3.reload.user).to eq user1
        expect(enrollment4.reload.user).to eq user1
        expect(enrollment5.reload.user).to eq user2
      end

      it "should move ccs to the new user (but only if they don't already exist)" do
        # unconfirmed: active conflict
        user1.communication_channels.create!(path: 'a@instructure.com')
        user2.communication_channels.create!(path: 'A@instructure.com') { |cc| cc.workflow_state = 'active' }
        # active: unconfirmed conflict
        user1.communication_channels.create!(path: 'b@instructure.com') { |cc| cc.workflow_state = 'active' }
        cc = user2.communication_channels.create!(path: 'B@instructure.com')
        # active: active conflict
        user1.communication_channels.create!(path: 'c@instructure.com') { |cc| cc.workflow_state = 'active' }
        user2.communication_channels.create!(path: 'C@instructure.com') { |cc| cc.workflow_state = 'active' }
        # unconfirmed: unconfirmed conflict
        user1.communication_channels.create!(path: 'd@instructure.com')
        user2.communication_channels.create!(path: 'D@instructure.com')
        # retired: unconfirmed conflict
        user1.communication_channels.create!(path: 'e@instructure.com') { |cc| cc.workflow_state = 'retired' }
        user2.communication_channels.create!(path: 'E@instructure.com')
        # unconfirmed: retired conflict
        user1.communication_channels.create!(path: 'f@instructure.com')
        user2.communication_channels.create!(path: 'F@instructure.com') { |cc| cc.workflow_state = 'retired' }
        # retired: active conflict
        user1.communication_channels.create!(path: 'g@instructure.com') { |cc| cc.workflow_state = 'retired' }
        user2.communication_channels.create!(path: 'G@instructure.com') { |cc| cc.workflow_state = 'active' }
        # active: retired conflict
        user1.communication_channels.create!(path: 'h@instructure.com') { |cc| cc.workflow_state = 'active' }
        user2.communication_channels.create!(path: 'H@instructure.com') { |cc| cc.workflow_state = 'retired' }
        # retired: retired conflict
        user1.communication_channels.create!(path: 'i@instructure.com') { |cc| cc.workflow_state = 'retired' }
        user2.communication_channels.create!(path: 'I@instructure.com') { |cc| cc.workflow_state = 'retired' }
        # <nothing>: active
        user2.communication_channels.create!(path: 'J@instructure.com') { |cc| cc.workflow_state = 'active' }
        # active: <nothing>
        user1.communication_channels.create!(path: 'k@instructure.com') { |cc| cc.workflow_state = 'active' }
        # <nothing>: unconfirmed
        user2.communication_channels.create!(path: 'L@instructure.com')
        # unconfirmed: <nothing>
        user1.communication_channels.create!(path: 'm@instructure.com')
        # <nothing>: retired
        user2.communication_channels.create!(path: 'N@instructure.com') { |cc| cc.workflow_state = 'retired' }
        # retired: <nothing>
        user1.communication_channels.create!(path: 'o@instructure.com') { |cc| cc.workflow_state = 'retired' }

        user1_ccs = user1.communication_channels.where.not(workflow_state: 'retired').
          map { |cc| [cc.path, cc.workflow_state] }.sort
        # cc will not be restored because it conflicted on merge and it was unconfirmed and it is frd deleted
        user2_ccs = user2.communication_channels.where.not(id: cc, workflow_state: 'retired').
          map { |cc| [cc.path, cc.workflow_state] }.sort

        UserMerge.from(user1).into(user2)
        SplitUsers.split_db_users(user2)
        user1.reload
        user2.reload

        expect(user1.communication_channels.where.not(workflow_state: 'retired').
          map { |cc| [cc.path, cc.workflow_state] }.sort).to eq user1_ccs
        expect(user2.communication_channels.where.not(workflow_state: 'retired').
          map { |cc| [cc.path, cc.workflow_state] }.sort).to eq user2_ccs
      end

    end

    it 'should restore submissions' do
      course1.enroll_student(user1, enrollment_state: 'active')
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
      }
      submission = assignment.submissions.find_by!(user: user1)
      submission.update!(valid_attributes)

      UserMerge.from(user1).into(user2)
      expect(submission.reload.user).to eq user2
      SplitUsers.split_db_users(user2)
      expect(submission.reload.user).to eq user1
    end

    it 'should handle conflicting submissions' do
      course1.enroll_student(user1, enrollment_state: 'active')
      course1.enroll_student(user2, enrollment_state: 'active')
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
      }
      submission1 = assignment.submissions.find_by!(user: user1)
      submission1.update!(valid_attributes)
      submission2 = assignment.submissions.find_by!(user: user2)
      submission2.update!(valid_attributes)

      UserMerge.from(user1).into(user2)
      expect(submission1.reload.user).to eq user1
      expect(submission2.reload.user).to eq user2
      Submission.where(id: submission1).update_all(workflow_state: 'deleted')
      SplitUsers.split_db_users(user2)
      expect(submission1.reload.user).to eq user1
      expect(submission2.reload.user).to eq user2
    end

    it 'should handle conflicting submissions other way too' do
      course1.enroll_student(user1, enrollment_state: 'active')
      course1.enroll_student(user2, enrollment_state: 'active')
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
      }
      submission1 = assignment.submissions.find_by!(user: user1)
      submission1.update!(valid_attributes)
      submission2 = assignment.submissions.find_by!(user: user2)

      UserMerge.from(user1).into(user2)
      expect(submission1.reload.user).to eq user2
      expect(submission2.reload.user).to eq user1
      SplitUsers.split_db_users(user2)
      expect(submission1.reload.user).to eq user1
      expect(submission2.reload.user).to eq user2
    end

    it 'should not blow up on deleted courses' do
      course1.enroll_student(user1, enrollment_state: 'active')
      UserMerge.from(user1).into(user2)
      course1.destroy
      expect { SplitUsers.split_db_users(user2) }.not_to raise_error
    end

    it 'should restore admins to the original state' do
      admin = account1.account_users.create(user: user1)
      admin2 = sub_account.account_users.create(user: user1)
      admin3 = sub_account.account_users.create(user: user2)
      UserMerge.from(user1).into(user2)
      admin.reload.destroy
      SplitUsers.split_db_users(user2)

      expect(admin.reload.workflow_state).to eq 'active'
      expect(admin.reload.user).to eq user1
      expect(admin2.reload.user).to eq user1
      expect(admin3.reload.user).to eq user2
    end

    context 'sharding' do
      specs_require_sharding

      it 'should merge a user across shards' do
        user1 = user_with_pseudonym(username: 'user1@example.com', active_all: 1)
        p1 = @pseudonym
        @shard1.activate do
          account = Account.create!
          @user2 = user_with_pseudonym(username: 'user2@example.com', active_all: 1, account: account)
          @p2 = @pseudonym
          UserMerge.from(user1).into(@user2)
          SplitUsers.split_db_users(@user2)
        end

        user1.reload
        @user2.reload

        expect(user1).not_to be_deleted
        expect(p1.reload.user).to eq user1
        expect(@user2.all_pseudonyms).to eq [@p2]
      end

      it 'should split a user across shards' do
        user1 = user_with_pseudonym(username: 'user1@example.com', active_all: 1)
        p1 = @pseudonym
        @shard1.activate do
          account = Account.create!
          @user2 = user_with_pseudonym(username: 'user2@example.com', active_all: 1, account: account)
          @p2 = @pseudonym
          UserMerge.from(user1).into(@user2)
        end
        SplitUsers.split_db_users(@user2)
        user1.reload
        @user2.reload

        expect(user1).not_to be_deleted
        expect(p1.reload.user).to eq user1
        expect(@user2.all_pseudonyms).to eq [@p2]
      end

      it "should split a user across shards with ccs" do
        user1 = user_with_pseudonym(username: 'user1@example.com', active_all: 1)
        user1_ccs = user1.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort

        @shard1.activate do
          account = Account.create!
          @user2 = user_with_pseudonym(username: 'user2@example.com', active_all: 1, account: account)
        end
        user2_ccs = @user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort

        @shard1.activate do
          UserMerge.from(user1).into(@user2)
          cc = @user2.reload.communication_channels.where(path: 'user1@example.com').take
          n = Notification.create!(name: 'Assignment Createds', subject: 'Tests', category: 'TestNevers')
          NotificationPolicy.create(notification: n, communication_channel: cc, frequency: 'immediately')
          SplitUsers.split_db_users(@user2)
        end

        user1.reload
        @user2.reload
        expect(user1.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq user1_ccs
        expect(@user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq user2_ccs
      end

      it 'should handle enrollments across shards' do
        user1 = user_with_pseudonym(username: 'user1@example.com', active_all: 1)
        e = course1.enroll_user(user1)
        @shard1.activate do
          account = Account.create!
          @user2 = user_with_pseudonym(username: 'user2@example.com', active_all: 1, account: account)
          @p2 = @pseudonym
          @shard1_course = account.courses.create!
          @e = @shard1_course.enroll_user(@user2)
          UserMerge.from(user1).into(@user2)
        end
        SplitUsers.split_db_users(@user2)

        expect(e.reload.user).to eq user1
        expect(@e.reload.user).to eq @user2
      end

      it "should work with cross-shard submissions" do
        @shard1.activate do
          course_with_teacher(:account => account_model)
        end

        @course.enroll_student(user1, enrollment_state: 'active')
        assignment = @course.assignments.create!(title: "some assignment", workflow_state: 'published', submission_types: "online_text_entry")
        submission = assignment.submit_homework(user1, submission_type: 'online_text_entry', body: 'fooey')

        UserMerge.from(user1).into(user2)
        #expect(submission.reload.user).to eq user2
        SplitUsers.split_db_users(user2)
        expect(submission.reload.user).to eq user1
      end
    end
  end
end
