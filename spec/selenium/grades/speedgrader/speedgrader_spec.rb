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

require_relative "../../common"
require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/groups_common"
require_relative "../../helpers/assignments_common"
require_relative "../../helpers/quizzes_common"
require_relative "../pages/speedgrader_page"
require_relative "../pages/student_grades_page"
require_relative "../pages/gradebook_page"
require_relative "../../assignments/page_objects/assignment_page"
require_relative "../../assignments/page_objects/submission_detail_page"

describe "Speedgrader" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include GradebookCommon
  include GroupsCommon
  include AssignmentsCommon

  let(:rubric_data) do
    [
      {
        description: "Awesomeness",
        long_description: "For real the most awesome thing",
        points: 10,
        id: "crit1",
        ratings: [
          { description: "Much Awesome", points: 10, id: "rat1" },
          { description: "So Awesome", points: 5, id: "rat2" },
          { description: "Lame", points: 0, id: "rat3" }
        ]
      },
      {
        description: "Wow",
        points: 10,
        id: "crit2",
        ratings: [
          { description: "Much Wow", points: 10, id: "rat4" },
          { description: "So Wow", points: 5, id: "rat5" },
          { description: "Wow... not", points: 0, id: "rat6" }
        ]
      }
    ]
  end

  before :once do
    course_factory(active_all: true)
    @students = create_users_in_course(@course, 5, return_type: :record, name_prefix: "Student_")
  end

  context "grading" do
    describe "displays grades correctly" do
      before do
        user_session(@teacher)
      end

      it "letter grades", priority: "1" do
        create_assignment_type_and_grade("letter_grade", "A", "C")
        grader_speedgrader_assignment("A", "C")
      end

      it "percent grades", priority: "1" do
        create_assignment_type_and_grade("percent", 15, 10)
        grader_speedgrader_assignment("75", "50")
      end

      it "points grades", priority: "1" do
        create_assignment_type_and_grade("points", 15, 10)
        grader_speedgrader_assignment("15", "10")
      end

      it "gpa scale grades", priority: "1" do
        create_assignment_type_and_grade("gpa_scale", "A", "D")
        grader_speedgrader_assignment("A", "D")
      end
    end

    context "quizzes" do
      before(:once) do
        @quiz = seed_quiz_with_submission
      end

      before do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @quiz.assignment_id)
      end

      it "page should load in acceptable time", priority: "1" do
        page_load_time = Benchmark.measure do
          Speedgrader.visit(@course.id, @quiz.assignment_id)
          Speedgrader.wait_for_grade_input
        end
        Rails.logger.debug "SpeedGrader for course #{@course.id} and assignment " \
                           "#{@quiz.assignment_id} loaded in #{page_load_time.real} seconds"
        expect(page_load_time.real).to be > 0.0
      end

      it "displays needs review alert on non-autograde questions", priority: "1" do
        in_frame "speedgrader_iframe", ".quizzes-speedgrader" do
          expect(Speedgrader.quiz_alerts[0]).to include_text("The following questions need review:")
        end
      end

      it "only displays needs review for file_upload and essay questions", priority: "2" do
        in_frame "speedgrader_iframe", ".quizzes-speedgrader" do
          expect(Speedgrader.quiz_questions_need_review[0]).to include_text("Question 2")
          expect(Speedgrader.quiz_questions_need_review[1]).to include_text("Question 3")
        end
      end

      it "does not display review warning on text only quiz questions", priority: "1" do
        in_frame "speedgrader_iframe", ".quizzes-speedgrader" do
          expect(Speedgrader.quiz_alerts[0]).not_to include_text("Question 4")
        end
      end
    end

    context "pass/fail assignment grading" do
      before :once do
        @assignment = @course.assignments.create!(
          grading_type: "pass_fail",
          points_possible: 0
        )
        @assignment.grade_student(@students.first, grade: "pass", grader: @teacher)
        @assignment.grade_student(@students.second, grade: "fail", grader: @teacher)
      end

      before do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @assignment.id)
        Speedgrader.wait_for_grade_input
      end

      it "complete/incomplete", priority: "1" do
        expect(Speedgrader.grade_input).to have_value "complete"
        Speedgrader.click_next_student_btn
        expect(Speedgrader.grade_input).to have_value "incomplete"
      end

      it "allows pass grade on assignments worth 0 points", priority: "1" do
        expect(Speedgrader.grade_input).to have_value("complete")
        expect(Speedgrader.points_possible_label).to include_text("(0 / 0)")
      end

      it "displays pass/fail correctly when total points possible is changed", priority: "1" do
        @assignment.update(points_possible: 1)
        refresh_page
        expect(Speedgrader.grade_input).to have_value("complete")
        expect(Speedgrader.points_possible_label).to include_text("(1 / 1)")
      end
    end

    context "Using a rubric" do
      before :once do
        @assignment = @course.assignments.create!(
          title: "Rubric",
          points_possible: 20
        )

        rubric = @course.rubrics.build(
          title: "Everything is Awesome",
          points_possible: 20
        )
        rubric.data = rubric_data
        rubric.save!
        rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        rubric.reload
      end

      before do
        user_session(@teacher)
      end

      it "properly shows the view longer description link" do
        Speedgrader.visit(@course.id, @assignment.id)

        Speedgrader.view_rubric_button.click
        expect(Speedgrader.view_longer_description_link(0)).to be_displayed
      end

      context "saves grades in" do
        before do
          Speedgrader.visit(@course.id, @assignment.id)
          Speedgrader.view_rubric_button.click
          Speedgrader.select_rubric_criterion("Much Awesome")
          Speedgrader.select_rubric_criterion("So Wow")
          Speedgrader.save_rubric_button.click
          wait_for_ajax_requests
        end

        it "speedgrader", priority: "1" do
          expect(Speedgrader.grade_input).to have_value "15"

          keep_trying_until(2) do
            disable_implicit_wait do
              expect(Speedgrader.rubric_total_points).to include_text "15"
            end
          end
        end

        it "assignment page", priority: "1" do
          StudentGradesPage.visit_as_teacher(@course, @students.first)

          f("#submission_#{@assignment.id}  i.icon-rubric").click

          expect(ff(".react-rubric-cell.graded-points").first).to include_text "10"
          expect(ff(".react-rubric-cell.graded-points").second).to include_text "5"
        end

        it "submissions page", priority: "1" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@students[0].id}"
          f("a.assess_submission_link").click
          wait_for_animations

          expect(ff('td[data-testid="criterion-points"] input').first).to have_value "10"
          expect(ff('td[data-testid="criterion-points"] input').second).to have_value "5"

          replace_content ff('td[data-testid="criterion-points"] input').first, "5"
          scroll_into_view("button.save_rubric_button")
          f("button.save_rubric_button").click

          el = f("#student_grading_#{@assignment.id}")
          expect(el).to have_value "10"
        end
      end
    end

    context "rubric with points removed" do
      before :once do
        @assignment = @course.assignments.create!(
          title: "Rubric with points removed"
        )
        rubric = @course.rubrics.build(
          title: "Everything is Awesome",
          points_possible: 20
        )
        rubric.data = rubric_data
        rubric.save!
        rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: false)
        rubric.rubric_associations.first.update!(hide_points: true)
        rubric.reload
      end

      before do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @assignment.id)
        wait_for_ajaximations
        Speedgrader.view_rubric_button.click
        wait_for_ajaximations
      end

      it "can be viewed on speedgrader" do
        expect(f("#rubric_holder")).to be_displayed
      end

      it "does not show points in rating tiers" do
        Speedgrader.rating_tiers.each do |rating|
          expect(rating).not_to include_text("pts")
        end
      end

      context "saving rubric ratings" do
        before do
          Speedgrader.rating_by_text("Much Awesome").click
          Speedgrader.rating_by_text("So Wow").click
          Speedgrader.save_rubric_button.click
          wait_for_ajaximations
        end

        it "saves the correct ratings on speedgrader" do
          expect(Speedgrader.saved_rubric_ratings.first).to be_displayed
          expect(Speedgrader.saved_rubric_ratings.second).to be_displayed
          expect(Speedgrader.saved_rubric_ratings.first).to include_text "Much Awesome"
          expect(Speedgrader.saved_rubric_ratings.first).not_to include_text "pts"
          expect(Speedgrader.saved_rubric_ratings.second).to include_text "So Wow"
          expect(Speedgrader.saved_rubric_ratings.second).not_to include_text "pts"
        end

        it "saves the correct ratings on student grades page" do
          StudentGradesPage.visit_as_teacher(@course, @students.first)
          f(".icon-rubric").click
          wait_for_ajaximations
          expect(f('tbody[data-testid="criterions"]')).to be_displayed

          ratings = ff(".rating-description")
          spikes = ff(".triangle")
          ratings.each do |rating|
            expect(rating).not_to include_text("pts")
          end

          expect(ratings.first).to include_text("Much Awesome")
          expect(ratings.fifth).to include_text("So Wow")

          # check that spikes appear only for selected ratings
          spikes.each_with_index do |spike, index|
            if index == 0 || index == 4
              expect(spike).to be_displayed
            else
              expect(spike).not_to be_displayed
            end
          end
        end
      end
    end

    context "rubric with outcomes" do
      before :once do
        @assignment = @course.assignments.create!(
          title: "Outcome Rubric",
          points_possible: 8
        )

        rubric = outcome_with_rubric
        rubric.save!
        rubric.associate_with(@assignment, @course, purpose: "grading")
        rubric.reload
      end

      describe "flashes a warning when grade changes in" do
        before do
          user_session(@teacher)
        end

        it "speedgrader" do
          Speedgrader.visit(@course.id, @assignment.id)
          Speedgrader.view_rubric_button.click
          Speedgrader.enter_rubric_points("5")
          wait_for_ajaximations
          expect(Speedgrader.rubric_criterion_points(0)).to include_text("Cannot give outcomes extra credit")
        end

        it "submissions page" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@students[0].id}"
          f("a.assess_submission_link").click
          wait_for_animations
          replace_content fj(".react-rubric-cell.graded-points:visible input"), "5"
          expect(Speedgrader.rubric_criterion_points(0)).to include_text("Cannot give outcomes extra credit")
        end
      end
    end

    context "Using a rubric to grade" do
      before do
        user_session(@teacher)
      end

      it "displays correct grades for student with proper selected ratings", priority: "1" do
        rubric = outcome_with_rubric
        @assignment = @course.assignments.create!(name: "assignment with rubric", points_possible: 10)
        @association = rubric.associate_with(
          @assignment,
          @course,
          purpose: "grading",
          use_for_grading: true
        )
        @submission = @assignment.submissions.find_by!(user: @students.first)
        @submission.update!(
          submission_type: "online_text_entry"
        )
        criterion1 = rubric.criteria.first
        criterion2 = rubric.criteria.last
        @assessment = @association.assess(
          user: @students.first,
          assessor: @teacher,
          artifact: @submission,
          assessment: {
            assessment_type: "grading",
            "criterion_#{criterion1[:id]}": { points: 3 },
            "criterion_#{criterion2[:id]}": { points: 0 }
          }
        )
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@students.first.id}"
        f("a.assess_submission_link").click
        expect(ff('tr[data-testid="rubric-criterion"]:nth-of-type(1) .rating-tier.selected').length).to eq 1
        expect(f('tr[data-testid="rubric-criterion"]:nth-of-type(1) .rating-tier.selected')).to include_text("3 pts")
        expect(ff('tr[data-testid="rubric-criterion"]:nth-of-type(2) .rating-tier.selected').length).to eq 1
        expect(f('tr[data-testid="rubric-criterion"]:nth-of-type(2) .rating-tier.selected')).to include_text("0 pts")
      end
    end

    context "submission status" do
      before do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        assignment = @course.assignments.create!(points_possible: 20)
        @submission = assignment.submissions.find_by!(user: @students[0])
        @submission.update!(late_policy_status: "missing")
        @submission = assignment.submissions.find_by!(user: @students[1])
        @submission.update!(late_policy_status: "extended")
        @submission = assignment.submissions.find_by!(user: @students[2])
        @submission.update!(late_policy_status: "late")
        assignment.grade_student(@students[3], grader: @teacher, excused: true)
        @submission = assignment.submissions.find_by!(user: @students[4])
        @custom_status = CustomGradeStatus.create!(name: "Custom Status", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher)
        @second_custom_status = CustomGradeStatus.create!(name: "Second Status", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher)
        @submission.update!(custom_grade_status: @custom_status)
        user_session(@teacher)
        Speedgrader.visit(@course.id, assignment.id)
      end

      it "displays correct status pill for each student submission" do
        expect(f(".submission-missing-pill")).to be_displayed
        Speedgrader.click_next_student_btn
        expect(f(".submission-extended-pill")).to be_displayed
        Speedgrader.click_next_student_btn
        expect(f(".submission-late-pill")).to be_displayed
        Speedgrader.click_next_student_btn
        expect(f(".submission-excused-pill")).to be_displayed
        Speedgrader.click_next_student_btn
        expect(f(".submission-custom-grade-status-pill-#{@custom_status.id}")).to be_displayed
      end

      it "updates status pill when standard status is changed to another standard status" do
        expect(f(".submission-missing-pill")).to be_displayed
        f("[data-testid='speedGraderStatusMenu-editButton']").click
        late_status = f("[data-testid='speedGraderStatusMenu-late']")
        expect(late_status).to be_displayed
        late_status.click
        expect(f(".submission-late-pill")).to be_displayed
      end

      it "updates status pill when standard status is changed to custom status" do
        expect(f(".submission-missing-pill")).to be_displayed
        f("[data-testid='speedGraderStatusMenu-editButton']").click
        custom_status = f("[data-testid='speedGraderStatusMenu-#{@custom_status.id}']")
        expect(custom_status).to be_displayed
        custom_status.click
        expect(f(".submission-custom-grade-status-pill-#{@custom_status.id}")).to be_displayed
      end

      it "updates status pill when custom status is changed to another custom status" do
        Speedgrader.visit(@course.id, @submission.assignment_id, 10, @submission.user_id)
        expect(f(".submission-custom-grade-status-pill-#{@custom_status.id}")).to be_displayed
        f("[data-testid='speedGraderStatusMenu-editButton']").click
        second_custom_status_button = f("[data-testid='speedGraderStatusMenu-#{@second_custom_status.id}']")
        expect(second_custom_status_button).to be_displayed
        second_custom_status_button.click
        expect(f(".submission-custom-grade-status-pill-#{@second_custom_status.id}")).to be_displayed
      end

      it "updates status pill when custom status is changed to standard status" do
        Speedgrader.visit(@course.id, @submission.assignment_id, 10, @submission.user_id)
        expect(f(".submission-custom-grade-status-pill-#{@custom_status.id}")).to be_displayed
        f("[data-testid='speedGraderStatusMenu-editButton']").click
        late_status = f("[data-testid='speedGraderStatusMenu-late']")
        expect(late_status).to be_displayed
        late_status.click
        expect(f(".submission-late-pill")).to be_displayed
      end
    end
  end

  context "reassigning" do
    context "with assignment" do
      before(:once) do
        @assignment_for_course = @course.assignments.create!(
          title: "Assignment A",
          submission_types: "online_text_entry,online_upload",
          due_at: 2.years.from_now
        )
      end

      before do
        user_session(@teacher)
      end

      it "does not display reassign button without a submission" do
        Speedgrader.visit(@course.id, @assignment_for_course.id)

        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end

      context "with submission" do
        let!(:resubmit_with_text) do
          @assignment_for_course.submit_homework(
            @students.first, submission_type: "online_text_entry", body: "hello!"
          )
        end

        it "displays disabled reassign button with a submission" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment:visible")
        end

        it "displays tooltip on reassign button" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          wrapper = ff("#reassign_assignment_wrapper")
          expect(wrapper[0].attribute("title")).to eq "Student feedback required in comments above to reassign."
        end

        it "enables reassign button after adding a comment" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          Speedgrader.add_comment_and_submit("commenting")
          expect(Speedgrader.comments.last).to be_displayed
          expect(Speedgrader.right_pane).not_to contain_css("#reassign_assignment[disabled]")
          expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment:visible")
        end

        it "does not display tooltip on enabled reassign button" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          Speedgrader.add_comment_and_submit("commenting")
          expect(Speedgrader.comments.last).to be_displayed
          wrapper = ff("#reassign_assignment_wrapper")
          expect(wrapper[0].attribute("title")).to eq ""
        end

        it "disables reassign button after reassigning" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          Speedgrader.add_comment_and_submit("commenting")
          expect(Speedgrader.comments.last).to be_displayed

          Speedgrader.click_reassignment_btn
          wait_for_ajax_requests

          expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment[disabled]:visible")
        end

        it "relabels reassign button after reassigning" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          Speedgrader.add_comment_and_submit("commenting")
          expect(Speedgrader.comments.last).to be_displayed

          Speedgrader.click_reassignment_btn
          wait_for_ajax_requests

          expect(Speedgrader.reassignment_btn.text).to eq "Reassigned"
        end

        it "displays alert after reassigning" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          Speedgrader.add_comment_and_submit("commenting")
          expect(Speedgrader.comments.last).to be_displayed

          Speedgrader.click_reassignment_btn
          wait_for_ajax_requests

          wrapper = ff("#reassignment_complete")
          expect(wrapper[0].text).to match(/The assignment has been reassigned./)
        end

        it "displays tooltip on disabled reassign button" do
          Speedgrader.visit(@course.id, @assignment_for_course.id)

          Speedgrader.add_comment_and_submit("commenting")
          expect(Speedgrader.comments.last).to be_displayed

          Speedgrader.click_reassignment_btn
          wait_for_ajax_requests

          wrapper = ff("#reassign_assignment_wrapper")
          expect(wrapper[0].attribute("title")).to eq "Assignment is reassigned."
        end

        context "student switching" do
          after do
            clear_local_storage
          end

          before :once do
            @assignment_for_course.submit_homework(
              @students.second, submission_type: "online_text_entry", body: "hello!"
            )
          end

          it "switching students during reassignment does not affect next student reassign button" do
            Speedgrader.visit(@course.id, @assignment_for_course.id)

            Speedgrader.add_comment_and_submit("commenting")
            expect(Speedgrader.comments.last).to be_displayed

            Speedgrader.click_reassignment_btn
            wait_for_ajax_requests
            Speedgrader.click_next_student_btn
            wait_for_animations

            expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment[disabled]:visible")
            wrapper = ff("#reassign_assignment_wrapper")
            expect(wrapper[0].attribute("title")).to eq "Student feedback required in comments above to reassign."
          end

          it "switching back to reassign student shows already asssigned" do
            Speedgrader.visit(@course.id, @assignment_for_course.id)

            Speedgrader.add_comment_and_submit("commenting")
            expect(Speedgrader.comments.last).to be_displayed

            Speedgrader.click_reassignment_btn
            wait_for_ajax_requests
            Speedgrader.click_next_student_btn
            wait_for_animations
            Speedgrader.click_next_or_prev_student :previous
            wait_for_animations

            expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment[disabled]:visible")
            wrapper = ff("#reassign_assignment_wrapper")
            expect(wrapper[0].attribute("title")).to eq "Assignment is reassigned."
            expect(Speedgrader.reassignment_btn.text).to eq "Reassigned"
          end
        end
      end
    end

    context "with limited attempt assignment" do
      before do
        @assignment_for_course = @course.assignments.create!(
          title: "Assignment A",
          submission_types: "online_text_entry,online_upload",
          due_at: 2.years.from_now,
          allowed_attempts: 2
        )
        @assignment_for_course.submit_homework(
          @students.first, submission_type: "online_text_entry", body: "hello!"
        )
      end

      before do
        user_session(@teacher)
      end

      after do
        clear_local_storage
      end

      it "allows reassignment after first attempt" do
        Speedgrader.visit(@course.id, @assignment_for_course.id)

        Speedgrader.add_comment_and_submit("commenting")
        expect(Speedgrader.comments.last).to be_displayed
        expect(Speedgrader.right_pane).not_to contain_css("#reassign_assignment[disabled]")
        expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment:visible")
      end

      it "does not allow reassignment after second attempt" do
        Speedgrader.visit(@course.id, @assignment_for_course.id)

        Speedgrader.add_comment_and_submit("commenting")
        expect(Speedgrader.comments.last).to be_displayed

        Speedgrader.click_reassignment_btn
        wait_for_ajax_requests

        @assignment_for_course.submit_homework(
          @students.first, submission_type: "online_text_entry", body: "again!"
        )

        Speedgrader.visit(@course.id, @assignment_for_course.id)

        expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment[disabled]:visible")
        wrapper = ff("#reassign_assignment_wrapper")
        expect(wrapper[0].attribute("title")).to eq "Student has met maximum allowed attempts."

        # Adding a comment shouldn't enable the button
        Speedgrader.add_comment_and_submit("commenting")
        expect(Speedgrader.comments.last).to be_displayed

        expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment[disabled]:visible")
      end

      it "allows reassignment when the assignment has been set back to unlimited attempts" do
        @assignment_for_course.update!(allowed_attempts: -1)

        Speedgrader.visit(@course.id, @assignment_for_course.id)

        Speedgrader.add_comment_and_submit("commenting")
        expect(Speedgrader.comments.last).to be_displayed
        expect(Speedgrader.right_pane).not_to contain_css("#reassign_assignment[disabled]")
        expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment:visible")
      end
    end

    context "with assignment overrides" do
      before(:once) do
        @assignment_for_course = @course.assignments.create!(
          title: "Assignment A",
          submission_types: "online_text_entry,online_upload"
        )
        @assignment_for_course.submit_homework(
          @students.first, submission_type: "online_text_entry", body: "hello!"
        )
        @assignment_for_course.submit_homework(
          @students.second, submission_type: "online_text_entry", body: "hello!"
        )

        section = @course.course_sections.create!(name: "new section")
        student_in_section(section, user: @students.second)
        @assignment_for_course.assignment_overrides.create! do |override|
          override.set = section
          override.title = "All"
          override.due_at = 2.years.from_now
          override.due_at_overridden = true
        end
      end

      before do
        user_session(@teacher)
      end

      after do
        clear_local_storage
      end

      it "does not display reassign button on submission without assignment override" do
        Speedgrader.visit(@course.id, @assignment_for_course.id)

        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end

      it "switching to submission with assignment override displays reassign button" do
        Speedgrader.visit(@course.id, @assignment_for_course.id)

        Speedgrader.click_next_student_btn
        wait_for_animations

        expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment[disabled]:visible")
        wrapper = ff("#reassign_assignment_wrapper")
        expect(wrapper[0].attribute("title")).to eq "Student feedback required in comments above to reassign."
      end

      it "switching back to submission without assignment override hides reassign button" do
        Speedgrader.visit(@course.id, @assignment_for_course.id)

        Speedgrader.click_next_student_btn
        wait_for_animations
        Speedgrader.click_next_or_prev_student :previous
        wait_for_animations

        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end
    end

    context "with moderated assignment and submission" do
      before(:once) do
        @final_grader = course_with_user("TeacherEnrollment", course: @course, active_enrollment: true).user
        @course.account.enable_feature!(:moderated_grading)
        @moderated_assignment = @course.assignments.create!(
          due_at: 2.years.from_now,
          final_grader: @final_grader,
          grader_count: 2,
          moderated_grading: true,
          points_possible: 10,
          submission_types: :online_text_entry,
          title: "Moderated Assignment"
        )

        @moderated_assignment.submit_homework(
          @students.first, submission_type: "online_text_entry", body: "hello!"
        )
      end

      it "does not display reassign button for non-moderator" do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @moderated_assignment.id)

        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end

      it "displays reassign button for moderator" do
        user_session(@final_grader)
        Speedgrader.visit(@course.id, @moderated_assignment.id)

        expect(Speedgrader.right_pane).to contain_jqcss("#reassign_assignment:visible")
      end
    end

    context "with quiz and submission" do
      before(:once) do
        @quiz = seed_quiz_with_submission
      end

      before do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @quiz.assignment_id)
      end

      it "does not display reassign button" do
        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end
    end

    context "with on paper assignment and grade" do
      before(:once) do
        @assignment = @course.assignments.create!(
          title: "Assignment A",
          grading_type: "points",
          submission_types: "on_paper,online_upload",
          due_at: 2.years.from_now
        )
        @assignment.grade_student @students[0], grade: 10, grader: @teacher
      end

      before do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @assignment.id)
      end

      it "does not display reassign button" do
        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end
    end

    context "with external tool assignment and grade" do
      before(:once) do
        @assignment = @course.assignments.create!(
          title: "Assignment A",
          grading_type: "points",
          submission_types: "external_tool",
          due_at: 2.years.from_now
        )
        @assignment.grade_student @students[0], grade: 10, grader: @teacher
      end

      before do
        user_session(@teacher)
        Speedgrader.visit(@course.id, @assignment.id)
      end

      it "does not display reassign button" do
        expect(Speedgrader.right_pane).not_to contain_jqcss("#reassign_assignment:visible")
      end
    end
  end

  context "assignment group" do
    it "updates grades for all students in group", priority: "1" do
      skip "Skipped because this spec fails if not run in foreground\nThis is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
      init_course_with_students 5
      user_session(@teacher)
      seed_groups 1, 1
      scores = [5, 7, 10]

      3.times do |i|
        @testgroup[0].add_user @students[i]
      end

      @testgroup[0].save!

      assignment = @course.assignments.create!(
        title: "Group Assignment",
        group_category_id: @testgroup[0].id,
        grade_group_students_individually: false,
        points_possible: 20
      )

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"

      # menu needs to be expanded for this to work
      options = ff("#students_selectmenu-menu li")
      # driver.execute_script("$('#students_selectmenu-menu li').focus()")

      options.each_with_index do |option, i|
        f("#students_selectmenu-button").click
        option.click
        Speedgrader.grade_input.send_keys scores[i]
      end

      get "/courses/#{@course.id}/gradebook"
      cells = ff("#gradebook_grid .container_1 .slick-cell")

      # For whatever reason, this spec fails occasionally.
      # Expected "10"
      # Got "-"

      expect(cells[0]).to include_text "10"
      expect(cells[3]).to include_text "10"
      expect(cells[6]).to include_text "10"
      expect(cells[9]).to include_text "5"
      expect(cells[12]).to include_text "7"
    end
  end

  context "grade by question" do
    before(:once) do
      @teacher.preferences[:enable_speedgrader_grade_by_question] = true
      @teacher.save!
    end

    let_once(:quiz) { seed_quiz_with_submission(6) }

    before do
      user_session(@teacher)
      Speedgrader.visit(@course.id, quiz.assignment_id)
    end

    it "displays question navigation bar when setting is enabled", priority: "1" do
      in_frame "speedgrader_iframe", ".quizzes-speedgrader" do
        expect(Speedgrader.quiz_header).to include_text quiz.title
        expect(Speedgrader.quiz_nav).to be_displayed
        expect(Speedgrader.quiz_nav_questions).to have_size 24
      end
    end

    it "scrolls nav bar and to questions", priority: "1" do
      skip_if_chrome("broken")

      in_frame "speedgrader_iframe", ".quizzes-speedgrader" do
        wrapper = f("#quiz-nav-inner-wrapper")

        # check scrolling
        first_left = wrapper.css_value("left").to_f

        f("#nav-link-next").click
        second_left = wrapper.css_value("left").to_f
        expect(first_left).to be > second_left

        # check anchors
        anchors = ff("#quiz-nav-inner-wrapper li a")
        data_id = anchors[1].attribute "data-id"
        anchors[1].click
        expect(f("#question_#{data_id}")).to have_class "selected_single_question"
      end
    end

    it "updates scores", priority: "1" do
      in_frame "speedgrader_iframe", ".quizzes-speedgrader" do
        replace_content Speedgrader.quiz_point_inputs[1], "1", tab_out: true
        replace_content Speedgrader.quiz_fudge_points, "7", tab_out: true

        # after_fudge_points_total is updated, even before update button is clicked
        expect(Speedgrader.quiz_after_fudge_total).to include_text "8"

        expect_new_page_load { Speedgrader.quiz_update_scores_button.click }
        expect(Speedgrader.quiz_after_fudge_total).to include_text "8"
      end
    end
  end

  context "Student drop-down" do
    before :once do
      @assignment = @course.assignments.create!(title: "My Title", grading_type: "letter_grade", points_possible: 20)
    end

    before do
      user_session(@teacher)
      # see first student
      Speedgrader.visit(@course.id, @assignment.id)
    end

    after do
      clear_local_storage
    end

    it "selects the first student" do
      expect(Speedgrader.selected_student).to include_text(@students[0].name)
    end

    it "has working next and previous arrows", priority: "1" do
      # click next to second student
      Speedgrader.click_next_student_btn
      expect(Speedgrader.selected_student).to include_text(@students[1].name)
      expect(Speedgrader.student_x_of_x_label).to include_text "2/5"

      # click next to third student
      Speedgrader.click_next_student_btn
      expect(Speedgrader.selected_student).to include_text(@students[2].name)
      expect(Speedgrader.student_x_of_x_label).to include_text "3/5"

      # go back to the second student
      Speedgrader.click_next_or_prev_student :previous
      expect(Speedgrader.selected_student).to include_text(@students[1].name)
      expect(Speedgrader.student_x_of_x_label).to include_text "2/5"
    end

    it "arrows wrap around to start when you reach the last student", priority: "1" do
      # click next to third student
      Speedgrader.click_next_student_btn
      Speedgrader.click_next_student_btn
      expect(Speedgrader.selected_student).to include_text(@students[2].name)
      expect(Speedgrader.student_x_of_x_label).to include_text "3/5"

      # wrap around to the first student
      Speedgrader.click_next_student_btn
      Speedgrader.click_next_student_btn
      Speedgrader.click_next_student_btn
      expect(Speedgrader.selected_student).to include_text(@students[0].name)
      expect(Speedgrader.student_x_of_x_label).to include_text "1/5"
    end

    it "list all students", priority: "1" do
      Speedgrader.click_students_dropdown
      3.times { |num| expect(Speedgrader.student_dropdown_menu).to include_text(@students[num].name) }
    end

    it "list alias when hide student name is selected", priority: "2" do
      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names

      expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }
      Speedgrader.click_students_dropdown
      (1..3).each { |num| expect(Speedgrader.student_dropdown_menu).to include_text("Student #{num}") }
    end

    # speedgrader student dropdown shows assignment submission status symbols next to student names
    it "has symbols indicating assignment submission status", priority: "1" do
      # grade 2 out of 3 assignments; student3 wont be submitting and wont be graded as well
      @assignment.grade_student(@students[0], grade: 15, grader: @teacher)
      @assignment.grade_student(@students[1], grade: 10, grader: @teacher)

      # resubmit only as student_2
      Timecop.travel(1.hour.from_now) do
        @assignment.submit_homework(
          @students[1],
          submission_type: "online_text_entry",
          body: "re-submitting!"
        )

        refresh_page
        Speedgrader.click_students_dropdown
        student_options = Speedgrader.student_dropdown_menu.find_elements(tag_name: "li")

        graded = %w[resubmitted graded not_submitted]
        3.times { |num| expect(student_options[num]).to have_class(graded[num]) }
      end
    end
  end

  context "submissions" do
    let(:resubmit_with_text) do
      @assignment_for_course.submit_homework(
        @students.first, submission_type: "online_text_entry", body: "hello!"
      )
    end

    # set up course, users and an assignment
    before(:once) do
      @assignment_for_course = @course.assignments.create!(
        title: "Assignment A",
        submission_types: "online_text_entry,online_upload"
      )
    end

    def submit_with_attachment
      @file_attachment = attachment_model(content_type: "application/pdf", context: @students.first)
      @submission_for_student = @assignment_for_course.submit_homework(
        @students.first,
        submission_type: "online_upload",
        attachments: [@file_attachment]
      )
    end

    it "deleted comment is not visible", priority: "1" do
      submit_with_attachment
      @comment_text = "First comment"
      @comment = @submission_for_student.add_comment(author: @teacher, comment: @comment_text)

      # page object

      # student can see the new comment
      user_session(@students.first)
      SubmissionDetails.visit_as_student(@course.id, @assignment_for_course.id, @students.first.id)
      expect(SubmissionDetails.comment_text_by_id(@comment.id)).to eq @comment_text

      @comment.destroy

      # student cannot see the deleted comment
      SubmissionDetails.visit_as_student(@course.id, @assignment_for_course.id, @students.first.id)
      expect(SubmissionDetails.comment_list_div).not_to contain_css("#submission_comment_#{@comment.id}")
    end

    it "displays the correct file submission in the right sidebar", priority: "1" do
      submit_with_attachment
      user_session(@teacher)

      Speedgrader.visit(@course.id, @assignment_for_course.id)
      expect(Speedgrader.submission_file_name.text).to eq @attachment.filename
    end

    it "displays submissions in order in the submission dropdown", priority: "1" do
      Timecop.freeze(1.hour.ago) { submit_with_attachment }
      resubmit_with_text
      user_session(@teacher)

      Speedgrader.visit(@course.id, @assignment_for_course.id)
      Speedgrader.click_submissions_to_view
      Speedgrader.select_option_submission_to_view("0")
      expect(Speedgrader.submission_file_name.text).to eq @attachment.filename
    end

    it "identifies the proxy submitter in the submission dropdown" do
      Timecop.freeze(1.hour.ago) { submit_with_attachment }
      resubmit_with_text
      Account.site_admin.enable_feature!(:proxy_file_uploads)
      teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      RoleOverride.create!(
        permission: "proxy_assignment_submission",
        enabled: true,
        role: teacher_role,
        account: @course.root_account
      )
      file_attachment = attachment_model(content_type: "application/pdf", context: @students.first)
      submission = @assignment_for_course.submit_homework(@students.first, submission_type: "online_upload", attachments: [file_attachment])
      @teacher.update!(short_name: "Test Teacher")
      submission.update!(proxy_submitter: @teacher)
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment_for_course.id)
      expect(Speedgrader.submission_to_view_dropdown).to include_text("(Test Teacher)")
    end

    it "identifies the proxy submitter in the submission details tray with only a single submission" do
      Account.site_admin.enable_feature!(:proxy_file_uploads)
      teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      RoleOverride.create!(
        permission: "proxy_assignment_submission",
        enabled: true,
        role: teacher_role,
        account: @course.root_account
      )
      file_attachment = attachment_model(content_type: "application/pdf", context: @students.first)
      submission = @assignment_for_course.submit_homework(@students.first, submission_type: "online_upload", attachments: [file_attachment])
      @teacher.update!(short_name: "Test Teacher")
      submission.update!(proxy_submitter: @teacher)
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment_for_course.id)
      expect(Speedgrader.submitter_info).to include_text("by Test Teacher")
    end
  end

  context "speedgrader nav bar" do
    before :once do
      @assignment = @course.assignments.create!(
        title: "Assignment A",
        submission_types: "online_text_entry,online_upload"
      )
    end

    before do
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)
    end

    it "opens and closes keyboard shortcut modal via blue info icon", priority: "2" do
      skip "EVAL-2497 (6/10/22)"

      Speedgrader.click_settings_link
      expect(Speedgrader.keyboard_shortcuts_link).to be_displayed

      # Open shortcut modal
      Speedgrader.click_keyboard_shortcuts_link
      wait_for_animations
      expect(Speedgrader.keyboard_navigation_modal).to be_displayed

      # Close shortcut modal
      Speedgrader.keyboard_modal_close_button.click
      wait_for_animations
      expect(Speedgrader.keyboard_navigation_modal).not_to be_displayed
    end

    it "navigates to gradebook via link" do
      # make sure gradebook link works
      expect_new_page_load { Speedgrader.gradebook_link.click }
      expect(Gradebook.grid).to be_displayed
    end
  end

  context "closed grading periods" do
    before(:once) do
      account = @course.root_account
      gpg = GradingPeriodGroup.new
      gpg.account_id = account
      gpg.save!
      gpg.grading_periods.create! start_date: 3.years.ago,
                                  end_date: 1.year.ago,
                                  close_date: 1.week.ago,
                                  title: "closed grading period"
      term = @course.enrollment_term
      term.update_attribute :grading_period_group, gpg

      @assignment = @course.assignments.create! name: "aaa", due_at: 2.years.ago
    end

    before do
      user_session(@teacher)
    end

    it "disables grading" do
      Speedgrader.visit(@course.id, @assignment.id)
      expect(f("#grade_container input")["readonly"]).to eq "true"
      expect(f("#closed_gp_notice")).to be_displayed
    end
  end

  private

  def grader_speedgrader_assignment(grade1, grade2)
    Speedgrader.visit(@course.id, @assignment.id)
    Speedgrader.wait_for_grade_input

    expect(Speedgrader.grade_input).to have_value grade1
    Speedgrader.click_next_student_btn
    expect(Speedgrader.grade_input).to have_value grade2
  end

  def create_assignment_type_and_grade(assignment_type, grade1, grade2)
    @assignment = create_assignment_with_type(assignment_type)
    @assignment.grade_student @students[0], grade: grade1, grader: @teacher
    @assignment.grade_student @students[1], grade: grade2, grader: @teacher
  end
end
