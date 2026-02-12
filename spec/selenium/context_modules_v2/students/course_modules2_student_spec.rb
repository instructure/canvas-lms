# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules2_index_page"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../shared_examples/course_modules2_shared"

describe "context modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray

  before :once do
    modules2_student_setup
  end

  before do
    user_session(@student)
  end

  it "shows the modules index page" do
    go_to_modules
    expect(student_modules_container).to be_displayed
  end

  context "module expand and collapse" do
    it "shows all modules items when module expanded" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)
      expand_btn = module_header_expand_toggles[0]
      expect(expand_btn).to be_displayed
      expand_btn.click

      # module should be expanded
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles[0].text).to eq(@module_item1.title)
      expect(module_item_titles.count).to eq(2)
    end

    it "can collapse module that has been expanded" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)
      module_header_expand_toggles[0].click

      # module should be expanded
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles.count).to eq(2)

      # collapse the module
      module_header_expand_toggles[0].click

      # module should be collapsed again
      expect(page_body).not_to contain_css(module_item_title_selector)
    end

    it "retains module expand status" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)
      expand_btn = module_header_expand_toggles[0]
      expect(expand_btn).to be_displayed
      expand_btn.click

      # first module should be expanded
      expect(module_item_titles.count).to eq(2)
      expect(module_item_titles[0]).to be_displayed

      # reload page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # first module should be expanded
      expect(module_item_titles.count).to eq(2)
      expect(module_item_titles[0]).to be_displayed
    end

    it "expands all modules" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click
      wait_for_ajaximations

      # all modules should be expanded
      expect(module_item_titles.count).to eq(8)
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles[1]).to be_displayed
      expect(module_item_titles[2]).to be_displayed
      expect(module_item_titles[3]).to be_displayed
      expect(screenreader_alert).to include_text("All module items loaded")
    end

    it "collapses all modules" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      # all modules should be expanded
      expect(module_item_titles.count).to eq(8)

      # collapse all modules
      collapse_all_modules_button.click

      # all modules should be collapsed again
      expect(page_body).not_to contain_css(module_item_title_selector)
    end

    it "expands all modules is retained on refresh" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      go_to_modules
      expect(student_modules_container).to be_displayed

      # all modules should be expanded
      expect(module_item_titles.count).to eq(8)
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles[1]).to be_displayed
      expect(module_item_titles[2]).to be_displayed
      expect(module_item_titles[3]).to be_displayed
    end

    it "collapses all modules is retained on refresh" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      # all modules should be expanded
      expect(module_item_titles.count).to eq(8)

      # collapse all modules
      collapse_all_modules_button.click

      # all modules should be collapsed again
      expect(page_body).not_to contain_css(module_item_title_selector)

      go_to_modules
      expect(student_modules_container).to be_displayed
      expect(page_body).not_to contain_css(module_item_title_selector)
    end
  end

  context "course home page" do
    before do
      @course.default_view = "modules"
      @course.save

      @course.root_account.enable_feature!(:modules_page_rewrite_student_view)
    end

    it "shows the new modules" do
      visit_course(@course)
      wait_for_ajaximations

      expect(f('[data-testid="modules-rewrite-student-container"]')).to be_displayed
    end
  end

  context "missing assignment button" do
    it "doesn't show the missing assignment button when there is no missing assignment" do
      go_to_modules
      expect(student_modules_container).to be_displayed
      # missing assignment button should not be displayed
      expect(missing_assignment_button_exists?).to be_falsey
    end

    it "shows the missing assignment button when there is a missing assignment" do
      @missing_assignment = @course.assignments.create!(title: "Missing Assignment",
                                                        submission_types: "online_text_entry",
                                                        points_possible: 10,
                                                        workflow_state: "published",
                                                        due_at: 2.days.ago)
      @missing_module_item = @module1.add_item(type: "assignment", id: @missing_assignment.id)
      go_to_modules
      expect(student_modules_container).to be_displayed
      expect(missing_assignment_button_exists?).to be_truthy
      expect(missing_assignment_button.text).to eq("1 Missing Assignment")
    end

    it "navigates to the assignments index page when clicked" do
      @missing_assignment = @course.assignments.create!(title: "Missing Assignment",
                                                        submission_types: "online_text_entry",
                                                        points_possible: 10,
                                                        workflow_state: "published",
                                                        due_at: 2.days.ago)
      @missing_module_item = @module1.add_item(type: "assignment", id: @missing_assignment.id)
      go_to_modules
      expect(student_modules_container).to be_displayed
      expect(missing_assignment_button_exists?).to be_truthy
      missing_assignment_button.click
      expect(driver.current_url).to include("/courses/#{@course.id}/assignments")
    end
  end

  context "assignments due button" do
    it "shows the number of assignments due this week if there are any" do
      # Create assignments due this week.  Force a date so there are no boundary issues
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @due_assignment1 = @course.assignments.create!(title: "Due Assignment 1",
                                                       submission_types: "online_text_entry",
                                                       points_possible: 10,
                                                       workflow_state: "published",
                                                       due_at: 2.days.from_now)
        @due_assignment2 = @course.assignments.create!(title: "Due Assignment 2",
                                                       submission_types: "online_text_entry",
                                                       points_possible: 10,
                                                       workflow_state: "published",
                                                       due_at: 3.days.from_now)
        @module1.add_item(type: "assignment", id: @due_assignment1.id)
        @module1.add_item(type: "assignment", id: @due_assignment2.id)

        go_to_modules
        expect(student_modules_container).to be_displayed
        expect(assignments_due_button_exists?).to be_truthy

        expect(assignments_due_button.text).to eq("2 Assignments Due This Week")
      end
    end

    it "does not show the assignments due button if there are no assignments due this week" do
      # Create assignment due next week
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @future_assignment = @course.assignments.create!(title: "Future Assignment",
                                                         submission_types: "online_text_entry",
                                                         points_possible: 10,
                                                         workflow_state: "published",
                                                         due_at: 2.weeks.from_now)
        @module1.add_item(type: "assignment", id: @future_assignment.id)
        go_to_modules
        expect(student_modules_container).to be_displayed
        expect(assignments_due_button_exists?).to be_falsey
      end
    end

    it "navigates to the assignments index page when assignments due button is clicked" do
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @due_assignment = @course.assignments.create!(title: "Due Assignment",
                                                      submission_types: "online_text_entry",
                                                      points_possible: 10,
                                                      workflow_state: "published",
                                                      due_at: 1.day.from_now)
        @module1.add_item(type: "assignment", id: @due_assignment.id)
        go_to_modules
        expect(student_modules_container).to be_displayed
        expect(assignments_due_button_exists?).to be_truthy
        click_assignments_due_button
        expect(driver.current_url).to include("/courses/#{@course.id}/assignments")
      end
    end

    it "does not include assignments due after this week in the assignments due count" do
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @due_this_week = @course.assignments.create!(title: "Due This Week",
                                                     submission_types: "online_text_entry",
                                                     points_possible: 10,
                                                     workflow_state: "published",
                                                     due_at: 2.days.from_now)
        @due_later = @course.assignments.create!(title: "Due Later",
                                                 submission_types: "online_text_entry",
                                                 points_possible: 10,
                                                 workflow_state: "published",
                                                 due_at: 2.weeks.from_now)
        @module1.add_item(type: "assignment", id: @due_this_week.id)
        @module1.add_item(type: "assignment", id: @due_later.id)
        go_to_modules
        expect(student_modules_container).to be_displayed
        expect(assignments_due_button_exists?).to be_truthy
        expect(assignments_due_button.text).to eq("1 Assignment Due This Week")
      end
    end

    it "includes due assignments of all types of learning objects in the due assignments count" do
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @due_quiz = quiz_model(course: @course, title: "Due Quiz", workflow_state: "available")
        @due_quiz.generate_quiz_data
        @due_quiz.due_at = 2.days.from_now
        @due_quiz.quiz_questions.create!(
          question_data: {
            name: "Quiz Questions",
            question_type: "fill_in_multiple_blanks_question",
            question_text: "[color1]",
            answers: [{ text: "one", id: 1 }, { text: "two", id: 2 }, { text: "three", id: 3 }],
            points_possible: 1
          }
        )
        @due_quiz.save!
        graded_assignment =
          @course.assignments.create!(
            title: "assignment",
            points_possible: 10,
            due_at: 2.days.from_now,
            submission_types: "online_text_entry",
            only_visible_to_overrides: false
          )
        @due_discussion = @course.discussion_topics.create!(title: "Graded Discussion", workflow_state: "active", assignment: graded_assignment)
        @due_assignment = @course.assignments.create!(title: "Due Assignment", submission_types: "online_text_entry", points_possible: 10, workflow_state: "published", due_at: 2.days.from_now)
        @module1.add_item(type: "quiz", id: @due_quiz.id)
        @module1.add_item(type: "discussion_topic", id: @due_discussion.id)
        @module1.add_item(type: "assignment", id: @due_assignment.id)

        go_to_modules
        expect(student_modules_container).to be_displayed
        expect(assignments_due_button_exists?).to be_truthy
        expect(assignments_due_button.text).to eq("3 Assignments Due This Week")
      end
    end
  end

  context "module header icons and progress" do
    it "shows Completed all items if it has complete all items requirements" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" } }
      @module1.save!
      go_to_modules
      expect(module_header_complete_all_pill(@module1.id).text).to include("Complete all items")
      get_student_views_assignment(@course.id, @assignment.id)
      go_to_modules

      expect(module_header_complete_all_pill(@module1.id).text).to include("Completed all items")
    end

    it "shows Completed 1 item if it has complete one item requirement" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" }, @module_item2.id => { type: "must_view" } }
      @module1.requirement_count = 1
      @module1.save!
      go_to_modules
      expect(module_header_complete_all_pill(@module1.id).text).to include("Complete 1 item")
      get_student_views_assignment(@course.id, @assignment.id)
      go_to_modules

      expect(module_header_complete_all_pill(@module1.id).text).to include("Completed 1 item")
    end

    it "shows Completed icon if item is complete" do
      @module1.completion_requirements = {
        @module_item1.id => { type: "must_view" }
      }
      @module1.save!
      go_to_modules
      module_header_expand_toggles[0].click
      get_student_views_assignment(@course.id, @assignment.id)
      go_to_modules
      expect(module_item_status_icon(@module_item1.id).text).to eq("Complete")
    end

    it "shows Missing icon if item is Missing" do
      @missing_assignment = @course.assignments.create!(
        title: "Overdue Assignment",
        submission_types: "online_text_entry",
        points_possible: 10,
        workflow_state: "published",
        due_at: 2.days.ago
      )

      @missing_module_item = @module1.add_item(type: "assignment", id: @missing_assignment.id)
      go_to_modules
      module_header_expand_toggles[0].click
      expect(module_item_status_icon(@missing_module_item.id).text).to eq("Missing")
    end

    it "shows Assignment icon and the text 'Assignment' if assignment" do
      @assignment = @course.assignments.create!(
        title: "Assignment",
        submission_types: "online_text_entry",
        points_possible: 10,
        workflow_state: "published",
        due_at: 2.days.from_now
      )
      go_to_modules
      module_header_expand_toggles[0].click
      @module_item = @module1.add_item(type: "assignment", id: @assignment.id)
      go_to_modules
      assignment_item = module_item_by_id(@module_item.id)
      expect(assignment_item.text).to include("Assignment")

      assignment_icon = module_item_assignment_icon(@module_item.id)
      expect(assignment_icon).to be_displayed
    end

    it 'shows Quiz icon and the text "Quiz" if a classic quiz' do
      classic_quiz = quiz_model(course: @course, title: "Classic Quiz", workflow_state: "available")
      classic_quiz.generate_quiz_data
      classic_quiz.quiz_questions.create!(
        question_data: {
          name: "Classic Q",
          question_type: "true_false_question",
          question_text: "Is this classic?",
          answers: [{ text: "true" }, { text: "false" }],
          points_possible: 1
        }
      )
      classic_quiz.save!
      classic_module_item = @module1.add_item(type: "quiz", id: classic_quiz.id)
      go_to_modules
      module_header_expand_toggles[0].click
      quiz_item = module_item_by_id(classic_module_item.id)
      expect(quiz_item.text).to include("Quiz")

      quiz_icon = module_item_quiz_icon(classic_module_item.id)
      expect(quiz_icon).to be_displayed
    end

    it 'shows Quiz icon and the text "Quiz" if a new quiz' do
      new_quiz = @course.quizzes.create!(title: "New Quiz", due_at: 1.week.from_now, quiz_type: "survey", workflow_state: "available")
      new_quiz_module_item = @module1.add_item(type: "quiz", id: new_quiz.id)
      go_to_modules
      module_header_expand_toggles[0].click
      new_quiz_item = module_item_by_id(new_quiz_module_item.id)
      expect(new_quiz_item.text).to include("New Quiz")

      quiz_icon = module_item_quiz_icon(new_quiz_module_item.id)
      expect(quiz_icon).to be_displayed
    end

    it 'shows Page icon and the text "Page" if a wiki page' do
      wiki_page = @course.wiki_pages.create!(
        title: "Test Page",
        body: "Content here"
      )
      page_module_item = @module1.add_item(type: "wiki_page", id: wiki_page.id)
      go_to_modules
      module_header_expand_toggles[0].click
      page_item = module_item_by_id(page_module_item.id)
      expect(page_item.text).to include("Page")

      page_icon = module_item_page_icon(page_module_item.id)
      expect(page_icon).to be_displayed
    end

    it 'shows Discussion icon and the text "Discussion" if a discussion' do
      discussion = @course.discussion_topics.create!(
        title: "Test Discussion",
        workflow_state: "active",
        assignment: @course.assignments.create!(
          title: "Graded Discussion",
          points_possible: 10,
          submission_types: "discussion_topic",
          workflow_state: "published"
        )
      )
      discussion_module_item = @module1.add_item(type: "discussion_topic", id: discussion.id)
      go_to_modules
      module_header_expand_toggles[0].click
      discussion_item = module_item_by_id(discussion_module_item.id)
      expect(discussion_item.text).to include("Discussion")

      discussion_icon = module_item_discussion_icon(discussion_module_item.id)
      expect(discussion_icon).to be_displayed
    end

    it "shows a header if it is a header" do
      header_module_item = @module1.add_item(
        type: "context_module_sub_header",
        title: "This is a header"
      )
      header_module_item.workflow_state = "active"
      header_module_item.save!
      @module1.save!
      go_to_modules
      module_header_expand_toggles[0].click
      header_item = module_item_by_id(header_module_item.id)

      expect(header_item.text).to include("This is a header")
    end

    it 'shows the external URL icon and text "External Url" if that item type' do
      external_url_item = @module1.add_item(
        type: "external_url",
        url: "http://example.com",
        title: "example"
      )
      external_url_item.workflow_state = "active"
      external_url_item.save!
      go_to_modules
      module_header_expand_toggles[0].click
      url_item = module_item_by_id(external_url_item.id)
      expect(url_item.text).to include("External Url")

      url_icon = module_item_url_icon(external_url_item.id)
      expect(url_icon).to be_displayed
    end

    it 'shows the external Tools icon and the text "External Tool" if that item type' do
      external_tool_assignment = @course.assignments.create!(
        title: "LTI Tool",
        submission_types: "external_tool",
        workflow_state: "published"
      )
      external_tool_module_item = @module1.add_item(
        type: "assignment",
        id: external_tool_assignment.id
      )
      go_to_modules
      module_header_expand_toggles[0].click
      tool_item = module_item_by_id(external_tool_module_item.id)
      expect(tool_item.text).to include("LTI Tool")
    end

    it "validates that item is indented when it has a non-zero indent" do
      indented_module_item = @module1.add_item(
        type: "assignment",
        id: @assignment.id,
        indent: 2 # Indent level 2 = 40px
      )
      go_to_modules
      module_header_expand_toggles[0].click
      item_indent = module_item_indent(indented_module_item.id)
      expect(item_indent).to match("padding: 0px 0px 0px 40px;")
    end

    it "shows locked icon if locked due to availability date" do
      unlock_time = 2.days.from_now.change(min: 0, sec: 0)
      @module1.update!(unlock_at: unlock_time)
      go_to_modules
      expect(module_header_locked_icon(@module1.id)).to be_displayed
      expect(module_header_locked_icon(@module1.id).text).to include("Locked")
    end

    it "includes Missing assignments icon with one missing assignment" do
      @missing_assignment = @course.assignments.create!(title: "Missing Assignment", submission_types: "online_text_entry", points_possible: 10, workflow_state: "published", due_at: 2.days.ago)
      @module1.add_item(type: "assignment", id: @missing_assignment.id)
      go_to_modules
      expect(module_header_missing_pill(@module1.id).text).to include("1 Missing Assignment")
    end

    it "includes Missing assignments icon with more than one missing assignment" do
      @missing_assignment1 = @course.assignments.create!(title: "Missing Assignment 1", submission_types: "online_text_entry", points_possible: 10, workflow_state: "published", due_at: 2.days.ago)
      @missing_assignment2 = @course.assignments.create!(title: "Missing Assignment 2", submission_types: "online_text_entry", points_possible: 10, workflow_state: "published", due_at: 2.days.ago)
      @module1.add_item(type: "assignment", id: @missing_assignment1.id)
      @module1.add_item(type: "assignment", id: @missing_assignment2.id)
      go_to_modules
      expect(module_header_missing_pill(@module1.id).text).to include("2 Missing Assignments")
    end

    it "includes Module Pre-requisites in the header" do
      @prereq_module = @course.context_modules.create!(name: "prereq module")
      @prereq_module.update!(prerequisites: [{ id: @module1.id, type: "context_module", name: @module1.name }])
      go_to_modules
      expect(module_header_prerequisites(@prereq_module.id).text).to include("Prerequisite: #{@module1.name}")
    end

    it "includes more than one Module Pre-requisite in the header" do
      @prereq_module = @course.context_modules.create!(name: "prereq module")
      @prereq_module.update!(prerequisites: [{ id: @module1.id, type: "context_module", name: @module1.name }, { id: @module2.id, type: "context_module", name: @module2.name }])
      go_to_modules
      expect(module_header_prerequisites(@prereq_module.id).text).to include("Prerequisites: #{@module1.name}, #{@module2.name}")
    end

    it "includes a Required Items progress bar if there are Complete All items" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" } }
      @module1.save!
      go_to_modules
      expect(module_progression_status_bar(@module1.id)).to be_displayed
      expect(module_progression_info_text(@module1.id)).to include("0 / 100")
    end

    it "includes a Required Items progress bar if there are Complete One items" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" }, @module_item2.id => { type: "must_view" } }
      @module1.requirement_count = 1
      @module1.save!
      go_to_modules
      expect(module_progression_status_bar(@module1.id)).to be_displayed
      expect(module_progression_info_text(@module1.id)).to include("0 / 100")
    end

    it "shows locked icon if it has a pre-requisite on a previous module" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" } }
      @module1.save!
      @module2.update!(prerequisites: [{ id: @module1.id, type: "context_module", name: @module1.name }])
      go_to_modules
      expect(module_header_locked_icon(@module2.id)).to be_displayed
    end

    it "shows a due date of the latest learning object due date when there is one" do
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @assignment.due_at = 2.days.from_now
        @assignment.save!
        @assignment2.due_at = 5.days.from_now
        @assignment2.save!
        go_to_modules
        expect(module_header_due_date(@module1.id).text).to include(@assignment2.due_at.strftime("%b %-d"))
      end
    end

    it "shows no due date in header when there are none assigned to learning objects in the module" do
      Timecop.freeze(Time.zone.local(2025, 6, 16, 10, 5, 0)) do
        @assignment.due_at = nil
        @assignment.save!
        @assignment2.due_at = nil
        @assignment2.save!
        go_to_modules
        expect(module_header_due_date_exists?(@module1.id)).to be_falsey
      end
    end

    it "navigates to the module item's URL when clicking the item container" do
      assignment = @course.assignments.create!(
        title: "Clickable assignment",
        submission_types: "online_text_entry",
        points_possible: 10,
        workflow_state: "published"
      )
      module_item = @module1.add_item(type: "assignment", id: assignment.id)

      go_to_modules
      expect(student_modules_container).to be_displayed
      module_header_expand_toggles[0].click

      module_item_by_id(module_item.id).click

      expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{assignment.id}")
    end
  end

  it_behaves_like "module unlock dates"
end
