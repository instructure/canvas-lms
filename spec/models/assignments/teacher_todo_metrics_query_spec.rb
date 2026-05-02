# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Assignments::TeacherTodoMetricsQuery do
  subject(:metrics) { described_class.new(assignment, teacher).metrics }

  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(course:, active_all: true).user }
  let_once(:assignment) do
    course.assignments.create!(
      title: "Essay 1",
      submission_types: "online_text_entry",
      due_at: 1.day.from_now,
      points_possible: 10
    )
  end

  def submit_on_time(student, resubmit: false)
    sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "done")
    if resubmit
      assignment.grade_student(student, grade: 5, grader: teacher)
      sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "revised")
    end
    sub
  end

  def submit_late(student, resubmit: false)
    sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "late")
    sub.update_columns(late_policy_status: "late")
    if resubmit
      assignment.grade_student(student, grade: 5, grader: teacher)
      sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "late again")
      sub.update_columns(late_policy_status: "late")
    end
    sub
  end

  def metrics_for(assignment_arg, user)
    described_class.new(assignment_arg, user).metrics
  end

  describe "#metrics" do
    context "with a typical mix of submissions" do
      before(:once) do
        5.times { submit_on_time(student_in_course(course:, active_all: true).user) }
        2.times { submit_late(student_in_course(course:, active_all: true).user) }
        submit_on_time(student_in_course(course:, active_all: true).user, resubmit: true)
        excused = student_in_course(course:, active_all: true).user
        assignment.submit_homework(excused, submission_type: "online_text_entry", body: "x")
        assignment.grade_student(excused, excused: true, grader: teacher)
        3.times { student_in_course(course:, active_all: true).user }
        graded = student_in_course(course:, active_all: true).user
        assignment.submit_homework(graded, submission_type: "online_text_entry", body: "great")
        assignment.grade_student(graded, grade: 8, grader: teacher)
      end

      it "computes all five metrics correctly" do
        expect(metrics).to eq(
          on_time_needs_grading_count: 6,
          late_needs_grading_count: 2,
          resubmitted_needs_grading_count: 1,
          submitted_submissions_count: 9,
          total_submissions_count: 12
        )
      end
    end

    context "when the user has no grading visibility" do
      it "returns zero metrics for an observer" do
        observer = user_factory(active_all: true)
        course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
        expect(metrics_for(assignment, observer))
          .to eq Assignments::TeacherTodoMetricsQuery::ZERO_METRICS
      end
    end

    context "with two sections and a section-limited TA" do
      let_once(:section_b) { course.course_sections.create!(name: "Section B") }
      let_once(:section_a_student) { student_in_course(course:, active_all: true).user }
      let_once(:section_b_student) do
        u = user_factory(active_all: true)
        section_b.enroll_user(u, "StudentEnrollment", "active")
        u
      end
      let_once(:section_b_ta) do
        ta = user_factory(active_all: true)
        course.enroll_ta(ta, section: section_b)
              .update!(limit_privileges_to_course_section: true, workflow_state: "active")
        ta
      end

      before(:once) do
        submit_late(section_a_student)
        submit_on_time(section_b_student)
      end

      it "includes both sections for a full-visibility teacher" do
        expect(metrics_for(assignment, teacher)).to include(
          on_time_needs_grading_count: 1,
          late_needs_grading_count: 1,
          total_submissions_count: 2
        )
      end

      it "limits the TA to only their own section" do
        expect(metrics_for(assignment, section_b_ta)).to include(
          on_time_needs_grading_count: 1,
          late_needs_grading_count: 0,
          total_submissions_count: 1
        )
      end
    end

    context "for moderated assignments before grades are published" do
      let_once(:moderated_assignment) do
        course.assignments.create!(
          title: "Moderated Essay",
          submission_types: "online_text_entry",
          moderated_grading: true,
          grader_count: 2,
          final_grader: teacher,
          due_at: 1.day.from_now,
          points_possible: 10
        )
      end
      let_once(:other_grader) { ta_in_course(course:, active_all: true).user }
      let_once(:another_grader) { ta_in_course(course:, active_all: true).user }
      let_once(:students) { Array.new(3) { student_in_course(course:, active_all: true).user } }

      before(:once) do
        students.each do |s|
          moderated_assignment.submit_homework(s, submission_type: "online_text_entry", body: "essay")
        end
      end

      it "counts every visible submission before any grader scores" do
        expect(metrics_for(moderated_assignment, teacher)).to include(
          on_time_needs_grading_count: 3,
          total_submissions_count: 3
        )
      end

      it "excludes the grader's own scored provisional" do
        students[0].submissions.find_by(assignment: moderated_assignment)
                   .find_or_create_provisional_grade!(teacher, score: 5)

        expect(metrics_for(moderated_assignment, teacher)).to include(
          on_time_needs_grading_count: 2,
          total_submissions_count: 2
        )
      end

      it "keeps the grader's nil-score provisional in the count" do
        students[0].submissions.find_by(assignment: moderated_assignment)
                   .find_or_create_provisional_grade!(teacher)

        expect(metrics_for(moderated_assignment, teacher)).to include(
          on_time_needs_grading_count: 3
        )
      end

      it "drops a submission after two other graders score it" do
        sub = students[0].submissions.find_by(assignment: moderated_assignment)

        # SubmissionLifecycleManager auto-populates ModeratedGrading::Selection
        # rows for moderated students, which raises the threshold from 1 to 2.
        sub.find_or_create_provisional_grade!(other_grader, score: 4)
        expect(metrics_for(moderated_assignment, teacher)).to include(on_time_needs_grading_count: 3)

        sub.find_or_create_provisional_grade!(another_grader, score: 5)
        expect(metrics_for(moderated_assignment, teacher)).to include(on_time_needs_grading_count: 2)
      end

      it "stops excluding once grades are published" do
        students[0].submissions.find_by(assignment: moderated_assignment)
                   .find_or_create_provisional_grade!(teacher, score: 5)
        moderated_assignment.update!(grades_published_at: Time.zone.now)

        expect(metrics_for(moderated_assignment, teacher)).to include(
          on_time_needs_grading_count: 3,
          total_submissions_count: 3
        )
      end
    end

    context "for checkpointed parent assignments" do
      let_once(:parent) { course.assignments.create!(title: "Discussion", has_sub_assignments: true) }
      let_once(:reply_to_topic) do
        parent.sub_assignments.create!(
          context: course,
          title: "Reply to Topic",
          submission_types: "online_text_entry",
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          due_at: 1.day.from_now,
          points_possible: 5
        )
      end
      let_once(:reply_to_entry) do
        parent.sub_assignments.create!(
          context: course,
          title: "Reply to Entry",
          submission_types: "online_text_entry",
          sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
          due_at: 1.day.from_now,
          points_possible: 5
        )
      end
      let_once(:student) { student_in_course(course:, active_all: true).user }

      before(:once) do
        reply_to_topic
        reply_to_entry
      end

      it "counts submissions to the children when the parent is queried" do
        reply_to_topic.submit_homework(student, submission_type: "online_text_entry", body: "topic")
        reply_to_entry.submit_homework(student, submission_type: "online_text_entry", body: "entry")

        expect(metrics_for(parent, teacher)).to include(
          on_time_needs_grading_count: 2,
          submitted_submissions_count: 2,
          total_submissions_count: 2
        )
      end

      # When a student submits only one of two checkpoints, the parent submission's
      # submission_type aggregates to NULL, which would fail needs_grading_conditions
      # if we queried the parent row instead of the children.
      it "counts a partial submission to one checkpoint" do
        reply_to_topic.submit_homework(student, submission_type: "online_text_entry", body: "topic")

        expect(metrics_for(parent, teacher)).to include(on_time_needs_grading_count: 1)
      end

      it "computes metrics for a sub_assignment directly" do
        reply_to_topic.submit_homework(student, submission_type: "online_text_entry", body: "topic")

        expect(metrics_for(reply_to_topic, teacher)).to include(
          on_time_needs_grading_count: 1,
          total_submissions_count: 1
        )
      end
    end

    context "with a student enrolled in two sections of the same course" do
      let_once(:section_b) { course.course_sections.create!(name: "Section B") }
      let_once(:dual_section_student) do
        u = user_factory(active_all: true)
        course.enroll_student(u, enrollment_state: "active", allow_multiple_enrollments: true)
        course.enroll_student(u, section: section_b, enrollment_state: "active", allow_multiple_enrollments: true)
        u
      end

      before(:once) { submit_on_time(dual_section_student) }

      it "counts the student once across both enrollments" do
        expect(metrics).to include(
          on_time_needs_grading_count: 1,
          submitted_submissions_count: 1,
          total_submissions_count: 1
        )
      end
    end

    context "for non-actionable submission states" do
      let_once(:student) { student_in_course(course:, active_all: true).user }

      it "excludes excused submissions from every count" do
        assignment.submit_homework(student, submission_type: "online_text_entry", body: "done")
        assignment.grade_student(student, excused: true, grader: teacher)

        expect(metrics).to eq(
          on_time_needs_grading_count: 0,
          late_needs_grading_count: 0,
          resubmitted_needs_grading_count: 0,
          submitted_submissions_count: 0,
          total_submissions_count: 0
        )
      end

      it "excludes graded submissions only from needs-grading buckets" do
        submit_on_time(student)
        assignment.grade_student(student, grade: 8, grader: teacher)

        expect(metrics).to include(
          on_time_needs_grading_count: 0,
          submitted_submissions_count: 1,
          total_submissions_count: 1
        )
      end

      it "excludes concluded enrollments" do
        submit_on_time(student)
        student.enrollments.first.conclude

        expect(metrics).to eq(
          on_time_needs_grading_count: 0,
          late_needs_grading_count: 0,
          resubmitted_needs_grading_count: 0,
          submitted_submissions_count: 0,
          total_submissions_count: 0
        )
      end

      it "excludes deleted submissions" do
        sub = submit_on_time(student)
        sub.update_columns(workflow_state: "deleted")

        expect(metrics).to include(
          on_time_needs_grading_count: 0,
          total_submissions_count: 0
        )
      end
    end

    context "for various lateness states" do
      let_once(:student) { student_in_course(course:, active_all: true).user }

      it "treats a submission before the due date as on_time" do
        submit_on_time(student)

        expect(metrics).to include(on_time_needs_grading_count: 1, late_needs_grading_count: 0)
      end

      it "treats late_policy_status='late' as late" do
        submit_late(student)

        expect(metrics).to include(late_needs_grading_count: 1, on_time_needs_grading_count: 0)
      end

      it "treats late_policy_status='extended' as on_time" do
        assignment.update!(due_at: 3.days.ago)
        sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "extended")
        sub.update_columns(late_policy_status: "extended")

        expect(metrics).to include(on_time_needs_grading_count: 1, late_needs_grading_count: 0)
      end

      it "treats a submission with no due date as on_time" do
        assignment.update!(due_at: nil)
        assignment.submit_homework(student, submission_type: "online_text_entry", body: "no due")

        expect(metrics).to include(on_time_needs_grading_count: 1, late_needs_grading_count: 0)
      end

      it "treats a submission with a custom grade status as on_time" do
        custom_status = course.root_account.custom_grade_statuses.create!(
          name: "Late allowed",
          color: "#ff0000",
          created_by: teacher
        )
        assignment.update!(due_at: 3.days.ago)
        sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "custom")
        sub.update_columns(custom_grade_status_id: custom_status.id)

        expect(metrics).to include(on_time_needs_grading_count: 1, late_needs_grading_count: 0)
      end

      it "treats a quiz submitted past due as late" do
        quiz = course.quizzes.create!(title: "Quiz", quiz_type: "assignment", due_at: 2.hours.ago)
        quiz.quiz_questions.create!(
          question_data: {
            "question_type" => "essay_question",
            "name" => "Essay",
            "question_text" => "Write something",
            "points_possible" => 1
          }
        )
        quiz.publish!
        quiz_assignment = quiz.assignment

        qs = quiz.generate_submission(student)
        qs.mark_completed
        sub = Submission.find_by!(assignment: quiz_assignment, user: student)
        sub.update_columns(
          submission_type: "online_quiz",
          workflow_state: "submitted",
          submitted_at: 1.minute.ago,
          score: nil,
          grade_matches_current_submission: true
        )

        expect(metrics_for(quiz_assignment, teacher)).to include(
          late_needs_grading_count: 1,
          on_time_needs_grading_count: 0
        )
      end
    end

    context "with a resubmitted submission" do
      let_once(:student) { student_in_course(course:, active_all: true).user }

      it "counts on-time resubmissions in both buckets" do
        submit_on_time(student, resubmit: true)

        expect(metrics).to include(
          on_time_needs_grading_count: 1,
          resubmitted_needs_grading_count: 1,
          late_needs_grading_count: 0
        )
      end

      it "counts late resubmissions in both buckets" do
        submit_late(student, resubmit: true)

        expect(metrics).to include(
          late_needs_grading_count: 1,
          resubmitted_needs_grading_count: 1,
          on_time_needs_grading_count: 0
        )
      end
    end

    context "for a submission awaiting manual review" do
      let_once(:student) { student_in_course(course:, active_all: true).user }

      # Reachable in real flows when a quiz with an essay question auto-grades —
      # the grader still owes a manual review on the essay portion.
      it "counts pending_review submissions in needs-grading buckets" do
        sub = assignment.submit_homework(student, submission_type: "online_text_entry", body: "essay")
        sub.update_columns(workflow_state: "pending_review")

        expect(metrics).to include(on_time_needs_grading_count: 1)
      end
    end
  end
end
