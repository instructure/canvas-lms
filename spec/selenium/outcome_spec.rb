require File.expand_path(File.dirname(__FILE__) + '/common')

describe "learning outcome test" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should create a learning outcome with a new rating" do
    skip_if_ie("Out of memory / Stack overflow")
    get "/courses/#{@course.id}/outcomes"

    #create learning outcome
    f('.add_outcome_link').click
    outcome_name = 'first new outcome'
    f('#learning_outcome_short_description').send_keys(outcome_name)
    f('.switch_views_link').click
    f('#learning_outcome_description').send_keys('new learning outcome')
    #add a new rating
    outcome_form = f('#edit_outcome_form')
    outcome_form.find_element(:css, '.add_rating_link').click
    rating_table = outcome_form.find_element(:css, '.rubric_criterion')
    new_rating_row = fj('#edit_outcome_form .rubric_criterion tr:nth-child(6)')
    new_rating_row.find_element(:css, 'input.outcome_rating_description').clear
    new_rating_row.find_element(:css, 'input.outcome_rating_description').send_keys('New Expectation')
    new_rating_points = new_rating_row.find_element(:name, 'learning_outcome[rubric_criterion][ratings][5][description]')
    replace_content(new_rating_points, '1')
    #delete a rating
    rating_table.find_element(:css, 'tr:nth-child(4) .delete_rating_link img').click
    threshold_input = rating_table.find_element(:name, 'learning_outcome[rubric_criterion][mastery_points]')
    replace_content(threshold_input, '4')
    submit_form(outcome_form)
    wait_for_ajaximations
    keep_trying_until { fj("#outcomes .learning_outcome .short_description").text.should == outcome_name }
    f('.show_details_link').click
    ffj('#outcomes .rubric_criterion .rating:visible').size.should eql(3)
  end

  def create_groups(names)
    button = driver.find_element(:css, '.add_outcome_group_link')
    records = []
    names.each do |name|
      button.click
      driver.find_element(:id, 'learning_outcome_group_title').send_keys(name, :enter)
      wait_for_ajax_requests
      records << LearningOutcomeGroup.find_by_title(name)
    end
    records
  end

  def create_outcomes(names)
    button = driver.find_element(:css, '.add_outcome_link')
    records = []
    names.each do |name|
      button.click
      driver.find_element(:id, 'learning_outcome_short_description').send_keys(name, :enter)
      wait_for_ajax_requests
      records << LearningOutcome.find_by_short_description(name)
    end
    records
  end

  context 'drag and drop' do

    before(:each) do
      get "/courses/#{@course.id}/outcomes"
      @group1, @group2 = create_groups ['group1', 'group2']
      @outcome1, @outcome2 = create_outcomes ['outcome1', 'outcome2']
      get "/courses/#{@course.id}/outcomes"

      # drag/drop handles
      @gh1, @gh2, @oh1, @oh2 = driver.find_elements(:css, '.reorder_link')

      # drag and drop is flakey in selenium mac
      load_simulate_js
    end

    it "should allow dragging and dropping outside of the outcomes list without throwing an error" do
      draggable = driver.find_element(:css, '.outcome_group .reorder_link')
      drag_to = driver.find_element(:css, '#section-tabs')
      driver.action.drag_and_drop(draggable, drag_to).perform
      driver.execute_script('return INST.errorCount;').should eql 0
    end

    it "re-order sibling outcomes" do
      #   <-
      # g1
      # g2
      # o1
      # o2->
      driver.action.drag_and_drop(@oh2, @gh1).perform
      wait_for_js
      wait_for_ajax_requests
      get "/courses/#{@course.id}/outcomes"

      # get the elements in the order we expect
      o2, g1, g2, o1 = driver.find_elements(:css, '#outcomes > .outcome_group .outcome_item')

      # verify they are in the order we expect
      g1.attribute(:id).should == "group_#{@group1.id}"
      g2.attribute(:id).should == "group_#{@group2.id}"
      o1.attribute(:id).should == "outcome_#{@outcome1.id}"
      o2.attribute(:id).should == "outcome_#{@outcome2.id}"
    end

    it "should nest an outcome into a group" do
      # g1<-
      # g2
      # o1
      # o2->
      drag_with_js('.reorder_link:eq(3)', 0, -165)
      wait_for_ajax_requests
      get "/courses/#{@course.id}/outcomes"
      only_first_level_items_selector = '#outcomes > .outcome_group > .child_outcomes > .outcome_item'
      g1, g2, o1, *extras = driver.find_elements :css, only_first_level_items_selector

      # test top level items, make sure the fourth is gone and the others are as we expect
      extras.length.should == 0
      g1.attribute(:id).should == "group_#{@group1.id}"
      g2.attribute(:id).should == "group_#{@group2.id}"
      o1.attribute(:id).should == "outcome_#{@outcome1.id}"

      # check that the outcome is nested
      o2 = g1.find_element(:id, "outcome_#{@outcome2.id}")
      o2.should be_displayed
    end

    it 'should re-order groups with children' do
      # first we have to nest the outcomes
      #   g1<-
      # ->g2
      #   o1->
      # <-o2

      # drag o1 into g1
      drag_with_js('.reorder_link:eq(2)', 0, -100)
      wait_for_ajax_requests

      # drag o2 into g2
      drag_with_js('.reorder_link:eq(3)', 0, -30)
      wait_for_ajax_requests

      # re-order the groups
      # ->
      #   g1
      #     o1
      # <-g2
      #     o2
      driver.action.drag_and_drop(@gh2, @gh1).perform
      drag_with_js('.reorder_link:eq(2)', 0, -200)
      wait_for_ajax_requests

      get "/courses/#{@course.id}/outcomes"
      only_first_level_items_selector = '#outcomes > .outcome_group > .child_outcomes > .outcome_item'

      # get them in the order we expect
      g2, g1, *extras = driver.find_elements :css, only_first_level_items_selector

      # make sure we only have two
      extras.length.should == 0

      # verify they're in order
      g1.attribute(:id).should == "group_#{@group1.id}"
      g2.attribute(:id).should == "group_#{@group2.id}"

      g1.find_element(:id, "outcome_#{@outcome1.id}").should be_displayed
      g2.find_element(:id, "outcome_#{@outcome2.id}").should be_displayed
    end
  end

  it "should create a rubric" do
    @context = @course
    @first_outcome = outcome_model
    @second_outcome = outcome_model({:short_description => 'second outcome'})

    get "/courses/#{@course.id}/outcomes"

    #create rubric
    find_with_jquery('#right-side a:last-child').click
    driver.find_element(:css, '.add_rubric_link').click
    driver.find_element(:css, '#rubrics input[name="title"]').send_keys('New Rubric')

    #edit first criterion
    driver.execute_script('$(".links").show();') #couldn't get mouseover to work
    driver.find_element(:css, '#criterion_1 .criterion_description .edit_criterion_link img').click
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').clear
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').send_keys('important criterion')
    submit_form('#edit_criterion_form')
    rating_row = find_with_jquery('#criterion_1 td:nth-child(2) table tr')
    rating_row.find_element(:css, '.edit_rating_link img').click
    rating_row.find_element(:css, '#edit_rating_form input[name="description"]').clear
    rating_row.find_element(:css, '#edit_rating_form input[name="description"]').send_keys('really good')
    rating_row.find_element(:css, '#edit_rating_form input[name="points"]').clear
    rating_row.find_element(:css, '#edit_rating_form input[name="points"]').send_keys('3')
    submit_form('#edit_rating_form')
    sleep 1
    driver.find_element(:css, '#criterion_1 .criterion_points').clear
    driver.find_element(:css, '#criterion_1 .criterion_points').send_keys('4')

    #add criterion
    driver.find_element(:css, '#rubric_new .add_criterion_link').click
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').clear
    driver.find_element(:css, '#edit_criterion_form input[name="description"]').send_keys('second critierion')
    submit_form('#edit_criterion_form')

    #add outcome
    driver.find_element(:css, '#rubric_new .find_outcome_link').click
    driver.find_element(:id, 'find_outcome_criterion_dialog').should be_displayed
    outcome_div = driver.find_element(:css, '#find_outcome_criterion_dialog table tr td.right .outcome_' + @first_outcome.id.to_s)
    outcome_div.find_element(:css, '.short_description').text.should == @first_outcome.short_description
    unless is_checked("#find_outcome_criterion_dialog .criterion_for_scoring")
      driver.find_element(:css, "#find_outcome_criterion_dialog .criterion_for_scoring").click
    end
    outcome_div.find_element(:css, '.select_outcome_link').click
    driver.find_element(:id, 'find_outcome_criterion_dialog').should_not be_displayed
    driver.find_element(:css, '#criterion_3 .learning_outcome_flag').should be_displayed
    driver.find_element(:css, '#criterion_3 td.points_form').should include_text('3')

    #add second outcome
    driver.find_element(:css, '#rubric_new .find_outcome_link').click
    find_with_jquery('#find_outcome_criterion_dialog .outcomes_select:last-child').click
    outcome_div = find_with_jquery('#find_outcome_criterion_dialog table tr td.right .outcome_' + @second_outcome.id.to_s)
    outcome_div.find_element(:css, '.select_outcome_link').click
    driver.find_element(:id, 'find_outcome_criterion_dialog').should_not be_displayed
    driver.find_element(:css, '#criterion_4 .learning_outcome_flag').should be_displayed
    sleep 1 #wait for points to recalculate

    #save and check rubric
    submit_form('#edit_rubric_form')
    wait_for_ajaximations
    driver.find_element(:css, '#rubrics .edit_rubric_link img').should be_displayed
    find_all_with_jquery('#rubrics tr.criterion:visible').size.should == 4
    expect_new_page_load { driver.find_element(:css, '#left-side .outcomes').click }
    expect_new_page_load { driver.find_element(:link, "Outcomes").click }
    find_with_jquery('#right-side a:last-child').click
    driver.find_element(:css, '#rubrics .details').should include_text('15')
  end
end
