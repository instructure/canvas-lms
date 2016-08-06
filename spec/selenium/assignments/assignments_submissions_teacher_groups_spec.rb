require_relative '../common'
require_relative '../helpers/assignments_common'

describe 'submissions' do
  include_context 'in-process server selenium tests'
  include AssignmentsCommon

  before do
    course_with_teacher_logged_in
  end

  context 'create assignment as a teacher' do

    it 'Should be able to create group assignments in a new assignment', priority: "1", test_id: 56751 do
      group_test_setup(3,3,1)
      create_assignment_with_group_category
      expect_new_page_load do
        f('button[type="submit"]').click
      end

      expect_new_page_load do
        f('.edit_assignment_link').click
      end

      expect(is_checked('input[type=checkbox][name=has_group_category]')).to be_truthy
      expect(fj('#assignment_group_category_id:visible')).to include_text(@group_category[0].name)
    end

    it 'Should be able to create group assignments in a new assignment', priority: "1", test_id: 238864 do
      @assignment = @course.assignments.create!(title: 'assignment 1', name: 'assignment 1', due_at: Time.now.utc + 2.days,
                                                points_possible: 50, submission_types: 'online_text_entry')
      group_test_setup(3,3,1)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"

      f('#has_group_category').click
      f('#assignment_group_category_id').click
      f('#assignment_group_category_id').send_keys :arrow_up
      f('#assignment_group_category_id').send_keys :return

      expect_new_page_load do
        f('button[type="submit"]').click
      end

      expect_new_page_load do
        f('.edit_assignment_link').click
      end

      expect(is_checked('input[type=checkbox][name=has_group_category]')).to be_truthy
      expect(fj('#assignment_group_category_id:visible')).to include_text(@group_category[0].name)
    end

    it 'Should be able to create a new student group category from the assignment edit page', priority: "1", test_id: 56752 do
      create_assignment_with_group_category

      f('input[name="category[split_groups]"]').click
      ff('.submit_button').detect(&:displayed?).click
      wait_for_ajaximations

      expect(fj('#assignment_group_category_id:visible')).to include_text("New Group Category")
    end
  end

  context 'grade a group assignment as a teacher' do
    it 'Submitting Group Assignments - Speedgrader', priority: "1", test_id: 112170 do
      create_assignment_for_group('online_text_entry')
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      fj('.ui-selectmenu-icon').click
      expect(fj('.ui-selectmenu-item-header')).to include_text(@testgroup[0].name)
    end

    it 'Submitting Group Assignments - Grade Students Individually', priority: "1", test_id: 70744 do
      create_assignment_for_group('online_text_entry', true)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      fj('.ui-selectmenu-icon').click
      expect(fj('.ui-selectmenu-item-header')).not_to include_text(@testgroup[0].name)
    end
  end
end
