# frozen_string_literal: true

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

describe SplitUsers do
  describe "user splitting" do
    let!(:restored_user) { user_model } # user will be merged into source_user and then restored on split
    let!(:source_user) { user_model } # always the destination user of merge
    let(:user3) { user_model }
    let(:course1) { course_factory(active_all: true) }
    let(:course2) { course_factory(active_all: true) }
    let(:course3) { course_factory(active_all: true) }
    let(:account1) { Account.default }
    let(:sub_account) { account1.sub_accounts.create! }

    it "restores terms_of use one way" do
      source_user.accept_terms
      source_user.save!
      UserMerge.from(restored_user).into(source_user)
      SplitUsers.split_db_users(restored_user)
      expect(restored_user.reload.preferences[:accepted_terms]).to be_nil
      expect(source_user.reload.preferences[:accepted_terms]).to_not be_nil
    end

    it "restores terms_of use other way" do
      restored_user.accept_terms
      restored_user.save!
      UserMerge.from(restored_user).into(source_user)
      expect(source_user.reload.preferences[:accepted_terms]).to_not be_nil
      SplitUsers.split_db_users(source_user)
      expect(restored_user.reload.preferences[:accepted_terms]).to_not be_nil
      expect(source_user.reload.preferences[:accepted_terms]).to be_nil
    end

    it "restores terms_of use no way" do
      UserMerge.from(restored_user).into(source_user)
      source_user.accept_terms
      source_user.save!
      SplitUsers.split_db_users(source_user)
      expect(source_user.reload.preferences[:accepted_terms]).to be_nil
      expect(restored_user.reload.preferences[:accepted_terms]).to be_nil
    end

    it "restores terms_of use both ways" do
      restored_user.accept_terms
      restored_user.save!
      source_user.accept_terms
      source_user.save!
      UserMerge.from(restored_user).into(source_user)
      SplitUsers.split_db_users(source_user)
      expect(source_user.reload.preferences[:accepted_terms]).to_not be_nil
      expect(restored_user.reload.preferences[:accepted_terms]).to_not be_nil
    end

    it "restores names" do
      restored_user.name = "jimmy one"
      restored_user.save!
      source_user.name = "jenny one"
      source_user.save!
      UserMerge.from(restored_user).into(source_user)
      source_user.name = "other name"
      source_user.save!
      SplitUsers.split_db_users(source_user)
      expect(restored_user.reload.name).to eq "jimmy one"
      expect(source_user.reload.name).to eq "jenny one"
    end

    it "restores pseudonyms to the original user" do
      pseudonym1 = source_user.pseudonyms.create!(unique_id: "sam1@example.com")
      pseudonym2 = account1.pseudonyms.create!(user: restored_user, unique_id: "sam2@example.com")
      pseudonym3 = account1.pseudonyms.create!(user: restored_user, unique_id: "sam3@example.com")
      UserMerge.from(restored_user).into(source_user)
      SplitUsers.split_db_users(source_user)

      source_user.reload
      restored_user.reload
      expect(pseudonym1.user).to eq source_user
      expect(pseudonym2.user).to eq restored_user
      expect(pseudonym3.user).to eq restored_user
    end

    it "does not split if the data is too old" do
      pseudonym1 = source_user.pseudonyms.create!(unique_id: "sam1@example.com")
      pseudonym2 = account1.pseudonyms.create!(user: restored_user, unique_id: "sam2@example.com")
      Timecop.travel(183.days.ago) do
        UserMerge.from(restored_user).into(source_user)
      end

      expect(SplitUsers.split_db_users(source_user)).to eq []

      expect(restored_user.workflow_state).to eq "deleted"
      expect(pseudonym1.reload.user).to eq source_user
      expect(pseudonym2.reload.user).to eq source_user
    end

    it "uses the setting for split time." do
      pseudonym1 = source_user.pseudonyms.create!(unique_id: "sam1@example.com")
      pseudonym2 = account1.pseudonyms.create!(user: restored_user, unique_id: "sam2@example.com")
      Setting.set("user_merge_to_split_time", "12")
      Timecop.travel(15.days.ago) do
        UserMerge.from(restored_user).into(source_user)
      end

      expect(SplitUsers.split_db_users(source_user)).to eq []

      Setting.set("user_merge_to_split_time", "30")

      SplitUsers.split_db_users(source_user)
      expect(pseudonym1.reload.user).to eq source_user
      expect(pseudonym2.reload.user).to eq restored_user
    end

    describe "with merge data" do
      it "restores users without merge data items" do
        UserMerge.from(restored_user).into(source_user)
        UserMergeDataItem.where(user_id: restored_user).find_each(&:destroy)
        SplitUsers.split_db_users(source_user)
        expect(restored_user.reload).not_to be_deleted
        expect(restored_user.name).to eq "restored user"
        expect(source_user.reload).not_to be_deleted
      end

      it "ignores user merge data items that are in a failed state" do
        UserMerge.from(restored_user).into(source_user)
        UserMerge.from(user3).into(source_user)
        UserMergeData.where(user_id: source_user).take.update(workflow_state: "failed")
        expect_any_instance_of(SplitUsers).to receive(:split_users).once
        SplitUsers.split_db_users(source_user)
      end

      it "moves lti_id to the new user" do
        course1.enroll_user(source_user)
        course2.enroll_user(restored_user)
        UserMerge.from(restored_user).into(source_user)
        UserMerge.from(source_user).into(user3)
        SplitUsers.split_db_users(user3)
        expect(user3.reload.past_lti_ids.count).to eq 0
        expect(source_user.reload.past_lti_ids.count).to eq 1
      end

      it "restores lti_id and uuid when these were overwritten by move_lti_ids" do
        restored_orig_lti_id = restored_user.lti_id
        restored_orig_uuid = restored_user.uuid
        restored_lti_context_id = Lti::Asset.opaque_identifier_for(restored_user)
        source_orig_lti_id = source_user.lti_id
        source_orig_uuid = source_user.uuid
        # (source_lti_context_id must be nil for this move to actually happen)
        UserMerge.from(restored_user).into(source_user)
        expect(source_user.reload.lti_id).to eq restored_orig_lti_id
        expect(source_user.uuid).to eq restored_orig_uuid
        expect(source_user.lti_context_id).to eq restored_lti_context_id
        SplitUsers.split_db_users(source_user)
        expect(source_user.reload.lti_id).to eq source_orig_lti_id
        expect(source_user.uuid).to eq source_orig_uuid
        expect(source_user.lti_context_id).to be_nil
        expect(restored_user.reload.lti_id).to eq restored_orig_lti_id
        expect(restored_user.uuid).to eq restored_orig_uuid
        expect(restored_user.lti_context_id).to eq restored_lti_context_id
      end

      it "doesn't raise if restored user uuid matches source user receiving merge data item uuid" do
        UserMerge.from(restored_user).into(source_user)
        merge_data = UserMergeData.active.splitable.find_by(user: source_user, from_user: restored_user)
        old_uuid = merge_data.items.where(item_type: "uuid").pick(:item)
        source_user.update!(uuid: old_uuid)
        allow(InstStatsd::Statsd).to receive(:increment)
        expect { SplitUsers.split_db_users(source_user, merge_data) }.not_to raise_error
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("split_users.undo_move_lti_ids.unique_constraint_failure")
        expect(restored_user.reload).not_to be_deleted
        expect(source_user).not_to be_deleted
      end

      it "splits multiple users if no merge_data is specified" do
        enrollment1 = course1.enroll_student(restored_user, enrollment_state: "active")
        enrollment2 = course1.enroll_student(source_user, enrollment_state: "active")
        enrollment3 = course2.enroll_student(restored_user, enrollment_state: "active")
        enrollment4 = course3.enroll_teacher(restored_user)
        enrollment5 = course1.enroll_teacher(user3)
        UserMerge.from(restored_user).into(source_user)
        UserMerge.from(user3).into(source_user)
        SplitUsers.split_db_users(source_user)

        restored_user.reload
        source_user.reload
        user3.reload
        expect(restored_user).not_to be_deleted
        expect(source_user).not_to be_deleted
        expect(user3).not_to be_deleted
        expect(enrollment1.reload.user).to eq restored_user
        expect(enrollment1.workflow_state).to eq "active"
        expect(enrollment2.reload.user).to eq source_user
        expect(enrollment3.reload.user).to eq restored_user
        expect(enrollment4.reload.user).to eq restored_user
        expect(enrollment5.reload.user).to eq user3
      end

      it "handles conflicting enrollments" do
        enrollment1 = course1.enroll_student(restored_user, enrollment_state: "active")
        UserMerge.from(restored_user).into(source_user)
        enrollment2 = course1.enroll_student(restored_user, enrollment_state: "active")
        SplitUsers.split_db_users(source_user)

        restored_user.reload
        source_user.reload
        expect(restored_user).not_to be_deleted
        expect(source_user).not_to be_deleted
        expect(enrollment1.reload.user).to eq source_user
        expect(enrollment2.reload.user).to eq restored_user
      end

      it "handles user_observers" do
        observer1 = user_model
        observer2 = user_model
        add_linked_observer(restored_user, observer1)
        add_linked_observer(source_user, observer2)
        UserMerge.from(restored_user).into(source_user)

        SplitUsers.split_db_users(source_user)

        expect(restored_user.linked_observers).to eq [observer1]
        expect(source_user.linked_observers).to eq [observer2]
      end

      it "handles access tokens" do
        at = AccessToken.create!(user: restored_user, developer_key: DeveloperKey.default)
        UserMerge.from(restored_user).into(source_user)
        expect(at.reload.user_id).to eq source_user.id
        SplitUsers.split_db_users(source_user)
        expect(at.reload.user_id).to eq restored_user.id
      end

      it "handles polls" do
        poll = Polling::Poll.create!(user: restored_user, question: "A Test Poll", description: "A test description.")
        UserMerge.from(restored_user).into(source_user)
        expect(poll.reload.user_id).to eq source_user.id
        SplitUsers.split_db_users(source_user)
        expect(poll.reload.user_id).to eq restored_user.id
      end

      it "handles favorites" do
        course1.enroll_user(restored_user)
        fav = Favorite.create!(user: restored_user, context: course1)
        UserMerge.from(restored_user).into(source_user)
        expect(source_user.favorites.take.context_id).to eq course1.id
        SplitUsers.split_db_users(source_user)
        expect(fav.reload.user_id).to eq restored_user.id
      end

      it "handles ignores" do
        course1.enroll_user(restored_user)
        assignment2 = assignment_model(course: course1)
        ignore = Ignore.create!(asset: assignment2, user: restored_user, purpose: "submitting")
        UserMerge.from(restored_user).into(source_user)
        expect(ignore.reload.user_id).to eq source_user.id
        SplitUsers.split_db_users(source_user)
        expect(ignore.reload.user_id).to eq restored_user.id
      end

      it "handles conversations" do
        sender = restored_user
        recipient = user3
        convo = sender.initiate_conversation([recipient])
        UserMerge.from(restored_user).into(source_user)
        expect(convo.reload.user_id).to eq source_user.id
        SplitUsers.split_db_users(source_user)
        expect(convo.reload.user_id).to eq restored_user.id
      end

      it "handles attachments" do
        attachment1 = Attachment.create!(user: restored_user,
                                         context: restored_user,
                                         filename: "test.txt",
                                         uploaded_data: StringIO.new("first"))
        attachment2 = Attachment.create!(user: source_user,
                                         context: source_user,
                                         filename: "test2.txt",
                                         uploaded_data: StringIO.new("second"))

        UserMerge.from(restored_user).into(source_user)
        run_jobs

        expect(attachment1.reload.context).to eq source_user
        expect(restored_user.reload.attachments).to eq []

        SplitUsers.split_db_users(source_user)
        expect(restored_user.reload.attachments).to eq [attachment1]
        expect(source_user.reload.attachments).to eq [attachment2]
      end

      it "handles when observing merged user" do
        link = add_linked_observer(source_user, restored_user)
        UserMerge.from(restored_user).into(source_user)

        SplitUsers.split_db_users(source_user)

        expect(restored_user.reload.as_observer_observation_links.to_a).to eq [link]
        expect(source_user.reload.as_student_observation_links.to_a).to eq [link]
      end

      it "handles as_observer_observation_links" do
        observee1 = user_model
        observee2 = user_model
        add_linked_observer(observee1, restored_user)
        add_linked_observer(observee2, source_user)
        UserMerge.from(restored_user).into(source_user)

        SplitUsers.split_db_users(source_user)

        expect(restored_user.as_observer_observation_links).to eq observee1.as_student_observation_links
        expect(source_user.as_observer_observation_links).to eq observee2.as_student_observation_links
      end

      it "handles duplicate user_observers" do
        observer1 = user_model
        observee1 = user_model
        add_linked_observer(observee1, restored_user)
        add_linked_observer(observee1, source_user)
        add_linked_observer(restored_user, observer1)
        add_linked_observer(source_user, observer1)
        UserMerge.from(restored_user).into(source_user)
        SplitUsers.split_db_users(source_user)

        expect(restored_user.as_observer_observation_links.count).to eq 1
        expect(source_user.as_observer_observation_links.count).to eq 1
        expect(restored_user.linked_observers).to eq [observer1]
        expect(source_user.linked_observers).to eq [observer1]

        expect(restored_user.as_observer_observation_links.first.workflow_state).to eq "active"
        expect(source_user.as_observer_observation_links.first.workflow_state).to eq "active"
        expect(restored_user.as_student_observation_links.first.workflow_state).to eq "active"
        expect(source_user.as_student_observation_links.first.workflow_state).to eq "active"
      end

      it "only splits users from merge_data when specified" do
        enrollment1 = course1.enroll_user(restored_user)
        enrollment2 = course1.enroll_student(source_user, enrollment_state: "active")
        enrollment3 = course2.enroll_student(restored_user, enrollment_state: "active")
        enrollment4 = course3.enroll_teacher(restored_user)
        enrollment5 = course1.enroll_teacher(user3)
        UserMerge.from(restored_user).into(source_user)
        UserMerge.from(user3).into(source_user)
        merge_data = UserMergeData.where(user_id: source_user, from_user: restored_user).first
        SplitUsers.split_db_users(source_user, merge_data)

        restored_user.reload
        source_user.reload
        user3.reload
        expect(restored_user).not_to be_deleted
        expect(source_user).not_to be_deleted
        expect(user3).to be_deleted
        expect(enrollment1.reload.user).to eq restored_user
        expect(enrollment2.reload.user).to eq source_user
        expect(enrollment3.reload.user).to eq restored_user
        expect(enrollment4.reload.user).to eq restored_user
        expect(enrollment5.reload.user).to eq source_user
      end

      it "moves ccs to the new user (but only if they don't already exist)" do
        Notification.where(name: "Report Generated").first_or_create
        # unconfirmed: active conflict
        communication_channel(restored_user, { username: "a@instructure.com" })
        communication_channel(source_user, { username: "A@instructure.com", active_cc: true })
        # active: unconfirmed conflict
        communication_channel(restored_user, { username: "b@instructure.com", active_cc: true })
        cc1 = communication_channel(source_user, { username: "B@instructure.com" })
        # active: active conflict + notification policy copy
        np_cc = communication_channel(restored_user, { username: "c@instructure.com", active_cc: true })
        np_cc.notification_policies.first.update!(frequency: "weekly")

        # Since active communication_channels have their policies, we need to delete it to have a CC that doens't have a policy
        needs_np = communication_channel(source_user, { username: "C@instructure.com", active_cc: true })
        needs_np.notification_policies.first.destroy!
        # unconfirmed: unconfirmed conflict
        communication_channel(restored_user, { username: "d@instructure.com" })
        communication_channel(source_user, { username: "D@instructure.com" })
        # retired: unconfirmed conflict
        communication_channel(restored_user, { username: "e@instructure.com", cc_state: "retired" })
        communication_channel(source_user, { username: "E@instructure.com" })
        # unconfirmed: retired conflict
        communication_channel(restored_user, { username: "f@instructure.com" })
        communication_channel(source_user, { username: "F@instructure.com", cc_state: "retired" })
        # retired: active conflict
        communication_channel(restored_user, { username: "g@instructure.com", cc_state: "retired" })
        communication_channel(source_user, { username: "G@instructure.com", active_cc: true })
        # active: retired conflict
        communication_channel(restored_user, { username: "h@instructure.com", active_cc: true })
        communication_channel(source_user, { username: "H@instructure.com", cc_state: "retired" })
        # retired: retired conflict
        communication_channel(restored_user, { username: "i@instructure.com", cc_state: "retired" })
        communication_channel(source_user, { username: "I@instructure.com", cc_state: "retired" })
        # <nothing>: active
        communication_channel(source_user, { username: "J@instructure.com", active_cc: true })
        # active: <nothing>
        communication_channel(restored_user, { username: "k@instructure.com", active_cc: true })
        # <nothing>: unconfirmed
        communication_channel(source_user, { username: "L@instructure.com" })
        # unconfirmed: <nothing>
        communication_channel(restored_user, { username: "m@instructure.com" })
        # <nothing>: retired
        communication_channel(source_user, { username: "N@instructure.com", cc_state: "retired" })
        # retired: <nothing>
        communication_channel(restored_user, { username: "o@instructure.com", cc_state: "retired" })

        restored_user_ccs = restored_user.communication_channels.where.not(workflow_state: "retired")
                                         .map { |cc| [cc.path, cc.workflow_state] }.sort
        # cc will not be restored because it conflicted on merge and it was unconfirmed and it is frd deleted
        source_user_ccs = source_user.communication_channels.where.not(id: cc1).where.not(workflow_state: "retired")
                                     .map { |cc| [cc.path, cc.workflow_state] }.sort

        UserMerge.from(restored_user).into(source_user)
        expect(needs_np.notification_policies.take.frequency).to eq "weekly"
        SplitUsers.split_db_users(source_user)
        restored_user.reload
        source_user.reload

        expect(restored_user.communication_channels.where.not(workflow_state: "retired")
          .map { |cc| [cc.path, cc.workflow_state] }.sort).to eq restored_user_ccs
        expect(source_user.communication_channels.where.not(workflow_state: "retired")
          .map { |cc| [cc.path, cc.workflow_state] }.sort).to eq source_user_ccs
      end

      it "deconflicts duplicated paths where it can" do
        Notification.where(name: "Report Generated").first_or_create
        communication_channel(restored_user, { username: "test@instructure.com" })
        restored_user_ccs = restored_user.communication_channels.where.not(workflow_state: "retired")
                                         .map { |cc| [cc.path, cc.workflow_state] }.sort
        source_user_ccs = source_user.communication_channels.where.not(workflow_state: "retired")
                                     .map { |cc| [cc.path, cc.workflow_state] }.sort
        UserMerge.from(restored_user).into(source_user)
        communication_channel(restored_user, { username: "test@instructure.com", cc_state: "retired" })
        SplitUsers.split_db_users(source_user)
        restored_user.reload
        source_user.reload
        expect(restored_user.communication_channels.where.not(workflow_state: "retired")
          .map { |cc| [cc.path, cc.workflow_state] }.sort).to eq restored_user_ccs
        expect(source_user.communication_channels.where.not(workflow_state: "retired")
          .map { |cc| [cc.path, cc.workflow_state] }.sort).to eq source_user_ccs
      end
    end

    it "restores submissions" do
      course1.enroll_student(restored_user, enrollment_state: "active")
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
      }
      submission = assignment.submissions.find_by!(user: restored_user)
      submission.update!(valid_attributes)

      UserMerge.from(restored_user).into(source_user)
      expect(submission.reload.user).to eq source_user
      SplitUsers.split_db_users(source_user)
      expect(submission.reload.user).to eq restored_user
    end

    it "handles conflicting submissions" do
      course1.enroll_student(restored_user, enrollment_state: "active")
      course1.enroll_student(source_user, enrollment_state: "active")
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
      }
      submission1 = assignment.submissions.find_by!(user: restored_user)
      submission1.update!(valid_attributes)
      submission2 = assignment.submissions.find_by!(user: source_user)
      submission2.update!(valid_attributes)

      UserMerge.from(restored_user).into(source_user)
      expect(submission1.reload.user).to eq restored_user
      expect(submission2.reload.user).to eq source_user
      Submission.where(id: submission1).update_all(workflow_state: "deleted")
      SplitUsers.split_db_users(source_user)
      expect(submission1.reload.user).to eq restored_user
      expect(submission2.reload.user).to eq source_user
    end

    it "handles conflicting submissions other way too" do
      course1.enroll_student(restored_user, enrollment_state: "active")
      course1.enroll_student(source_user, enrollment_state: "active")
      assignment = course1.assignments.new(title: "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
      }
      submission1 = assignment.submissions.find_by!(user: restored_user)
      submission1.update!(valid_attributes)
      submission2 = assignment.submissions.find_by!(user: source_user)

      UserMerge.from(restored_user).into(source_user)
      expect(submission1.reload.user).to eq source_user
      expect(submission2.reload.user).to eq restored_user
      SplitUsers.split_db_users(source_user)
      expect(submission1.reload.user).to eq restored_user
      expect(submission2.reload.user).to eq source_user
    end

    it "swaps back unsubmitted/deleted submissions conflicting with existing assignments" do
      assignment = course1.assignments.create!(title: "some assignment",
                                               submission_types: "online_text_entry",
                                               points_possible: 10,
                                               workflow_state: "published")
      course1.enroll_student(restored_user, enrollment_state: "active")

      UserMerge.from(restored_user).into(source_user)
      unsubmitted_submission = assignment.find_or_create_submission(restored_user)
      real_submission = assignment.submit_homework(source_user, submission_type: "online_text_entry", body: "zarf")
      SplitUsers.split_db_users(source_user)

      expect(real_submission.reload.user).to eq restored_user
      expect(unsubmitted_submission.reload.user).to eq source_user
    end

    it "does not blow up on deleted courses" do
      course1.enroll_student(restored_user, enrollment_state: "active")
      UserMerge.from(restored_user).into(source_user)
      course1.destroy
      expect { SplitUsers.split_db_users(source_user) }.not_to raise_error
    end

    it "restores admins to the original state" do
      admin = account1.account_users.create(user: restored_user)
      admin2 = sub_account.account_users.create(user: restored_user)
      admin3 = sub_account.account_users.create(user: source_user)
      UserMerge.from(restored_user).into(source_user)
      admin.reload.destroy
      SplitUsers.split_db_users(source_user)

      expect(admin.reload.workflow_state).to eq "active"
      expect(admin.reload.user).to eq restored_user
      expect(admin2.reload.user).to eq restored_user
      expect(admin3.reload.user).to eq source_user
    end

    context "sharding" do
      specs_require_sharding
      let!(:shard1_source_user) { @shard1.activate { user_model } }
      let!(:shard1_account) { @shard1.activate { Account.create! } }
      let!(:shard1_course) { shard1_account.courses.create! }

      it "handles access tokens" do
        at = AccessToken.create!(user: restored_user, developer_key: DeveloperKey.default)
        UserMerge.from(restored_user).into(shard1_source_user)
        expect(at.reload.user_id).to eq shard1_source_user.id
        SplitUsers.split_db_users(shard1_source_user)
        expect(at.reload.user_id).to eq restored_user.id
      end

      it "moves submissions from new courses post merge when appropriate" do
        pseudonym1 = restored_user.pseudonyms.create!(unique_id: "sam1@example.com")
        UserMerge.from(restored_user).into(shard1_source_user)
        e = course1.enroll_student(shard1_source_user, enrollment_state: "active")
        Enrollment.where(id: e).update_all(sis_pseudonym_id: pseudonym1.id)
        assignment = course1.assignments.new(title: "some assignment")
        assignment.workflow_state = "published"
        assignment.save
        valid_attributes = {
          grade: "1.5",
          grader: @teacher,
          url: "www.instructure.com"
        }
        submission = assignment.submissions.find_by!(user: shard1_source_user)
        submission.update!(valid_attributes)
        SplitUsers.split_db_users(shard1_source_user)
        expect(submission.reload.user).to eq restored_user
      end

      it "handles user_observers cross shard" do
        observer1 = user_model
        observer2 = user_model
        add_linked_observer(restored_user, observer1)
        add_linked_observer(shard1_source_user, observer2)
        UserMerge.from(restored_user).into(shard1_source_user)
        expect(restored_user.linked_observers).to eq []
        expect(shard1_source_user.linked_observers.pluck(:id).sort).to eq [observer1.id, observer2.id].sort
        SplitUsers.split_db_users(shard1_source_user)
        expect(restored_user.reload.linked_observers).to eq [observer1]
        expect(shard1_source_user.reload.linked_observers).to eq [observer2]
      end

      it "handles user_observees cross shard" do
        observee1 = user_model
        observee2 = user_model
        add_linked_observer(observee1, restored_user)
        add_linked_observer(observee2, shard1_source_user)
        UserMerge.from(restored_user).into(shard1_source_user)
        expect(restored_user.linked_observers).to eq []
        expect(shard1_source_user.as_observer_observation_links.shard(shard1_source_user).map(&:user_id).uniq.sort).to eq [observee1.id, observee2.id].uniq.sort
        SplitUsers.split_db_users(shard1_source_user)
        expect(restored_user.reload.as_observer_observation_links.shard(restored_user).map(&:user)).to eq [observee1]
        expect(shard1_source_user.reload.as_observer_observation_links.map(&:user)).to eq [observee2]
      end

      it "handles user_observers cross shard from target shard" do
        observer1 = user_model
        add_linked_observer(restored_user, observer1)
        @shard1.activate do
          UserMerge.from(restored_user).into(shard1_source_user)
        end
        expect(restored_user.linked_observers).to eq []
        expect(shard1_source_user.linked_observers.pluck(:id).sort).to eq [observer1.id].sort
        SplitUsers.split_db_users(shard1_source_user)
        expect(restored_user.reload.linked_observers).to eq [observer1]
      end

      it "handles conflicting submissions for cross shard users" do
        course1.enroll_student(restored_user, enrollment_state: "active")
        course1.enroll_student(shard1_source_user, enrollment_state: "active")
        assignment = course1.assignments.new(title: "some assignment")
        assignment.workflow_state = "published"
        assignment.save
        valid_attributes = {
          grade: "1.5",
          grader: @teacher,
          url: "www.instructure.com"
        }
        submission1 = assignment.submissions.find_by!(user: restored_user)
        submission1.update!(valid_attributes)
        submission2 = assignment.submissions.find_by!(user: shard1_source_user)

        UserMerge.from(restored_user).into(shard1_source_user)
        expect(submission1.reload.user).to eq shard1_source_user
        expect(submission2.reload.user).to eq restored_user
        SplitUsers.split_db_users(shard1_source_user)
        expect(submission1.reload.user).to eq restored_user
        expect(submission2.reload.user).to eq shard1_source_user
      end

      it "swaps out conflicting unsubmitted/deleted submissions across shards" do
        assignment = shard1_course.assignments.create!(title: "some assignment",
                                                       submission_types: "online_text_entry",
                                                       points_possible: 10,
                                                       workflow_state: "published")
        shard1_course.enroll_student(restored_user, enrollment_state: "active")

        UserMerge.from(restored_user).into(shard1_source_user)
        unsubmitted_submission = assignment.find_or_create_submission(restored_user)
        real_submission = assignment.submit_homework(shard1_source_user, submission_type: "online_text_entry", body: "zarf")
        SplitUsers.split_db_users(shard1_source_user)

        expect(real_submission.reload.user).to eq restored_user
        expect(unsubmitted_submission.reload.user).to eq shard1_source_user
      end

      it "restores admins to the original state" do
        admin = account1.account_users.create(user: restored_user)
        shard1_source_user.associate_with_shard(sub_account.shard)
        admin2 = sub_account.account_users.create(user: shard1_source_user)
        UserMerge.from(restored_user).into(shard1_source_user)
        admin.reload.destroy
        SplitUsers.split_db_users(shard1_source_user)

        expect(admin.reload.workflow_state).to eq "active"
        expect(admin.reload.user).to eq restored_user
        expect(admin2.reload.user).to eq shard1_source_user
      end

      it "merges a user across shards" do
        pseudonym1 = restored_user.pseudonyms.create!(unique_id: "sam1@example.com")
        @shard1.activate do
          account = Account.create!
          @pseudonym2 = shard1_source_user.pseudonyms.create!(account:, unique_id: "sam1@example.com")
          UserMerge.from(restored_user).into(shard1_source_user)
          SplitUsers.split_db_users(shard1_source_user)
        end

        restored_user.reload
        shard1_source_user.reload

        expect(restored_user).not_to be_deleted
        expect(pseudonym1.reload.user).to eq restored_user
        expect(shard1_source_user.all_pseudonyms).to eq [@pseudonym2]
      end

      it "splits a user across shards with ccs" do
        communication_channel(restored_user, { username: "a@example.com", active_cc: true })
        restored_user_ccs = restored_user.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort
        source_user_ccs = shard1_source_user.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort

        @shard1.activate do
          UserMerge.from(restored_user).into(shard1_source_user)
          cc = shard1_source_user.reload.communication_channels.where(path: "a@example.com").take
          n = Notification.create!(name: "Assignment Createds", subject: "Tests", category: "TestNevers")
          NotificationPolicyOverride.create(notification: n, communication_channel: cc, frequency: "immediately", context: shard1_course)
          SplitUsers.split_db_users(shard1_source_user)
        end

        restored_user.reload
        shard1_source_user.reload
        expect(restored_user.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq restored_user_ccs
        expect(shard1_source_user.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to eq source_user_ccs
      end

      it "handles enrollments across shards" do
        e = course1.enroll_user(restored_user)
        @shard1.activate do
          @e = shard1_course.enroll_user(shard1_source_user)
          UserMerge.from(restored_user).into(shard1_source_user)
        end
        SplitUsers.split_db_users(shard1_source_user)

        expect(e.reload.user).to eq restored_user
        expect(@e.reload.user).to eq shard1_source_user
      end

      it "works with cross-shard submissions" do
        shard1_course.enroll_student(restored_user, enrollment_state: "active")
        assignment = shard1_course.assignments.create!(title: "some assignment", workflow_state: "published", submission_types: "online_text_entry")
        submission = assignment.submit_homework(restored_user, submission_type: "online_text_entry", body: "fooey")

        UserMerge.from(restored_user).into(source_user)
        SplitUsers.split_db_users(source_user)
        expect(submission.reload.user).to eq restored_user
      end

      it "copies notification policies" do
        communication_channel(restored_user, { username: "a@example.com", active_cc: true })

        Notification.create!(name: "Assignment", subject: "Tests", category: "TestNevers")

        @shard1.activate do
          UserMerge.from(restored_user).into(shard1_source_user)
          cc = shard1_source_user.communication_channels.where(path: "a@example.com").take!
          expect(cc.notification_policies.count).to eq 1
        end

        SplitUsers.split_db_users(shard1_source_user)
        expect(shard1_source_user.communication_channels.count).to eq 0
      end

      it "copies notification policies on conflict" do
        communication_channel(restored_user, { username: "a@example.com", active_cc: true })

        Notification.create!(name: "Assignment", subject: "Tests", category: "TestNevers")
        # conflict_cc
        cc = communication_channel(shard1_source_user, { username: "a@example.com", active_cc: true })

        UserMerge.from(restored_user).into(shard1_source_user)
        expect(cc.notification_policies.count).to eq 1

        SplitUsers.split_db_users(shard1_source_user)
        expect(shard1_source_user.communication_channels.count).to eq 1
      end
    end
  end
end
