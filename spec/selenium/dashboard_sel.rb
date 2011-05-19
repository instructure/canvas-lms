require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "dashboard selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    course_with_student(:active_all => true)
    user_with_pseudonym(:user => @user)
  end

  it "should serve embed tags from a safefiles iframe" do
    factory_with_protected_attributes(Announcement, :context => @course, :title => "hey all read this k", :message => <<-MESSAGE)
<p>flash:</p>
<p><object width="425" height="350" data="/javascripts/swfobject/test.swf" type="application/x-shockwave-flash"><param name="wmode" value="transparent" /><param name="src" value="/javascripts/swfobject/test.swf" /></object></p>
MESSAGE
    login
    get "/"
    uri = nil
    name = driver.find_elements(:class_name, "user_content_iframe").first.attribute('name')
    driver.switch_to.frame(name)
    keep_trying {
      driver.current_url.should match("/object_snippet")
    }
    html = Nokogiri::HTML(driver.page_source)
    obj = html.at_css('object')
    obj.should_not be_nil
    obj['data'].should == '/javascripts/swfobject/test.swf'
  end

  def test_hiding(url)
    factory_with_protected_attributes(Announcement, :context => @course, :title => "hey all read this k", :message => "announcement")
    items = @user.stream_item_instances
    items.size.should == 1
    items.first.hidden.should == false

    login

    get url
    find_all_with_jquery("div.communication_message.announcement").size.should == 1
    # force the element to be visible so we can click it -- webdriver has a
    # hover() event but it only works on Windows so far
    driver.execute_script("$('div.communication_message.announcement .disable_item_link').css('visibility', 'visible')")
    driver.find_element(:css, "div.communication_message.announcement .disable_item_link").click
    keep_trying { find_all_with_jquery("div.communication_message.announcement").size.should == 0 }

    # should still be gone on reload
    get url
    find_all_with_jquery("div.communication_message.announcement").size.should == 0

    @user.stream_items.size.should == 0
    items.first.reload.hidden.should == true
  end

  it "should allow hiding a stream item on the dashboard" do
    test_hiding("/")
  end

  it "should allow hiding a stream item on the course page" do
    test_hiding("/courses/#{@course.to_param}")
  end
end

describe "cross-listing Windows-Firefox-Tests" do
  it_should_behave_like "dashboard selenium tests"
end
