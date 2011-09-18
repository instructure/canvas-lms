require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "dashboard selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    course_with_student_logged_in(:active_all => true)
  end

  def test_hiding(url)
    factory_with_protected_attributes(Announcement, :context => @course, :title => "hey all read this k", :message => "announcement")
    items = @user.stream_item_instances
    items.size.should == 1
    items.first.hidden.should == false

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

  it "should display assignment in to do list" do
    due_date = Time.now.utc + 2.days
    @assignment = @course.assignments.create(:name => 'test assignment', :due_at => due_date)
    get "/"
    driver.find_element(:css, '.events_list .event a').should include_text('test assignment')
  end

  it "should display calendar events in the coming up list" do
    calendar_event_model({
      :title => "super fun party",
      :description => 'celebrating stuff',
      :start_at => 5.minutes.ago,
      :end_at => 5.minutes.from_now
    })
    get "/"
    driver.find_element(:css, 'div.events_list .event a').should include_text(@event.title)
  end

  it "should add comment to announcement" do
    @context = @course
    announcement_model({ :title => "hey all read this k", :message => "announcement" })
    get "/"
    driver.find_element(:css, '.topic_message .add_entry_link').click
    driver.find_element(:name, 'discussion_entry[plaintext_message]').send_keys('first comment')
    driver.find_element(:css, '.add_sub_message_form').submit
    wait_for_ajax_requests
    wait_for_animations
    driver.find_element(:css, '.topic_message .subcontent').should include_text('first comment')
  end
  
  it "should create an announcement for the first course that is not visible in the second course" do
    @context = @course
    announcement_model({ :title => "hey all read this k", :message => "announcement" })
    @second_course = Course.create!(:name => 'second course')
    @second_course.offer!
    #add teacher as a user
    u = User.create!
    u.register!
    e = @course.enroll_teacher(u)
    e.workflow_state = 'active'
    e.save!
    @second_enrollment = @second_course.enroll_student(@user)
    @enrollment.workflow_state = 'active'
    @enrollment.save!
    @second_course.reload

    get "/"
    driver.execute_script('$("#menu > .menu-item").addClass("hover-pending").addClass("hover");')
    driver.find_element(:css, '#menu span[title="' + @second_course.name + '"]').click
    driver.find_element(:id, 'no_topics_message').should include_text('No Recent Messages')
  end

end

describe "dashboard Windows-Firefox-Tests" do
  it_should_behave_like "dashboard selenium tests"
end
