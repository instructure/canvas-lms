require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')
describe "group weights" do
  it_should_behave_like "in-process server selenium tests"

  ASSIGNMENT_1_POINTS = "10"
  ASSIGNMENT_2_POINTS = "5"
  ASSIGNMENT_3_POINTS = "50"
  ATTENDANCE_POINTS = "15"

  STUDENT_NAME_1 = "student 1"
  STUDENT_NAME_2 = "student 2"
  STUDENT_NAME_3 = "student 3"
  STUDENT_SORTABLE_NAME_1 = "1, student"
  STUDENT_SORTABLE_NAME_2 = "2, student"
  STUDENT_SORTABLE_NAME_3 = "3, student"
  STUDENT_1_TOTAL_IGNORING_UNGRADED = "100%"
  STUDENT_2_TOTAL_IGNORING_UNGRADED = "66.7%"
  STUDENT_3_TOTAL_IGNORING_UNGRADED = "66.7%"
  STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS = "18.8%"
  STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS = "12.5%"
  STUDENT_3_TOTAL_TREATING_UNGRADED_AS_ZEROS = "12.5%"
  DEFAULT_PASSWORD = "qwerty"

  def get_group_points
    group_points_holder = keep_trying_until do
      group_points_holder = ff('div.assignment-points-possible')
      group_points_holder
    end
    group_points_holder
  end

  def check_group_points(expected_weight_text)
    for i in 2..3 do
      get_group_points[i].text.should == expected_weight_text + ' of grade'
    end
  end

  def set_group_weight(assignment_group, weight_number)
    f('#gradebook_settings').click
    wait_for_ajaximations
    f('[aria-controls="assignment_group_weights_dialog"]').click

    dialog = f('#assignment_group_weights_dialog')
    dialog.should be_displayed

    group_check = dialog.find_element(:id, 'group_weighting_scheme')
    keep_trying_until do
      group_check.click
      is_checked('#group_weighting_scheme').should be_true
    end
    group_weight_input = f("#assignment_group_#{assignment_group.id}_weight")
    set_value(group_weight_input, weight_number)
    fj('.ui-button:contains("Save")').click
    wait_for_ajaximations
    @course.reload.group_weighting_scheme.should == 'percent'
  end

  def validate_group_weight_text(assignment_groups, weight_numbers)
    assignment_groups.each_with_index do |ag, i|
      heading = fj(".slick-column-name:contains('#{ag.name}') .assignment-points-possible")
      heading.should include_text("#{weight_numbers[i]}% of grade")
    end
  end

  def validate_group_weight(assignment_group, weight_number)
    assignment_group.reload.group_weight.should == weight_number
  end

  before (:each) do
    course_with_teacher_logged_in
    student_in_course
    @course.update_attributes(:group_weighting_scheme => 'percent')
    @group1 = @course.assignment_groups.create!(:name => 'first assignment group', :group_weight => 50)
    @group2 = @course.assignment_groups.create!(:name => 'second assignment group', :group_weight => 50)
    @assignment1 = assignment_model({
                                        :course => @course,
                                        :name => 'first assignment',
                                        :due_at => Date.today,
                                        :points_possible => 50,
                                        :submission_types => 'online_text_entry',
                                        :assignment_group => @group1
                                    })
    @assignment2 = assignment_model({
                                        :course => @course,
                                        :name => 'second assignment',
                                        :due_at => Date.today,
                                        :points_possible => 10,
                                        :submission_types => 'online_text_entry',
                                        :assignment_group => @group2
                                    })
    @course.reload
  end

  it "should validate setting group weights" do
    weight_numbers = [26.0, 73.5]

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    group_1 = AssignmentGroup.find_by_name(@group1.name)
    group_2 = AssignmentGroup.find_by_name(@group2.name)

    #set and check the group weight of the first assignment group
    set_group_weight(group_1, weight_numbers[0])
    validate_group_weight(group_1, weight_numbers[0])

    #set and check the group weight of the first assignment group
    set_group_weight(group_2, weight_numbers[1])
    validate_group_weight(group_2, weight_numbers[1])

    # TODO: make the header cell in the UI update to reflect new value
    # validate_group_weight_text(AssignmentGroup.all, weight_numbers)
  end

  it "should display group weights correctly when set on assignment groups" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    check_group_points('50.00%')
  end

  it "should display group weights with fractional value" do
    @group1.group_weight = 70.5; @group1.save!
    @group2.group_weight = 29.5; @group2.save!

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    validate_group_weight_text([@group1, @group2], ['70.50', '29.50'])
  end

  it "should display group weights correctly when unsetting group weights through assignments page" do
    pending("bug 7435 - Gradebook2 keeps weighted assignment groups, even when turned off") do
      get "/courses/#{@course.id}/assignments"

      f('#class_weighting_policy').click
      wait_for_ajaximations
      check_group_points('0%')
    end
  end
end
