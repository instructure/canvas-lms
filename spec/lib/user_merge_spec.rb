# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe UserMerge do
  describe "with simple users" do
    let!(:user1) { user_model(name: "target_user") }
    let!(:user2) { user_model(name: "from_user") }
    let(:course1) { course_factory(active_all: true) }
    let(:course2) { course_factory(active_all: true) }

    it "deletes the old user" do
      UserMerge.from(user2).into(user1)
      user1.reload
      user2.reload
      expect(user1).not_to be_deleted
      expect(user2).to be_deleted
    end

    it "fails if a user is a test user" do
      fake_student = course1.student_view_student
      expect { UserMerge.from(user2).into(fake_student) }.to raise_error("cannot merge a test student")
    end

    it "fails if there is an existing active user merge data object for the same user pair" do
      UserMerge.from(user2).into(user1)
      expect { UserMerge.from(user2).into(user1) }.to raise_error(UserMerge::UnsafeMergeError)
    end

    it "logs who did the user merge" do
      merger = user_model
      mergeme = UserMerge.from(user2)
      mergeme.into(user1, merger:, source: "this spec")
      expect(mergeme.merge_data.items.where(item_type: "logs").take.item).to eq "{:merger_id=>#{merger.id}, :source=>\"this spec\"}"
    end

    it "marks as failed on merge failures" do
      mergeme = UserMerge.from(user2)
      # make any method that gets called raise an error
      allow(mergeme).to receive(:copy_favorites).and_raise("boom")
      expect { mergeme.into(user1) }.to raise_error("boom")
      expect(mergeme.merge_data.workflow_state).to eq "failed"
      expect(mergeme.merge_data.items.where(item_type: "merge_error").take.item.first).to eq "boom"
    end

    it "records where the user was merged to" do
      UserMerge.from(user2).into(user1)
      expect(user2.reload.merged_into_user).to eq user1
    end

    it "moves pseudonyms to the new user" do
      pseudonym = user2.pseudonyms.create!(unique_id: "sam@yahoo.com")
      pseudonym2 = user2.pseudonyms.create!(unique_id: "sam2@yahoo.com")
      UserMerge.from(user2).into(user1)
      merge_data = UserMergeData.where(user_id: user1).first
      expect(merge_data.from_user_id).to eq user2.id
      expect(merge_data.records.pluck(:context_id).sort).to eq [pseudonym.id, pseudonym2.id].sort
      user2.reload
      expect(user2.pseudonyms).to be_empty
      user1.reload
      expect(user1.pseudonyms.map(&:unique_id)).to include("sam@yahoo.com")
    end

    it "moves lti_id to the new users" do
      user_1_old_lti = user1.lti_id
      old_lti = user2.lti_id
      old_lti_context = user2.lti_context_id
      course1.enroll_user(user1)
      course2.enroll_user(user2)
      UserMerge.from(user2).into(user1)
      expect(user1.reload.past_lti_ids.take.user_lti_id).to eq old_lti
      expect(user1.past_lti_ids.take.user_lti_context_id).to eq old_lti_context
      user3 = user_model
      Lti::Asset.opaque_identifier_for(user3)
      UserMerge.from(user1).into(user3)
      expect(user3.reload.past_lti_ids.where(context_id: course1).take.user_lti_id).to eq user_1_old_lti
      expect(user3.past_lti_ids.where(context_id: course2).take.user_lti_id).to eq old_lti
    end

    it "moves past_lti_id to the new user multiple merges with conflict" do
      course1.enroll_user(user1)
      course2.enroll_user(user2)
      UserPastLtiId.create!(user: user2, context: course2, user_uuid: "fake_uuid", user_lti_id: "fake_lti_id_from_old_merge")
      UserMerge.from(user2).into(user1)
      expect(user1.reload.past_lti_ids.take.user_lti_id).to eq "fake_lti_id_from_old_merge"
    end

    it "moves admins to the new user" do
      account1 = account_model
      admin = account1.account_users.create(user: user2)
      UserMerge.from(user2).into(user1)
      merge_data = UserMergeData.where(user_id: user1).first
      expect(merge_data.from_user_id).to eq user2.id
      expect(merge_data.records.where(context_type: "AccountUser").first.context_id).to eq admin.id
      user1.reload
      expect(user1.account_users.first.id).to eq admin.id
    end

    it "uses avatar information from merged user if none exists" do
      user2.avatar_image = { "type" => "external", "url" => "https://example.com/image.png" }
      user2.save!

      UserMerge.from(user2).into(user1)
      user1.reload
      user2.reload

      %i[avatar_image_source avatar_image_url avatar_image_updated_at avatar_state].each do |attr|
        expect(user1[attr]).to eq user2[attr]
      end
    end

    it "does not overwrite avatar information already in place" do
      user1.avatar_state = "locked"
      user1.save!
      user2.avatar_image = { "type" => "external", "url" => "https://example.com/image.png" }
      user2.save!

      UserMerge.from(user2).into(user1)
      user1.reload
      user2.reload
      expect(user1.avatar_state).not_to eq user2.avatar_state
    end

    it "moves access tokens to the new user" do
      at = AccessToken.create!(user: user2, developer_key: DeveloperKey.default)
      UserMerge.from(user2).into(user1)
      at.reload
      expect(at.user_id).to eq user1.id
    end

    it "recalculates cached_due_date on unsubmitted placeholder submissions for the new user" do
      due_date_timestamp = DateTime.now.iso8601
      course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
      assignment = course1.assignments.create!(
        title: "some assignment",
        grading_type: "points",
        submission_types: "online_text_entry",
        due_at: due_date_timestamp
      )
      expect(Submission.where(user_id: user2.id, assignment_id: assignment.id).take.cached_due_date)
        .to eq due_date_timestamp

      UserMerge.from(user2).into(user1)

      submission = Submission.where(user_id: user1.id, assignment_id: assignment.id).take
      expect(submission.cached_due_date).to eq due_date_timestamp
      expect(submission.workflow_state).to eq "unsubmitted"
    end

    it "recalculates cached_due_date on submissions for assignments with overrides" do
      due_date_timestamp = DateTime.now.iso8601
      course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
      assignment = course1.assignments.create!(
        title: "Assignment with student due date override",
        grading_type: "points",
        submission_types: "online_text_entry"
      )
      override = assignment.assignment_overrides.create!(
        due_at: due_date_timestamp,
        due_at_overridden: true,
        all_day: true,
        unlock_at_overridden: true,
        lock_at_overridden: true
      )
      override.assignment_override_students.create!(user: user2)
      assignment.update(due_at: nil, only_visible_to_overrides: true)
      expect(Submission.where(user_id: user2.id, assignment_id: assignment.id).take.cached_due_date)
        .to eq due_date_timestamp

      UserMerge.from(user2).into(user1)

      submission = Submission.where(user_id: user1.id, assignment_id: assignment.id).take
      expect(submission.cached_due_date).to eq due_date_timestamp
      expect(submission.workflow_state).to eq "unsubmitted"
    end

    it "deletes from user's assignment override student when both users have them" do
      due_date_timestamp = DateTime.now.iso8601
      course1.enroll_user(user1, "StudentEnrollment", enrollment_state: "active")
      course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
      a1 = assignment_model(course: course1)
      s1 = a1.find_or_create_submission(user1)
      s1.submission_type = "online_quiz"
      s1.save!
      s2 = a1.find_or_create_submission(user2)
      s2.submission_type = "online_quiz"
      s2.save!
      override = a1.assignment_overrides.create!(
        due_at: due_date_timestamp,
        due_at_overridden: true,
        all_day: true,
        unlock_at_overridden: true,
        lock_at_overridden: true
      )
      o1 = override.assignment_override_students.create!(user: user1)
      o2 = override.assignment_override_students.create!(user: user2)
      a1.update(due_at: nil, only_visible_to_overrides: true)

      UserMerge.from(user1).into(user2)

      expect(o1.reload.workflow_state).to eq "deleted"
      expect(o1.reload.user).to eq user1
      expect(o2.reload.workflow_state).to eq "active"
      expect(o2.reload.user).to eq user2
    end

    it "moves and swap assignment override student to target user" do
      due_date_timestamp = DateTime.now.iso8601
      course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
      assignment = course1.assignments.create!(
        title: "Assignment with student due date override",
        grading_type: "points",
        submission_types: "online_text_entry"
      )
      override = assignment.assignment_overrides.create!(
        due_at: due_date_timestamp,
        due_at_overridden: true,
        all_day: true,
        unlock_at_overridden: true,
        lock_at_overridden: true
      )
      o1 = override.assignment_override_students.create!(user: user2)
      assignment.update(due_at: nil, only_visible_to_overrides: true)
      expect(AssignmentOverrideStudent.count).to eq 1

      UserMerge.from(user2).into(user1)

      expect(AssignmentOverrideStudent.count).to eq 1
      expect(o1.reload.workflow_state).to eq "active"
      expect(o1.reload.user).to eq user1
    end

    context "when from user and target user are enrolled in the same course" do
      it "prefers submitted submissions by target user if assignment / submission conflict" do
        course1.enroll_user(user1, "StudentEnrollment", enrollment_state: "creation_pending")
        course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
        assignment = course1.assignments.create!(
          title: "upload_assignment",
          points_possible: 10.0,
          grading_type: "points",
          workflow_state: "published",
          context: course1,
          submission_types: "online_upload"
        )
        attachment_model context: user1
        submission = assignment.submit_homework user1, attachments: [@attachment]
        UserMerge.from(user2).into(user1)
        expect(user2.reload.submissions.length).to be(0)
        expect(user1.reload.submissions.length).to be(1)
        expect(user1.submissions.map(&:id)).to include(submission.id)
      end

      it "ignores scored unsubmitted submission belonging to from user" do
        course_with_teacher_logged_in active_all: true
        @course.enroll_user(user1, "StudentEnrollment", enrollment_state: "active")
        @course.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
        assignment = @course.assignments.create!(
          title: "online_text_entry",
          points_possible: 10.0,
          grading_type: "points",
          workflow_state: "published",
          context: @course,
          submission_types: "online_text_entry"
        )
        assignment2 = @course.assignments.create!(
          title: "on_paper",
          points_possible: 10.0,
          grading_type: "points",
          workflow_state: "published",
          context: @course,
          submission_types: "on_paper"
        )
        submission = assignment.submit_homework(user1, submission_type: "online_text_entry")
        assignment2.grade_student(user2, grader: @teacher, grade: 10)
        submission2 = Submission.where(user_id: user2, assignment_id: assignment2).graded.take
        UserMerge.from(user2).into(user1)
        expect(user2.reload.submissions.length).to be(0)
        expect(user1.reload.submissions.length).to be(2)
        expect(user1.submissions.map(&:id)).to include(submission.id)
        expect(user1.submissions.map(&:id)).not_to include(submission2.id)
      end
    end

    it "moves submissions to the new user (but only if they don't already exist)" do
      a1 = assignment_model
      s1 = a1.find_or_create_submission(user1)
      s1.submission_type = "online_quiz"
      s1.save!
      s2 = a1.find_or_create_submission(user2)
      s2.submission_type = "online_quiz"
      s2.save!
      a2 = assignment_model
      s3 = a2.find_or_create_submission(user2)
      s3.submission_type = "online_quiz"
      s3.save!
      expect(user2.submissions.length).to be(2)
      expect(user1.submissions.length).to be(1)
      UserMerge.from(user2).into(user1)
      user2.reload
      user1.reload
      expect(user2.submissions.length).to be(1)
      expect(user2.submissions.first.id).to eql(s2.id)
      expect(user1.submissions.length).to be(2)
      expect(user1.submissions.map(&:id)).to include(s1.id)
      expect(user1.submissions.map(&:id)).to include(s3.id)
    end

    it "does not move or delete submission when both users have submissions" do
      a1 = assignment_model
      s1 = a1.find_or_create_submission(user1)
      s1.submission_type = "online_quiz"
      s1.save!
      s2 = a1.find_or_create_submission(user2)
      s2.submission_type = "online_quiz"
      s2.save!

      UserMerge.from(user1).into(user2)

      expect(user1.reload.submissions).to eq [s1.reload]
      expect(user2.reload.submissions).to eq [s2.reload]
    end

    it "prioritizes grades over submissions" do
      a1 = assignment_model(course: course1)
      course1.enroll_user(user1)
      s1 = a1.grade_student(user1, grade: "10", grader: @teacher).first
      s2 = a1.find_or_create_submission(user2)
      s2.submission_type = "online_quiz"
      s2.save!

      UserMerge.from(user1).into(user2)

      expect(user1.reload.submissions).to eq [s2.reload]
      expect(user2.reload.submissions).to eq [s1.reload]
    end

    it "moves and swap submission when one user has a submission" do
      a2 = assignment_model
      s3 = a2.find_or_create_submission(user1)
      s3.submission_type = "online_quiz"
      s3.save!
      s4 = a2.find_or_create_submission(user2)
      UserMerge.from(user1).into(user2)

      expect(user1.reload.submissions).to eq [s4.reload]
      expect(user2.reload.submissions).to eq [s3.reload]
    end

    it "moves quiz submissions to the new user (but only if they don't already exist)" do
      q1 = quiz_model
      qs1 = q1.generate_submission(user1)
      qs2 = q1.generate_submission(user2)

      sub = submission_model(user: user2)
      sub.quiz_submission_id = qs2
      sub.save!
      qs2.submission_id = sub
      qs2.save!

      q2 = quiz_model
      qs3 = q2.generate_submission(user2)

      expect(user1.quiz_submissions.length).to be(1)
      expect(user2.quiz_submissions.length).to be(2)

      UserMerge.from(user2).into(user1)

      user2.reload
      user1.reload

      expect(user2.quiz_submissions.length).to be(1)
      expect(user2.quiz_submissions.first.id).to be(qs1.id)
      expect(qs2.reload.submission_id).to eq sub.id

      expect(user1.quiz_submissions.length).to be(2)
      expect(user1.quiz_submissions.map(&:id)).to include(qs2.id)
      expect(user1.quiz_submissions.map(&:id)).to include(qs3.id)
    end

    it "moves ccs to the new user (but only if they don't already exist)" do
      # unconfirmed => active conflict
      communication_channel(user1, { username: "a@instructure.com" })
      communication_channel(user2, { username: "A@instructure.com", active_cc: true })
      # active => unconfirmed conflict
      cc1 = communication_channel(user1, { username: "b@instructure.com", active_cc: true })
      communication_channel(user2, { username: "B@instructure.com" })
      # active => active conflict
      communication_channel(user1, { username: "c@instructure.com", active_cc: true })
      communication_channel(user2, { username: "C@instructure.com", active_cc: true })
      # unconfirmed => unconfirmed conflict
      communication_channel(user1, { username: "d@instructure.com" })
      communication_channel(user2, { username: "D@instructure.com" })
      # retired => unconfirmed conflict
      communication_channel(user1, { username: "e@instructure.com", cc_state: "retired" })
      communication_channel(user2, { username: "E@instructure.com" })
      # unconfirmed => retired conflict
      communication_channel(user1, { username: "f@instructure.com" })
      communication_channel(user2, { username: "F@instructure.com", cc_state: "retired" })
      # retired => active conflict
      communication_channel(user1, { username: "g@instructure.com", cc_state: "retired" })
      communication_channel(user2, { username: "G@instructure.com", cc_state: "active" })
      # active => retired conflict
      communication_channel(user1, { username: "h@instructure.com", cc_state: "active" })
      communication_channel(user2, { username: "H@instructure.com", cc_state: "retired" })
      # retired => retired conflict
      communication_channel(user1, { username: "i@instructure.com", cc_state: "retired" })
      communication_channel(user2, { username: "I@instructure.com", cc_state: "retired" })
      # <nothing> => active
      communication_channel(user2, { username: "j@instructure.com", active_cc: true })
      # active => <nothing>
      communication_channel(user1, { username: "k@instructure.com", active_cc: true })
      # <nothing> => unconfirmed
      communication_channel(user2, { username: "l@instructure.com" })
      # unconfirmed => <nothing>
      communication_channel(user1, { username: "m@instructure.com" })
      # <nothing> => retired
      communication_channel(user2, { username: "n@instructure.com", cc_state: "retired" })
      # retired => <nothing>
      communication_channel(user1, { username: "o@instructure.com", cc_state: "retired" })

      UserMerge.from(user1).into(user2)
      user1.reload
      user2.reload
      records = UserMergeData.where(user_id: user2).take.records
      expect(records.count).to eq 8
      record = records.where(context_id: cc1).take
      expect(record.previous_user_id).to eq user1.id
      expect(record.previous_workflow_state).to eq "active"
      expect(record.context_type).to eq "CommunicationChannel"

      expect(user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to match_array([
                                                                                                           ["A@instructure.com", "active"],
                                                                                                           ["C@instructure.com", "active"],
                                                                                                           ["D@instructure.com", "unconfirmed"],
                                                                                                           ["E@instructure.com", "unconfirmed"],
                                                                                                           ["G@instructure.com", "active"],
                                                                                                           ["I@instructure.com", "retired"],
                                                                                                           ["b@instructure.com", "active"],
                                                                                                           ["f@instructure.com", "unconfirmed"],
                                                                                                           ["h@instructure.com", "active"],
                                                                                                           ["j@instructure.com", "active"],
                                                                                                           ["k@instructure.com", "active"],
                                                                                                           ["l@instructure.com", "unconfirmed"],
                                                                                                           ["m@instructure.com", "unconfirmed"],
                                                                                                           ["n@instructure.com", "retired"]
                                                                                                         ])
      expect(user1.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to match_array([
                                                                                                           ["a@instructure.com", "retired"],
                                                                                                           ["c@instructure.com", "retired"],
                                                                                                           ["d@instructure.com", "retired"],
                                                                                                           ["e@instructure.com", "retired"],
                                                                                                           ["g@instructure.com", "retired"],
                                                                                                           ["i@instructure.com", "retired"],
                                                                                                           ["o@instructure.com", "retired"]
                                                                                                         ])
      %w[B@instructure.com F@instructure.com H@instructure.com].each do |path|
        expect(CommunicationChannel.where(user_id: [user1, user2]).by_path(path).detect { |cc| cc.path == path }).to be_nil
      end
    end

    it "moves and uniquify enrollments" do
      enrollment1 = course1.enroll_user(user1)
      enrollment2 = course1.enroll_student(user2, enrollment_state: "active")
      section = course1.course_sections.create!
      enrollment3 = course1.enroll_student(user1,
                                           enrollment_state: "invited",
                                           allow_multiple_enrollments: true,
                                           section:)
      enrollment4 = course1.enroll_teacher(user1)

      UserMerge.from(user1).into(user2)
      merge_data = UserMergeData.where(user_id: user2).first
      expect(merge_data.records.pluck(:context_id).sort)
        .to eq [enrollment1.id, enrollment3.id, enrollment4.id].sort
      enrollment1.reload
      expect(enrollment1.user).to eq user1
      expect(enrollment1).to be_deleted
      merge_data_record = merge_data.records.where(context_id: enrollment1).first
      expect(merge_data_record.previous_workflow_state).to eq "invited"
      enrollment2.reload
      expect(enrollment2).to be_active
      expect(enrollment2.user).to eq user2
      enrollment3.reload
      expect(enrollment3).to be_invited
      enrollment4.reload
      expect(enrollment4.user).to eq user2
      expect(enrollment4).to be_invited

      user1.reload
      expect(user1.enrollments).to eq [enrollment1]
    end

    it "handles enrollment conflicts like a champ" do
      enrollment1 = course1.enroll_student(user1, enrollment_state: "invited")
      enrollment2 = course1.enroll_student(user2, enrollment_state: "active")
      UserMerge.from(user2).into(user1)
      merge_data = UserMergeData.where(user_id: user1).first

      expect(merge_data.records.pluck(:context_id).sort)
        .to eq [enrollment1.id, enrollment2.id].sort
      enrollment1.reload
      expect(enrollment1.user).to eq user1
      expect(enrollment1.workflow_state).to eq "active"
      expect(enrollment1.enrollment_state.state).to eq "active"
      merge_data_record = merge_data.records.where(context_id: enrollment1).first
      expect(merge_data_record.previous_workflow_state).to eq "invited"

      enrollment2.reload
      expect(enrollment2.user).to eq user2
      expect(enrollment2.workflow_state).to eq "deleted"
      expect(enrollment2.enrollment_state.state).to eq "deleted"
      merge_data_record2 = merge_data.records.where(context_id: enrollment2).first
      expect(merge_data_record2.previous_workflow_state).to eq "active"
    end

    it "removes conflicting module progressions" do
      course1.enroll_user(user1, "StudentEnrollment", enrollment_state: "active")
      course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
      assignment = course1.assignments.create!(title: "some assignment")
      assignment2 = course1.assignments.create!(title: "some second assignment")
      context_module = course1.context_modules.create!(name: "some module")
      context_module2 = course1.context_modules.create!(name: "some second module")
      tag = context_module.add_item(id: assignment, type: "assignment")
      tag2 = context_module2.add_item(id: assignment2, type: "assignment")

      context_module.completion_requirements = { tag.id => { type: "must_view" } }
      context_module2.completion_requirements = { tag2.id => { type: "min_score", min_score: 5 } }
      context_module.save
      context_module2.save

      # have a conflicting module_progrssion
      assignment2.grade_student(user1, grade: "10", grader: @teacher)
      assignment2.grade_student(user2, grade: "4", grader: @teacher)

      # have a duplicate module_progression
      context_module.update_for(user1, :read, tag)
      context_module.update_for(user2, :read, tag)

      # it should work
      expect { UserMerge.from(user1).into(user2) }.to_not raise_error

      # it should have deleted or moved the module progressions for User1 and kept the completed ones for user2
      expect(ContextModuleProgression.where(user_id: user1, context_module_id: [context_module, context_module2]).count).to eq 0
      expect(ContextModuleProgression.where(user_id: user2, context_module_id: [context_module, context_module2], workflow_state: "completed").count).to eq 2
    end

    it "removes observer enrollments that observe themselves (target)" do
      enrollment1 = course1.enroll_user(user1, "StudentEnrollment", enrollment_state: "active")
      enrollment2 = course1.enroll_user(user2, "ObserverEnrollment", enrollment_state: "active", associated_user_id: user1.id)

      UserMerge.from(user1).into(user2)
      merge_data = UserMergeData.where(user_id: user2).first
      o = merge_data.records.where(context_id: enrollment2).first
      expect(o.previous_workflow_state).to eq "active"
      expect(enrollment1.reload.user).to eql user2
      expect(enrollment2.reload.workflow_state).to eql "deleted"
    end

    it "removes observer enrollments that observe themselves (source)" do
      enrollment1 = course1.enroll_user(user1, "StudentEnrollment", enrollment_state: "active")
      enrollment2 = course1.enroll_user(user2, "ObserverEnrollment", enrollment_state: "active", associated_user_id: user1.id)

      UserMerge.from(user2).into(user1)
      expect(enrollment1.reload.user).to eql user1
      expect(enrollment2.reload.workflow_state).to eql "deleted"
    end

    it "moves and uniquify observee enrollments" do
      course2
      course1.enroll_user(user1)
      course1.enroll_user(user2)

      observer1 = user_with_pseudonym
      observer2 = user_with_pseudonym
      add_linked_observer(user1, observer1)
      add_linked_observer(user1, observer2)
      add_linked_observer(user2, observer2)
      expect(ObserverEnrollment.count).to be 3
      Enrollment.where(user_id: observer2, associated_user_id: user1).update_all(workflow_state: "completed")

      UserMerge.from(user1).into(user2)
      expect(user1.observee_enrollments.size).to be 1 # deleted
      expect(user1.observee_enrollments.active_or_pending).to be_empty
      expect(user2.observee_enrollments.size).to be 2
      expect(user2.observee_enrollments.active_or_pending.size).to be 2
      expect(observer1.observer_enrollments.active_or_pending.size).to be 1
      expect(observer2.observer_enrollments.active_or_pending.size).to be 1
    end

    it "moves and uniquify observers" do
      observer1 = user_model
      observer2 = user_model
      add_linked_observer(user1, observer1)
      add_linked_observer(user1, observer2)
      add_linked_observer(user2, observer2)

      # make sure active link from user 1 comes over even if user 2 has
      # a destroyed link
      link = add_linked_observer(user2, observer1)
      link.destroy

      UserMerge.from(user1).into(user2)
      data = UserMergeData.where(user_id: user2).first
      expect(data.records.where(context_type: "UserObservationLink").count).to eq 2
      user1.reload
      expect(user1.linked_observers).to be_empty
      expect(UserObservationLink.where(student: user1).first.workflow_state).to eq "deleted"
      user2.reload
      expect(user2.linked_observers.sort_by(&:id)).to eql [observer1, observer2]
    end

    it "moves and uniquify observed users" do
      student1 = user_model
      student2 = user_model
      student3 = user_model
      add_linked_observer(student1, user1)
      add_linked_observer(student2, user1)
      add_linked_observer(student3, user1)
      add_linked_observer(student2, user2)

      # make sure active link from user 1 comes over even if user 2 has
      # a destroyed link
      link = add_linked_observer(student3, user2)
      link.destroy

      UserMerge.from(user1).into(user2)
      user1.reload
      expect(user1.linked_students).to be_empty
      user2.reload
      expect(user2.linked_students.sort_by(&:id)).to eql [student1, student2, student3]
    end

    it "moves conversations to the new user" do
      c1 = user1.initiate_conversation([user_factory, user_factory]) # group conversation
      c1.add_message("hello")
      c1.update_attribute(:workflow_state, "unread")
      c2 = user1.initiate_conversation([user_factory]) # private conversation
      c2.add_message("hello")
      c2.update_attribute(:workflow_state, "unread")
      old_private_hash = c2.conversation.private_hash

      UserMerge.from(user1).into(user2)
      expect(c1.reload.user_id).to eql user2.id
      expect(c1.conversation.participants).not_to include(user1)
      expect(user1.reload.unread_conversations_count).to be 0

      expect(c2.reload.user_id).to eql user2.id
      expect(c2.conversation.participants).not_to include(user1)
      expect(c2.conversation.private_hash).not_to eql old_private_hash
      expect(user2.reload.unread_conversations_count).to be 2
    end

    it "points other user's observers to the new user" do
      observer = user_model
      course1.enroll_student(user1)
      oe = course1.enroll_user(observer, "ObserverEnrollment")
      oe.update_attribute(:associated_user_id, user1.id)
      UserMerge.from(user1).into(user2)
      expect(oe.reload.associated_user_id).to eq user2.id
    end

    it "moves appointments" do
      course1.enroll_user(user1, "StudentEnrollment", enrollment_state: "active")
      course1.enroll_user(user2, "StudentEnrollment", enrollment_state: "active")
      ag = AppointmentGroup.create(title: "test",
                                   contexts: [course1],
                                   participants_per_appointment: 1,
                                   min_appointments_per_participant: 1,
                                   new_appointments: [
                                     ["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"],
                                     ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]
                                   ])
      res1 = ag.appointments.first.reserve_for(user1, @teacher)
      ag.appointments.last.reserve_for(user2, @teacher)
      UserMerge.from(user1).into(user2)
      res1.reload
      expect(res1.context_id).to eq user2.id
      expect(res1.context_code).to eq user2.asset_string
    end

    it "moves user attachments and handle duplicates" do
      attachment1 = Attachment.create!(user: user1, context: user1, filename: "test.txt", uploaded_data: StringIO.new("first"))
      attachment2 = Attachment.create!(user: user1, context: user1, filename: "test.txt", uploaded_data: StringIO.new("notfirst"))
      attachment3 = Attachment.create!(user: user2, context: user2, filename: "test.txt", uploaded_data: StringIO.new("first"))

      UserMerge.from(user1).into(user2)
      run_jobs

      expect(user2.attachments.count).to eq 2
      expect(user2.attachments.not_deleted.count).to eq 2

      expect(user2.attachments.not_deleted.detect { |a| a.md5 == attachment1.md5 }).to eq attachment3

      new_attachment = user2.attachments.not_deleted.detect { |a| a.md5 == attachment2.md5 }
      expect(new_attachment.display_name).not_to eq "test.txt" # attachment2 should be copied and renamed because it has unique file data
    end

    it "moves discussion topics and entries" do
      topic = course1.discussion_topics.create!(user: user2)
      entry = topic.discussion_entries.create!(user: user2)

      UserMerge.from(user2).into(user1)

      expect(topic.reload.user).to eq user1
      expect(entry.reload.user).to eq user1
    end

    it "freshens moved topics" do
      topic = course1.discussion_topics.create!(user: user2)
      now = Time.at(5.minutes.from_now.to_i) # truncate milliseconds
      Timecop.freeze(now) do
        UserMerge.from(user2).into(user1)
        expect(topic.reload.updated_at).to eq now
      end
    end

    it "freshens topics with moved entries" do
      topic = course1.discussion_topics.create!(user: user1)
      topic.discussion_entries.create!(user: user2)
      now = Time.at(5.minutes.from_now.to_i) # truncate milliseconds
      Timecop.freeze(now) do
        UserMerge.from(user2).into(user1)
        expect(topic.reload.updated_at).to eq now
      end
    end
  end

  it "updates account associations" do
    account1 = account_model
    account2 = account_model
    pseudo1 = (user1 = user_with_pseudonym account: account1).pseudonym
    pseudo2 = (user2 = user_with_pseudonym account: account2).pseudonym
    subsubaccount1 = (subaccount1 = account1.sub_accounts.create!).sub_accounts.create!
    subsubaccount2 = (subaccount2 = account2.sub_accounts.create!).sub_accounts.create!
    course_with_student(account: subsubaccount1, user: user1)
    course_with_student(account: subsubaccount2, user: user2)

    expect(user1.associated_accounts.map(&:id).sort).to eq [account1, subaccount1, subsubaccount1].map(&:id).sort
    expect(user2.associated_accounts.map(&:id).sort).to eq [account2, subaccount2, subsubaccount2].map(&:id).sort

    expect(pseudo1.user).to eq user1
    expect(pseudo2.user).to eq user2

    UserMerge.from(user1).into(user2)

    pseudo1, pseudo2 = [pseudo1, pseudo2].map { |p| Pseudonym.find(p.id) }
    user1, user2 = [user1, user2].map { |u| User.find(u.id) }

    expect(pseudo1.user).to eq pseudo2.user
    expect(pseudo1.user).to eq user2

    expect(user1.associated_accounts.map(&:id).sort).to eq []
    expect(user2.associated_accounts.map(&:id).sort).to eq [account1, account2, subaccount1, subaccount2, subsubaccount1, subsubaccount2].map(&:id).sort
  end

  context "versions" do
    let!(:user1) { user_model }
    let!(:user2) { user_model }

    context "submissions" do
      it "updates the versions table" do
        other_user = user_model

        a1 = assignment_model(submission_types: "online_text_entry")
        a1.submit_homework(user2, {
                             submission_type: "online_text_entry",
                             body: "hi"
                           })
        s1 = a1.submit_homework(user2, {
                                  submission_type: "online_text_entry",
                                  body: "hi again"
                                })
        s_other = a1.submit_homework(other_user, {
                                       submission_type: "online_text_entry",
                                       body: "hi again"
                                     })

        expect(s1.versions.count).to be(2)
        s1.versions.each { |v| expect(v.model.user_id).to eql(user2.id) }
        expect(s_other.versions.first.model.user_id).to eql(other_user.id)

        UserMerge.from(user2).into(user1)
        s1 = Submission.find(s1.id)
        s_other.reload

        expect(s1.versions.count).to be(2)
        s1.versions.each { |v| expect(v.model.user_id).to eql(user1.id) }
        expect(s_other.versions.first.model.user_id).to eql(other_user.id)
      end

      it "updates the submission_versions table" do
        assignment = assignment_model(submission_types: "online_text_entry")
        assignment.submit_homework(user2, {
                                     submission_type: "online_text_entry",
                                     body: "submission whoo"
                                   })
        submission = assignment.submit_homework(user2, {
                                                  submission_type: "online_text_entry",
                                                  body: "another submission!"
                                                })

        versions = SubmissionVersion.where(version_id: submission.versions)

        expect(versions.count).to be(2)
        versions.each { |v| expect(v.user_id).to eql(user2.id) }
        UserMerge.from(user2).into(user1)

        versions.reload
        expect(versions.count).to be(2)
        versions.each { |v| expect(v.user_id).to eql(user1.id) }
      end
    end

    it "updates quiz submissions" do
      quiz_with_graded_submission([], user: user2)
      qs1 = @quiz_submission
      quiz_with_graded_submission([], user: user2)
      qs2 = @quiz_submission

      expect(qs1.versions).to be_present
      qs1.versions.each { |v| expect(v.model.user_id).to eql(user2.id) }
      expect(qs2.versions).to be_present
      qs2.versions.each { |v| expect(v.model.user_id).to eql(user2.id) }

      UserMerge.from(user2).into(user1)
      qs1.reload
      qs2.reload

      expect(qs1.versions).to be_present
      qs1.versions.each { |v| expect(v.model.user_id).to eql(user1.id) }
      expect(qs2.versions).to be_present
      qs2.versions.each { |v| expect(v.model.user_id).to eql(user1.id) }
    end

    it "updates other appropriate versions" do
      course_factory(active_all: true)
      wiki_page = @course.wiki_pages.create(title: "Hi", user_id: user2.id)
      ra = rubric_assessment_model(context: @course, user: user2)

      expect(wiki_page.versions).to be_present
      wiki_page.versions.each { |v| expect(v.model.user_id).to eql(user2.id) }
      expect(ra.versions).to be_present
      ra.versions.each { |v| expect(v.model.user_id).to eql(user2.id) }

      UserMerge.from(user2).into(user1)
      wiki_page.reload
      ra.reload

      expect(wiki_page.versions).to be_present
      wiki_page.versions.each { |v| expect(v.model.user_id).to eql(user1.id) }
      expect(ra.versions).to be_present
      ra.versions.each { |v| expect(v.model.user_id).to eql(user1.id) }
    end
  end

  context "sharding" do
    specs_require_sharding

    it "moves past_lti_id to the new user on other shard" do
      @shard1.activate do
        account = Account.create!
        @user1 = user_with_pseudonym(username: "user1@example.com", active_all: 1, account:)
        Lti::Asset.opaque_identifier_for(@user1)
      end
      course = course_factory(active_all: true)
      user2 = user_with_pseudonym(username: "user2@example.com", active_all: 1)
      UserPastLtiId.create!(
        user: user2,
        context: course,
        user_uuid: "fake_uuid",
        user_lti_id: "fake_lti_id_from_old_merge"
      )
      UserMerge.from(user2).into(@user1)
      expect(
        UserPastLtiId.shard(course).where(user_id: @user1).take.user_lti_id
      ).to eq "fake_lti_id_from_old_merge"
    end

    describe "move_lti_ids" do
      before :once do
        @shard1.activate do
          account1 = Account.create!
          @user1 = user_with_pseudonym(username: "user1@example.com", account: account1)
          @lti_context_id_1 = Lti::Asset.opaque_identifier_for(@user1)
          @lti_id_1 = @user1.lti_id
          @uuid1 = @user1.uuid
          course_with_student account: account1, user: @user1, active_all: true
        end
        @user2 = user_with_pseudonym
        @lti_id_2 = @user2.lti_id
        @uuid2 = @user2.uuid
      end

      it "moves lti ids to the new user if possible" do
        UserMerge.from(@user1).into(@user2)

        expect(@user1.reload).to be_deleted
        expect(@user1.lti_context_id).to be_nil
        expect([@uuid1, @uuid2]).not_to include @user1.uuid

        expect(@user2.reload.lti_context_id).to eq @lti_context_id_1
        expect(@user2.lti_id).to eq @lti_id_1
        expect(@user2.uuid).to eq @uuid1

        merge_items = UserMergeData.active.find_by(user_id: @user2.id).items
        expect(merge_items.find_by(item_type: "lti_id").item).to eq @lti_id_2
        expect(merge_items.find_by(item_type: "uuid").item).to eq @uuid2
      end

      it "falls back on the old behavior if unique constraint check fails" do
        # force a constraint violation by stubbing out the shadow record update
        expect(@user1).to receive(:update_shadow_records_synchronously!).at_least(:once).and_return(nil)
        allow(InstStatsd::Statsd).to receive(:increment)
        expect { UserMerge.from(@user1).into(@user2) }.not_to raise_error
        expect(InstStatsd::Statsd).to have_received(:increment).with("user_merge.move_lti_ids.unique_constraint_failure")
        expect(@user1.reload).to be_deleted
        expect(@user1.lti_context_id).to eq @lti_context_id_1
        expect(@user2.past_lti_ids.shard(@shard1).where(user_lti_context_id: @lti_context_id_1)).to exist
      end

      it "doesn't move lti ids if the target user has enrollments" do
        course_with_student(user: @user2, active_all: true)

        UserMerge.from(@user1).into(@user2)

        expect(@user1.reload.lti_context_id).to eq @lti_context_id_1
        expect(@user1.lti_id).to eq @lti_id_1
        expect(@user1.uuid).to eq @uuid1

        expect(@user2.reload.lti_context_id).to be_nil
        expect(@user2.lti_id).to eq @lti_id_2
        expect(@user2.uuid).to eq @uuid2
        expect(@user2.past_lti_ids.shard(@shard1).where(user_lti_context_id: @lti_context_id_1)).to exist

        # ensure past lti ids aren't orphaned when another merge happens
        user3 = user_with_pseudonym
        uuid3 = user3.uuid
        UserMerge.from(@user2).into(user3)
        expect(user3.reload.uuid).to eq uuid3
        expect(user3.past_lti_ids.shard(@shard1).where(user_lti_context_id: @lti_context_id_1)).to exist
      end

      it "doesn't move lti ids if the target user has an lti_context_id" do
        lti_context_id_2 = Lti::Asset.opaque_identifier_for(@user2)
        UserMerge.from(@user1).into(@user2)
        expect(@user1.reload.lti_context_id).to eq @lti_context_id_1
        expect(@user2.reload.lti_context_id).to eq lti_context_id_2
      end
    end

    it "moves prefs over" do
      @shard1.activate do
        @user2 = user_model
        account = Account.create!
        @shard_course = course_factory(account:)
      end
      course = course_factory
      user1 = user_model
      @user2.set_preference(:custom_colors,
                            { "course_#{@shard_course.local_id}" => "#254284", "course_#{course.global_id}" => "#346543" })
      UserMerge.from(@user2).into(user1)
      expect(user1.reload.get_preference(:custom_colors)).to eq(
        { "course_#{@shard_course.global_id}" => "#254284", "course_#{course.local_id}" => "#346543" }
      )
    end

    it "moves nicknames" do
      @shard1.activate do
        @user2 = user_model
        account = Account.create!
        @shard_course = course_factory(account:)
        @user2.set_preference(:course_nicknames, @shard_course.id, "Marketing")
      end
      course = course_factory
      user1 = user_model
      @user2.set_preference(:course_nicknames, course.global_id, "Math")
      @user2.save!
      UserMerge.from(@user2).into(user1)
      user1.reload
      expect(user1.get_preference(:course_nicknames, @shard_course.global_id)).to eq "Marketing"
      expect(user1.get_preference(:course_nicknames, course.id)).to eq "Math"
    end

    it "handles favorites" do
      @shard1.activate do
        @user2 = user_model
        account = Account.create!
        @shard_course = course_factory(account:)
        @shard_course.enroll_user(@user2)
        group = account.groups.create!
        @fav = Favorite.create!(user: @user2, context: @shard_course)
        @fav2 = Favorite.create!(user: @user2, context: group)
        Favorite.create!(user: @user2, context: course_model(account:)).update!(context: nil)
      end
      user1 = user_model
      UserMerge.from(@user2).into(user1)
      expect(user1.favorites.size).to eq 2
      expect(user1.favorites.where(context_type: "Course").take.context).to eq @shard_course
      expect(user1.favorites.where(context_type: "Group").count).to eq 1
    end

    it "handles duplicate favorites" do
      user2 = @shard1.activate do
        user_model
      end
      user1 = user_model

      course = course_factory
      course.enroll_user(user1)
      course.enroll_user(user2)
      user1.favorites.create!(context: course)
      user2.favorites.create!(context: course)

      @shard1.activate do
        UserMerge.from(user2).into(user1)
      end
      expect(user1.favorites.take.context_id).to eq course.id
    end

    it "handles duplicate favorites other direction" do
      user2 = @shard1.activate do
        user_model
      end
      user1 = user_model

      course = course_factory
      course.enroll_user(user1)
      course.enroll_user(user2)
      user1.favorites.create!(context: course)
      user2.favorites.create!(context: course)

      @shard1.activate do
        UserMerge.from(user1).into(user2)
      end
      expect(user2.favorites.take.context_id).to eq course.id
    end

    it "merges with user_services across shards" do
      user1 = user_model
      @shard1.activate do
        @user2 = user_model
        user_service_model(user: @user2)
      end
      expect { UserMerge.from(@user2).into(user1) }.to_not raise_error
    end

    it "merges a user across shards" do
      user1 = user_with_pseudonym(username: "user1@example.com", active_all: 1)
      p1 = @pseudonym
      cc1 = @cc
      @shard1.activate do
        account = Account.create!
        @user2 = user_with_pseudonym(username: "user2@example.com", active_all: 1, account:)
        @p2 = @pseudonym
      end

      @shard2.activate do
        UserMerge.from(user1).into(@user2)
      end

      expect(user1).to be_deleted
      expect(p1.reload.user).to eq @user2
      expect(cc1.reload).to be_retired
      @user2.reload
      expect(@user2.communication_channels.to_a.map(&:path).sort).to eq ["user1@example.com", "user2@example.com"]
      expect(@user2.all_pseudonyms).to eq [p1, @p2]
      expect(@user2.associated_shards).to eq [@shard1, Shard.default]
    end

    it "handles conflicting notification policies" do
      user1 = user_with_pseudonym(username: "user1@example.com", active_all: 1)
      p1 = @pseudonym
      cc1 = @cc
      notification_policy_model(notification: notification_model, communication_channel: cc1)

      @shard1.activate { @user2 = user_model }

      UserMerge.from(user1).into(@user2)

      expect(user1).to be_deleted
      expect(p1.reload.user).to eq @user2
      expect(cc1.reload).to be_retired
      @user2.reload
      expect(@user2.communication_channels.to_a.map(&:path).sort).to eq ["user1@example.com"]
    end

    it "handles root_account_ids on ccs" do
      user1 = user_with_pseudonym(username: "user1@example.com", active_all: 1)
      other_account = Account.create(name: "anuroot")
      UserAccountAssociation.create!(account: other_account, user: user1)
      user1.update_root_account_ids
      user2 = user_with_pseudonym(username: "user2@example.com", active_all: 1, account: other_account)
      UserMerge.from(user2).into(user1)
      expect(@cc.reload.root_account_ids).to eq user1.root_account_ids
    end

    it "associates the user with all shards" do
      user1 = user_with_pseudonym(username: "user1@example.com", active_all: 1)
      p1 = @pseudonym
      @shard1.activate do
        account = Account.create!
        @p2 = account.pseudonyms.create!(unique_id: "user1@exmaple.com", user: user1)
      end

      @shard2.activate do
        account = Account.create!
        @user2 = user_with_pseudonym(username: "user2@example.com", active_all: 1, account:)
        @p3 = @pseudonym
        UserMerge.from(user1).into(@user2)
      end

      expect(@user2.associated_shards.sort_by(&:id)).to eq [Shard.default, @shard1, @shard2].sort_by(&:id)
      expect(@user2.all_pseudonyms.sort_by(&:id)).to eq [p1, @p2, @p3].sort_by(&:id)
    end

    it "moves ccs to the new user (but only if they don't already exist)" do
      user1 = user_model
      @shard1.activate do
        @user2 = user_model
      end

      # unconfirmed => active conflict
      communication_channel(user1, { username: "a@instructure.com" })
      communication_channel(@user2, { username: "A@instructure.com", active_cc: true })
      # active => unconfirmed conflict
      communication_channel(user1, { username: "b@instructure.com", active_cc: true })
      communication_channel(@user2, { username: "B@instructure.com" })
      # active => active conflict
      communication_channel(user1, { username: "c@instructure.com", active_cc: true })
      communication_channel(@user2, { username: "C@instructure.com", active_cc: true })
      # unconfirmed => unconfirmed conflict
      communication_channel(user1, { username: "d@instructure.com" })
      communication_channel(@user2, { username: "D@instructure.com" })
      # retired => unconfirmed conflict
      communication_channel(user1, { username: "e@instructure.com", cc_state: "retired" })
      communication_channel(@user2, { username: "E@instructure.com" })
      # unconfirmed => retired conflict
      communication_channel(user1, { username: "f@instructure.com" })
      communication_channel(@user2, { username: "F@instructure.com", cc_state: "retired" })
      # retired => active conflict
      communication_channel(user1, { username: "g@instructure.com", cc_state: "retired" })
      communication_channel(@user2, { username: "G@instructure.com", cc_state: "active" })
      # active => retired conflict
      communication_channel(user1, { username: "h@instructure.com", cc_state: "active" })
      communication_channel(@user2, { username: "H@instructure.com", cc_state: "retired" })
      # retired => retired conflict
      communication_channel(user1, { username: "i@instructure.com", cc_state: "retired" })
      communication_channel(@user2, { username: "I@instructure.com", cc_state: "retired" })
      # <nothing> => active
      communication_channel(@user2, { username: "j@instructure.com", active_cc: true })
      # active => <nothing>
      communication_channel(user1, { username: "k@instructure.com", active_cc: true })
      # <nothing> => unconfirmed
      communication_channel(@user2, { username: "l@instructure.com" })
      # unconfirmed => <nothing>
      communication_channel(user1, { username: "m@instructure.com" })
      # <nothing> => retired
      communication_channel(@user2, { username: "n@instructure.com", cc_state: "retired" })
      # retired => <nothing>
      communication_channel(user1, { username: "o@instructure.com", cc_state: "retired" })

      @shard2.activate do
        UserMerge.from(user1).into(@user2)
      end

      user1.reload
      @user2.reload
      expect(@user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to match_array([
                                                                                                            ["A@instructure.com", "active"],
                                                                                                            ["C@instructure.com", "active"],
                                                                                                            ["D@instructure.com", "unconfirmed"],
                                                                                                            ["E@instructure.com", "unconfirmed"],
                                                                                                            ["G@instructure.com", "active"],
                                                                                                            ["I@instructure.com", "retired"],
                                                                                                            ["b@instructure.com", "active"],
                                                                                                            ["f@instructure.com", "unconfirmed"],
                                                                                                            ["h@instructure.com", "active"],
                                                                                                            ["j@instructure.com", "active"],
                                                                                                            ["k@instructure.com", "active"],
                                                                                                            ["l@instructure.com", "unconfirmed"],
                                                                                                            ["m@instructure.com", "unconfirmed"],
                                                                                                            ["n@instructure.com", "retired"],
                                                                                                            ["o@instructure.com", "retired"]
                                                                                                          ])
      # on cross shard merges, the deleted user retains all CCs (pertinent ones were
      # duplicated over to the surviving shard)
      expect(user1.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort).to match_array([
                                                                                                           ["a@instructure.com", "retired"],
                                                                                                           ["b@instructure.com", "retired"],
                                                                                                           ["c@instructure.com", "retired"],
                                                                                                           ["d@instructure.com", "retired"],
                                                                                                           ["e@instructure.com", "retired"],
                                                                                                           ["f@instructure.com", "retired"],
                                                                                                           ["g@instructure.com", "retired"],
                                                                                                           ["h@instructure.com", "retired"],
                                                                                                           ["i@instructure.com", "retired"],
                                                                                                           ["k@instructure.com", "retired"],
                                                                                                           ["m@instructure.com", "retired"],
                                                                                                           ["o@instructure.com", "retired"]
                                                                                                         ])
    end

    it "does not fail copying retired sms channels" do
      user1 = User.create!
      @shard1.activate do
        @user2 = User.create!
      end

      cc1 = @user2.communication_channels.sms.create!(path: "abc")
      cc1.retire!
      @user2.reload

      UserMerge.from(@user2).into(user1)
      expect(user1.communication_channels.reload.length).to eq 1
      cc2 = user1.communication_channels.first
      expect(cc2.path).to eq "abc"
      expect(cc2.workflow_state).to eq "retired"
    end

    it "moves user attachments and handle duplicates" do
      course_factory
      # FileSystemBackend is not namespace-aware, so the same id+name in
      # different shards (e.g. root_attachment and its copy) can cause
      # :boom: ... set high ids for things that get copied, so their
      # copies' ids don't collide
      root_attachment = Attachment.create(id: 1_000_000,
                                          context: @course,
                                          filename: "unique_name1.txt",
                                          uploaded_data: StringIO.new("root_attachment_data"))
      user1 = User.create!
      # should not copy because it's identical to @user2_attachment1
      user1_attachment1 = Attachment.create!(user: user1,
                                             context: user1,
                                             filename: "shared_name1.txt",
                                             uploaded_data: StringIO.new("shared_data"))
      # copy should have root_attachment directed to @user2_attachment2, and be renamed
      user1_attachment2 = Attachment.create!(id: 1_000_001,
                                             user: user1,
                                             context: user1,
                                             filename: "shared_name2.txt",
                                             uploaded_data: StringIO.new("shared_data2"))
      # should copy as a root_attachment (even though it isn't one currently)
      user1_attachment3 = Attachment.create!(id: 1_000_002,
                                             user: user1,
                                             context: user1,
                                             filename: "unique_name2.txt",
                                             uploaded_data: StringIO.new("root_attachment_data"))
      user1_attachment3.content_type = "text/plain"
      user1_attachment3.save!
      expect(user1_attachment3.root_attachment).to eq root_attachment

      @shard1.activate do
        new_account = Account.create!
        @user2 = user_with_pseudonym(account: new_account)

        @user2_attachment1 = Attachment.create!(user: @user2,
                                                context: @user2,
                                                filename: "shared_name1.txt",
                                                uploaded_data: StringIO.new("shared_data"))

        @user2_attachment2 = Attachment.create!(user: @user2,
                                                context: @user2,
                                                filename: "unique_name3.txt",
                                                uploaded_data: StringIO.new("shared_data2"))

        @user2_attachment3 = Attachment.create!(user: @user2,
                                                context: @user2,
                                                filename: "shared_name2.txt",
                                                uploaded_data: StringIO.new("unique_data"))
      end

      UserMerge.from(user1).into(@user2)
      run_jobs

      # 3 from user1, and 3 from @user2
      expect(@user2.attachments.not_deleted.count).to eq 6

      new_user2_attachment1 = @user2.attachments.not_deleted.detect { |a| a.md5 == user1_attachment2.md5 && a.id != @user2_attachment2.id }
      expect(new_user2_attachment1.root_attachment).to eq @user2_attachment2
      expect(new_user2_attachment1.display_name).not_to eq user1_attachment2.display_name # should rename
      expect(new_user2_attachment1.namespace).not_to eq user1_attachment1.namespace

      new_user2_attachment2 = @user2.attachments.not_deleted.detect { |a| a.md5 == user1_attachment3.md5 }
      expect(new_user2_attachment2.root_attachment).to be_nil
      expect(new_user2_attachment2.content_type).to eq "text/plain"
    end

    it "marks cross-shard user submission attachments so they're still visible" do
      user1 = User.create!
      user1_attachment = Attachment.create!(user: user1,
                                            context: user1,
                                            filename: "shared_name1.txt",
                                            uploaded_data: StringIO.new("shared_data"))
      course_factory
      a1 = assignment_model(submission_types: "online_upload")
      submission = a1.submit_homework(user1, attachments: [user1_attachment])

      @shard1.activate do
        new_account = Account.create!
        @user2 = user_with_pseudonym(account: new_account)
      end

      UserMerge.from(user1).into(@user2)
      run_jobs

      expect(Submission.find(submission.id).versioned_attachments).to eq [user1_attachment]
    end

    it "moves cross-sharded conversations to the new user" do
      user1 = user_factory
      c1 = user1.initiate_conversation([user_factory, user_factory]) # group conversation
      c1.add_message("hello")
      c1.update_attribute(:workflow_state, "unread")
      c2 = user1.initiate_conversation([user_factory]) # private conversation
      c2.add_message("hello")
      c2.update_attribute(:workflow_state, "unread")

      @shard1.activate do
        new_account = Account.create!
        @user2 = user_with_pseudonym(account: new_account)
      end

      c3 = user1.initiate_conversation([user_factory, @user2]) # conversation where the target user already exists
      c3.add_message("hello")

      UserMerge.from(user1).into(@user2)
      expect(@user2.all_conversations.pluck(:conversation_id)).to match_array([c1, c2, c3].map(&:conversation_id))
    end

    context "manual invitation" do
      it "does not keep a temporary invitation in cache for an enrollment deleted after a user merge" do
        set_cache(:redis_cache_store)

        email = "foo@example.com"
        course_factory
        @course.offer!

        # create an active enrollment (usually through an SIS import)
        user1 = user_with_pseudonym(username: email, active_all: true)
        @course.enroll_user(user1).accept!

        # manually invite the same email address into the course
        # if open_registration is set on the root account, this creates a new temporary user
        user2 = user_with_communication_channel(username: email, user_state: "creation_pending")
        @course.enroll_user(user2)

        # cache the temporary invitations
        expect(Enrollment.cached_temporary_invitations(user1.communication_channels.first.path)).not_to be_empty

        # when the user follows the confirmation link, they will be prompted to merge into the other user
        UserMerge.from(user2).into(user1)

        # should not hold onto the now-deleted invitation
        # (otherwise it will retrieve it in CoursesController#fetch_enrollment,
        # which causes the login loop in CoursesController#accept_enrollment)
        expect(Enrollment.cached_temporary_invitations(user1.reload.communication_channels.first.path)).to be_empty
      end
    end
  end
end
