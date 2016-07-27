require_relative '../../helpers/gradebook2_common'

describe "editing grades" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  before(:each) do
    gradebook_data_setup
  end

  context 'submission details dialog', priority: "1", test_id: 220305 do
    it 'successfully grades a submission' do
      skip_if_chrome('issue with set_value')
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajaximations
      open_comment_dialog(0, 0)
      grade_box = f("form.submission_details_grade_form input.grading_value")
      expect(grade_box).to have_value @assignment_1_points
      set_value(grade_box, 7)
      f("form.submission_details_grade_form button").click
      wait_for_ajax_requests
      cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .slick-cell:nth-child(1)')
      expect(cell.text).to include '7'
      expect(final_score_for_row(0)).to eq "80%"
    end
  end

  it "should update a graded quiz and have the points carry over to the quiz attempts page", priority: "1", test_id: 220310 do
    points = 50
    q = factory_with_protected_attributes(@course.quizzes, :title => "new quiz", :points_possible => points, :quiz_type => 'assignment', :workflow_state => 'available')
    q.save!
    qs = q.generate_submission(@student_1)
    Quizzes::SubmissionGrader.new(qs).grade_submission
    q.reload

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l5', points.to_s)

    get "/courses/#{@course.id}/quizzes/#{q.id}/history?quiz_submission_id=#{qs.id}"
    expect(f('.score_value').text).to eq points.to_s
    expect(f('#after_fudge_points_total').text).to eq points.to_s
  end

  it "should treat ungraded as 0s when asked, and ignore when not", priority: "1", test_id: 164222 do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    # make sure it shows like it is not treating ungraded as 0's by default
    expect(is_checked('#include_ungraded_assignments')).to be_falsey
    expect(final_score_for_row(0)).to eq @student_1_total_ignoring_ungraded
    expect(final_score_for_row(1)).to eq @student_2_total_ignoring_ungraded

    # set the "treat ungraded as 0's" option in the header

    f('#gradebook_settings').click
    f('label[for="include_ungraded_assignments"]').click

    # now make sure that the grades show as if those ungraded assignments had a '0'
    expect(is_checked('#include_ungraded_assignments')).to be_truthy
    expect(final_score_for_row(0)).to eq @student_1_total_treating_ungraded_as_zeros
    expect(final_score_for_row(1)).to eq @student_2_total_treating_ungraded_as_zeros

    # reload the page and make sure it remembered the setting
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    expect(is_checked('#include_ungraded_assignments')).to be_truthy
    expect(final_score_for_row(0)).to eq @student_1_total_treating_ungraded_as_zeros
    expect(final_score_for_row(1)).to eq @student_2_total_treating_ungraded_as_zeros

    # NOTE: gradebook1 does not handle 'remembering' the `include_ungraded_assignments` setting

    # check that reverting back to unchecking 'include_ungraded_assignments' also reverts grades
    f('#gradebook_settings').click
    f('label[for="include_ungraded_assignments"]').click
    expect(is_checked('#include_ungraded_assignments')).to be_falsey
    expect(final_score_for_row(0)).to eq @student_1_total_ignoring_ungraded
    expect(final_score_for_row(1)).to eq @student_2_total_ignoring_ungraded

    # clear our saved settings
    driver.execute_script 'localStorage.clear();'
  end

  it "should validate initial grade totals are correct", priority: "1", test_id: 220311 do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    expect(final_score_for_row(0)).to eq @student_1_total_ignoring_ungraded
    expect(final_score_for_row(1)).to eq @student_2_total_ignoring_ungraded
  end

  it "should change grades and validate course total is correct", priority: "1", test_id: 220312 do
    expected_edited_total = "33.33%"
    get "/courses/#{@course.id}/gradebook"

    #editing grade for first row, first cell
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2', 0)

    #editing grade for second row, first cell
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(2) .l2', 0)

    #refresh page and make sure the grade sticks
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    expect(final_score_for_row(0)).to eq expected_edited_total
    expect(final_score_for_row(1)).to eq expected_edited_total
  end

  it "should allow setting a letter grade on a no-points assignment", priority: "1", test_id: 220313 do
    assignment_model(:course => @course, :grading_type => 'letter_grade', :points_possible => nil, :title => 'no-points')
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l5', 'A-')
    wait_for_ajax_requests
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l5')).to include_text('A-')
    expect(@assignment.reload.submissions.size).to eq 1
    sub = @assignment.submissions.first
    expect(sub.grade).to eq 'A-'
    expect(sub.score).to eq 0.0
  end

  it "should not update default grades for users not in this section", priority: "1", test_id: 220314 do
    # create new user and section

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    driver.execute_script "$('#section_option_#{@other_section.id}').click()"

    set_default_grade(2, 13)
    @other_section.users.each { |u| expect(u.submissions.map(&:grade)).to include '13' }
    @course.default_section.users.each { |u| expect(u.submissions.map(&:grade)).not_to include '13' }
  end

  it "should edit a grade, move to the next cell and validate focus is not lost", priority: "1", test_id: 220318 do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    first_cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2')
    first_cell.click
    grade_input = first_cell.find_element(:css, '.grade')
    set_value(grade_input, 3)
    grade_input.send_keys(:tab)
    wait_for_ajax_requests
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l3')).to have_class('editable')
  end

  it "should display dropped grades correctly after editing a grade", priority: "1", test_id: 220316 do
    @course.assignment_groups.first.update_attribute :rules, 'drop_lowest:1'
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    assignment_1_sel = '#gradebook_grid .container_1 .slick-row:nth-child(1) .l3'
    assignment_2_sel= '#gradebook_grid .container_1 .slick-row:nth-child(1) .l4'
    a1 = f(assignment_1_sel)
    a2 = f(assignment_2_sel)
    expect(a1).to have_class 'dropped'
    expect(a2).not_to have_class 'dropped'

    a2.click
    grade_input = a2.find_element(:css, '.grade')
    set_value(grade_input, 3)
    grade_input.send_keys(:tab)
    wait_for_ajaximations
    expect(f(assignment_1_sel)).not_to have_class 'dropped'
    expect(f(assignment_2_sel)).to have_class 'dropped'
  end

  it "should update a grade when clicking outside of slickgrid", priority: "1", test_id: 220319 do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    first_cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2')
    first_cell.click
    grade_input = first_cell.find_element(:css, '.grade')
    set_value(grade_input, 3)
    ff('body')[0].click
    wait_for_ajax_requests
    expect(f("body")).not_to contain_css('.gradebook_cell_editable')
  end

  it "should validate curving grades option", priority: "1", test_id: 220320 do
    skip_if_chrome('issue with set_value')
    curved_grade_text = "8"

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    open_assignment_options(0)
    f('[data-action="curveGrades"]').click
    curve_form = f('#curve_grade_dialog')
    set_value(curve_form.find_element(:css, '#middle_score'), curved_grade_text)
    fj('.ui-dialog-buttonset .ui-button:contains("Curve Grades")').click
    accept_alert
    expect(find_slick_cells(1, f('#gradebook_grid .container_1'))[0].text).to eq curved_grade_text
  end

  it "should optionally assign zeroes to unsubmitted assignments during curving", priority: "1", test_id: 220321 do
    get "/courses/#{@course.id}/gradebook"

    wait_for_ajaximations

    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(2) .l2', '')

    open_assignment_options(0)
    f('[data-action="curveGrades"]').click

    f('#assign_blanks').click
    fj('.ui-dialog-buttonpane button:visible').click
    accept_alert
    expect(find_slick_cells(1, f('#gradebook_grid .container_1'))[0].text).to eq '0'
  end

  it "should not factor non graded assignments into group total", priority: "1", test_id: 220323 do
    expected_totals = [@student_1_total_ignoring_ungraded, @student_2_total_ignoring_ungraded]
    ungraded_submission = @ungraded_assignment.submit_homework(@student_1, :body => 'student 1 submission ungraded assignment')
    @ungraded_assignment.grade_student(@student_1, :grade => 20)
    ungraded_submission.save!
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    assignment_group_cells = ff('.assignment-group-cell')
    expected_totals.zip(assignment_group_cells) do |expected, cell|
      expect(cell.text).to eq expected
    end
  end

  it "should validate setting default grade for an assignment", priority: "1", test_id: 220383 do
    expected_grade = "45"
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    set_default_grade(2, expected_grade)
    grade_grid = f('#gradebook_grid .container_1')
    StudentEnrollment.count.times do |n|
      expect(find_slick_cells(n, grade_grid)[2].text).to eq expected_grade
    end
  end

  it "should display an error on failed updates", priority: "1", test_id: 220384 do
    SubmissionsApiController.any_instance.expects(:update).returns('bad response')
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2', 0)
    expect_flash_message :error, /refresh/
  end
end
