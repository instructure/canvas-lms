require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external tool buttons" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  def editor_traversal
    "$('textarea[name=message]').parent().find('iframe').contents().find('body')"
  end

  def editor_html
    driver.execute_script("return #{editor_traversal}.html()")
  end

  def editor_text
    driver.execute_script("return #{editor_traversal}.text()")
  end

  def load_selection_test_tool(element, context=@course)
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
    tool.editor_button = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :icon_url => "/images/add.png",
        :text => "Selection Test"
    }
    tool.save!

    get "/#{context.class.to_s.downcase.pluralize}/#{context.id}/discussion_topics/new"
    wait_for_ajaximations
    external_tool_button = f(".mce-instructure_external_tool_button")
    expect(external_tool_button).to be_displayed

    external_tool_button.click
    wait_for_ajax_requests
    editor_html
    expect(editor_text).to eq ""

    expect(f("#external_tool_button_dialog")).to be_displayed

    in_frame('external_tool_button_frame') do
      f(element).click
      wait_for_ajax_requests
    end
    expect(f("body")).not_to contain_jqcss("#external_tool_button_dialog:visible")
  end

  it "should allow inserting basic lti links from external tool buttons", priority: "1", test_id: 2624914 do
    load_selection_test_tool("#basic_lti_link")
    html = editor_html
    expect(html).to match(/example/)
    expect(html).to match(/lti link/)
    expect(html).to match(/lti embedded link/)
  end

  it "should allow inserting iframes from external tool buttons", priority: "1", test_id: 2624915 do
    load_selection_test_tool("#iframe_link")
    expect(editor_html).to match(/iframe/)
  end

  it "should allow inserting images from external tool buttons", priority: "1", test_id: 2624916 do
    load_selection_test_tool("#image_link")
    expect(editor_html).to match(/delete\.png/)
  end

  it "should allow inserting links from external tool buttons", priority: "1", test_id: 2624917 do
    load_selection_test_tool("#link_link")
    expect(editor_html).to match(/delete link/)
  end

  # TODO reimplement per CNVS-29606, but make sure we're testing at the right level
  it "should show limited number of external tool buttons"

  # TODO reimplement per CNVS-29607, but make sure we're testing at the right level
  it "should load external tool if selected from the dropdown"
end
