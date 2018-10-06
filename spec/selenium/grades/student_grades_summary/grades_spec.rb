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
    @teacher1 = course_with_teacher(name: 'Teacher Boss1', active_user: true, active_enrollment: true, active_course: true).user
    @student_1 = course_with_student(course: @course, name: "Student 1", active_all:true).user
    @student_2 = course_with_student(course: @course, name: "Student 2", active_all:true).user

    # first assignment data
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(name: 'first assignment group', group_weight: 33.3)
    @group2 = @course.assignment_groups.create!(name: 'second assignment group', group_weight: 33.3)
    @group3 = @course.assignment_groups.create!(name: 'third assignment group', group_weight: 33.3)
    @first_assignment = assignment_model({
      course: @course,
      title: 'first assignment',
      due_at: due_date,
      points_possible: 10,
      submission_types: 'online_text_entry',
      assignment_group: @group,
      peer_reviews: true,
      anonymous_peer_reviews: true
    })
    rubric_model
    @rubric.criteria[0][:criterion_use_range] = true
    @rubric.save!
    @association = @rubric.associate_with(@first_assignment, @course, purpose: 'grading')
    @assignment.assign_peer_review(@student_2, @student_1)
    @assignment.reload

    @submission = @first_assignment.submit_homework(@student_1, body: 'student first submission')
    @first_assignment.grade_student(@student_1, grade: 10, grader: @teacher)
    @assessment = @association.assess({
      user: @student_1,
      assessor: @teacher,
      artifact: @submission,
      assessment: {
        assessment_type: 'grading',
        criterion_crit1: {
          points: 10,
          comments: "cool, yo"
        }
      }
    })
    @submission.reload
    @submission.score = 3
    @submission.add_comment(author: @teacher, comment: 'submission comment')
    @submission.add_comment({
      author: @student_2,
      comment: "Anonymous Peer Review"
    })
    @submission.save!

    #second student submission
    @student_2_submission = @first_assignment.submit_homework(@student_2, body: 'second student second submission')
    @first_assignment.grade_student(@student_2, grade: 4, grader: @teacher)
    @student_2_submission.score = 3
    @submission.save!

    #second assigmnent data
    due_date = due_date + 1.days
    @second_assignment = assignment_model({
      course: @course,
      title: 'second assignment',
      due_at: due_date,
      points_possible: 5,
      submission_types:'online_text_entry',
      assignment_group: @group
    })

    @second_association = @rubric.associate_with(@second_assignment, @course, purpose: 'grading')
    @second_submission = @second_assignment.submit_homework(@student_1, body: 'student second submission')
    @second_assignment.grade_student(@student_1, grade: 2, grader: @teacher)
    @second_submission.save!
    @second_assessment = @second_association.assess({
      user: @student_1,
      assessor: @teacher,
      artifact: @second_submission,
      assessment: {
        assessment_type: 'grading',
        criterion_crit1: {
          points: 2
        }
      }
    })

    #third assignment data
    due_date = due_date + 1.days
    @third_assignment = assignment_model({title: 'third assignment', due_at: due_date, course: @course})
  end

  context "as a teacher" do
    before(:each) do
      user_session(@teacher)
    end

    context 'overall grades' do
      before(:each) do
        @course_names = []
        @course_names << @course
        3.times do |i|
          course = Course.create!(name: "course #{i}", account: Account.default)
          course.enroll_user(@teacher, 'TeacherEnrollment').accept!
          course.offer!
          @course_names << course
        end
        GlobalGrades.visit
      end

      it "should validate courses display", priority: "1", test_id: 222510 do
        4.times { |c| expect(GlobalGrades.course_details).to include_text(@course_names[c].name) }
      end
    end

    it "should show the student outcomes report if enabled", priority: "1", test_id: 229447 do
      @outcome_group ||= @course.root_outcome_group
      @outcome = @course.created_learning_outcomes.create!(title: 'outcome')
      @outcome_group.add_outcome(@outcome)
      Account.default.set_feature_flag!('student_outcome_gradebook', 'on')
      StudentGradesPage.visit_as_teacher(@course, @student_1)
      expect(f('#navpills')).not_to be_nil
      f('a[href="#outcomes"]').click
      wait_for_ajaximations
      expect(fj("span:contains('Toggle outcomes for Unnamed Course')")).to be_present
      f(".icon-expand").click
      wait_for_ajaximations
      expect(ff("span[data-selenium='outcome']").count).to eq @course.learning_outcome_links.count
    end

    context 'student view' do
      it "should be available to student view student", priority: "1", test_id: 229448 do
        @fake_student = @course.student_view_student
        @fake_submission = @first_assignment.submit_homework(@fake_student, body: 'fake student submission')
        @first_assignment.grade_student(@fake_student, grade: 8, grader: @teacher)

        enter_student_view
        StudentGradesPage.visit_as_student(@course)

        expect(f("#submission_#{@first_assignment.id} .grade")).to include_text "8"
      end
    end
  end

  context "as a student" do
    before(:each) do
      user_session(@student_1)
    end

    it "should display tooltip on focus", priority: "1", test_id: 229659 do
      StudentGradesPage.visit_as_student(@course)

      expect(driver.execute_script(
        "return $('#submission_#{@submission.assignment_id} .assignment_score .grade .tooltip_wrap').css('visibility')"
      )).to eq('hidden')

      driver.execute_script(
        'window.focus()'
      )

      driver.execute_script(
        "$('#submission_#{@submission.assignment_id} .assignment_score .grade').focus()"
      )

      expect(driver.execute_script(
        "return $('#submission_#{@submission.assignment_id} .assignment_score .grade .tooltip_wrap').css('visibility')"
      )).to eq('visible')
    end

    it "should allow student to test modifying grades", priority: "1", test_id: 229660 do
      skip_if_chrome('issue with blur')
      StudentGradesPage.visit_as_student(@course)

      expect_any_instantiation_of(@first_assignment).to receive(:find_or_create_submission).and_return(@submission)

      #check initial total
      expect(f('#submission_final-grade .assignment_score .grade').text).to eq '33.33%'

      edit_grade = lambda do |field, score|
        field.click
        set_value field.find_element(:css, 'input'), score.to_s
        driver.execute_script '$("#grade_entry").blur()'
      end

      assert_grade = lambda do |grade|
        wait_for_ajaximations
        expect(f('#submission_final-grade .grade')).to include_text grade.to_s
      end

      # test changing existing scores
      first_row_grade = f("#submission_#{@submission.assignment_id} .assignment_score .grade")
      edit_grade.call(first_row_grade, 4)
      assert_grade.call("40%")

      #using find with jquery to avoid caching issues

      # test changing unsubmitted scores
      third_grade = f("#submission_#{@third_assignment.id} .assignment_score .grade")
      edit_grade.call(third_grade, 10)
      assert_grade.call("96.97%")

      driver.execute_script '$("#grade_entry").focus()'
    end

    it "should display rubric on assignment and properly highlight levels", priority: "1", test_id: 229661 do
      zero_assignment = assignment_model({title: 'zero assignment', course: @course})
      zero_association = @rubric.associate_with(zero_assignment, @course, purpose: 'grading')
      zero_submission = zero_assignment.submissions.find_by!(user: @student_1) # unsubmitted submission :/

      zero_association.assess({
        user: @student_1,
        assessor: @teacher,
        artifact: zero_submission,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            points: 0
          }
        }
      })
      StudentGradesPage.visit_as_student(@course)

      # click first rubric
      f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link").click
      wait_for_ajaximations
      expect(fj('.react-rubric caption:visible')).to include_text(@rubric.title)
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text('10')

      # check if only proper rating is highlighted for a score of 10 on scale of 10|5|0
      expect(ffj('.rubric_assessments:visible .selected').length).to eq 1
      expect(fj('.rubric_assessments:visible .selected')).to include_text('10')

      # check rubric comment
      expect(fj('.assessment-comments:visible div').text).to eq 'cool, yo'

      # close first rubric
      scroll_into_view("a:contains('Close Rubric'):visible")
      fj("a:contains('Close Rubric'):visible").click

      # click second rubric
      scroll_into_view("#submission_#{zero_assignment.id} .toggle_rubric_assessments_link")
      f("#submission_#{zero_assignment.id} .toggle_rubric_assessments_link").click
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text('0')

      # check if only proper rating is highlighted for a score of 0 on scale of 10|5|0
      expect(ffj('.rubric_assessments:visible .selected').length).to eq 1
      expect(fj('.rubric_assessments:visible .selected')).to include_text('0')
    end

    context "rubric criterion ranges disabled" do
      before(:each) do
        @rubric.criteria[0][:criterion_use_range] = false
        @rubric.save!
      end

      after(:each) do
        @rubric.criteria[0][:criterion_use_range] = true
        @rubric.save!
      end

      it "should not highlight scores between ranges when range rating is disabled" do
        StudentGradesPage.visit_as_student(@course)

        # open rubric
        f("#submission_#{@second_assignment.id} .toggle_rubric_assessments_link").click

        # check if no highlights exist on a non-range criterion for a score of 2 on scale of 10|5|0
        expect(find_with_jquery('.rubric_assessments:visible .selected')).to be nil
      end
    end

    context "rubric criterion ranges enabled" do
      it "should highlight scores between ranges when range rating is enabled" do
        @course.account.root_account.enable_feature!(:rubric_criterion_range)
        StudentGradesPage.visit_as_student(@course)

        # open rubric
        f("#submission_#{@second_assignment.id} .toggle_rubric_assessments_link").click

        # check if proper highlights exist on a range criterion for a score of 2 on scale of 10|5|0
        expect(ffj('.rubric_assessments:visible .selected').length).to eq 1
        expect(fj('.rubric_assessments:visible .selected')).to include_text('5')
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

    it "should not display rubric on muted assignment", priority: "1", test_id: 229662 do
      StudentGradesPage.visit_as_student(@course)

      @first_assignment.muted = true
      @first_assignment.save!
      StudentGradesPage.visit_as_student(@course)

      expect(f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link")).not_to be_displayed
    end

    it "should not display letter grade score on muted assignment", priority: "1", test_id: 229663 do
      StudentGradesPage.visit_as_student(@course)

      @another_assignment = assignment_model({
        course: @course,
        title: 'another assignment',
        points_possible: 100,
        submission_types: 'online_text_entry',
        assignment_group: @group,
        grading_type: 'letter_grade',
        muted: 'true'
      })
      @another_submission = @another_assignment.submit_homework(@student_1, body: 'student second submission')
      @another_assignment.grade_student(@student_1, grade: 81, grader: @teacher)
      @another_submission.save!
      StudentGradesPage.visit_as_student(@course)
      expect(f('.score_value').text).to eq ''
    end

    it "should display assignment statistics", priority: "1", test_id: 229664 do
      5.times do |count|
        @s = course_with_student(course: @course, name: "Student #{count}", active_all:true).user
        @first_assignment.grade_student(@s, grade: 4, grader: @teacher)
      end

      AssignmentScoreStatisticsGenerator.update_score_statistics(@course.id)

      StudentGradesPage.visit_as_student(@course)
      f('.toggle_score_details_link').click

      score_row = f('#grades_summary tr.grade_details')
      expect(score_row).to include_text('Mean:')
      expect(score_row).to include_text('High: 4')
      expect(score_row).to include_text('Low: 3')
    end

    it "should not show assignment statistics on assignments with less than 5 submissions",
       priority: "1", test_id: 229667 do
      StudentGradesPage.visit_as_student(@course)
      expect(f("#content")).not_to contain_css("#grade_info_#{@first_assignment.id} .tooltip")
    end

    it "should not show assignment statistics on assignments when it is disabled on the course",
       priority: "1", test_id: 229668 do
      # get up to a point where statistics can be shown
      5.times do |count|
        s = course_with_student(course: @course, name: "Student_#{count}", active_all:true).user
        @first_assignment.grade_student(s, grade: 4, grader: @teacher)
      end
      # but then prevent them at the course levels
      @course.update_attributes(hide_distribution_graphs: true)

      StudentGradesPage.visit_as_student(@course)
      expect(f("#content")).not_to contain_css("#grade_info_#{@first_assignment.id} .tooltip")
    end

    it "should display teacher comments", priority: "1", test_id: 229665 do
      StudentGradesPage.visit_as_student(@course)

      # check comment
      f('.toggle_comments_link').click
      comment_row = f('#grades_summary tr.comments_thread')
      expect(comment_row).to include_text('submission comment')
    end

    it 'should not display name of anonymous reviewer', priority: "1", test_id: 229666 do
      StudentGradesPage.visit_as_student(@course)

      f('.toggle_comments_link').click
      comment_row = f('#grades_summary tr.comments_thread')
      expect(comment_row).to include_text('Anonymous User')
    end

    it "should show rubric even if there are no comments", priority: "1", test_id: 229669 do
      @third_association = @rubric.associate_with(@third_assignment, @course, purpose: 'grading')
      @third_submission = @third_assignment.submissions.find_by!(user: @student_1) # unsubmitted submission :/

      @third_association.assess({
        user: @student_1,
        assessor: @teacher,
        artifact: @third_submission,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            points: 2,
            comments: "not bad, not bad"
          }
        }
      })

      StudentGradesPage.visit_as_student(@course)

      # click rubric
      f("#submission_#{@third_assignment.id} .toggle_rubric_assessments_link").click
      expect(fj('.react-rubric caption:visible')).to include_text(@rubric.title)
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text('2')

      # check rubric comment
      expect(fj('.assessment-comments:visible div').text).to eq 'not bad, not bad'
    end

    context "with outcome gradebook enabled" do
      before :once do
        Account.default.set_feature_flag!('student_outcome_gradebook', 'on')

        @outcome_group ||= @course.root_outcome_group
        @outcome = @course.created_learning_outcomes.create!(title: 'outcome')
        @outcome_group.add_outcome(@outcome)
      end

      it "should show the outcome gradebook", priority: "1", test_id: 229670 do
        StudentGradesPage.visit_as_student(@course)
        expect(f('#navpills')).not_to be_nil
        f('a[href="#outcomes"]').click
        wait_for_ajaximations
        expect(fj("span:contains('Toggle outcomes for Unnamed Course')")).to be_present
        f(".icon-expand").click
        wait_for_ajaximations
        expect(ff("span[data-selenium='outcome']").count).to eq @course.learning_outcome_links.count
      end

      it "should show the outcome gradebook if the student is in multiple sections", priority: "1", test_id: 229671 do
        @other_section = @course.course_sections.create(name: "the other section")
        @course.enroll_student(@student_1, section: @other_section, allow_multiple_enrollments: true)

        StudentGradesPage.visit_as_student(@course)
        expect(f('#navpills')).not_to be_nil
        f('a[href="#outcomes"]').click
        wait_for_ajaximations
        expect(fj("span:contains('Toggle outcomes for Unnamed Course')")).to be_present
        f(".icon-expand").click
        wait_for_ajaximations
        expect(ff("span[data-selenium='outcome']").count).to eq @course.learning_outcome_links.count
      end
    end
  end

  context "as an observer" do
    it "should allow observers to see grades of all enrollment associations", priority: "1", test_id: 229883 do
      @obs = user_model(name: "Observer")
      e1 = @course.observer_enrollments.create(user: @obs, workflow_state: "active")
      e1.associated_user = @student_1
      e1.save!
      e2 = @course.observer_enrollments.create(user: @obs, workflow_state: "active")
      e2.associated_user = @student_2
      e2.save!

      user_session(@obs)
      StudentGradesPage.visit_as_student(@course)

      expect(f("#student_select_menu")).to be_displayed
      expect(fj("#student_select_menu option:selected")).to include_text "Student 1"
      expect(f("#submission_#{@submission.assignment_id} .grade")).to include_text "3"

      click_option("#student_select_menu", "Student 2")
      expect_new_page_load { f('#apply_select_menus').click }

      expect(f("#student_select_menu")).to be_displayed
      expect(fj("#student_select_menu option:selected")).to include_text "Student 2"
      expect(f("#submission_#{@submission.assignment_id} .grade")).to include_text "4"

      click_option("#student_select_menu", "Student 1")
      expect_new_page_load { f('#apply_select_menus').click }

      expect(f("#student_select_menu")).to be_displayed
      expect(fj("#student_select_menu option:selected")).to include_text "Student 1"
      expect(f("#submission_#{@submission.assignment_id} .grade")).to include_text "3"
    end
  end
end
