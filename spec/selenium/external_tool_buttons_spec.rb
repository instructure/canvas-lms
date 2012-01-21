require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external tool buttons selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def load_selection_test_tool(&block)
    course_with_teacher_logged_in
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
    tool.settings[:editor_button] = {
      :url => "http://#{HostUrl.default_host}/selection_test",
      :icon_url => "/images/add.png",
      :text => "Selection Test"
    }
    tool.save!
    get "/courses/#{@course.id}/discussion_topics"
    
    driver.find_element(:css, ".add_topic_link").click
    keep_trying_until {  driver.find_elements(:css, "#topic_content_topic_new_instructure_external_button_#{tool.id}").detect(&:displayed?) }
    driver.find_element(:css, "#topic_content_topic_new_instructure_external_button_#{tool.id}").click
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should == ""

    keep_trying_until { driver.find_elements(:css, "#external_tool_button_dialog iframe").detect(&:displayed?) }
    
    frame = driver.find_element(:css, "#external_tool_button_dialog iframe")
    
    in_frame('external_tool_button_frame') do
      keep_trying_until { driver.find_elements(:css, ".link").detect(&:displayed?) }
      yield
    end
    keep_trying_until { !driver.find_element(:css, "#external_tool_button_dialog").displayed? }
  end
  
  it "should allow inserting oembed content from external tool buttons" do
    load_selection_test_tool do
      driver.find_element(:css, "#oembed_link").click
    end
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should match(/ZB8T0193/)
  end
  
  it "should allow inserting basic lti links from external tool buttons" do
    load_selection_test_tool do
      driver.find_element(:css, "#basic_lti_link").click
    end
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should match(/example/)
    html.should match(/lti link/)
    html.should match(/lti embedded link/)
  end
  
  it "should allow inserting iframes from external tool buttons" do
    load_selection_test_tool do
      driver.find_element(:css, "#iframe_link").click
    end
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should match(/iframe/)
  end
  
  it "should allow inserting images from external tool buttons" do
    load_selection_test_tool do
      driver.find_element(:css, "#image_link").click
    end
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should match(/delete\.png/)
  end
  
  it "should allow inserting links from external tool buttons" do
    load_selection_test_tool do
      driver.find_element(:css, "#link_link").click
    end
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should match(/delete link/)
  end
  
  it "should show limited number of external tool buttons" do
    course_with_teacher_logged_in
    tools = []
    4.times do |i|
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.settings[:editor_button] = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :icon_url => "/images/add.png",
        :text => "Selection Test #{i}"
      }
      tool.save!
      tools << tool
    end

    get "/courses/#{@course.id}/discussion_topics"
    driver.find_element(:css, ".add_topic_link").click
    keep_trying_until {  driver.find_elements(:css, "#topic_content_topic_new_instructure_external_button_#{tools[0].id}").detect(&:displayed?) }
    driver.find_element(:css, "#topic_content_topic_new_instructure_external_button_#{tools[1].id}").should be_displayed
    driver.find_elements(:css, "#topic_content_topic_new_instructure_external_button_#{tools[2].id}").length.should == 0
    driver.find_elements(:css, "#topic_content_topic_new_instructure_external_button_#{tools[3].id}").length.should == 0
    driver.find_element(:css, "#topic_content_topic_new_instructure_external_button_clump").should be_displayed
    driver.find_element(:css, "#topic_content_topic_new_instructure_external_button_clump").click

    driver.find_element(:css, "#instructure_dropdown_list").should be_displayed
    driver.find_elements(:css, "#instructure_dropdown_list div.option").length.should == 2
  end
  
  it "should load external tool if selected from the dropdown" do
    course_with_teacher_logged_in
    tools = []
    4.times do |i|
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.settings[:editor_button] = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :icon_url => "/images/add.png",
        :text => "Selection Test #{i}"
      }
      tool.save!
      tools << tool
    end

    get "/courses/#{@course.id}/discussion_topics"
    driver.find_element(:css, ".add_topic_link").click
    keep_trying_until {  driver.find_elements(:css, "#topic_content_topic_new_instructure_external_button_clump").detect(&:displayed?) }
    driver.find_element(:css, "#topic_content_topic_new_instructure_external_button_clump").click

    driver.find_element(:css, "#instructure_dropdown_list").should be_displayed
    driver.find_elements(:css, "#instructure_dropdown_list div.option").length.should == 2
    driver.find_elements(:css, "#instructure_dropdown_list div.option").last.click
    
    keep_trying_until { driver.find_elements(:css, "#external_tool_button_dialog iframe").detect(&:displayed?) }
    
    frame = driver.find_element(:css, "#external_tool_button_dialog iframe")
    
    in_frame('external_tool_button_frame') do
      keep_trying_until { driver.find_elements(:css, ".link").detect(&:displayed?) }
      driver.find_element(:css, "#oembed_link").click
    end
    keep_trying_until { !driver.find_element(:css, "#external_tool_button_dialog").displayed? }
    html = driver.execute_script("return $('#topic_content_topic_new').editorBox('get_code')")
    html.should match(/ZB8T0193/)
  end
end
