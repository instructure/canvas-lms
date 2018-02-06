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

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'
require_relative '../../helpers/groups_common'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GroupsCommon

  before(:once) { gradebook_data_setup }
  before(:each) do
    user_session(@teacher)
  end

  it "shows unpublished assignments", priority: "1", test_id: 3253281 do
    assignment = @course.assignments.create! title: 'unpublished'
    assignment.unpublish
    Gradezilla.visit(@course)
    expect(f('#gradebook_grid .container_1 .slick-header')).to include_text(assignment.title)
  end

  it "hides 'not-graded' assignments", priority: "1", test_id: 210017 do
    Gradezilla.visit(@course)

    expect(f('.slick-header-columns')).not_to include_text(@ungraded_assignment.title)
  end

  it 'filters students', priority: "1", test_id: 210018 do
    Gradezilla.visit(@course)
    expect(Gradezilla.fetch_student_names.size).to eq(@all_students.size)
    f('.gradebook_filter input').send_keys @course.students[0].name
    sleep 1 # InputFilter has a delay
    expect(Gradezilla.fetch_student_names.size).to eq(1)
    expect(Gradezilla.fetch_student_names[0]).to eq(@course.students[0].name)
  end

  it "validates correct number of students showing up in gradebook", priority: "1", test_id: 210019 do
    Gradezilla.visit(@course)
    expect(Gradezilla.fetch_student_names.size).to eq(@course.students.count)
  end

  it "shows students sorted by their sortable_name", priority: "1", test_id: 210022 do
    Gradezilla.visit(@course)
    expect(Gradezilla.fetch_student_names).to eq @all_students.map(&:name)
  end

  context "muting/un-muting assignment" do
    before(:each) do
      Gradezilla.visit(@course)
      Gradezilla.toggle_assignment_muting(@second_assignment.id)
    end

    it "handles muting correctly", priority: "1", test_id: 164227 do
      # TODO "change test ids when Gradezilla test cases are created"
      expect(Gradezilla.total_cell_mute_icon_select).to be_displayed
      expect(@second_assignment.reload).to be_muted

      # reload the page and make sure it remembered the setting
      Gradezilla.visit(@course)
      expect(Gradezilla.total_cell_mute_icon_select).to be_displayed
    end

    it "handles un-muting correctly", priority: "1", test_id: 164227 do
      # TODO "change test ids when Gradezilla test cases are created"
      # make sure you can un-mute
      Gradezilla.toggle_assignment_muting(@second_assignment.id)

      expect(Gradezilla.content_selector).not_to contain_css(".total-cell .icon-muted")
      expect(@second_assignment.reload).not_to be_muted
    end
  end

  context "unpublished course" do
    before do
      @course.claim!
      Gradezilla.visit(@course)
    end

    it "allows editing grades", priority: "1", test_id: 210026 do
      cell = Gradezilla::Cells.grading_cell(@student_1, @first_assignment)
      expect(f('.gradebook-cell', cell)).to include_text '10'
      cell.click
      expect(Gradezilla::Cells.grading_cell_input(@student_1, @first_assignment)).not_to be_blank
    end
  end

  it 'gradebook settings modal is displayed when gradebook settings button is clicked',
     priority: '1', test_id: 164219 do
    Gradezilla.visit(@course)

    Gradezilla.gradebook_settings_btn_select
    expect(f('[aria-label="Gradebook Settings"]')).to be_displayed
  end

  it 'late policies tab is selected by default',
     priority: '1', test_id: 164220 do
    Gradezilla.visit(@course)

    Gradezilla.gradebook_settings_btn_select
    expect(f('[aria-label="Gradebook Settings"]')).to be_displayed
    late_policies_tab = fj('[aria-label="Gradebook Settings"] [role="tablist"] [role="tab"]:first')
    expect(late_policies_tab.attribute('aria-selected')).to eq('true')
  end

  it 'focus is returned to gradebook settings button when modal is closed', priority: '1', test_id: 164221 do
    Gradezilla.visit(@course)

    Gradezilla.gradebook_settings_btn_select
    expect(f('[aria-label="Gradebook Settings"]')).to be_displayed

    f('#gradebook-settings-cancel-button').click
    expect { driver.switch_to.active_element }.to become(f('#gradebook-settings-button'))
  end

  it "includes student view student for grading" do
    @fake_student1 = @course.student_view_student
    @fake_student1.update_attribute :workflow_state, "deleted"
    @fake_student2 = @course.student_view_student
    @fake_student1.update_attribute :workflow_state, "registered"
    @fake_submission = @first_assignment.submit_homework(@fake_student1, :body => 'fake student submission')

    Gradezilla.visit(@course)

    fakes = [@fake_student1.name, @fake_student2.name]
    expect(ff('.student-name').last(2).map(&:text)).to eq fakes

    # test students will always be last
    f('.slick-header-column').click
    expect(ff('.student-name').last(2).map(&:text)).to eq fakes
  end

  it "excludes non-graded group assignment in group total" do
    gc = group_category
    graded_assignment = @course.assignments.create!({
                                                      :title => 'group assignment 1',
                                                      :due_at => (Time.zone.now + 1.week),
                                                      :points_possible => 10,
                                                      :submission_types => 'online_text_entry',
                                                      :assignment_group => @group,
                                                      :group_category => gc,
                                                      :grade_group_students_individually => true
                                                    })
    group_assignment = @course.assignments.create!({
                                                     :title => 'group assignment 2',
                                                     :due_at => (Time.zone.now + 1.week),
                                                     :points_possible => 0,
                                                     :submission_types => 'not_graded',
                                                     :assignment_group => @group,
                                                     :group_category => gc,
                                                     :grade_group_students_individually => true
                                                   })
    project_group = group_assignment.group_category.groups.create!(:name => 'g1', :context => @course)
    project_group.users << @student_1
    graded_assignment.grade_student @student_1, grade: 10, grader: @teacher # 10 points possible
    group_assignment.grade_student @student_1, grade: 2, grader: @teacher # 0 points possible

    Gradezilla.visit(@course)
    group_grade = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .assignment-group-cell .percentage')
    total_grade = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .percentage')
    expect(group_grade).to include_text('100%') # otherwise 108%
    expect(total_grade).to include_text('100%') # otherwise 108%
  end

  it "hides assignment mute warning in total column for 'not_graded', muted assignments" do
    assignment = @course.assignments.create!({
                                               title: 'Non Graded Assignment',
                                               due_at: (Time.zone.now + 1.week),
                                               points_possible: 10,
                                               submission_types: 'not_graded'
                                             })

    assignment.mute!
    Gradezilla.visit(@course)

    expect(f("body")).not_to contain_css(".total-cell .icon-muted")
  end

  context "downloading and uploading submissions" do
    it "updates the dropdown menu after downloading and processes submission uploads", test_id: 3253285, priority: "1" do
      # Given I have a student with an uploaded submission
      a = attachment_model(:context => @student_2, :content_type => 'text/plain')
      @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])

      # When I go to the gradebook
      Gradezilla.visit(@course)

      # chrome fails to find the download submissions link because it does not fit normal screen
      make_full_screen

      # And I click the download submissions button
      Gradezilla.click_assignment_header_menu_element(@first_assignment.id,"download submissions")

      # And I close the download submissions dialog
      fj("div:contains('Download Assignment Submissions'):first .ui-dialog-titlebar-close").click

      # And I click the dropdown menu on the assignment again
      Gradezilla.click_assignment_header_menu(@first_assignment.id)

      # And I click the re-upload submissions link
      f('[data-menu-item-id="reupload-submissions"]').click

      # When I attach a submissions zip file
      fixture_file = Rails.root.join('spec', 'fixtures', 'files', 'submissions.zip')
      f('input[name=submissions_zip]').send_keys(fixture_file)

      # And I upload it
      expect_new_page_load do
        fj('button:contains("Upload Files")').click
      end

      # Then I will see a message indicating the file was processed
      expect(f('#content h3')).to include_text 'Attached files to the following user submissions'
    end
  end

  it "shows late submissions" do
    Gradezilla.visit(@course)
    expect(f("body")).not_to contain_css(".late")

    @student_3_submission.write_attribute(:cached_due_date, 1.week.ago)
    @student_3_submission.save!
    Gradezilla.visit(@course)

    expect(ff('.late')).to have_size(1)
  end

  it "hides the speedgrader link for large courses", priority: "2", test_id: 210099 do
    pending('TODO: Refactor this and add it back as part of CNVS-32440')
    allow(@course).to receive(:large_roster?).and_return(true)

    Gradezilla.visit(@course)

    f('.Gradebook__ColumnHeaderAction button').click
    expect(f('.gradebook-header-menu')).not_to include_text("SpeedGrader")
  end

  context 'grading quiz submissions' do
    # set up course and users
    let(:test_course) { course_factory() }
    let(:teacher)     { user_factory(active_all: true) }
    let(:student)     { user_factory(active_all: true) }
    let!(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
    end
    # create quiz with essay question
    let(:essay_quiz_question) do
      {
        question_name: 'Short Essay',
        points_possible: 10,
        question_text: 'Write an essay',
        question_type: 'essay_question'
      }
    end
    let(:essay_quiz) { test_course.quizzes.create(title: 'Essay Quiz') }
    let(:essay_question) do
      essay_quiz.quiz_questions.create!(question_data: essay_quiz_question)
      essay_quiz.workflow_state = 'available'
      essay_quiz.save!
      essay_quiz
    end
    # create quiz with file upload question
    let(:file_upload_question) do
      {
        question_name: 'File Upload',
        points_possible: 5,
        question_text: 'Upload a file',
        question_type: 'file_upload_question'
      }
    end
    let(:file_upload_quiz) { test_course.quizzes.create(title: 'File Upload Quiz') }
    let(:file_question) do
      file_upload_quiz.quiz_questions.create!(question_data: file_upload_question)
      file_upload_quiz.workflow_state = 'available'
      file_upload_quiz.save!
      file_upload_quiz
    end
    # generate submissions
    let(:essay_submission) { essay_question.generate_submission(student) }
    let(:essay_text) { {"question_#{essay_question.id}" => "Essay Response!"} }
    let(:file_submission) { file_question.generate_submission(student) }

    it 'displays the "needs grading" icon for essay questions', priority: "1", test_id: 229430 do
      essay_submission.complete!(essay_text)
      user_session(teacher)

      Gradezilla.visit(test_course)
      expect(f('#gradebook_grid .icon-not-graded')).to be_truthy
    end

    it 'displays the "needs grading" icon for file_upload questions', priority: "1", test_id: 498844 do
      file_submission.attachments.create!({
                                            :filename => "doc.doc",
                                            :display_name => "doc.doc", :user => @user,
                                            :uploaded_data => dummy_io
                                          })
      file_submission.complete!
      user_session(teacher)

      Gradezilla.visit(test_course)
      expect(f('#gradebook_grid .icon-not-graded')).to be_truthy
    end

    it 'removes the "needs grading" icon when graded manually', priority: "1", test_id: 491040 do
      essay_submission.complete!(essay_text)
      user_session(teacher)

      Gradezilla.visit(test_course)
      # in order to get into edit mode with an icon in the way, a total of 3 clicks are needed
      grading_cell = Gradezilla::Cells.grading_cell(student, essay_quiz.assignment)
      grading_cell.click

      Gradezilla::Cells.edit_grade(student, essay_quiz.assignment, 10)
      expect(grading_cell).not_to contain_css('.icon-not-graded')
    end
  end
end
