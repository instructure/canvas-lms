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
      expect(add_button).not_to be_nil
      add_button
    end
    expect_new_page_load { add_button.click }
    external_tool_button = f(".instructure_external_tool_button")
    expect(external_tool_button).to be_displayed
    external_tool_button.click
    wait_for_ajax_requests
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to eq ""

    expect(fj("#external_tool_button_dialog")).to be_displayed

    in_frame('external_tool_button_frame') do
      f(element).click
      wait_for_ajax_requests
    end
    keep_trying_until { !expect(f("#external_tool_button_dialog")).not_to be_displayed }
  end

  it "should allow inserting oembed content from external tool buttons" do
    load_selection_test_tool("#oembed_link")

    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to match(/ZB8T0193/)
  end

  it "should allow inserting basic lti links from external tool buttons" do
    load_selection_test_tool("#basic_lti_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to match(/example/)
    expect(html).to match(/lti link/)
    expect(html).to match(/lti embedded link/)
  end

  it "should allow inserting iframes from external tool buttons" do
    load_selection_test_tool("#iframe_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to match(/iframe/)
  end

  it "should allow inserting images from external tool buttons" do
    load_selection_test_tool("#image_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to match(/delete\.png/)
  end

  it "should allow inserting links from external tool buttons" do
    load_selection_test_tool("#link_link")
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to match(/delete link/)
  end

  it "should show limited number of external tool buttons" do
    skip('fragile')
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
    expect(fj("[id$='instructure_external_button_#{tools[0].id}']")).to be_displayed
    expect(fj("[id$='instructure_external_button_#{tools[1].id}']")).to be_displayed
    expect(fj("[id$='instructure_external_button_#{tools[2].id}']")).to be_nil
    expect(fj("[id$='instructure_external_button_#{tools[3].id}']")).to be_nil
    expect(f(".mce_instructure_external_button_clump")).to be_displayed
    f(".mce_instructure_external_button_clump").click

    expect(f("#instructure_dropdown_list")).to be_displayed
    expect(ff("#instructure_dropdown_list .option").length).to eq 2
  end

  it "should load external tool if selected from the dropdown" do
    skip('failing')
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
    keep_trying_until { expect(fj(".mce_instructure_external_button_clump")).to be_displayed }
    f(".mce_instructure_external_button_clump").click

    expect(f("#instructure_dropdown_list")).to be_displayed
    expect(ff("#instructure_dropdown_list .option").length).to eq 2
    ff("#instructure_dropdown_list .option").last.click

    keep_trying_until { expect(fj("#external_tool_button_dialog iframe:visible")).to be_displayed }

    in_frame('external_tool_button_frame') do
      keep_trying_until { expect(fj(".link:visible")).to be_displayed }
      f("#oembed_link").click
      wait_for_ajax_requests
    end

    wait_for_ajax_requests
    expect(f("#external_tool_button_dialog")).not_to be_displayed
    html = driver.execute_script("return $('textarea[name=message]').editorBox('get_code')")
    expect(html).to match(/ZB8T0193/)
  end
end
