require_relative '../common'
require_relative '../helpers/assignments_common'

describe 'submissions' do
  include_context 'in-process server selenium tests'
  include AssignmentsCommon

  before do
    course_with_teacher_logged_in
  end

  context "Assignment" do
    it "Create an assignment as a teacher", priority: "1", test_id: 56751 do
      group_test_setup(3,3,1)
      expect do
        create_assignment_with_group_category_preparation
        validate_and_submit_form
      end.to change { Assignment.count }.by 1
      expect(Assignment.last.group_category).to be_present
    end

    it "Edit an assignment", priority: "1", test_id: 238864 do
      @assignment = @course.assignments.create!(title: 'assignment 1', name: 'assignment 1', due_at: Time.now.utc + 2.days,
                                                points_possible: 50, submission_types: 'online_text_entry')
      group_test_setup(3,3,1)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      select_assignment_group_category(-2)
      validate_and_submit_form
    end

    it 'Should be able to create a new student group category from the assignment edit page', priority: "1", test_id: 56752 do
      original_number_of_assignment = Assignment.count
      original_number_of_group = Group.count
      create_assignment_preparation
      f('#has_group_category').click
      replace_content(f('#new_category_name'), "canv")
      f('#split_groups').click
      replace_content(f('input[name=create_group_count]'), '1')
      f('#newGroupSubmitButton').click
      wait_for_ajaximations
      submit_assignment_form
      validate_edit_and_publish_links_exist
      expect(Assignment.count).to be(original_number_of_assignment + 1)
      expect(Group.count).to be(original_number_of_group + 1)
    end
  end

  context 'grade a group assignment as a teacher' do
    it 'Submitting Group Assignments - Speedgrader', priority: "1", test_id: 112170 do
      create_assignment_for_group('online_text_entry')
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('.ui-selectmenu-icon').click
      expect(f('.ui-selectmenu-item-header')).to include_text(@testgroup[0].name)
    end

    it 'Submitting Group Assignments - Grade Students Individually', priority: "1", test_id: 70744 do
      create_assignment_for_group('online_text_entry', true)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('.ui-selectmenu-icon').click
      expect(f('.ui-selectmenu-item-header')).not_to include_text(@testgroup[0].name)
    end
  end

  private

  def validate_and_submit_form
    validate_group_category_is_checked(@group_category[0].name)
    submit_assignment_form
    validate_edit_and_publish_links_exist
  end

  def validate_group_category_is_checked(group_name)
    expect(is_checked('input[type=checkbox][name=has_group_category]')).to be_truthy
    expect(fj('#assignment_group_category_id:visible')).to include_text(group_name)
  end

  def validate_edit_and_publish_links_exist
    expect(f('.edit_assignment_link')).to be_truthy
    expect(f('.publish-text')).to be_truthy
  end
end
