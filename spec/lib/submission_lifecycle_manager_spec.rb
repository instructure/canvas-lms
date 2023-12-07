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
#

require_relative "../spec_helper"

describe SubmissionLifecycleManager do
  before(:once) do
    course_with_student(active_all: true)
    assignment_model(course: @course)
  end

  describe ".recompute" do
    before do
      @instance = double("instance", recompute: nil)
    end

    it "doesn't call self.recompute_course if the assignment passed in hasn't been persisted" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute_course)

      assignment = Assignment.new(course: @course, workflow_state: :published)
      SubmissionLifecycleManager.recompute(assignment)
    end

    it "wraps assignment in an array" do
      expect(SubmissionLifecycleManager).to receive(:new).with(@course, [@assignment.id], hash_including(update_grades: false))
                                                         .and_return(@instance)
      SubmissionLifecycleManager.recompute(@assignment)
    end

    it "delegates to an instance" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute(@assignment)
    end

    it "queues a delayed job in an assignment-specific singleton in production" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:delay_if_production)
        .with(singleton: "cached_due_date:calculator:Assignment:#{@assignment.global_id}:UpdateGrades:0",
              strand: "cached_due_date:calculator:Course:#{@assignment.context.global_id}",
              max_attempts: 10).and_return(@instance)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute(@assignment)
    end

    it "calls recompute with the value of update_grades if it is set to true" do
      expect(SubmissionLifecycleManager).to receive(:new).with(@course, [@assignment.id], hash_including(update_grades: true))
                                                         .and_return(@instance)
      expect(@instance).to receive(:delay_if_production)
        .with(singleton: "cached_due_date:calculator:Assignment:#{@assignment.global_id}:UpdateGrades:1",
              strand: "cached_due_date:calculator:Course:#{@assignment.context.global_id}",
              max_attempts: 10).and_return(@instance)
      SubmissionLifecycleManager.recompute(@assignment, update_grades: true)
    end

    it "calls recompute with the value of update_grades if it is set to false" do
      expect(SubmissionLifecycleManager).to receive(:new).with(@course, [@assignment.id], hash_including(update_grades: false))
                                                         .and_return(@instance)
      expect(@instance).to receive(:delay_if_production)
        .with(singleton: "cached_due_date:calculator:Assignment:#{@assignment.global_id}:UpdateGrades:0",
              strand: "cached_due_date:calculator:Course:#{@assignment.context.global_id}",
              max_attempts: 10).and_return(@instance)
      SubmissionLifecycleManager.recompute(@assignment, update_grades: false)
    end

    it "initializes a SubmissionLifecycleManager with the value of executing_user if it is passed as an argument" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, [@assignment.id], hash_including(executing_user: @student))
        .and_return(@instance)
      SubmissionLifecycleManager.recompute(@assignment, executing_user: @student)
    end

    it "initializes a SubmissionLifecycleManager with the user set by with_executing_user if executing_user is not passed" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, [@assignment.id], hash_including(executing_user: @student))
        .and_return(@instance)

      SubmissionLifecycleManager.with_executing_user(@student) do
        SubmissionLifecycleManager.recompute(@assignment)
      end
    end

    it "initializes a SubmissionLifecycleManager with a nil executing_user if no user has been specified at all" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, [@assignment.id], hash_including(executing_user: nil))
        .and_return(@instance)
      SubmissionLifecycleManager.recompute(@assignment)
    end
  end

  describe ".recompute_course" do
    before do
      @assignments = [@assignment]
      @assignments << assignment_model(course: @course)
      @instance = double("instance", recompute: nil)
    end

    it "passes along the whole array" do
      expect(SubmissionLifecycleManager).to receive(:new).with(@course, @assignments, hash_including(update_grades: false))
                                                         .and_return(@instance)
      SubmissionLifecycleManager.recompute_course(@course, assignments: @assignments)
    end

    it "defaults to all assignments in the context" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id)), hash_including(update_grades: false)).and_return(@instance)
      SubmissionLifecycleManager.recompute_course(@course)
    end

    it "delegates to an instance" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute_course(@course, assignments: @assignments)
    end

    it "calls recompute with the value of update_grades if it is set to true" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id)), hash_including(update_grades: true)).and_return(@instance)
      SubmissionLifecycleManager.recompute_course(@course, update_grades: true)
    end

    it "calls recompute with the value of update_grades if it is set to false" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id)), hash_including(update_grades: false)).and_return(@instance)
      SubmissionLifecycleManager.recompute_course(@course, update_grades: false)
    end

    it "queues a delayed job in a singleton in production if assignments.nil" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:delay_if_production)
        .with(
          singleton: "cached_due_date:calculator:Course:#{@course.global_id}:UpdateGrades:0",
          max_attempts: 10,
          strand: "cached_due_date:calculator:Course:#{@course.global_id}"
        )
        .and_return(@instance)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute_course(@course)
    end

    it "queues a delayed job without a singleton if assignments is passed" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:delay_if_production).with(max_attempts: 10, strand: "cached_due_date:calculator:Course:#{@course.global_id}")
                                                        .and_return(@instance)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute_course(@course, assignments: @assignments)
    end

    it "does not queue a delayed job when passed run_immediately: true" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).not_to receive(:delay_if_production)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute_course(@course, assignments: @assignments, run_immediately: true)
    end

    it "calls the recompute method when passed run_immediately: true" do
      expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:recompute).with(no_args)
      SubmissionLifecycleManager.recompute_course(@course, assignments: @assignments, run_immediately: true)
    end

    it "operates on a course id" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id).sort), hash_including(update_grades: false))
        .and_return(@instance)
      expect(@instance).to receive(:delay_if_production)
        .with(
          singleton: "cached_due_date:calculator:Course:#{@course.global_id}:UpdateGrades:0",
          max_attempts: 10,
          strand: "cached_due_date:calculator:Course:#{@course.global_id}"
        )
        .and_return(@instance)
      expect(@instance).to receive(:recompute)
      SubmissionLifecycleManager.recompute_course(@course.id)
    end

    it "initializes a SubmissionLifecycleManager with the value of executing_user if it is passed in as an argument" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id)), hash_including(executing_user: @student))
        .and_return(@instance)
      SubmissionLifecycleManager.recompute_course(@course, executing_user: @student, run_immediately: true)
    end

    it "initializes a SubmissionLifecycleManager with the user set by with_executing_user if executing_user is not passed" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id)), hash_including(executing_user: @student))
        .and_return(@instance)

      SubmissionLifecycleManager.with_executing_user(@student) do
        SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)
      end
    end

    it "initializes a SubmissionLifecycleManager with a nil executing_user if no user has been specified" do
      expect(SubmissionLifecycleManager).to receive(:new)
        .with(@course, match_array(@assignments.map(&:id)), hash_including(executing_user: nil))
        .and_return(@instance)
      SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)
    end
  end

  describe ".recompute_users_for_course" do
    context "when run for a sis import" do
      specs_require_sharding

      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "calls recompute_for_sis_import in a delayed job" do
        expect do
          SubmissionLifecycleManager.recompute_users_for_course(@student.id, @course, nil, sis_import: true)
        end.to change {
          Delayed::Job.where(tag: "SubmissionLifecycleManager#recompute_for_sis_import").count
        }.from(0).to(1)
      end

      it "limits the number of sis recompute jobs that can run concurrently" do
        course_with_student(active_all: true)
        assignment_model(course: @course)

        stub_const("SubmissionLifecycleManager::MAX_RUNNING_JOBS", 1)
        Delayed::Job.create!(
          locked_at: Time.zone.now,
          locked_by: "foo",
          tag: "SubmissionLifecycleManager#recompute_for_sis_import",
          shard_id: @course.shard.id
        )
        expect do
          SubmissionLifecycleManager.recompute_users_for_course(@student.id, @course, nil, sis_import: true)
        end.not_to change {
          Delayed::Job.where(tag: "SubmissionLifecycleManager#recompute_for_sis_import").count
        }.from(1)
      end
    end

    context "when not run for a sis import" do
      let!(:assignment_1) { @assignment }
      let(:assignment_2) { assignment_model(course: @course) }
      let(:assignments) { [assignment_1, assignment_2] }

      let!(:student_1) { @student }
      let(:student_2) { student_in_course(course: @course) }
      let(:student_ids) { [student_1.id, student_2.id] }
      let(:instance) { instance_double("SubmissionLifecycleManager", recompute: nil) }

      it "delegates to an instance" do
        expect(SubmissionLifecycleManager).to receive(:new).and_return(instance)
        expect(instance).to receive(:recompute)
        SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course)
      end

      it "passes along the whole user array" do
        expect(SubmissionLifecycleManager).to receive(:new).and_return(instance)
                                                           .with(@course,
                                                                 Assignment.active.where(context: @course).pluck(:id),
                                                                 student_ids,
                                                                 hash_including(update_grades: false))
        SubmissionLifecycleManager.recompute_users_for_course(student_ids, @course)
      end

      it "calls recompute with the value of update_grades if it is set to true" do
        expect(SubmissionLifecycleManager).to receive(:new)
          .with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(update_grades: true))
          .and_return(instance)
        expect(instance).to receive(:recompute)
        SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course, assignments.map(&:id), update_grades: true)
      end

      it "calls recompute with the value of update_grades if it is set to false" do
        expect(SubmissionLifecycleManager).to receive(:new)
          .with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(update_grades: false))
          .and_return(instance)
        expect(instance).to receive(:recompute)
        SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course, assignments.map(&:id), update_grades: false)
      end

      it "passes assignments if it has any specified" do
        expect(SubmissionLifecycleManager).to receive(:new).and_return(instance)
                                                           .with(@course, assignments, student_ids, hash_including(update_grades: false))
        SubmissionLifecycleManager.recompute_users_for_course(student_ids, @course, assignments)
      end

      it "handles being called with a course id" do
        expect(SubmissionLifecycleManager).to receive(:new).and_return(instance)
                                                           .with(@course,
                                                                 Assignment.active.where(context: @course).pluck(:id),
                                                                 student_ids,
                                                                 hash_including(update_grades: false))
        SubmissionLifecycleManager.recompute_users_for_course(student_ids, @course.id)
      end

      it "queues a delayed job in a singleton if given no assignments and no singleton option" do
        @instance = double
        expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
        expect(@instance).to receive(:delay_if_production)
          .with(
            singleton: "cached_due_date:calculator:Course:#{@course.global_id}:Users:#{Digest::SHA256.hexdigest(student_1.id.to_s)}:UpdateGrades:0",
            strand: "cached_due_date:calculator:Course:#{@course.global_id}",
            max_attempts: 10
          )
          .and_return(@instance)
        expect(@instance).to receive(:recompute)
        SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course)
      end

      it "queues a delayed job in a singleton if given no assignments and a singleton option" do
        @instance = double
        expect(SubmissionLifecycleManager).to receive(:new).and_return(@instance)
        expect(@instance).to receive(:delay_if_production)
          .with(singleton: "what:up:dog", max_attempts: 10, strand: "cached_due_date:calculator:Course:#{@course.global_id}")
          .and_return(@instance)
        expect(@instance).to receive(:recompute)
        SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course, nil, singleton: "what:up:dog", strand: "cached_due_date:calculator:Course:#{@course.global_id}")
      end

      it "initializes a SubmissionLifecycleManager with the value of executing_user if set" do
        expect(SubmissionLifecycleManager).to receive(:new)
          .with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(executing_user: student_1))
          .and_return(instance)

        SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course, nil, executing_user: student_1)
      end

      it "initializes a SubmissionLifecycleManager with the user set by with_executing_user if executing_user is not passed" do
        expect(SubmissionLifecycleManager).to receive(:new)
          .with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(executing_user: student_1))
          .and_return(instance)

        SubmissionLifecycleManager.with_executing_user(student_1) do
          SubmissionLifecycleManager.recompute_users_for_course(student_1.id, @course, nil)
        end
      end

      it "initializes a SubmissionLifecycleManager with a nil executing_user if no user has been specified" do
        expect(SubmissionLifecycleManager).to receive(:new)
          .with(@course, match_array(assignments.map(&:id)), hash_including(executing_user: nil))
          .and_return(instance)
        SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)
      end
    end
  end

  describe ".with_executing_user" do
    let(:student) { User.create! }
    let(:other_student) { User.create! }
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: "hi") }
    let(:instance) { instance_double("SubmissionLifecycleManager", recompute: nil) }

    it "accepts a User" do
      expect do
        SubmissionLifecycleManager.with_executing_user(student) do
          SubmissionLifecycleManager.recompute_course(course, run_immediately: true)
        end
      end.not_to raise_error
    end

    it "accepts a user ID" do
      expect do
        SubmissionLifecycleManager.with_executing_user(student.id) do
          SubmissionLifecycleManager.recompute_course(course, run_immediately: true)
        end
      end.not_to raise_error
    end

    it "accepts a nil value" do
      expect do
        SubmissionLifecycleManager.with_executing_user(nil) do
          SubmissionLifecycleManager.recompute_course(course, run_immediately: true)
        end
      end.not_to raise_error
    end

    it "raises an error if no argument is given" do
      expect do
        SubmissionLifecycleManager.with_executing_user do
          SubmissionLifecycleManager.recompute_course(course, run_immediately: true)
        end
      end.to raise_error(ArgumentError)
    end
  end

  describe ".current_executing_user" do
    let(:student) { User.create! }
    let(:other_student) { User.create! }

    it "returns the user set by with_executing_user" do
      SubmissionLifecycleManager.with_executing_user(student) do
        expect(SubmissionLifecycleManager.current_executing_user).to eq student
      end
    end

    it "returns nil if no user has been set" do
      expect(SubmissionLifecycleManager.current_executing_user).to be_nil
    end

    it "returns the user in the closest scope when multiple calls are nested" do
      SubmissionLifecycleManager.with_executing_user(student) do
        SubmissionLifecycleManager.with_executing_user(other_student) do
          expect(SubmissionLifecycleManager.current_executing_user).to eq other_student
        end
      end
    end

    it "does not consider users who are no longer in scope" do
      SubmissionLifecycleManager.with_executing_user(student) do
        SubmissionLifecycleManager.with_executing_user(other_student) { nil }

        expect(SubmissionLifecycleManager.current_executing_user).to eq student
      end
    end
  end

  describe "#recompute" do
    subject(:cacher) { SubmissionLifecycleManager.new(@course, [@assignment]) }

    let(:submission) { submission_model(assignment: @assignment, user: first_student) }
    let(:first_student) { @student }

    context "sharding" do
      specs_require_sharding

      before do
        @shard1.activate do
          account = Account.create!
          course_with_student(account:, active_all: true)
          assignment_model(course: @course)
        end
      end

      it "does not soft-delete assigned submissions when the assignment ID is passed as a global ID" do
        @shard2.activate do
          expect { SubmissionLifecycleManager.new(@course, [@assignment.id]).recompute }.not_to change {
            @assignment.all_submissions.find_by(user: @student).workflow_state
          }.from("unsubmitted")
        end
      end

      it "does not soft-delete assigned submissions when the assignment ID is passed as a local ID" do
        @shard1.activate do
          expect { SubmissionLifecycleManager.new(@course, [@assignment.id]).recompute }.not_to change {
            @assignment.all_submissions.find_by(user: @student).workflow_state
          }.from("unsubmitted")
        end
      end
    end

    context "unassigning students that have concluded enrollments" do
      before do
        @assignment = @course.assignments.create!
        @enrollment = @course.enrollments.find_by(user: @student, course_section: @course.default_section)
        @second_section = @course.course_sections.create!(name: "Second Section")
      end

      let(:submission) { Submission.find_by(user: @student, assignment: @assignment) }

      context "some students remain assigned to the assignment" do
        before do
          second_student = user_factory(active_all: true)
          @course.enroll_student(second_student, enrollment_state: "active", section: @second_section)
        end

        it "does not delete the submission if all of a student's enrollments are completed" do
          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "unsubmitted"
        end

        it "does not delete the submission if all of a students enrollments are completed, rejected, or deleted" do
          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Third Section"),
            allow_multiple_enrollments: true
          ).destroy

          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Fourth Section"),
            allow_multiple_enrollments: true
          ).reject!

          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "unsubmitted"
        end

        it "deletes the submission if the student has at least one active enrollment" do
          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Third Section"),
            allow_multiple_enrollments: true
          )

          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "deleted"
        end

        it "deletes the submission if the student has at least one inactive enrollment" do
          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Third Section"),
            allow_multiple_enrollments: true
          ).deactivate

          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "deleted"
        end
      end

      context "no students remain assigned to the assignment" do
        it "does not delete the submission if all of a student's enrollments are completed" do
          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "unsubmitted"
        end

        it "does not delete the submission if all of a students enrollments are completed, rejected, or deleted" do
          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Third Section"),
            allow_multiple_enrollments: true
          ).destroy

          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Fourth Section"),
            allow_multiple_enrollments: true
          ).reject!

          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "unsubmitted"
        end

        it "deletes the submission if the student has at least one active enrollment" do
          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Third Section"),
            allow_multiple_enrollments: true
          )

          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "deleted"
        end

        it "deletes the submission if the student has at least one inactive enrollment" do
          @course.enroll_student(
            @student,
            enrollment_state: "active",
            section: @course.course_sections.create!(name: "Third Section"),
            allow_multiple_enrollments: true
          ).deactivate

          @enrollment.conclude
          create_section_override_for_assignment(@assignment, course_section: @second_section)
          @assignment.update!(only_visible_to_overrides: true)
          cacher.recompute
          expect(submission.workflow_state).to eq "deleted"
        end
      end
    end

    describe "re-adding removed students from a quiz" do
      specs_require_sharding

      it "assigns the correct workflow state to the submission" do
        @shard2.activate do
          account = Account.create!
          course_with_student(active_all: true, account:)

          @quiz = @course.quizzes.create!
          @quiz.workflow_state = "available"
          @quiz.quiz_data = [{ correct_comments: "", assessment_question_id: nil, incorrect_comments: "", question_name: "Question 1", points_possible: 1, question_text: "Write an essay!", name: "Question 1", id: 128, answers: [], question_type: "essay_question" }]
          @quiz.save!

          @quiz_submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
          @quiz_submission.update!(workflow_state: "pending_review")

          submission = @quiz_submission.submission
          submission.update_columns(grade: "5", workflow_state: "deleted")

          expect { SubmissionLifecycleManager.new(@course, @quiz.assignment).recompute }.to change {
            submission.reload.workflow_state
          }.from("deleted").to("pending_review")
        end
      end
    end

    describe "re-adding removed students from a lti quiz" do
      before :once do
        Account.site_admin.enable_feature!(:new_quiz_deleted_workflow_restore_pending_review_state)

        account = Account.create!
        course_with_student(active_all: true, account:)
        @new_quiz = new_quizzes_assignment(course: @course, title: "Some New Quiz")
        @new_quiz.workflow_state = "available"
        @new_quiz.save!
      end

      it "assigns the correct workflow state to the new quiz submission if pending_review" do
        submission = @new_quiz.submit_homework(@student)
        submission.workflow_state = "pending_review"
        submission.save!
        Version.create!(versionable: submission, model: submission)

        submission.update_columns(grade: "5", workflow_state: "deleted")

        expect { SubmissionLifecycleManager.new(@course, @new_quiz).recompute }.to change {
          submission.reload.workflow_state
        }.from("deleted").to("pending_review")
      end

      it "assigns the correct workflow state to the new quiz submission if graded" do
        submission = @new_quiz.submit_homework(@student)
        submission.workflow_state = "graded"
        submission.save!
        Version.create!(versionable: submission, model: submission)

        submission.update_columns(grade: "5", workflow_state: "deleted")

        expect { SubmissionLifecycleManager.new(@course, @new_quiz).recompute }.to change {
          submission.reload.workflow_state
        }.from("deleted").to("graded")
      end

      it "does not assign workflow to pending_review when feature flag off" do
        Account.site_admin.disable_feature!(:new_quiz_deleted_workflow_restore_pending_review_state)
        submission = @new_quiz.submit_homework(@student)
        submission.workflow_state = "pending_review"
        submission.save!
        Version.create!(versionable: submission, model: submission)

        submission.update_columns(grade: "5", workflow_state: "deleted")

        expect { SubmissionLifecycleManager.new(@course, @new_quiz).recompute }.to change {
          submission.reload.workflow_state
        }.from("deleted").to("graded")
      end
    end

    describe "updated_at" do
      it "updates the updated_at when the workflow_state of a submission changes" do
        submission.update!(workflow_state: "deleted")
        expect { cacher.recompute }.to change { submission.reload.updated_at }
      end

      it "updates the updated_at when the due date of the assignment changed" do
        allow(SubmissionLifecycleManager).to receive(:recompute)
        submission.assignment.update!(due_at: 1.day.from_now)
        expect { cacher.recompute }.to change { submission.reload.updated_at }
      end

      it "updates the updated_at when the grading period changed" do
        allow(SubmissionLifecycleManager).to receive(:recompute_course)
        group = @course.grading_period_groups.create!
        group.grading_periods.create!(
          close_date: @assignment.due_at + 1.day,
          end_date: @assignment.due_at + 1.day,
          start_date: @assignment.due_at - 10.days,
          title: "gp"
        )
        expect { cacher.recompute }.to change { submission.reload.updated_at }
      end

      it "updates the updated_at when the anonymous id of the submission changed" do
        submission.update!(anonymous_id: nil)
        expect { cacher.recompute }.to change { submission.reload.updated_at }
      end

      it "does not update the updated_at when no attributes changed" do
        expect { cacher.recompute }.not_to change { submission.reload.updated_at }
      end
    end

    describe "moderated grading" do
      it "creates moderated selections for students" do
        expect(cacher).to receive(:create_moderation_selections_for_assignment).once.and_return(nil)
        cacher.recompute
      end
    end

    describe "anonymous_id" do
      context "given no existing submission" do
        before do
          submission.delete
          cacher.recompute
        end

        it "creates a submission with an anoymous_id" do
          first_student_submission = @assignment.submissions.find_by!(user: first_student)
          expect(first_student_submission.anonymous_id).to be_present
        end
      end

      context "given an existing submission with an anoymous_id" do
        it "does not change anonymous_ids" do
          expect { cacher.recompute }.not_to change { submission.reload.anonymous_id }
        end
      end

      context "given an existing submission without an anonymous_id" do
        before do
          submission.update_attribute(:anonymous_id, nil)
        end

        it "sets anonymous_id for an existing submission" do
          expect { cacher.recompute }.to change { submission.reload.anonymous_id }.from(nil).to(String)
        end
      end
    end

    describe "cached_due_date" do
      before do
        Submission.update_all(cached_due_date: nil)
      end

      context "without existing submissions" do
        it "creates submissions for enrollments that are not overridden" do
          Submission.destroy_all
          expect { cacher.recompute }.to change {
            Submission.active.where(assignment_id: @assignment.id).count
          }.from(0).to(1)
        end

        it "doesn't blow up when handling BC dates" do
          bc_date = 5000.years.ago
          @assignment.update_columns(due_at: bc_date)
          expect { cacher.recompute }.to change {
            Submission.find_by(assignment: @assignment, user: @student)&.cached_due_date
          }.from(nil).to(bc_date.change(usec: 0))
        end

        it "deletes submissions for enrollments that are deleted" do
          @course.student_enrollments.update_all(workflow_state: "deleted")

          expect { cacher.recompute }.to change {
            Submission.active.where(assignment_id: @assignment.id).count
          }.from(1).to(0)
        end

        it "updates the timestamp when deleting submissions for enrollments that are deleted" do
          @course.student_enrollments.update_all(workflow_state: "deleted")

          expect { cacher.recompute }.to change {
            Submission.where(assignment_id: @assignment.id).first.updated_at
          }
        end

        it "creates submissions for enrollments that are overridden" do
          assignment_override_model(assignment: @assignment, set: @course.default_section)
          @override.override_due_at(@assignment.due_at + 1.day)
          @override.save!
          Submission.destroy_all

          expect { cacher.recompute }.to change {
            Submission.active.where(assignment_id: @assignment.id).count
          }.from(0).to(1)
        end

        it "does not create submissions for enrollments that are not assigned" do
          @assignment1 = @assignment
          @assignment2 = assignment_model(course: @course)
          @assignment2.only_visible_to_overrides = true
          @assignment2.save!

          Submission.delete_all

          expect { SubmissionLifecycleManager.recompute_course(@course) }.to change {
            Submission.active.count
          }.from(0).to(1)
        end

        it "does not create submissions for concluded enrollments" do
          student2 = user_factory
          @course.enroll_student(student2, enrollment_state: "active")
          student2.enrollments.find_by(course: @course).conclude
          expect { SubmissionLifecycleManager.recompute_course(@course) }.not_to change {
            Submission.active.where(user_id: student2.id).count
          }
        end
      end

      it "does not create another submission for enrollments that have a submission" do
        expect { cacher.recompute }.not_to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }
      end

      it "does not create another submission for enrollments that have a submission, even with an overridden" do
        assignment_override_model(assignment: @assignment, set: @course.default_section)
        @override.override_due_at(@assignment.due_at + 1.day)
        @override.save!

        expect { cacher.recompute }.not_to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }
      end

      it "deletes submissions for enrollments that are no longer assigned" do
        @assignment.only_visible_to_overrides = true

        expect { @assignment.save! }.to change {
          Submission.active.count
        }.from(1).to(0)
      end

      it "updates the timestamp when deleting submissions for enrollments that are no longer assigned" do
        @assignment.only_visible_to_overrides = true

        expect { @assignment.save! }.to change {
          Submission.first.updated_at
        }
      end

      it "restores submissions for enrollments that are assigned again" do
        @assignment.submit_homework(@student, submission_type: :online_url, url: "http://instructure.com")
        @assignment.only_visible_to_overrides = true
        @assignment.save!
        expect(Submission.first.workflow_state).to eq "deleted"

        @assignment.only_visible_to_overrides = false
        expect { @assignment.save! }.to change {
          Submission.active.count
        }.from(0).to(1)
        expect(Submission.first.workflow_state).to eq "submitted"
      end

      context "no overrides" do
        it "sets the cached_due_date to the assignment due_at" do
          @assignment.due_at += 1.day
          @assignment.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end

        it "sets the cached_due_date to nil if the assignment has no due_at" do
          @assignment.due_at = nil
          @assignment.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to be_nil
        end
      end

      context "one applicable override" do
        before do
          assignment_override_model(
            assignment: @assignment,
            set: @course.default_section
          )
        end

        it "prefers override's due_at over assignment's due_at" do
          @override.override_due_at(@assignment.due_at - 1.day)
          @override.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override.due_at.change(usec: 0)
        end

        it "prefers override's due_at over assignment's nil" do
          @override.override_due_at(@assignment.due_at - 1.day)
          @override.save!

          @assignment.due_at = nil
          @assignment.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override.due_at.change(usec: 0)
        end

        it "prefers override's nil over assignment's due_at" do
          @override.override_due_at(nil)
          @override.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override.due_at
        end

        it "does not apply override if it doesn't override due_at" do
          @override.clear_due_at_override
          @override.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end
      end

      context "adhoc override" do
        before do
          @student1 = @student
          @student2 = user_factory
          @course.enroll_student(@student2, enrollment_state: "active")

          assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 1.day
          )
          @override.assignment_override_students.create!(user: @student2)

          @submission1 = submission_model(assignment: @assignment, user: @student1)
          @submission2 = submission_model(assignment: @assignment, user: @student2)
          Submission.update_all(cached_due_date: nil)
        end

        it "applies to students in the adhoc set" do
          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(usec: 0)
        end

        it "does not apply to students not in the adhoc set" do
          cacher.recompute
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end
      end

      context "section override" do
        before do
          @student1 = @student
          @student2 = user_factory

          add_section("second section")
          @course.enroll_student(@student2, enrollment_state: "active", section: @course_section)

          assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 1.day,
            set: @course_section
          )

          @submission1 = submission_model(assignment: @assignment, user: @student1)
          @submission2 = submission_model(assignment: @assignment, user: @student2)
          Submission.update_all(cached_due_date: nil)

          cacher.recompute
        end

        it "applies to students in that section" do
          expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(usec: 0)
        end

        it "does not apply to students in other sections" do
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end

        it "does not apply to non-active enrollments in that section" do
          @course.enroll_student(@student1,
                                 enrollment_state: "deleted",
                                 section: @course_section,
                                 allow_multiple_enrollments: true)
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end
      end

      context "group override" do
        before do
          @student1 = @student
          @student2 = user_factory
          @course.enroll_student(@student2, enrollment_state: "active")

          @assignment.group_category = group_category
          @assignment.save!

          group_with_user(
            group_context: @course,
            group_category: @assignment.group_category,
            user: @student2,
            active_all: true
          )

          assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 1.day,
            set: @group
          )

          @submission1 = submission_model(assignment: @assignment, user: @student1)
          @submission2 = submission_model(assignment: @assignment, user: @student2)
          Submission.update_all(cached_due_date: nil)
        end

        it "applies to students in that group" do
          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(usec: 0)
        end

        it "does not apply to students not in the group" do
          cacher.recompute
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end

        it "does not apply to non-active memberships in that group" do
          cacher.recompute
          @group.add_user(@student1, "deleted")
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end
      end

      context "multiple overrides" do
        before do
          add_section("second section")
          multiple_student_enrollment(@student, @course_section)

          @override1 = assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 1.day,
            set: @course.default_section
          )

          @override2 = assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 1.day,
            set: @course_section
          )
        end

        it "prefers first override's due_at if latest" do
          @override1.override_due_at(@assignment.due_at + 2.days)
          @override1.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override1.due_at.change(usec: 0)
        end

        it "prefers second override's due_at if latest" do
          @override2.override_due_at(@assignment.due_at + 2.days)
          @override2.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override2.due_at.change(usec: 0)
        end

        it "is nil if first override's nil" do
          @override1.override_due_at(nil)
          @override1.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to be_nil
        end

        it "is nil if second override's nil" do
          @override2.override_due_at(nil)
          @override2.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to be_nil
        end
      end

      context "multiple submissions with selective overrides" do
        before do
          @student1 = @student
          @student2 = user_factory
          @student3 = user_factory

          add_section("second section")
          @course.enroll_student(@student2, enrollment_state: "active", section: @course_section)
          @course.enroll_student(@student3, enrollment_state: "active")
          multiple_student_enrollment(@student3, @course_section)

          @override1 = assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 2.days,
            set: @course.default_section
          )

          @override2 = assignment_override_model(
            assignment: @assignment,
            due_at: @assignment.due_at + 2.days,
            set: @course_section
          )

          @submission1 = submission_model(assignment: @assignment, user: @student1)
          @submission2 = submission_model(assignment: @assignment, user: @student2)
          @submission3 = submission_model(assignment: @assignment, user: @student3)
          Submission.update_all(cached_due_date: nil)
        end

        it "uses first override where second doesn't apply" do
          @override1.override_due_at(@assignment.due_at + 1.day)
          @override1.save!

          cacher.recompute
          expect(@submission1.reload.cached_due_date).to eq @override1.due_at.change(usec: 0)
        end

        it "uses second override where the first doesn't apply" do
          @override2.override_due_at(@assignment.due_at + 1.day)
          @override2.save!

          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override2.due_at.change(usec: 0)
        end

        it "uses the best override where both apply" do
          @override1.override_due_at(@assignment.due_at + 1.day)
          @override1.save!

          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override2.due_at.change(usec: 0)
        end
      end

      context "multiple assignments, only one overridden" do
        before do
          @assignment1 = @assignment
          @assignment2 = assignment_model(course: @course)

          assignment_override_model(
            assignment: @assignment1,
            due_at: @assignment1.due_at + 1.day
          )
          @override.assignment_override_students.create!(user: @student)

          @submission1 = submission_model(assignment: @assignment1, user: @student)
          @submission2 = submission_model(assignment: @assignment2, user: @student)
          Submission.update_all(cached_due_date: nil)

          SubmissionLifecycleManager.new(@course, [@assignment1, @assignment2]).recompute
        end

        it "applies to submission on the overridden assignment" do
          expect(@submission1.reload.cached_due_date).to eq @override.due_at.change(usec: 0)
        end

        it "does not apply to apply to submission on the other assignment" do
          expect(@submission2.reload.cached_due_date).to eq @assignment.due_at.change(usec: 0)
        end
      end

      it "kicks off a LatePolicyApplicator job on completion when called with a single assignment" do
        expect(LatePolicyApplicator).to receive(:for_assignment).with(@assignment)

        cacher.recompute
      end

      it "does not kick off a LatePolicyApplicator job when called with multiple assignments" do
        @assignment1 = @assignment
        @assignment2 = assignment_model(course: @course)

        expect(LatePolicyApplicator).not_to receive(:for_assignment)

        SubmissionLifecycleManager.new(@course, [@assignment1, @assignment2]).recompute
      end

      it "does not kick off a LatePolicyApplicator job when explicitly told not to" do
        expect(LatePolicyApplicator).not_to receive(:for_assignment)

        SubmissionLifecycleManager.new(@course, [@assignment], skip_late_policy_applicator: true).recompute
      end

      it "runs the GradeCalculator inline when update_grades is true" do
        expect(@course).to receive(:recompute_student_scores_without_send_later)

        SubmissionLifecycleManager.new(@course, [@assignment], update_grades: true).recompute
      end

      it "runs the GradeCalculator inline with student ids when update_grades is true and students are given" do
        expect(@course).to receive(:recompute_student_scores_without_send_later).with([@student.id])

        SubmissionLifecycleManager.new(@course, [@assignment], [@student.id], update_grades: true).recompute
      end

      it "does not run the GradeCalculator inline when update_grades is false" do
        expect(@course).not_to receive(:recompute_student_scores_without_send_later)

        SubmissionLifecycleManager.new(@course, [@assignment], update_grades: false).recompute
      end

      it "does not run the GradeCalculator inline when update_grades is not specified" do
        expect(@course).not_to receive(:recompute_student_scores_without_send_later)

        SubmissionLifecycleManager.new(@course, [@assignment]).recompute
      end

      context "when called for specific users" do
        before(:once) do
          @student_1 = @student
          @student_2, @student_3, @student_4 = n_students_in_course(3, course: @course)
          # The n_students_in_course helper creates the enrollments in a
          # way that appear to skip callbacks
          cacher.recompute
        end

        it "leaves other users submissions alone on enrollment destroy" do
          @student_3.enrollments.each(&:destroy)

          sub_ids = Submission.active.where(assignment: @assignment).order(:user_id).pluck(:user_id)
          expect(sub_ids).to contain_exactly(@student_1.id, @student_2.id, @student_4.id)
        end

        it "adds submissions for a single user added to a course" do
          new_student = user_model
          @course.enroll_user(new_student)

          submission = Submission.active.where(assignment: @assignment, user_id: new_student.id)
          expect(submission).to exist
        end

        it "adds submissions for multiple users" do
          new_students = n_students_in_course(2, course: @course)
          new_student_ids = new_students.map(&:id)

          ddc = SubmissionLifecycleManager.new(@course, @assignment, new_student_ids)
          ddc.recompute

          submission_count = Submission.active.where(assignment: @assignment, user_id: new_student_ids).count
          expect(submission_count).to eq 2
        end
      end
    end

    describe "cached_quiz_lti" do
      let_once(:tool) do
        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
      end

      it "sets cached_quiz_lti to false if the assignment is not a Quizzes.Next assignment" do
        cacher.recompute
        expect(submission).to_not be_cached_quiz_lti
      end

      it "sets cached_quiz_lti to true if the assignment's external tool identifies itself as Quizzes 2" do
        @assignment.update!(submission_types: "external_tool")
        tool.content_tags.create!(context: @assignment)

        cacher.recompute
        expect(submission).to be_cached_quiz_lti
      end
    end

    describe "root_account_id" do
      it "is set to the associated course's root account ID" do
        new_student = user_model
        @course.enroll_user(new_student)

        submission = @assignment.submission_for_student(new_student)
        expect(submission.root_account_id).to eq @assignment.course.root_account_id
      end
    end

    it "adds course_id" do
      cacher.recompute
      expect(submission.course_id).to eq @course.id
    end
  end

  describe "AnonymousOrModerationEvent logging" do
    let(:course) { Course.create! }
    let(:teacher) { User.create! }
    let(:student) { User.create! }

    let(:original_due_at) { Time.zone.now }
    let(:due_at) { 1.day.from_now }

    # Remove seconds, following the lead of EffectiveDueDates
    let(:original_due_at_formatted) { original_due_at.change(usec: 0).iso8601 }
    let(:due_at_formatted) { due_at.change(usec: 0).iso8601 }

    let(:event_type) { "submission_updated" }

    before do
      course.enroll_teacher(teacher, active_all: true)
      course.enroll_student(student, active_all: true)
    end

    context "when an executing user is supplied" do
      context "when the due date changes on an auditable assignment" do
        let!(:assignment) do
          course.assignments.create!(
            title: "zzz",
            anonymous_grading: true,
            due_at: original_due_at
          )
        end
        let(:last_event) { AnonymousOrModerationEvent.where(assignment:, event_type:).last }

        before do
          Assignment.suspend_due_date_caching do
            assignment.update!(due_at:)
          end
        end

        it "creates an AnonymousOrModerationEvent for each updated submission" do
          expect do
            SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          end.to change {
            AnonymousOrModerationEvent.where(assignment:, event_type:).count
          }.by(1)
        end

        it "includes the old due date in the payload" do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          expect(last_event.payload["due_at"].first).to eq original_due_at_formatted
        end

        it "includes the new due date in the payload" do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          expect(last_event.payload["due_at"].second).to eq due_at_formatted
        end
      end

      context "when a due date is added to an auditable assignment" do
        let!(:assignment) { course.assignments.create!(title: "zzz", anonymous_grading: true) }
        let(:last_event) { AnonymousOrModerationEvent.where(assignment:, event_type:).last }

        before do
          Assignment.suspend_due_date_caching do
            assignment.update!(due_at:)
          end
        end

        it "creates an AnonymousOrModerationEvent for each updated submission" do
          expect do
            SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          end.to change {
            AnonymousOrModerationEvent.where(assignment:, event_type:).count
          }.by(1)
        end

        it "includes nil as the old due date in the payload" do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          expect(last_event.payload["due_at"].first).to be_nil
        end

        it "includes the new due date in the payload" do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          expect(last_event.payload["due_at"].second).to eq due_at_formatted
        end
      end

      context "when a due date is removed from an auditable assignment" do
        let!(:assignment) { course.assignments.create!(title: "z!", anonymous_grading: true, due_at: original_due_at) }
        let(:last_event) { AnonymousOrModerationEvent.where(assignment:, event_type:).last }

        before do
          Assignment.suspend_due_date_caching do
            assignment.update!(due_at: nil)
          end
        end

        it "creates an AnonymousOrModerationEvent for each updated submission" do
          expect do
            SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          end.to change {
            AnonymousOrModerationEvent.where(assignment:, event_type:).count
          }.by(1)
        end

        it "includes the old due date in the payload" do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          expect(last_event.payload["due_at"].first).to eq original_due_at_formatted
        end

        it "includes nil as the new due date in the payload" do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
          expect(last_event.payload["due_at"].second).to be_nil
        end
      end

      it "does not create AnonymousOrModerationEvents for non-auditable assignments" do
        assignment = nil
        Assignment.suspend_due_date_caching do
          assignment = course.assignments.create!(
            title: "zzz",
            due_at:
          )
        end

        expect do
          SubmissionLifecycleManager.recompute(assignment, executing_user: teacher)
        end.not_to change {
          AnonymousOrModerationEvent.where(assignment:, event_type: "submission_updated").count
        }
      end
    end

    it "does not create AnonymousOrModerationEvents when no executing user is supplied" do
      assignment = nil
      Assignment.suspend_due_date_caching do
        assignment = course.assignments.create!(title: "zzz", anonymous_grading: true)
      end

      expect do
        SubmissionLifecycleManager.recompute(assignment)
      end.not_to change {
        AnonymousOrModerationEvent.where(assignment:, event_type: "submission_updated").count
      }
    end
  end

  context "error trapping" do
    let(:submission_lifecycle_manager) { SubmissionLifecycleManager.new(@course, @assignment) }

    describe ".perform_submission_upsert" do
      it "raises Delayed::RetriableError when deadlocked" do
        allow(Submission.connection).to receive(:execute).and_raise(ActiveRecord::Deadlocked)

        expect { submission_lifecycle_manager.send(:perform_submission_upsert, []) }.to raise_error(Delayed::RetriableError)
      end

      it "raises Delayed::RetriableError when unique record violations occur" do
        allow(Score.connection).to receive(:execute).and_raise(ActiveRecord::RecordNotUnique)

        expect { submission_lifecycle_manager.send(:perform_submission_upsert, []) }.to raise_error(Delayed::RetriableError)
      end
    end
  end
end
