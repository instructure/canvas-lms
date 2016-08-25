require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/groups_common'

describe "gradebook performance" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let(:uneditable_cells) { f('.cannot_edit') }
  let(:gradebook_headers) { ff('#gradebook_grid .gradebook-header-column') }
  let(:header_titles) { gradebook_headers.map { |header| header.attribute('title') } }

  context "as a teacher" do
    let!(:setup) do
      gradebook_data_setup
      @course.root_account.enable_feature!(:gradebook_performance)
    end

    it "hides unpublished/shows published assignments" do
      assignment = @course.assignments.create! title: 'unpublished'
      assignment.unpublish
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajax_requests
      expect(header_titles).not_to include assignment.title

      @first_assignment.publish
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajax_requests
      expect(header_titles).to include @first_assignment.title
    end

    it "shows 'not-graded' assignments" do
      get "/courses/#{@course.id}/gradebook"

      expect(header_titles).not_to include @ungraded_assignment.title
    end

    def filter_student(text)
      f('.gradebook_filter input').send_keys text
      sleep 1 # InputFilter has a delay
    end

    def visible_students
      ff('.student-name')
    end

    it 'filters students' do
      get "/courses/#{@course.id}/gradebook"
      expect(visible_students.length).to eq @all_students.size
      filter_student 'student 1'
      expect(visible_students.length).to eq 1
      expect(visible_students[0].text).to eq 'student 1'
    end

    it "validates correct number of students showing up in gradebook" do
      get "/courses/#{@course.id}/gradebook"

      expect(visible_students.count).to eq @course.students.count
    end

    it "does not show concluded enrollments in active courses by default" do
      @student_1.enrollments.where(course_id: @course).first.conclude

      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      get "/courses/#{@course.id}/gradebook"
      expect(visible_students.count).to eq @course.students.count

      # select the option and we'll now show concluded
      f('#gradebook_settings').click
      f('label[for="show_concluded_enrollments"]').click
      wait_for_ajax_requests

      expect(visible_students.count).to eq @course.all_students.count
    end

    it "shows concluded enrollments in concluded courses by default" do
      @course.complete!

      expect(@course.students.count).to eq 0
      expect(@course.all_students.count).to eq @all_students.size

      get "/courses/#{@course.id}/gradebook"
      expect(visible_students.count).to eq @course.all_students.count
    end

    it "shows students sorted by their sortable_name" do
      get "/courses/#{@course.id}/gradebook"
      student_names = visible_students.map(&:text)
      expect(student_names).to eq @all_students.map(&:name)
    end

    it "allows showing only a certain section" do
      get "/courses/#{@course.id}/gradebook"

      choose_section = ->(name) do
        fj('.section-select-button:visible').click
        wait_for_js
        ffj('.section-select-menu:visible a').find { |a| a.text.include? name }.click
        wait_for_js
      end

      choose_section.call "All Sections"
      expect(fj('.section-select-button:visible')).to include_text("All Sections")

      choose_section.call @other_section.name
      expect(fj('.section-select-button:visible')).to include_text(@other_section.name)

      expect(f('#gradebook_grid .student-name').text).to eq 'student 2'

      # verify that it remembers the section to show across page loads
      get "/courses/#{@course.id}/gradebook"
      expect(fj('.section-select-button:visible')).to include_text @other_section.name
      expect(f('#gradebook_grid .student-name').text).to eq 'student 2'

      # now verify that you can set it back
      choose_section.call "All Sections"
      expect(fj('.section-select-button:visible')).to include_text("All Sections")
      expect(ff('#gradebook_grid .student-name').first.text).to eq 'student 1'
      expect(ff('#gradebook_grid .student-name').second.text).to eq 'student 2'
    end


    it "handles multiple enrollments correctly" do
      @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)
      choose_section = ->(name) do
        fj('.section-select-button:visible').click
        wait_for_js
        ffj('.section-select-menu:visible a').find { |a| a.text.include? name }.click
        wait_for_js
      end

      get "/courses/#{@course.id}/gradebook"
      wait_for_ajaximations

      expect(fj('.section-select-button:visible')).to include_text("All Sections")

      choose_section.call @course.default_section.name
      expect(f('#gradebook_grid .student-name').text).to eq @student_1.name

      choose_section.call @other_section.name
      expect(f('#gradebook_grid .student-name').text).to eq @student_1.name
    end

    it "displays for users with only :view_all_grades permissions" do
      user_logged_in

      role = custom_account_role('CustomAdmin', :account => Account.default)
      RoleOverride.create!(:role => role,
                           :permission => 'view_all_grades',
                           :context => Account.default,
                           :enabled => true)
      AccountUser.create!(:user => @user,
                          :account => Account.default,
                          :role => role)

      get "/courses/#{@course.id}/gradebook"
      expect_no_flash_message :error
    end

    it "displays for users with only :manage_grades permissions" do
      user_logged_in
      role = custom_account_role('CustomAdmin', :account => Account.default)
      RoleOverride.create!(:role => role,
                           :permission => 'manage_grades',
                           :context => Account.default,
                           :enabled => true)
      AccountUser.create!(:user => @user,
                          :account => Account.default,
                          :role => role)

      get "/courses/#{@course.id}/gradebook"
      expect_no_flash_message :error
    end

    it "includes student view student for grading" do
      fake_student1 = @course.student_view_student
      fake_student1.update_attribute :workflow_state, "deleted"
      fake_student2 = @course.student_view_student
      fake_student1.update_attribute :workflow_state, "registered"
      @fake_submission = @first_assignment.submit_homework(fake_student1, :body => 'fake student submission')

      get "/courses/#{@course.id}/gradebook"

      fakes = [fake_student1.name, fake_student2.name]
      expect(ff('.student-name').last(2).map(&:text)).to eq fakes
    end

    it "does not include non-graded group assignment in group total" do
      skip('CNVS-30264 - Broken and throwing false positives, fix with react gradebook')
      driver.manage.window.maximize
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

      graded_assignment.submissions.create(:user => @student)
      graded_assignment.grade_student @student_1, :grade => 10 # 10 points possible
      group_assignment.submissions.create(:user => @student)
      group_assignment.grade_student @student_1, :grade => 2 # 0 points possible

      make_full_screen
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajaximations
      expect(f('#gradebook_grid .assignment-group-grade')).to include_text('100%') # otherwise 108%
      cell = f('#gradebook_grid .total-grade')
      hover cell
      expect(cell).to include_text('100%') # otherwise 108%
    end
  end
end
