require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')
describe "group weights" do
  include_context "in-process server selenium tests"

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

  it "should validate setting group weights", priority: "1", test_id: 164007 do
    weight_numbers = [26.1, 73.5]

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    group_1 = AssignmentGroup.where(name: @group1.name).first
    group_2 = AssignmentGroup.where(name: @group2.name).first

    #set and check the group weight of the first assignment group
    set_group_weight(group_1, weight_numbers[0])

    #set and check the group weight of the second assignment group
    set_group_weight(group_2, weight_numbers[1])
    validate_group_weight(group_2, weight_numbers[1])

    # check display of group weights in column heading
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    check_group_points(['26.10%', '73.50%'])
  end

  it "should display group weights correctly when unsetting group weights through assignments page" do
    skip("bug 7435 - Gradebook2 keeps weighted assignment groups, even when turned off")
    get "/courses/#{@course.id}/assignments"

    f('#class_weighting_policy').click
    wait_for_ajaximations
    check_group_points('0%')
  end

  context "warning message" do
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
                                          :points_possible => 0,
                                          :submission_types => 'online_text_entry',
                                          :assignment_group => @group2
                                      })
      @course.reload
    end

    it 'should display trangle warnings for assignment groups with 0 points possible', priority: "1", test_id: 164013 do
      get "/courses/#{@course.id}/gradebook"
      refresh_page
      expect(ff('.icon-warning').count).to eq(2)
    end

    it 'should remove trangle warnings if group weights are turned off in gradebook', priority: "1", test_id: 305579 do
      get "/courses/#{@course.id}/gradebook"
      f('#gradebook_settings').click
      f('#ui-id-4').click
      f('#group_weighting_scheme').click
      submit_dialog('.ui-dialog-buttonset', '.ui-button')
      refresh_page
      expect(ff('.icon-warning').count).to eq(0)
    end
  end
end