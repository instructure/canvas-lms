# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "spec_helper"

describe Gradebook::FinalGradeOverrides do
  let(:final_grade_overrides) { Gradebook::FinalGradeOverrides.new(@course, @teacher).to_h }

  before(:once) do
    @course = Course.create!
    @course.enable_feature!(:final_grades_override)
    @course.update!(allow_final_grade_override: true)

    grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
    @course.enrollment_term.grading_period_group = grading_period_group
    @course.enrollment_term.save!

    @grading_period_1 = grading_period_group.grading_periods.create!(
      end_date: 1.month.from_now,
      start_date: 1.month.ago,
      title: "Q1"
    )
    @grading_period_2 = grading_period_group.grading_periods.create!(
      end_date: 2.months.from_now,
      start_date: 1.month.from_now,
      title: "Q2"
    )

    @teacher = teacher_in_course(course: @course, active_all: true).user

    @student_enrollment_1 = student_in_course(active_all: true, course: @course)
    @student_enrollment_2 = student_in_course(active_all: true, course: @course)
    @test_student_enrollment = course_with_user("StudentViewEnrollment", course: @course, active_all: true)

    @student_1 = @student_enrollment_1.user
    @student_2 = @student_enrollment_2.user
    @test_student = @test_student_enrollment.user

    @assignment = assignment_model(course: @course, points_possible: 10)
    @assignment.grade_student(@student_1, grade: "85%", grader: @teacher)
    @assignment.grade_student(@student_2, grade: "85%", grader: @teacher)
    @assignment.grade_student(@test_student, grade: "85%", grader: @teacher)

    @custom_status = CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @teacher)
  end

  it "includes user ids for each user with an overridden course grade" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_2.scores.find_by!(course_score: true).update!(override_score: 9.1)
    expect(final_grade_overrides.keys).to match_array([@student_1.id, @student_2.id])
  end

  it "includes the overridden course grade for the user" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    expect(final_grade_overrides[@student_1.id]).to have_key(:course_grade)
  end

  it "includes the percentage on the overridden course grade" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes the overridden grading period grades for the user" do
    @student_enrollment_1.scores.find_by!(grading_period: @grading_period_1).update!(override_score: 89.1)
    expect(final_grade_overrides[@student_1.id][:grading_period_grades]).to have_key(@grading_period_1.id)
  end

  it "includes the percentage on overridden grading period grades" do
    @student_enrollment_1.scores.find_by!(grading_period: @grading_period_1).update!(override_score: 89.1)
    grading_period_overrides = final_grade_overrides[@student_1.id][:grading_period_grades]
    expect(grading_period_overrides[@grading_period_1.id][:percentage]).to equal(89.1)
  end

  it "includes scores for inactive students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.deactivate
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes scores for concluded students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.conclude
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes scores for invited students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.update(workflow_state: "invited", last_activity_at: nil)
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes scores for test students" do
    @test_student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @test_student_enrollment.update(workflow_state: "invited", last_activity_at: nil)
    expect(final_grade_overrides[@test_student.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "excludes scores for deleted students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.update(workflow_state: "deleted")
    expect(final_grade_overrides).not_to have_key(@student_1.id)
  end

  it "returns an empty map when no students were given final grade overrides" do
    expect(final_grade_overrides).to be_empty
  end

  it "includes custom grade status id on the course grade & grading period grade" do
    @student_enrollment_1.scores.find_by!(grading_period: @grading_period_1).update!(override_score: 90, custom_grade_status: @custom_status)
    @student_enrollment_2.scores.find_by!(course_score: true).update!(override_score: 88, custom_grade_status: @custom_status)

    grading_period_overrides = final_grade_overrides[@student_1.id][:grading_period_grades]
    expect(grading_period_overrides[@grading_period_1.id][:custom_grade_status_id]).to equal(@custom_status.id)

    expect(final_grade_overrides[@student_2.id][:course_grade][:custom_grade_status_id]).to equal(@custom_status.id)
  end

  it "includes custom grade status id on the course grade & grading period grade where override_score is nil" do
    @student_enrollment_1.scores.find_by!(grading_period: @grading_period_1).update!(override_score: nil, custom_grade_status: @custom_status)
    @student_enrollment_2.scores.find_by!(course_score: true).update!(override_score: nil, custom_grade_status: @custom_status)

    grading_period_overrides = final_grade_overrides[@student_1.id][:grading_period_grades]
    expect(grading_period_overrides[@grading_period_1.id][:custom_grade_status_id]).to equal(@custom_status.id)

    expect(final_grade_overrides[@student_2.id][:course_grade][:custom_grade_status_id]).to equal(@custom_status.id)
  end

  describe "bulk updates" do
    let(:grading_period) { @grading_period_1 }
    let(:other_grading_period) { @grading_period_2 }
    let(:course) { Course.create! }
    let(:teacher) { User.create! }

    let(:student) { User.create! }
    let(:multiple_enrollment_student) { User.create! }
    let(:unaffected_student) { User.create! }

    let(:override_updates) do
      [
        { student_id: student.id, override_score: 70.0 },
        { student_id: multiple_enrollment_student.id, override_score: 75.0 }
      ]
    end

    before do
      course.enrollment_term.grading_period_group = grading_period.grading_period_group
      course.enable_feature!(:final_grades_override)
      course.allow_final_grade_override = true
      course.save!

      course.enroll_teacher(teacher, enrollment_state: "active")
      course.enroll_student(student, enrollment_state: "active")
      course.enroll_student(unaffected_student, enrollment_state: "active")
      course.enroll_student(multiple_enrollment_student, enrollment_state: "active")
      course.enroll_student(multiple_enrollment_student, enrollment_state: "active")
    end

    describe ".queue_bulk_update" do
      it "returns a progress object" do
        progress = Gradebook::FinalGradeOverrides.queue_bulk_update(course, teacher, override_updates, nil)

        expect(progress).to be_a(Progress)
      end
    end

    describe ".process_bulk_update" do
      let(:grade_change_records) { Auditors::ActiveRecord::GradeChangeRecord.where(course:) }

      def run(updates: override_updates, grading_period: nil, updating_user: teacher, progress: nil)
        course.recompute_student_scores(run_immediately: true)
        Gradebook::FinalGradeOverrides.process_bulk_update(progress, course, updating_user, updates, grading_period)
      end

      it "updates the override score for each included record" do
        run

        student1_enrollment = student.enrollments.first
        student2_enrollment = multiple_enrollment_student.enrollments.first

        aggregate_failures do
          expect(student1_enrollment.override_score).to eq 70.0
          expect(student2_enrollment.override_score).to eq 75.0

          expect(unaffected_student.enrollments.first.override_score).to be_nil
        end
      end

      it "updates scores for the specific grading period if one is given" do
        run(grading_period:)

        student1_enrollment = student.enrollments.first
        student2_enrollment = multiple_enrollment_student.enrollments.first
        unaffected_enrollment = unaffected_student.enrollments.first

        aggregate_failures do
          expect(student1_enrollment.override_score({ grading_period_id: grading_period.id })).to eq 70.0
          expect(student1_enrollment.override_score).to be_nil
          expect(student2_enrollment.override_score({ grading_period_id: grading_period.id })).to eq 75.0
          expect(student2_enrollment.override_score).to be_nil

          expect(unaffected_enrollment.override_score({ grading_period_id: grading_period.id })).to be_nil
        end
      end

      it "does not update grading periods other than the one requested" do
        student1_enrollment = student.enrollments.first

        run(grading_period:)
        expect(student1_enrollment.override_score({ grading_period_id: other_grading_period.id })).to be_nil
      end

      it "updates all enrollments for students with multiple enrollments" do
        run

        student2_course_override_scores = multiple_enrollment_student.enrollments.map(&:override_score)
        expect(student2_course_override_scores).to all eq 75.0
      end

      it "records exactly one grade change event for each student" do
        run

        aggregate_failures do
          expect(grade_change_records.count).to eq 2
          expect(grade_change_records.where(grader: teacher).count).to eq 2

          student1_records = grade_change_records.where(student:)
          expect(student1_records.count).to eq 1
          student1_course_record = student1_records.find_by(grading_period_id: nil)
          expect(student1_course_record.score_after).to eq 70.0

          student2_records = grade_change_records.where(student: multiple_enrollment_student)
          expect(student2_records.count).to eq 1
          student2_course_record = student2_records.find_by(grading_period_id: nil)
          expect(student2_course_record.score_after).to eq 75.0
        end
      end

      it "records the passed-in user as the grader for the update events" do
        run

        expect(grade_change_records.map(&:grader)).to all eq teacher
      end

      it "ignores updates referencing students not in the course" do
        some_other_student = User.create!
        updates = [{ student_id: some_other_student.id, override_score: 100.0 }]

        run(updates:)
        expect(grade_change_records).to be_empty
      end

      context "with visibility restricted by section" do
        let(:section1) { course.course_sections.create! }
        let(:section1_student) { course.enroll_student(User.create!, section: section1, enrollment_state: "active").user }

        let(:section2) { course.course_sections.create! }
        let(:section2_student) { course.enroll_student(User.create!, section: section2, enrollment_state: "active").user }

        let(:section1_ta) do
          enrollment = course.enroll_ta(
            User.create!,
            enrollment_state: "active",
            section: section1,
            limit_privileges_to_course_section: true
          )
          enrollment.user
        end

        it "does not update students that the teacher cannot see" do
          updates = [
            { student_id: section1_student.id, override_score: 50.0 },
            { student_id: section2_student.id, override_score: 70.0 }
          ]

          run(updates:, updating_user: section1_ta)

          section1_student_enrollment = section1_student.enrollments.first
          section2_student_enrollment = section2_student.enrollments.first

          aggregate_failures do
            expect(section1_student_enrollment.override_score).to eq 50.0
            expect(section2_student_enrollment.override_score).to be_nil
          end
        end

        it "updates scores for all enrollments, even if not all visible, for a student that the teacher can see" do
          course.enroll_student(
            section2_student,
            allow_multiple_enrollments: true,
            enrollment_state: "active",
            section: section1
          )

          updates = [{ student_id: section2_student.id, override_score: 70.0 }]

          run(updates:, updating_user: section1_ta)

          student2_enrollments = section2_student.enrollments
          aggregate_failures do
            expect(student2_enrollments.find_by(course_section: section1).override_score).to eq 70.0
            expect(student2_enrollments.find_by(course_section: section2).override_score).to eq 70.0
          end
        end
      end

      context "handles grade override statuses" do
        before do
          Account.site_admin.enable_feature!(:custom_gradebook_statuses)
          @student1_enrollment = student.enrollments.first
          @student2_enrollment = multiple_enrollment_student.enrollments.first

          @student1_score = @student1_enrollment.scores.create!(course_score: true, override_score: 100)
          @student2_score = @student2_enrollment.scores.create!(course_score: true, override_score: 100)
          @custom_status_2 = CustomGradeStatus.create(
            name: "NEW Status",
            color: "#000000",
            root_account: @course.root_account,
            created_by: @teacher
          )
        end

        let(:override_status_updates) do
          [
            { student_id: student.id, override_status_id: @custom_status.id },
            { student_id: multiple_enrollment_student.id, override_status_id: @custom_status.id }
          ]
        end

        it "sucessfully sets the override statuses" do
          run(updates: override_status_updates)

          aggregate_failures do
            expect(@student1_score.reload.custom_grade_status_id).to eq @custom_status.id
            expect(@student2_score.reload.custom_grade_status_id).to eq @custom_status.id

            expect(unaffected_student.enrollments.first.override_score).to be_nil
          end
        end

        it "sucessfully changes an override status" do
          @student1_score.update(custom_grade_status_id: @custom_status.id)
          override_status_updates_test = [
            { student_id: student.id, override_status_id: @custom_status_2.id },
            { student_id: multiple_enrollment_student.id, override_status_id: @custom_status.id }
          ]
          run(updates: override_status_updates_test)

          aggregate_failures do
            expect(@student1_score.reload.custom_grade_status_id).to eq @custom_status_2.id
            expect(@student2_score.reload.custom_grade_status_id).to eq @custom_status.id
          end
        end

        it "sucessfully clears out a custom status" do
          @student2_score.update(custom_grade_status_id: @custom_status.id)
          override_status_updates_test = [
            { student_id: student.id, override_status_id: @custom_status.id },
            { student_id: multiple_enrollment_student.id, override_status_id: nil }
          ]
          run(updates: override_status_updates_test)

          aggregate_failures do
            expect(@student1_score.reload.custom_grade_status_id).to eq @custom_status.id
            expect(@student2_score.reload.custom_grade_status_id).to be_nil
          end
        end

        it "sucessfully modifies both override_status and override_score" do
          @student2_score.update(override_score: nil)
          override_status_updates_test = [
            { student_id: student.id, override_status_id: @custom_status.id },
            { student_id: multiple_enrollment_student.id, override_score: 90.0, override_status_id: @custom_status.id }
          ]
          run(updates: override_status_updates_test)

          @student1_score.reload
          @student2_score.reload

          aggregate_failures do
            expect(@student1_score.reload.custom_grade_status_id).to eq @custom_status.id
            expect(@student2_score.custom_grade_status_id).to eq @custom_status.id
            expect(@student1_score.override_score).to eq 100.0
            expect(@student2_score.override_score).to eq 90.0
          end
        end

        it "sucessfully modifies override status with a grading period" do
          grading_period_score_1 = @student1_enrollment.scores.create!(course_score: false, override_score: 100, grading_period:)
          grading_period_score_2 = @student2_enrollment.scores.create!(course_score: false, override_score: 100, grading_period:)
          override_status_updates_test = [
            { student_id: student.id, override_status_id: @custom_status.id },
            { student_id: multiple_enrollment_student.id, override_status_id: @custom_status.id }
          ]
          run(updates: override_status_updates_test, grading_period:)

          aggregate_failures do
            expect(grading_period_score_1.reload.custom_grade_status_id).to eq @custom_status.id
            expect(grading_period_score_2.reload.custom_grade_status_id).to eq @custom_status.id
          end
        end

        it "does not modify override status if the feature flag is OFF" do
          Account.site_admin.disable_feature!(:custom_gradebook_statuses)
          run(updates: override_status_updates)

          aggregate_failures do
            expect(@student1_score.reload.custom_grade_status_id).to be_nil
            expect(@student2_score.reload.custom_grade_status_id).to be_nil
          end
        end
      end

      describe "error handling" do
        let(:progress) { Progress.create!(course:, tag: "override_grade_update") }

        it "notes an error of type invalid_student_id for invalid student IDs" do
          updates = [{ student_id: "fred", override_score: 100.0 }]
          run(updates:, progress:)

          expect(progress.results[:errors]).to contain_exactly({ student_id: "fred", error: :invalid_student_id })
        end

        it "notes an error of type failed_to_update when a score value cannot be saved" do
          updates = [{ student_id: student.id, override_score: "asdfasdfasdf" }]
          run(updates:, progress:)

          expect(progress.results[:errors]).to contain_exactly({ student_id: student.id, error: :failed_to_update })
        end

        it "notes an error of type failed_to_update when a score object cannot be found" do
          other_grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(course.root_account)
          other_grading_period = other_grading_period_group.grading_periods.create!(
            start_date: 1.month.ago,
            end_date: 1.month.from_now,
            title: "other grading period"
          )

          updates = [{ student_id: student.id, override_score: 80.0 }]
          run(grading_period: other_grading_period, updates:, progress:)

          expect(progress.results[:errors]).to contain_exactly({ student_id: student.id, error: :failed_to_update })
        end
      end
    end
  end
end
