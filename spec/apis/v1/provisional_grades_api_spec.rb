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

require_relative "../api_spec_helper"

describe "Provisional Grades API", type: :request do
  it_behaves_like "a provisional grades status action", :provisional_grades

  describe "bulk_select" do
    let_once(:course) do
      course = course_factory
      course.account.enable_service(:avatars)
      course
    end

    let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
    let_once(:ta_1) { ta_in_course(active_all: true, course:).user }
    let_once(:ta_2) { ta_in_course(active_all: true, course:).user }
    let_once(:students) { Array.new(3) { |n| student_in_course(active_all: true, course:, name: "Student #{n}").user } }

    let_once(:assignment) do
      course.assignments.create!(
        final_grader_id: teacher.id,
        grader_count: 2,
        moderated_grading: true,
        points_possible: 10
      )
    end

    let_once(:submissions) { students.map { |student| student.submissions.first } }
    let_once(:grades) do
      [
        grade_student(assignment, students[0], ta_1, 5),
        grade_student(assignment, students[1], ta_1, 6),
        grade_student(assignment, students[1], ta_2, 7),
        grade_student(assignment, students[2], ta_2, 8)
      ]
    end

    def grade_student(assignment, student, grader, score)
      graded_submissions = assignment.grade_student(student, grader:, score:, provisional: true)
      graded_submissions.first.provisional_grade(grader)
    end

    def bulk_select(provisional_grades, user = teacher)
      path = "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/provisional_grades/bulk_select"
      params = {
        action: "bulk_select",
        assignment_id: assignment.to_param,
        controller: "provisional_grades",
        course_id: course.to_param,
        format: "json",
        provisional_grade_ids: provisional_grades.map(&:id)
      }
      api_call_as_user(user, :put, path, params)
    end

    def selected_grades
      assignment.moderated_grading_selections.filter_map(&:provisional_grade)
    end

    it "selects multiple provisional grades" do
      bulk_select(grades[0..1])
      expect(selected_grades).to match_array(grades[0..1])
    end

    it "selects provisional grades for different graders" do
      bulk_select([grades[0], grades[2]])
      expect(selected_grades).to match_array([grades[0], grades[2]])
    end

    it "creates a moderation event for each selection made" do
      expect { bulk_select([grades[0], grades[2]]) }.to change {
        AnonymousOrModerationEvent.where(user: teacher, event_type: :provisional_grade_selected).count
      }.from(0).to(2)
    end

    it "selects the later grade when given multiple provisional grade ids for the same student" do
      bulk_select(grades[0..2])
      expect(selected_grades).to match_array([grades[0], grades[2]])
    end

    it "returns json including the id of each selected provisional grade" do
      json = bulk_select(grades[0..1])
      ids = json.pluck("selected_provisional_grade_id")
      expect(ids).to match_array(grades[0..1].map(&:id))
    end

    it "touches submissions related to the selected provisional grades" do
      expect { bulk_select(grades[0..1]) }.to change { submissions[0].reload.updated_at }
    end

    it "does not touch submissions not related to the selected provisional grades" do
      expect { bulk_select(grades[0..1]) }.not_to change { submissions[2].reload.updated_at }
    end

    it "excludes the anonymous ids for submissions when the user can view student identities" do
      json = bulk_select(grades[0..1])
      expect(json).to all(not_have_key("anonymous_id"))
    end

    it "includes the anonymous ids for submissions when the user cannot view student identities" do
      assignment.update!(anonymous_grading: true)
      json = bulk_select(grades[0..1])
      ids = json.pluck("anonymous_id")
      expect(ids).to match_array(submissions[0..1].map(&:anonymous_id))
    end

    it "excludes the student ids for submissions when the user cannot view student identities" do
      assignment.update!(anonymous_grading: true)
      json = bulk_select(grades[0..1])
      expect(json).to all(not_have_key("student_id"))
    end

    context "when given a provisional grade id for an already-selected provisional grade" do
      before(:once) do
        selection = assignment.moderated_grading_selections.find_by!(student_id: students[0].id)
        selection.selected_provisional_grade_id = grades[0].id
        selection.save!
      end

      it "excludes the already-selected provisional grade from the returned json" do
        json = bulk_select(grades[0..1])
        ids = json.pluck("selected_provisional_grade_id")
        expect(ids).to match_array([grades[1].id])
      end

      it "does not touch the submission for the already-selected provisional grade" do
        expect { bulk_select(grades[0..1]) }.not_to change { submissions[0].reload.updated_at }
      end
    end

    context "when given a provisional grade id for a different assignment" do
      let_once(:other_assignment) do
        course.assignments.create!(
          final_grader_id: teacher.id,
          grader_count: 2,
          moderated_grading: true,
          points_possible: 10
        )
      end
      let_once(:other_grade) { grade_student(other_assignment, students[0], ta_1, 10) }

      it "does not select the unrelated provisional grade" do
        bulk_select(grades[0..1] + [other_grade])
        expect(other_grade.reload.selection).not_to be_present
      end

      it "excludes the unrelated provisional grade from the returned json" do
        json = bulk_select(grades[0..1] + [other_grade])
        ids = json.pluck("selected_provisional_grade_id")
        expect(ids).to match_array(grades[0..1].map(&:id))
      end
    end

    it "ignores ids not associated with a provisional grade" do
      invalid_id = ModeratedGrading::ProvisionalGrade.maximum(:id).next # ensure the id is not used
      invalid_grade = ModeratedGrading::ProvisionalGrade.new(id: invalid_id)
      json = bulk_select(grades[0..1] + [invalid_grade])
      ids = json.pluck("selected_provisional_grade_id")
      expect(ids).to match_array(grades[0..1].map(&:id))
    end

    it "is unauthorized when the user is not the assigned final grader" do
      assignment.update_attribute(:final_grader_id, nil)
      bulk_select(grades[0..1])
      assert_status(401)
    end

    it 'is unauthorized when the user is an account admin without "Select Final Grade for Moderation" permission' do
      course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
      bulk_select(grades[0..1], account_admin_user)
      assert_status(401)
    end

    it "is authorized when the user is the final grader" do
      bulk_select(grades[0..1])
      assert_status(200)
    end

    it 'is authorized when the user is an account admin with "Select Final Grade for Moderation" permission' do
      bulk_select(grades[0..1], account_admin_user)
      assert_status(200)
    end
  end

  describe "select" do
    before(:once) do
      course_with_student active_all: true
      @course.account.enable_service(:avatars)
      ta_in_course active_all: true
      @assignment = @course.assignments.build
      @assignment.grader_count = 1
      @assignment.moderated_grading = true
      @assignment.final_grader_id = @teacher.id
      @assignment.save!
      subs = @assignment.grade_student @student, grader: @ta, score: 0, provisional: true
      @pg = subs.first.provisional_grade(@ta)
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/provisional_grades/#{@pg.id}/select"
      @params = { controller: "provisional_grades",
                  action: "select",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_id: @assignment.to_param,
                  provisional_grade_id: @pg.to_param }
    end

    it "fails if the student isn't in the moderation set" do
      @assignment.moderated_grading_selections.destroy_all
      json = api_call_as_user(@teacher, :put, @path, @params, {}, {}, { expected_status: 400 })
      expect(json["message"]).to eq "student not in moderation set"
    end

    it "selects a provisional grade" do
      json = api_call_as_user(@teacher, :put, @path, @params)
      expect(json).to eq({
                           "assignment_id" => @assignment.id,
                           "student_id" => @student.id,
                           "selected_provisional_grade_id" => @pg.id
                         })
      expect(@assignment.moderated_grading_selections.where(student_id: @student.id).first.provisional_grade).to eq(@pg)
    end

    it "creates a moderation event for the selection" do
      expect { api_call_as_user(@teacher, :put, @path, @params) }.to change {
        AnonymousOrModerationEvent.where(user: @teacher, event_type: :provisional_grade_selected).count
      }.from(0).to(1)
    end

    it "uses anonymous_id instead of student_id if user cannot view student names" do
      allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
      json = api_call_as_user(@teacher, :put, @path, @params)
      expect(json).to eq({
                           "assignment_id" => @assignment.id,
                           "anonymous_id" => @pg.submission.anonymous_id,
                           "selected_provisional_grade_id" => @pg.id
                         })
      expect(@assignment.moderated_grading_selections.where(student_id: @student.id).first.provisional_grade).to eq(@pg)
    end

    it_behaves_like "authorization for provisional final grade selection", :put
  end

  describe "publish" do
    before :once do
      course_with_student active_all: true
      @course.account.enable_service(:avatars)
      course_with_ta course: @course, active_all: true
      @assignment = @course.assignments.create!
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/provisional_grades/publish"
      @params = { controller: "provisional_grades",
                  action: "publish",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_id: @assignment.to_param }
    end

    it "requires a moderated assignment" do
      @assignment.update_attribute :final_grader_id, @teacher.id
      json = api_call_as_user(@teacher, :post, @path, @params, {}, {}, { expected_status: 400 })
      expect(json["message"]).to eq "Assignment does not use moderated grading"
    end

    context "with moderated assignment" do
      before(:once) do
        @assignment.update_attribute :moderated_grading, true
        @assignment.update_attribute :grader_count, 2
        @assignment.update_attribute :final_grader_id, @teacher.id
      end

      it "responds with a 200 for a valid request" do
        api_call_as_user(@teacher, :post, @path, @params, {}, {}, expected_status: 200)
      end

      it "requires manage_grades permissions" do
        @course.root_account.role_overrides.create!(
          permission: :manage_grades,
          role: Role.find_by(name: "TeacherEnrollment"),
          enabled: false
        )
        api_call_as_user(@teacher, :post, @path, @params, {}, {}, expected_status: 401)
      end

      it "fails if grades were already published" do
        @assignment.update_attribute :grades_published_at, Time.now.utc
        json = api_call_as_user(@teacher, :post, @path, @params, {}, {}, { expected_status: 400 })
        expect(json["message"]).to eq "Assignment grades have already been published"
      end

      context "with empty provisional grades (comments only)" do
        before(:once) do
          @submission = @assignment.submit_homework(@student, body: "hello")
          @submission.add_comment(author: @ta, provisional: true, comment: "A provisional comment")
          @provisional_grade = @submission.provisional_grades.first
        end

        it "publishes an empty provisional grade for an active student" do
          api_call_as_user(@teacher, :post, @path, @params)

          expect(@assignment.reload.grades_published?).to be_truthy
          expect(@submission.reload.grade).to be_nil
        end

        it "publishes an empty provisional grade for a student with concluded enrollment" do
          student_enrollment = @course.enrollments.find_by(user: @student)
          student_enrollment.conclude

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@assignment.reload.grades_published?).to be_truthy
          expect(@submission.reload.grade).to be_nil
        end

        it "publishes an empty provisional grade for a student with an inactive enrollment" do
          student_enrollment = @course.enrollments.find_by(user: @student)
          student_enrollment.deactivate

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@assignment.reload.grades_published?).to be_truthy
          expect(@submission.reload.grade).to be_nil
        end

        it "returns unprocessable_entity when non-empty provisional grades exist and no grade is selected" do
          second_ta = course_with_user("TaEnrollment", course: @course, active_all: true).user
          third_ta = course_with_user("TaEnrollment", course: @course, active_all: true).user
          @assignment.grade_student(@student, grader: second_ta, score: 72, provisional: true)
          @assignment.grade_student(@student, grader: third_ta, score: 88, provisional: true)

          api_call_as_user(@teacher, :post, @path, @params)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(@assignment.reload.grades_published?).to be false
        end
      end

      context "with provisional grades" do
        before(:once) do
          @submission = @assignment.submit_homework(@student, body: "hello")
          @assignment.grade_student(@student, { grader: @ta, score: 100, provisional: true })
        end

        it "publishes provisional grades" do
          expect(@submission.workflow_state).to eq "submitted"
          expect(@submission.score).to be_nil
          expect(@student.messages).to be_empty

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@submission.reload.workflow_state).to eq "graded"
          expect(@submission.grader).to eq @ta
          expect(@submission.score).to eq 100

          @assignment.reload
          expect(@assignment.grades_published_at).to be_within(1.minute.to_i).of(Time.now.utc)
        end

        it "does not publish provisional grades for concluded students" do
          @course.enrollments.find_by(user: @student).conclude
          api_call_as_user(@teacher, :post, @path, @params)
          aggregate_failures do
            expect(@submission.reload.workflow_state).to eq "submitted"
            expect(@submission.grader).to be_nil
            expect(@submission.score).to be_nil
          end
        end

        it "publishes the selected provisional grade when the student is in the moderation set" do
          @submission.provisional_grade(@ta).update_attribute(:graded_at, 1.minute.ago)

          sel = @assignment.moderated_grading_selections.find_by(student: @student)

          @other_ta = user_factory active_user: true
          @course.enroll_ta @other_ta, enrollment_state: "active"
          @assignment.grade_student(@student, { grader: @other_ta, score: 90, provisional: true })

          sel.selected_provisional_grade_id = @submission.provisional_grade(@other_ta).id
          sel.save!

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@submission.reload.workflow_state).to eq "graded"
          expect(@submission.grader).to eq @other_ta
          expect(@submission.score).to eq 90
        end
      end

      context "with one provisional grade" do
        it "publishes the only provisional grade if none have been explicitly selected" do
          course_with_user("TaEnrollment", course: @course, active_all: true)
          @course.account.enable_service(:avatars)
          @submission = @assignment.submit_homework(@student, body: "hello")
          @assignment.grade_student(@student, grader: @ta, score: 72, provisional: true)

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@submission.reload.score).to eq 72
        end
      end

      context "with multiple provisional grades" do
        before(:once) do
          @first_ta = @ta
          @first_student = @student
          @second_ta = course_with_user("TaEnrollment", course: @course, active_all: true).user
          @second_student = course_with_user("StudentEnrollment", course: @course, active_all: true).user
          @first_student_submission = @assignment.submit_homework(@first_student, body: "hello")
          @second_student_submission = @assignment.submit_homework(@second_student, body: "hello")
        end

        context "when some submissions have no grades" do
          it "returns status ok" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(response).to have_http_status(:ok)
          end

          it "publishes assignment" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(@assignment.reload.grades_published_at).not_to be_nil
          end

          it "does not publish a score for those that were ungraded" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(@first_student_submission.reload.score).to be_nil
          end
        end

        context "when no grades have been explicitly selected" do
          before(:once) do
            @assignment.grade_student(@first_student, grader: @first_ta, score: 72, provisional: true)
            @assignment.grade_student(@first_student, grader: @second_ta, score: 88, provisional: true)
          end

          it "returns status unprocessable entity" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "does not publish the assignment" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(@assignment.reload.grades_published_at).to be_nil
          end

          it "does not grade the submission" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(@first_student_submission.reload).not_to be_graded
          end
        end

        context "when not all grades have been explicitly selected" do
          before do
            @assignment.grade_student(@student, grader: @ta, score: 12, provisional: true)
            @assignment.grade_student(@student, grader: @second_ta, score: 34, provisional: true)
            @assignment.grade_student(@second_student, grader: @ta, score: 56, provisional: true)
            @assignment.grade_student(@second_student, grader: @second_ta, score: 78, provisional: true)
            first_student_selection = @assignment.moderated_grading_selections.find_by(student: @student)
            first_student_selection.update!(selected_provisional_grade_id: @first_student_submission.provisional_grade(@ta))
          end

          it "returns status unprocessable entity" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "does not grade the submission" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(@first_student_submission.reload).not_to be_graded
          end

          it "does not publish the assignment" do
            api_call_as_user(@teacher, :post, @path, @params)
            expect(@assignment.reload.grades_published_at).to be_nil
          end
        end

        it "only calls GradeCalculator once even if there are multiple selections" do
          @assignment.grade_student(@first_student, grader: @first_ta, score: 12, provisional: true)
          @assignment.grade_student(@first_student, grader: @second_ta, score: 34, provisional: true)
          @assignment.grade_student(@second_student, grader: @first_ta, score: 56, provisional: true)
          @assignment.grade_student(@second_student, grader: @second_ta, score: 78, provisional: true)
          first_student_selection = @assignment.moderated_grading_selections.find_by(student: @first_student)
          second_student_selection = @assignment.moderated_grading_selections.find_by(student: @second_student)
          first_student_selection.update!(selected_provisional_grade_id: @first_student_submission.provisional_grade(@ta))
          second_student_selection.update!(selected_provisional_grade_id: @second_student_submission.provisional_grade(@second_ta))

          expect(GradeCalculator).to receive(:recompute_final_score).once

          api_call_as_user(@teacher, :post, @path, @params)
        end
      end

      it_behaves_like "authorization for provisional final grade selection", :post
    end
  end
end
