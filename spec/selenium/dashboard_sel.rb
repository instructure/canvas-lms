require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "dashboard selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    course_with_student(:active_all => true)
    user_with_pseudonym(:user => @user)
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
    keep_trying_until { find_all_with_jquery("div.communication_message.announcement").size.should == 0 }

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

describe "dashboard Windows-Firefox-Tests" do
  it_should_behave_like "dashboard selenium tests"
end
