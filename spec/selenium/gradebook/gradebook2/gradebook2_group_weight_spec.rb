require_relative '../../helpers/gradebook2_common'

describe "group weights" do
  include_context "in-process server selenium tests"
  include_context "gradebook_components"
  include Gradebook2Common

  def student_totals()
    totals = ff('.total-cell')
    points = []
    for i in totals do
      points.push(i.text)
    end
    points
  end

  def toggle_group_weight
    gradebook_settings_cog.click
    set_group_weights.click
    group_weighting_scheme.click
    save_button.click
    wait_for_ajax_requests
  end

  before(:each) do
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

  it 'should show total column as points' do
    points_array = ["25"]
    unweighted_array = ["41.67%"]
    weighted_array = ["45%"]

    @assignment1.grade_student @student, :grade => 20
    @assignment2.grade_student @student, :grade => 5

    @course.show_total_grade_as_points = true
    @course.update_attributes(:group_weighting_scheme => 'points')

    # Displays total column as points
    get "/courses/#{@course.id}/gradebook2"
    expect(student_totals).to eq(points_array)
    wait_for_ajax_requests

    # Display weighted totals
    toggle_group_weight
    expect(student_totals).to eq(weighted_array)

    # Display unweighted totals again
    toggle_group_weight
    expect(student_totals).to eq(unweighted_array)
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
    # TODO: make the header cell in the UI update to reflect new value
    # validate_group_weight_text(AssignmentGroup.all, weight_numbers)
  end

  context "warning message" do
    before(:each) do
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

    it 'should display triangle warnings for assignment groups with 0 points possible', priority: "1", test_id: 164013 do
      get "/courses/#{@course.id}/gradebook"
      expect(ff('.icon-warning').count).to eq(2)
    end

    it 'should remove triangle warnings if group weights are turned off in gradebook', priority: "1", test_id: 305579 do
      get "/courses/#{@course.id}/gradebook"
      f('#gradebook_settings').click
      f("[aria-controls='assignment_group_weights_dialog']").click
      f('#group_weighting_scheme').click
      submit_dialog('.ui-dialog-buttonset', '.ui-button')
      refresh_page
      expect(f("body")).not_to contain_css('.icon-warning')
    end

    it 'should not display triangle warnings if an assignment is muted in both header and total column' do
      get "/courses/#{@course.id}/gradebook2"
      toggle_muting(@assignment2)
      expect(f("#content")).not_to contain_jqcss('.total-cell .icon-warning')
      expect(f("#content")).not_to contain_jqcss(".container_1 .slick-header-column[id*='assignment_#{@assignment2.id}'] .icon-warning")
    end

    it 'should display triangle warnings if an assignment is unmuted in both header and total column' do
      @assignment2.muted = true
      @assignment2.save!
      get "/courses/#{@course.id}/gradebook2"
      toggle_muting(@assignment2)
      expect(f('.total-cell .icon-warning')).to be_displayed
      expect(fj(".container_1 .slick-header-column[id*='assignment_#{@assignment2.id}'] .icon-warning")).to be_displayed
      expect(f("#content")).not_to contain_jqcss(".container_1 .slick-header-column[id*='assignment_#{@assignment2.id}'] .muted")
    end
  end
end
