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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../../helpers/groups_common"

describe "Gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GroupsCommon

  before(:once) do
    gradebook_data_setup
  end

  before do
    user_session(@teacher)
  end

  it "shows unpublished assignments", priority: "1" do
    assignment = @course.assignments.create! title: "unpublished"
    assignment.unpublish
    Gradebook.visit(@course)
    expect(f("#gradebook_grid .container_1 .slick-header")).to include_text(assignment.title)
  end

  it "hides 'not-graded' assignments", priority: "1" do
    Gradebook.visit(@course)

    expect(f(".slick-header-columns")).not_to include_text(@ungraded_assignment.title)
  end

  it "splits student first and last name when view option is toggled on" do
    Account.site_admin.enable_feature!(:gradebook_show_first_last_names)
    @course.account.settings[:allow_gradebook_show_first_last_names] = true
    @course.account.save!

    Gradebook.visit(@course)
    Gradebook.open_gradebook_menu("View")
    Gradebook.split_student_names_option.click

    expect(f("span[data-testid='first-name-header']").text).to eql("Student First Name")
    expect(f("span[data-testid='student-column-header']").text).to eql("Student Last Name")

    expect(Gradebook.student_column_cell_element(0, 0)).to include_text(@student_1.last_name)
    expect(Gradebook.student_column_cell_element(1, 1)).to include_text(@student_1.first_name)
  end

  context "search" do
    context "redesign" do
      before do
        Gradebook.visit(@course)
      end

      it "filters students" do
        expect(Gradebook.fetch_student_names.size).to eq(@all_students.size)
        f("#gradebook-student-search input").send_keys @course.students[0].name
        f("#gradebook-student-search input").send_keys(:return)
        expect(Gradebook.fetch_student_names).to match_array [@course.students[0].name]
      end

      it "filters assignments" do
        graded_assignments = @course.assignments.where(grading_type: "points").where.not(points_possible: nil)
        expect(Gradebook.fetch_assignment_names.size).to eq(graded_assignments.size)
        f("#gradebook-assignment-search input").send_keys(@course.assignments[0].name)
        f("#gradebook-assignment-search input").send_keys(:return)
        expect(Gradebook.fetch_assignment_names).to match_array [@course.assignments[0].name]
      end

      it "filters students and assignments" do
        f("#gradebook-student-search input").send_keys(@course.students[1].name)
        f("#gradebook-student-search input").send_keys(:return)
        f("#gradebook-assignment-search input").send_keys(@course.assignments[1].name)
        f("#gradebook-assignment-search input").send_keys(:return)
        expect(Gradebook.fetch_student_names).to match_array [@course.students[1].name]
        expect(Gradebook.fetch_assignment_names).to match_array [@course.assignments[1].name]
      end

      it "filters by multiple students and assignments" do
        f("#gradebook-student-search input").send_keys(@course.students[0].name)
        f("#gradebook-student-search input").send_keys(:return)
        f("#gradebook-student-search input").send_keys(@course.students[1].name)
        f("#gradebook-student-search input").send_keys(:return)
        f("#gradebook-assignment-search input").send_keys(@course.assignments[0].name)
        f("#gradebook-assignment-search input").send_keys(:return)
        f("#gradebook-assignment-search input").send_keys(@course.assignments[1].name)
        f("#gradebook-assignment-search input").send_keys(:return)
        expect(Gradebook.fetch_student_names).to match_array [@course.students[0].name, @course.students[1].name]
        expect(Gradebook.fetch_assignment_names).to match_array [@course.assignments[0].name, @course.assignments[1].name]
      end
    end
  end

  it "validates correct number of students showing up in gradebook", priority: "1" do
    Gradebook.visit(@course)
    expect(Gradebook.fetch_student_names.size).to eq(@course.students.count)
  end

  it "shows students sorted by their sortable_name", priority: "1" do
    Gradebook.visit(@course)
    expect(Gradebook.fetch_student_names).to eq @all_students.map(&:name)
  end

  context "unpublished course" do
    before do
      @course.claim!
      Gradebook.visit(@course)
    end

    it "allows editing grades", priority: "1" do
      cell = Gradebook::Cells.grading_cell(@student_1, @first_assignment)
      expect(f(".gradebook-cell", cell)).to include_text "10"
      cell.click
      expect(Gradebook::Cells.grading_cell_input(@student_1, @first_assignment)).not_to be_blank
    end
  end

  context "view ungraded as 0" do
    before do
      @course.account.enable_feature!(:view_ungraded_as_zero)
      Gradebook.visit(@course)
    end

    it "persists its value when changed in the View menu" do
      Gradebook.select_view_dropdown
      Gradebook.select_view_ungraded_as_zero
      Gradebook.select_view_dropdown

      expect(Gradebook.view_ungraded_as_zero).to contain_css("svg[name='IconCheck']")

      driver.navigate.refresh
      Gradebook.select_view_dropdown

      expect(Gradebook.view_ungraded_as_zero).to contain_css("svg[name='IconCheck']")
    end

    it 'toggles the presence of "Ungraded as 0" in the Total grade column header' do
      expect(Gradebook.assignment_header_cell_element("Total").text).not_to include("UNGRADED AS 0")

      Gradebook.select_view_dropdown
      Gradebook.select_view_ungraded_as_zero

      expect(Gradebook.assignment_header_cell_element("Total").text).to include("UNGRADED AS 0")
    end

    it 'toggles the presence of "Ungraded as 0" in assignment group grade column header' do
      expect(Gradebook.assignment_header_cell_element("first assignment group").text).not_to include("UNGRADED AS 0")

      Gradebook.select_view_dropdown
      Gradebook.select_view_ungraded_as_zero

      expect(Gradebook.assignment_header_cell_element("first assignment group").text).to include("UNGRADED AS 0")
    end

    it "toggles which version of the total grade is displayed for a student" do
      expect(Gradebook::Cells.get_total_grade(@student_1)).to eq "100% A"

      Gradebook.select_view_dropdown
      Gradebook.select_view_ungraded_as_zero

      expect(Gradebook::Cells.get_total_grade(@student_1)).to eq "18.75% F"
    end

    it "does not change the grades in the backend" do
      expect(Gradebook.scores_api(@course).first[:score]).to eq 100.0

      Gradebook.select_view_dropdown
      Gradebook.select_view_ungraded_as_zero

      expect(Gradebook.scores_api(@course).first[:score]).to eq 100.0
    end
  end

  it "gradebook settings modal is displayed when gradebook settings button is clicked",
     priority: "1" do
    Gradebook.visit(@course)

    Gradebook.gradebook_settings_btn_select
    expect(f('[aria-label="Gradebook Settings"]')).to be_displayed
  end

  it "late policies tab is selected by default",
     priority: "1" do
    Gradebook.visit(@course)

    Gradebook.gradebook_settings_btn_select
    expect(f('[aria-label="Gradebook Settings"]')).to be_displayed
    late_policies_tab = fj('[aria-label="Gradebook Settings"] [role="tablist"] [role="tab"]:first')
    expect(late_policies_tab.attribute("aria-selected")).to eq("true")
  end

  it "focus is returned to gradebook settings button when modal is closed", priority: "1" do
    Gradebook.visit(@course)

    Gradebook.gradebook_settings_btn_select
    expect(f('[aria-label="Gradebook Settings"]')).to be_displayed

    f("#gradebook-settings-cancel-button").click
    expect { driver.switch_to.active_element }.to become(f('[data-testid="gradebook-settings-button"]'))
  end

  it "includes student view student for grading" do
    @fake_student1 = @course.student_view_student
    @fake_student1.update_attribute :workflow_state, "deleted"
    @fake_student2 = @course.student_view_student
    @fake_student1.update_attribute :workflow_state, "registered"
    @fake_submission = @first_assignment.submit_homework(@fake_student1, body: "fake student submission")

    Gradebook.visit(@course)

    fakes = [@fake_student1.name, @fake_student2.name]
    expect(ff(".student-name").last(2).map(&:text)).to eq fakes

    # test students will always be last
    f(".slick-header-column").click
    expect(ff(".student-name").last(2).map(&:text)).to eq fakes
  end

  it "excludes non-graded group assignment in group total" do
    gc = group_category
    graded_assignment = @course.assignments.create!({
                                                      title: "group assignment 1",
                                                      due_at: 1.week.from_now,
                                                      points_possible: 10,
                                                      submission_types: "online_text_entry",
                                                      assignment_group: @group,
                                                      group_category: gc,
                                                      grade_group_students_individually: true
                                                    })
    group_assignment = @course.assignments.create!({
                                                     title: "group assignment 2",
                                                     due_at: 1.week.from_now,
                                                     points_possible: 0,
                                                     submission_types: "not_graded",
                                                     assignment_group: @group,
                                                     group_category: gc,
                                                     grade_group_students_individually: true
                                                   })
    project_group = group_assignment.group_category.groups.create!(name: "g1", context: @course)
    project_group.users << @student_1
    graded_assignment.grade_student @student_1, grade: 10, grader: @teacher # 10 points possible
    group_assignment.grade_student @student_1, grade: 2, grader: @teacher # 0 points possible

    Gradebook.visit(@course)
    group_grade = f("#gradebook_grid .container_1 .slick-row:nth-child(1) .assignment-group-cell .percentage")
    total_grade = f("#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .percentage")
    expect(group_grade).to include_text("100%") # otherwise 108%
    expect(total_grade).to include_text("100%") # otherwise 108%
  end

  it "hides assignment mute warning in total column for 'not_graded', muted assignments" do
    assignment = @course.assignments.create!({
                                               title: "Non Graded Assignment",
                                               due_at: 1.week.from_now,
                                               points_possible: 10,
                                               submission_types: "not_graded"
                                             })

    assignment.mute!
    Gradebook.visit(@course)

    expect(f("body")).not_to contain_css(".total-cell .icon-off")
  end

  context "downloading and uploading submissions" do
    it "redirects to the submissions upload page after uploading submissions" do
      # Given I have a student with an uploaded submission
      a = attachment_model(context: @student_2, content_type: "text/plain")
      @first_assignment.submit_homework(@student_2, submission_type: "online_upload", attachments: [a])

      # When I go to the gradebook
      Gradebook.visit(@course)

      # chrome fails to find the download submissions link because it does not fit normal screen

      # And I click the download submissions button
      Gradebook.click_assignment_header_menu_element(@first_assignment.id, "download submissions")

      # And I close the download submissions dialog
      fj("div:contains('Download Assignment Submissions'):first .ui-dialog-titlebar-close").click

      # And I click the dropdown menu on the assignment again
      Gradebook.click_assignment_header_menu(@first_assignment.id)

      # And I click the re-upload submissions link
      f('[data-menu-item-id="reupload-submissions"]').click

      # When I attach a submissions zip file
      fixture_file = Rails.root.join("spec/fixtures/files/submissions.zip")
      f("input[name=submissions_zip]").send_keys(fixture_file)

      # And I upload it
      expect_new_page_load do
        fj('button:contains("Upload Files")').click
      end

      run_jobs
      refresh_page

      # Then I should see a message indicating the file was processed
      expect(f("#content")).to include_text "Done! We took the files you uploaded"
    end
  end

  it "shows late submissions" do
    Gradebook.visit(@course)
    expect(f("body")).not_to contain_css(".late")

    @student_3_submission.write_attribute(:cached_due_date, 1.week.ago)
    @student_3_submission.save!
    Gradebook.visit(@course)

    expect(ff(".late")).to have_size(1)
  end

  it "hides the speedgrader link for large courses", priority: "2" do
    pending("TODO: Refactor this and add it back as part of CNVS-32440")
    allow(@course).to receive(:large_roster?).and_return(true)

    Gradebook.visit(@course)

    f(".Gradebook__ColumnHeaderAction button").click
    expect(f(".gradebook-header-menu")).not_to include_text("SpeedGrader")
  end

  context "grading quiz submissions" do
    # set up course and users
    let(:test_course) { course_factory }
    let(:teacher)     { user_factory(active_all: true) }
    let(:student)     { user_factory(active_all: true) }
    let!(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, "TeacherEnrollment", enrollment_state: "active")
      test_course.enroll_user(student, "StudentEnrollment", enrollment_state: "active")
    end
    # create quiz with essay question
    let(:essay_quiz_question) do
      {
        question_name: "Short Essay",
        points_possible: 10,
        question_text: "Write an essay",
        question_type: "essay_question"
      }
    end
    let(:essay_quiz) { test_course.quizzes.create(title: "Essay Quiz") }
    let(:essay_question) do
      essay_quiz.quiz_questions.create!(question_data: essay_quiz_question)
      essay_quiz.workflow_state = "available"
      essay_quiz.save!
      essay_quiz
    end
    # create quiz with file upload question
    let(:file_upload_question) do
      {
        question_name: "File Upload",
        points_possible: 5,
        question_text: "Upload a file",
        question_type: "file_upload_question"
      }
    end
    let(:file_upload_quiz) { test_course.quizzes.create(title: "File Upload Quiz") }
    let(:file_question) do
      file_upload_quiz.quiz_questions.create!(question_data: file_upload_question)
      file_upload_quiz.workflow_state = "available"
      file_upload_quiz.save!
      file_upload_quiz
    end
    # generate submissions
    let(:essay_submission) { essay_question.generate_submission(student) }
    let(:essay_text) { { "question_#{essay_question.id}": "Essay Response!" } }
    let(:file_submission) { file_question.generate_submission(student) }

    it 'displays the "needs grading" icon for essay questions', priority: "1" do
      essay_submission.complete!(essay_text)
      user_session(teacher)

      Gradebook.visit(test_course)
      expect(f("#gradebook_grid .icon-not-graded")).to be_truthy
    end

    it 'displays the "needs grading" icon for file_upload questions', priority: "1" do
      file_submission.attachments.create!({
                                            filename: "doc.doc",
                                            display_name: "doc.doc",
                                            user: @user,
                                            uploaded_data: dummy_io
                                          })
      file_submission.complete!
      user_session(teacher)

      Gradebook.visit(test_course)
      expect(f("#gradebook_grid .icon-not-graded")).to be_truthy
    end

    it 'removes the "needs grading" icon when graded manually', priority: "1" do
      essay_submission.complete!(essay_text)
      user_session(teacher)

      Gradebook.visit(test_course)
      # in order to get into edit mode with an icon in the way, a total of 3 clicks are needed
      grading_cell = Gradebook::Cells.grading_cell(student, essay_quiz.assignment)
      grading_cell.click

      Gradebook::Cells.edit_grade(student, essay_quiz.assignment, 10)
      # Re-select element in case it's gone stale
      grading_cell = Gradebook::Cells.grading_cell(student, essay_quiz.assignment)
      expect(grading_cell).not_to contain_css(".icon-not-graded")
    end
  end

  context "export" do
    it "exports the gradebook and displays a flash message when successfully started" do
      Gradebook.visit(@course)
      Gradebook.action_menu.click
      Gradebook.action_menu_item_selector("export").click

      expect_flash_message :success, "Gradebook export has started. This may take a few minutes."
    end
  end
end
