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

require_relative "../../common"
require_relative "../pages/global_grades_page"
require_relative "../pages/student_grades_page"

describe "grades" do
  include_context "in-process server selenium tests"

  before(:once) do
    @teacher1 = course_with_teacher(name: "Dedicated Teacher1", active_user: true, active_enrollment: true, active_course: true).user
    @student_1 = course_with_student(course: @course, name: "Student 1", active_all: true).user
    @student_2 = course_with_student(course: @course, name: "Student 2", active_all: true).user

    # first assignment data
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(name: "first assignment group", group_weight: 33.3)
    @group2 = @course.assignment_groups.create!(name: "second assignment group", group_weight: 33.3)
    @group3 = @course.assignment_groups.create!(name: "third assignment group", group_weight: 33.3)
    @first_assignment = assignment_model({
                                           course: @course,
                                           title: "first assignment",
                                           due_at: due_date,
                                           points_possible: 10,
                                           submission_types: "online_text_entry",
                                           assignment_group: @group,
                                           peer_reviews: true,
                                           anonymous_peer_reviews: true
                                         })
    rubric_model
    @rubric.criteria[0][:criterion_use_range] = true
    @rubric.save!
    @association = @rubric.associate_with(@first_assignment, @course, purpose: "grading")
    @assignment.assign_peer_review(@student_2, @student_1)
    @assignment.reload

    @submission = @first_assignment.submit_homework(@student_1, body: "student first submission")
    @first_assignment.grade_student(@student_1, grade: 10, grader: @teacher)
    @assessment = @association.assess({
                                        user: @student_1,
                                        assessor: @teacher,
                                        artifact: @submission,
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: 10,
                                            comments: "cool, yo"
                                          }
                                        }
                                      })
    @submission.reload
    @submission.score = 3
    @submission.add_comment(author: @teacher, comment: "submission comment")
    @submission.add_comment({
                              author: @student_2,
                              comment: "Anonymous Peer Review"
                            })
    @submission.save!

    # second student submission
    @student_2_submission = @first_assignment.submit_homework(@student_2, body: "second student second submission")
    @first_assignment.grade_student(@student_2, grade: 4, grader: @teacher)
    @student_2_submission.score = 3
    @submission.save!

    # second assigmnent data
    due_date += 1.day
    @second_assignment = assignment_model({
                                            course: @course,
                                            title: "second assignment",
                                            due_at: due_date,
                                            points_possible: 5,
                                            submission_types: "online_text_entry",
                                            assignment_group: @group
                                          })

    @second_association = @rubric.associate_with(@second_assignment, @course, purpose: "grading")
    @second_submission = @second_assignment.submit_homework(@student_1, body: "student second submission")
    @second_assignment.grade_student(@student_1, grade: 2, grader: @teacher)
    @second_submission.save!
    @second_assessment = @second_association.assess({
                                                      user: @student_1,
                                                      assessor: @teacher,
                                                      artifact: @second_submission,
                                                      assessment: {
                                                        assessment_type: "grading",
                                                        criterion_crit1: {
                                                          points: 2
                                                        }
                                                      }
                                                    })

    # third assignment data
    due_date += 1.day
    @third_assignment = assignment_model({ title: "third assignment", due_at: due_date, course: @course })
  end

  context "as a teacher" do
    before do
      user_session(@teacher)
    end

    it "shows the student outcomes report if enabled", priority: "1" do
      @outcome_group ||= @course.root_outcome_group
      @outcome = @course.created_learning_outcomes.create!(title: "outcome")
      @outcome_group.add_outcome(@outcome)
      Account.default.set_feature_flag!("student_outcome_gradebook", "on")
      StudentGradesPage.visit_as_teacher(@course, @student_1)
      expect(f("#navpills")).not_to be_nil
      f('a[href="#outcomes"]').click
      wait_for_ajaximations
      expect(fj("span:contains('Toggle outcomes for Unnamed Course')")).to be_present
      f(".icon-expand").click
      wait_for_ajaximations
      expect(ff("span[data-selenium='outcome']").count).to eq @course.learning_outcome_links.count
    end
  end

  context "as a student" do
    before do
      user_session(@student_1)
    end

    it "allows student to test modifying grades", priority: "1" do
      skip_if_chrome("issue with blur")
      StudentGradesPage.visit_as_student(@course)

      expect_any_instantiation_of(@first_assignment).to receive(:find_or_create_submission).and_return(@submission)

      # check initial total
      expect(f("#submission_final-grade .assignment_score .grade").text).to eq "33.33%"

      edit_grade = lambda do |field, score|
        field.click
        set_value field.find_element(:css, "input"), score.to_s
        driver.execute_script '$("#grade_entry").blur()'
      end

      assert_grade = lambda do |grade|
        wait_for_ajaximations
        expect(f("#submission_final-grade .grade")).to include_text grade.to_s
      end

      # test changing existing scores
      first_row_grade = f("#submission_#{@submission.assignment_id} .assignment_score .grade")
      edit_grade.call(first_row_grade, 4)
      assert_grade.call("40%")

      # using find with jquery to avoid caching issues

      # test changing unsubmitted scores
      third_grade = f("#submission_#{@third_assignment.id} .assignment_score .grade")
      edit_grade.call(third_grade, 10)
      assert_grade.call("96.97%")

      driver.execute_script '$("#grade_entry").focus()'
    end

    it "displays rubric on assignment and properly highlight levels", priority: "1" do
      zero_assignment = assignment_model({ title: "zero assignment", course: @course })
      zero_association = @rubric.associate_with(zero_assignment, @course, purpose: "grading")
      zero_submission = zero_assignment.submissions.find_by!(user: @student_1) # unsubmitted submission :/

      zero_association.assess({
                                user: @student_1,
                                assessor: @teacher,
                                artifact: zero_submission,
                                assessment: {
                                  assessment_type: "grading",
                                  criterion_crit1: {
                                    points: 0
                                  }
                                }
                              })
      StudentGradesPage.visit_as_student(@course)

      # click first rubric
      f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link").click
      wait_for_ajaximations
      expect(fj(".react-rubric caption:visible")).to include_text(@rubric.title)
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("10")

      # check if only proper rating is highlighted for a score of 10 on scale of 10|5|0
      expect(ffj(".rubric_assessments:visible .selected").length).to eq 1
      expect(fj(".rubric_assessments:visible .selected")).to include_text("10")

      # check rubric comment
      expect(fj(".rubric-freeform:visible div")).to include_text "cool, yo"

      # close first rubric
      scroll_into_view("a:contains('Close Rubric'):visible")
      fj("a:contains('Close Rubric'):visible").click

      # click second rubric
      scroll_into_view("#submission_#{zero_assignment.id} .toggle_rubric_assessments_link")
      f("#submission_#{zero_assignment.id} .toggle_rubric_assessments_link").click
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("0")

      # check if only proper rating is highlighted for a score of 0 on scale of 10|5|0
      expect(ffj(".rubric_assessments:visible .selected").length).to eq 1
      expect(fj(".rubric_assessments:visible .selected")).to include_text("0")
    end

    context "rubric criterion ranges disabled" do
      before do
        @rubric.criteria[0][:criterion_use_range] = false
        @rubric.save!
      end

      after do
        @rubric.criteria[0][:criterion_use_range] = true
        @rubric.save!
      end

      it "does not highlight scores between ranges when range rating is disabled" do
        StudentGradesPage.visit_as_student(@course)

        # open rubric
        f("#submission_#{@second_assignment.id} .toggle_rubric_assessments_link").click

        # check if no highlights exist on a non-range criterion for a score of 2 on scale of 10|5|0
        expect(find_with_jquery(".rubric_assessments:visible .selected")).to be_nil
      end
    end

    context "rubric criterion ranges enabled" do
      it "highlights scores between ranges when range rating is enabled" do
        @course.account.root_account.enable_feature!(:rubric_criterion_range)
        StudentGradesPage.visit_as_student(@course)

        # open rubric
        f("#submission_#{@second_assignment.id} .toggle_rubric_assessments_link").click

        # check if proper highlights exist on a range criterion for a score of 2 on scale of 10|5|0
        expect(ffj(".rubric_assessments:visible .selected").length).to eq 1
        expect(fj(".rubric_assessments:visible .selected")).to include_text("5")
      end
    end

    it "shows the assessment link when there are assessment ratings with nil points" do
      assessment = @rubric.rubric_assessments.first
      assessment.ratings.first[:points] = nil
      assessment.save!
      StudentGradesPage.visit_as_student(@course)
      assessments_link = f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link")
      expect(assessments_link).to be_present
    end

    it "does not display rubric on muted assignment", priority: "1" do
      StudentGradesPage.visit_as_student(@course)

      @first_assignment.mute!
      StudentGradesPage.visit_as_student(@course)

      expect(f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link")).not_to be_displayed
    end

    it "does not display letter grade score on muted assignment", priority: "1" do
      StudentGradesPage.visit_as_student(@course)

      @another_assignment = assignment_model({
                                               course: @course,
                                               title: "another assignment",
                                               points_possible: 100,
                                               submission_types: "online_text_entry",
                                               assignment_group: @group,
                                               grading_type: "letter_grade",
                                               muted: true
                                             })
      @another_assignment.ensure_post_policy(post_manually: true)
      @another_submission = @another_assignment.submit_homework(@student_1, body: "student second submission")
      @another_assignment.grade_student(@student_1, grade: 81, grader: @teacher)
      @another_submission.save!
      StudentGradesPage.visit_as_student(@course)
      expect(f(".score_value").text).to eq ""
    end

    it "does not show assignment statistics on assignments when it is disabled on the course",
       priority: "1" do
      # get up to a point where statistics can be shown
      5.times do |count|
        s = course_with_student(course: @course, name: "Student_#{count}", active_all: true).user
        @first_assignment.grade_student(s, grade: 4, grader: @teacher)
      end
      # but then prevent them at the course levels
      @course.update(hide_distribution_graphs: true)

      StudentGradesPage.visit_as_student(@course)
      expect(f("#content")).not_to contain_css("#grade_info_#{@first_assignment.id} .tooltip")
    end

    it "does not display name of anonymous reviewer", priority: "1" do
      StudentGradesPage.visit_as_student(@course)

      f(".toggle_comments_link").click
      expect(StudentGradesPage.submission_comments.second).to include_text("Anonymous User")
    end

    it "shows rubric even if there are no comments", priority: "1" do
      @third_association = @rubric.associate_with(@third_assignment, @course, purpose: "grading")
      @third_submission = @third_assignment.submissions.find_by!(user: @student_1) # unsubmitted submission :/

      @third_association.assess({
                                  user: @student_1,
                                  assessor: @teacher,
                                  artifact: @third_submission,
                                  assessment: {
                                    assessment_type: "grading",
                                    criterion_crit1: {
                                      points: 2,
                                      comments: "not bad, not bad"
                                    }
                                  }
                                })

      StudentGradesPage.visit_as_student(@course)

      # click rubric
      f("#submission_#{@third_assignment.id} .toggle_rubric_assessments_link").click
      expect(fj(".react-rubric caption:visible")).to include_text(@rubric.title)
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("2")

      # check rubric comment
      expect(fj(".rubric-freeform:visible div")).to include_text "not bad, not bad"
    end

    context "with outcome gradebook enabled" do
      before :once do
        Account.default.set_feature_flag!("student_outcome_gradebook", "on")

        @outcome_group ||= @course.root_outcome_group
        @outcome = @course.created_learning_outcomes.create!(title: "outcome")
        @outcome_group.add_outcome(@outcome)
      end

      it "shows the outcome gradebook", priority: "1" do
        StudentGradesPage.visit_as_student(@course)
        expect(f("#navpills")).not_to be_nil
        f('a[href="#outcomes"]').click
        wait_for_ajaximations
        expect(fj("span:contains('Toggle outcomes for Unnamed Course')")).to be_present
        f(".icon-expand").click
        wait_for_ajaximations
        expect(ff("span[data-selenium='outcome']").count).to eq @course.learning_outcome_links.count
      end

      it "shows the outcome gradebook if the student is in multiple sections", priority: "1" do
        @other_section = @course.course_sections.create(name: "the other section")
        @course.enroll_student(@student_1, section: @other_section, allow_multiple_enrollments: true)

        StudentGradesPage.visit_as_student(@course)
        expect(f("#navpills")).not_to be_nil
        f('a[href="#outcomes"]').click
        wait_for_ajaximations
        expect(fj("span:contains('Toggle outcomes for Unnamed Course')")).to be_present
        f(".icon-expand").click
        wait_for_ajaximations
        expect(ff("span[data-selenium='outcome']").count).to eq @course.learning_outcome_links.count
      end
    end
  end
end
