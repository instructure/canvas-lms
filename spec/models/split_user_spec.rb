require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe SplitUsers do
  describe 'user splitting' do
    let!(:user1) { user_model }
    let!(:user2) { user_model }
    let(:user3) { user_model }
    let(:course1) { course(active_all: true) }
    let(:course2) { course(active_all: true) }
    let(:course3) { course(active_all: true) }
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
      Timecop.travel(93.days.ago) do
        UserMerge.from(user2).into(user1)
      end

      expect(SplitUsers.split_db_users(user1)).to eq []

      expect(user2.workflow_state).to eq 'deleted'
      expect(pseudonym1.reload.user).to eq user1
      expect(pseudonym2.reload.user).to eq user1
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
        user1.observers << observer1
        user2.observers << observer2
        UserMerge.from(user1).into(user2)

        SplitUsers.split_db_users(user2)

        expect(user1.observers).to eq [observer1]
        expect(user2.observers).to eq [observer2]
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

      it 'should handle user_observees' do
        observee1 = user_model
        observee2 = user_model
        observee1.observers << user1
        observee2.observers << user2
        UserMerge.from(user1).into(user2)

        SplitUsers.split_db_users(user2)

        expect(user1.user_observees).to eq observee1.user_observers
        expect(user2.user_observees).to eq observee2.user_observers
      end

      it 'should handle duplicate user_observers' do
        observer1 = user_model
        observee1 = user_model
        observee1.observers << user1
        observee1.observers << user2
        user1.observers << observer1
        user2.observers << observer1
        UserMerge.from(user1).into(user2)
        SplitUsers.split_db_users(user2)

        expect(user1.user_observees.count).to eq 1
        expect(user2.user_observees.count).to eq 1
        expect(user1.observers).to eq [observer1]
        expect(user2.observers).to eq [observer1]

        expect(user1.user_observees.first.workflow_state).to eq 'active'
        expect(user2.user_observees.first.workflow_state).to eq 'active'
        expect(user1.user_observers.first.workflow_state).to eq 'active'
        expect(user2.user_observers.first.workflow_state).to eq 'active'
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
    end

    it 'should restore submissions' do
      course1.enroll_student(user1, enrollment_state: 'active')
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {assignment_id: assignment.id, user_id: user1.id, grade: "1.5", url: "www.instructure.com"}
      submission = Submission.create!(valid_attributes)

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
      valid_attributes = {assignment_id: assignment.id, user_id: user1.id, grade: "1.5", url: "www.instructure.com"}
      submission1 = Submission.create!(valid_attributes)
      valid_attributes[:user_id] = user2.id
      submission2 = Submission.create!(valid_attributes)

      UserMerge.from(user1).into(user2)
      expect(submission1.reload.user).to eq user1
      expect(submission2.reload.user).to eq user2
      SplitUsers.split_db_users(user2)
      expect(submission1.reload.user).to eq user1
      expect(submission2.reload.user).to eq user2
    end

    it 'should restore admins even with stale data' do
      admin = account1.account_users.create(user: user1)
      admin2 = sub_account.account_users.create(user: user1)
      admin3 = sub_account.account_users.create(user: user2)
      UserMerge.from(user1).into(user2)
      admin.reload.destroy
      SplitUsers.split_db_users(user2)

      expect{admin.reload}.to raise_error(ActiveRecord::RecordNotFound)
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
    end
  end
end
