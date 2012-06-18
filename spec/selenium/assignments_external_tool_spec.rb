require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external tool assignments" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @t1 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool1", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 1')
    @t2 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool2", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 2')
  end

  it "should allow creating" do
    skip_if_ie('Out of memory')
    get "/courses/#{@course.id}/assignments"

    #create assignment
    click_option('#right-side select.assignment_groups_select', 'Assignments')
    driver.find_element(:css, '.add_assignment_link').click
    driver.find_element(:id, 'assignment_title').send_keys('test1')
    driver.find_element(:css, '.ui-datepicker-trigger').click
    datepicker = datepicker_next
    datepicker.find_element(:css, '.ui-datepicker-ok').click
    driver.find_element(:id, 'assignment_points_possible').clear
    driver.find_element(:id, 'assignment_points_possible').send_keys('5')
    click_option('.assignment_submission_types', 'External Tool')
    expect_new_page_load { driver.find_element(:css, '.more_options_link').click }
    keep_trying_until do
      find_with_jquery('#context_external_tools_select td.tools .tool:first-child:visible').click
      sleep 2 # wait for javascript to execute
      driver.find_element(:css, '#context_external_tools_select input#external_tool_create_url').attribute('value').should == @t1.url
    end
    keep_trying_until do
      driver.find_elements(:css, '#context_external_tools_select td.tools .tool')[1].click
      driver.find_element(:css, '#context_external_tools_select input#external_tool_create_url').attribute('value').should == @t2.url
    end
    driver.find_element(:css, '#select_context_content_dialog .add_item_button').click
    driver.find_element(:css, '#assignment_external_tool_tag_attributes_url').attribute('value').should == @t2.url
    submit_form('form.new_assignment')

    wait_for_ajax_requests
    a = @course.assignments(true).last
    a.should be_present
    a.submission_types.should == 'external_tool'
    a.external_tool_tag.should be_present
    a.external_tool_tag.url.should == @t2.url
    a.external_tool_tag.new_tab.should be_false
  end

  it "should allow editing" do
    skip_if_ie('Out of memory')
    a = assignment_model(:course => @course, :title => "test2", :submission_types => 'external_tool')
    a.create_external_tool_tag(:url => @t1.url)
    a.external_tool_tag.update_attribute(:content_type, 'ContextExternalTool')

    get "/courses/#{@course.id}/assignments/#{a.id}/edit"
    # don't display dialog on page load, since url isn't blank
    driver.find_element(:css, '#context_external_tools_select').should_not be_displayed
    driver.find_element(:css, '#assignment_external_tool_tag_attributes_url').click
    driver.find_elements(:css, '#context_external_tools_select td.tools .tool')[0].click
    driver.find_element(:css, '#context_external_tools_select input#external_tool_create_url').attribute('value').should == @t1.url
    driver.find_element(:css, '#select_context_content_dialog .add_item_button').click
    driver.find_element(:css, '#assignment_external_tool_tag_attributes_url').attribute('value').should == @t1.url
    submit_form('form.edit_assignment')

    wait_for_ajax_requests
    a.reload
    a.submission_types.should == 'external_tool'
    a.external_tool_tag.should be_present
    a.external_tool_tag.url.should == @t1.url
  end
end