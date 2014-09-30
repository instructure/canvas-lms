require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external tool buttons" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  def load_selection_test_tool(element)
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
    tool.editor_button = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :icon_url => "/images/add.png",
        :text => "Selection Test"
    }
    tool.save!
    get "/courses/#{@course.id}/discussion_topics"
    wait_for_ajaximations

    add_button = keep_trying_until do
      add_button = f('.btn-primary')
      add_button.should_not be_nil
      add_button
    end
    expect_new_page_load { add_button.click }
    external_tool_button = f(".instructure_external_tool_button")
    external_tool_button.should be_displayed
    external_tool_button.click
    wait_for_ajax_requests
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should == ""

    fj("#external_tool_button_dialog").should be_displayed

    in_frame('external_tool_button_frame') do
      f(element).click
      wait_for_ajax_requests
    end
    keep_trying_until { !f("#external_tool_button_dialog").should_not be_displayed }
  end

  it "should allow inserting oembed content from external tool buttons" do
    load_selection_test_tool("#oembed_link")

    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should match(/ZB8T0193/)
  end

  it "should allow inserting basic lti links from external tool buttons" do
    load_selection_test_tool("#basic_lti_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should match(/example/)
    html.should match(/lti link/)
    html.should match(/lti embedded link/)
  end

  it "should allow inserting iframes from external tool buttons" do
    load_selection_test_tool("#iframe_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should match(/iframe/)
  end

  it "should allow inserting images from external tool buttons" do
    load_selection_test_tool("#image_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should match(/delete\.png/)
  end

  it "should allow inserting links from external tool buttons" do
    load_selection_test_tool("#link_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should match(/delete link/)
  end

  it "should show limited number of external tool buttons" do
    pending('fragile')
    tools = []
    4.times do |i|
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.editor_button = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :icon_url => "/images/add.png",
          :text => "Selection Test #{i}"
      }
      tool.save!
      tools << tool
    end

    get "/courses/#{@course.id}/discussion_topics"
    expect_new_page_load { f('.btn-primary').click }
    # find things whose id *ends* with instructure_external_button_...
    fj("[id$='instructure_external_button_#{tools[0].id}']").should be_displayed
    fj("[id$='instructure_external_button_#{tools[1].id}']").should be_displayed
    fj("[id$='instructure_external_button_#{tools[2].id}']").should be_nil
    fj("[id$='instructure_external_button_#{tools[3].id}']").should be_nil
    f(".mce_instructure_external_button_clump").should be_displayed
    f(".mce_instructure_external_button_clump").click

    f("#instructure_dropdown_list").should be_displayed
    ff("#instructure_dropdown_list .option").length.should == 2
  end

  it "should load external tool if selected from the dropdown" do
    pending('failing')
    tools = []
    4.times do |i|
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.editor_button = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :icon_url => "/images/add.png",
          :text => "Selection Test #{i}"
      }
      tool.save!
      tools << tool
    end

    get "/courses/#{@course.id}/discussion_topics"
    expect_new_page_load { f('.btn-primary').click }
    keep_trying_until { fj(".mce_instructure_external_button_clump").should be_displayed }
    f(".mce_instructure_external_button_clump").click

    f("#instructure_dropdown_list").should be_displayed
    ff("#instructure_dropdown_list .option").length.should == 2
    ff("#instructure_dropdown_list .option").last.click

    keep_trying_until { fj("#external_tool_button_dialog iframe:visible").should be_displayed }

    in_frame('external_tool_button_frame') do
      keep_trying_until { fj(".link:visible").should be_displayed }
      f("#oembed_link").click
      wait_for_ajax_requests
    end

    wait_for_ajax_requests
    f("#external_tool_button_dialog").should_not be_displayed
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    html.should match(/ZB8T0193/)
  end
end
