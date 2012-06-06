require File.expand_path(File.dirname(__FILE__) + "/common")
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')
describe "edititing grades" do
  it_should_behave_like "gradebook2 selenium tests"

  before (:each) do
    data_setup
  end

  it "should change grades and validate course total is correct" do
    expected_edited_total = "33.3%"
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    #editing grade for first row, first cell
    edit_grade(f('#gradebook_grid [row="0"] .l0'), 0)

    #editing grade for second row, first cell
    edit_grade(f('#gradebook_grid [row="1"] .l0'), 0)

    #refresh page and make sure the grade sticks
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    final_score_for_row(0).should eql expected_edited_total
    final_score_for_row(1).should eql expected_edited_total

    #go back to gradebook1 and compare to make sure they match
    check_gradebook_1_totals({
                                 @student_1.id => expected_edited_total,
                                 @student_2.id => expected_edited_total
                             })
  end

  it "should update a graded quiz and have the points carry over to the quiz attempts page" do
    points = 50
    q = factory_with_protected_attributes(@course.quizzes, :title => "new quiz", :points_possible => points, :quiz_type => 'assignment', :workflow_state => 'available')
    q.save!
    qs = q.generate_submission(@student_1)
    qs.grade_submission
    q.reload

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    edit_grade(f('#gradebook_grid [row="0"] .l3'), points.to_s)

    get "/courses/#{@course.id}/quizzes/#{q.id}/history?quiz_submission_id=#{qs.id}"
    f('.score_value').text.should == points.to_s
    f('#after_fudge_points_total').text.should == points.to_s
  end

  it "should treat ungraded as 0's when asked, and ignore when not" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    # make sure it shows like it is not treating ungraded as 0's by default
    is_checked('#include_ungraded_assignments').should be_false
    final_score_for_row(0).should eql STUDENT_1_TOTAL_IGNORING_UNGRADED
    final_score_for_row(1).should eql STUDENT_2_TOTAL_IGNORING_UNGRADED

    # set the "treat ungraded as 0's" option in the header
    open_gradebook_settings(f('label[for="include_ungraded_assignments"]'))

    # now make sure that the grades show as if those ungraded assignments had a '0'
    is_checked('#include_ungraded_assignments').should be_true
    final_score_for_row(0).should eql STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS
    final_score_for_row(1).should eql STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS

    # reload the page and make sure it remembered the setting
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    is_checked('#include_ungraded_assignments').should be_true
    final_score_for_row(0).should eql STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS
    final_score_for_row(1).should eql STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS

    # NOTE: gradebook1 does not handle 'remembering' the `include_ungraded_assignments` setting

    # clear our saved settings
    driver.execute_script 'localStorage.clear();'
  end

  it "should validate initial grade totals are correct" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    final_score_for_row(0).should eql STUDENT_1_TOTAL_IGNORING_UNGRADED
    final_score_for_row(1).should eql STUDENT_2_TOTAL_IGNORING_UNGRADED
  end

  it "should allow setting a letter grade on a no-points assignment" do
    assignment_model(:course => @course, :grading_type => 'letter_grade', :points_possible => nil, :title => 'no-points')
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    edit_grade(f('#gradebook_grid [row="0"] .l3'), 'A-')
    wait_for_ajax_requests
    f('#gradebook_grid [row="0"] .l3').text.should == 'A-'
    @assignment.submissions.size.should == 1
    sub = @assignment.submissions.first
    sub.grade.should == 'A-'
    sub.score.should == 0.0
  end

  it "should not update default grades for users not in this section" do
    # create new user and section

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    driver.execute_script "$('#section_option_#{@other_section.id}').click()"

    set_default_grade(2, 13)
    @other_section.users.each { |u| u.submissions.map(&:grade).should include '13' }
    @course.default_section.users.each { |u| u.submissions.map(&:grade).should_not include '13' }
  end

  it "should edit a grade, move to the next cell and validate focus is not lost" do
    pending('bug 7375 - server response causes active cell in same row to loose focus') do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      first_cell = f('#gradebook_grid [row="0"] .l0')
      grade_input = keep_trying_until do
        first_cell.click
        first_cell.find_element(:css, '.grade')
      end
      set_value(grade_input, 3)
      first_cell.send_keys(:tab)
      wait_for_ajax_requests
      f('#gradebook_grid [row="0"] .l1').should have_class('editable')
    end
  end

  it "should validate curving grades option" do
    curved_grade_text = "8"

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    open_assignment_options(0)
    f('#ui-menu-1-4').click
    curve_form = f('#curve_grade_dialog')
    set_value(curve_form.find_element(:css, '#middle_score'), curved_grade_text)
    find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Curve Grades")').click
    keep_trying_until do
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.dismiss
      true
    end
    driver.switch_to.default_content
    find_slick_cells(1, f('#gradebook_grid'))[0].text.should == curved_grade_text
  end

  it "should correctly set default grades for a specific section" do
      pending("intermittently fails")
      def open_section_menu_and_click(menu_item_css)
        f('#section_to_show').click
        section_menu = f('#section-to-show-menu')
        section_menu.should be_displayed
        section_menu.find_element(:css, menu_item_css).click
      end

      expected_grade = "45"
      gradebook_row_1 = '#gradebook_grid [row="1"]'
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      open_section_menu_and_click('#section-to-show-menu-1')
      set_default_grade(2, expected_grade)
      open_section_menu_and_click('#section-to-show-menu-0')
      f(gradebook_row_1).should be_displayed
      validate_cell_text(f("#{gradebook_row_1} .r2"), '-')
  end

  it "should not factor non graded assignments into group total" do
    pending("bug 7558 - Non-Graded Assignments are being factored in the Assignment Group's total") do
      expected_totals = [STUDENT_1_TOTAL_IGNORING_UNGRADED, STUDENT_2_TOTAL_IGNORING_UNGRADED]
      ungraded_submission = @ungraded_assignment.submit_homework(@student_1, :body => 'student 1 submission ungraded assignment')
      @ungraded_assignment.grade_student(@student_1, :grade => 20)
      ungraded_submission.save!
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      assignment_group_cells = ff('.assignment-group-cell')
      assignment_group_cells.each_with_index do |agc, i|
        validate_cell_text(agc, expected_totals[i])
      end
    end
  end

  it "should validate setting default grade for an assignment" do
    expected_grade = "45"
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    set_default_grade(2, expected_grade)
    grade_grid = f('#gradebook_grid')
    StudentEnrollment.count.times do |n|
      find_slick_cells(n, grade_grid)[2].text.should == expected_grade
    end
  end
end
