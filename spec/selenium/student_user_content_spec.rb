require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user_content" do
  include_examples "in-process server selenium tests"

  context "as a student" do

  def message_body
    <<-MESSAGE
<p>flash:</p>
<p><object width="425" height="350" data="/javascripts/swfobject/test.swf" type="application/x-shockwave-flash"><param name="wmode" value="transparent" /><param name="src" value="/javascripts/swfobject/test.swf" /></object></p>
    MESSAGE
  end

  before (:each) do
    course_with_student_logged_in(:active_all => true)
    HostUrl.stubs(:is_file_host?).returns(true)
  end

  describe "iframes" do

    it "should serve embed tags from a safefiles iframe" do
      factory_with_protected_attributes(Announcement, :context => @course, :title => "hey all read this k", :message => message_body)
      get "/courses/#{@course.to_param}/discussion_topics/#{Announcement.first.to_param}"
      wait_for_ajaximations
      name = ff(".user_content_iframe").first.attribute('name')
      in_frame(name) do
        keep_trying_until { driver.current_url.should match("/object_snippet") }
        html = Nokogiri::HTML(driver.page_source)
        obj = html.at_css('object')
        obj.should_not be_nil
        obj['data'].should == '/javascripts/swfobject/test.swf'
      end
    end

    it "should iframe calendar json requests" do
      e = factory_with_protected_attributes(CalendarEvent, :context => @course, :title => "super fun party", :description => message_body, :start_at => 5.minutes.ago, :end_at => 5.minutes.from_now)
      get "/calendar"
      wait_for_ajaximations

      ff(".user_content_iframe").size.should == 0
      event_el = keep_trying_until { f("#event_calendar_event_#{e.id}") }
      event_el.find_element(:tag_name, 'a').click
      wait_for_ajax_requests
      name = keep_trying_until { ff(".user_content_iframe").first.attribute('name') }
      in_frame(name) do
        keep_trying_until { driver.current_url.should match("/object_snippet") }
        html = Nokogiri::HTML(driver.page_source)
        obj = html.at_css('object')
        obj.should_not be_nil
        obj['data'].should == '/javascripts/swfobject/test.swf'
      end
    end
  end
end
end
