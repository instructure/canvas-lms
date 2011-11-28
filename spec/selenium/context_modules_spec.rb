require File.expand_path(File.dirname(__FILE__) + "/common")

describe "context_modules selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should only display 'out-of' on an assignment min score restriction when the assignment has a total" do
    course_with_teacher_logged_in

    ag = @course.assignment_groups.create!
    a1 = ag.assignments.create!(:context => @course)
    a1.points_possible = 10
    a1.save
    a2 = ag.assignments.create!(:context => @course)
    m = @course.context_modules.create!
    
    make_content_tag = lambda do |assignment|
      ct = ContentTag.new
      ct.content_id = assignment.id
      ct.content_type = 'Assignment'
      ct.context_id = @course.id
      ct.context_type = 'Course'
      ct.title = "Assignment #{assignment.id}"
      ct.tag_type = "context_module"
      ct.context_module_id = m.id
      ct.context_code = "course_#{@course.id}"
      ct.save!
      ct
    end
    content_tag_1 = make_content_tag.call a1
    content_tag_2 = make_content_tag.call a2

    get "/courses/#{@course.id}/modules"

    keep_trying_until {
      hover_and_click('#context_modules .edit_module_link')
      wait_for_ajax_requests
      driver.find_element(:id, 'add_context_module_form').should be_displayed
    }
    assignment_picker = keep_trying_until { 
      driver.find_element(:css, '.add_completion_criterion_link').click
      find_with_jquery('.assignment_picker:visible')
    }

    assignment_picker.find_element(:css, "option[value='#{content_tag_1.id}']").click
    requirement_picker = find_with_jquery('.assignment_requirement_picker:visible')
    requirement_picker.find_element(:css, 'option[value="min_score"]').click
    driver.execute_script('return $(".points_possible_parent:visible").length').should > 0

    assignment_picker.find_element(:css, "option[value='#{content_tag_2.id}']").click
    requirement_picker.find_element(:css, 'option[value="min_score"]').click
    driver.execute_script('return $(".points_possible_parent:visible").length').should == 0
  end

  it "should rearrange modules" do
    course_with_teacher_logged_in
    m1 = @course.context_modules.create!(:name => 'module 1')
    m2 = @course.context_modules.create!(:name => 'module 2')

    get "/courses/#{@course.id}/modules"
    sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait 
  
    m1_img = driver.find_element(:css, '#context_modules .context_module:first-child .reorder_module_link img')
    m2_img = driver.find_element(:css, '#context_modules .context_module:last-child .reorder_module_link img')
    driver.action.drag_and_drop(m2_img, m1_img).perform
    wait_for_ajax_requests

    m1.reload
    m1.position.should == 2
    m2.reload
    m2.position.should == 1
  end

end
