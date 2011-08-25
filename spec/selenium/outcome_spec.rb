require File.expand_path(File.dirname(__FILE__) + '/common')

describe "learning outcome test" do
  it_should_behave_like "in-process server selenium tests"

  it "should create a learning outcome with a new rating" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/outcomes"

    #create learning outcome
    driver.find_element(:css, '.add_outcome_link').click
    outcome_name = 'first new outcome'
    driver.find_element(:id, 'learning_outcome_short_description').send_keys(outcome_name)
    tiny_frame = wait_for_tiny(driver.find_element(:id, 'learning_outcome_description'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('new outcome description')
    end
    #add a new rating
    driver.find_element(:css, '#edit_outcome_form .add_rating_link').click
    rating_table = driver.find_element(:css, '#edit_outcome_form .rubric_criterion')
    new_rating_row = rating_table.find_element(:css, 'tr:nth-child(6)')
    new_rating_row.find_element(:css, 'input.outcome_rating_description').clear
    new_rating_row.find_element(:css, 'input.outcome_rating_description').send_keys('New Expectation')
    new_rating_points = new_rating_row.find_element(:name, 'learning_outcome[rubric_criterion][ratings][5][description]')
    new_rating_points.clear
    new_rating_points.send_keys('1')
    #delete a rating
    rating_table.find_element(:css, 'tr:nth-child(4) .delete_rating_link img').click
    threshold_input = rating_table.find_element(:name, 'learning_outcome[rubric_criterion][mastery_points]')
    threshold_input.clear
    threshold_input.send_keys('4')
    driver.find_element(:id, 'edit_outcome_form').submit
    wait_for_ajax_requests
    wait_for_animations
    driver.find_element(:link, outcome_name).should be_displayed
    driver.find_element(:css, '.show_details_link').click
    find_all_with_jquery('#outcomes .rubric_criterion .rating:visible').size.should eql(3)
  end

  it "should create a rubric" do
    course_with_teacher_logged_in
    @context = @course
    outcome_model
    
    get "/courses/#{@course.id}/outcomes"

    #create rubric
    driver.find_element(:css, '#right-side a:last-child').click
    driver.find_element(:css, '.add_rubric_link').click
    driver.find_element(:css, '#rubric_new input[name="title"]').send_keys('New Rubric')
    #edit first criterion
    driver.execute_script('$(".links").show();')#couldn't get mouseover to work
    edit_desc_img = driver.
      find_element(:css, '#criterion_1 .criterion_description .edit_criterion_link img').click
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').clear
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').send_keys('important criterion')
    driver.find_element(:id, 'edit_criterion_form').submit
    rating_row = driver.find_element(:css, '#criterion_1 td:nth-child(2) table tr')
    first_rating = rating_row.find_element(:css, '.edit_rating_link img').click
    rating_row.find_element(:css, '#edit_rating_form input[name="description"]').clear
    rating_row.find_element(:css, '#edit_rating_form input[name="description"]').send_keys('really good')
    rating_row.find_element(:css, '#edit_rating_form input[name="points"]').clear
    rating_row.find_element(:css, '#edit_rating_form input[name="points"]').send_keys('3')
    rating_row.find_element(:id, 'edit_rating_form').submit
    driver.find_element(:css, '#criterion_1 .criterion_points').clear
    driver.find_element(:css, '#criterion_1 .criterion_points').send_keys('4')

    #add criterion
    driver.find_element(:css, '#rubric_new .add_criterion_link').click
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').clear
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').send_keys('second critierion')
    driver.find_element(:id, 'edit_criterion_form').submit

    #add outcome
    driver.find_element(:css, '#rubric_new .find_outcome_link').click
    driver.find_element(:id, 'find_outcome_criterion_dialog').should be_displayed
    outcome_div = driver.find_element(:css, '#find_outcome_criterion_dialog table tr td.right .outcome_' + @outcome.id.to_s)
    outcome_div.find_element(:css, '.short_description').text.should == @outcome.short_description
    outcome_div.find_element(:css, '.criterion_for_scoring').click
    outcome_div.find_element(:css, '.select_outcome_link').click
    driver.find_element(:id, 'find_outcome_criterion_dialog').should_not be_displayed
    driver.find_element(:css, '#criterion_3 .learning_outcome_flag').should be_displayed
    driver.find_element(:css, '#criterion_3 td.points_form').should include_text('3 pts')

    #save and check rubric
    driver.find_element(:id, 'edit_rubric_form').submit
    wait_for_ajax_requests
    wait_for_animations
    driver.find_element(:css, '#rubrics .edit_rubric_link img').should be_displayed
    find_all_with_jquery('#rubrics tr.criterion:visible').size.should == 3
    driver.find_element(:css, '#left-side .outcomes').click
    driver.find_element(:link, "Outcomes").click
    driver.find_element(:css, '#right-side a:last-child').click
    driver.find_element(:css, '#rubrics .details').should include_text('3')
  end

end
