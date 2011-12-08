require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "dashboard selenium tests" do
  it_should_behave_like "in-process server selenium tests"

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
    course_with_student_logged_in(:active_all => true)
    test_hiding("/")
  end

  it "should allow hiding a stream item on the course page" do
    course_with_student_logged_in(:active_all => true)
    test_hiding("/courses/#{@course.to_param}")
  end

  it "should show conversation stream items on the dashboard" do
    course_with_student_logged_in(:active_all => true)
    c = User.create.initiate_conversation([@user.id, User.create.id])
    c.add_message('test')
    c.add_participants([User.create.id])

    items = @user.stream_item_instances
    items.size.should == 1

    get "/"
    find_all_with_jquery("div.communication_message.conversation").size.should == 1
    find_all_with_jquery("div.communication_message.conversation .communication_sub_message:visible").size.should == 3 # two messages, plus add message form
  end

  it "should allow replying to conversation stream items" do
    course_with_student_logged_in(:active_all => true)
    c = User.create.initiate_conversation([@user.id, User.create.id])
    c.add_message('test')

    get "/"
    driver.find_element(:css, ".reply_message .textarea").click
    driver.find_element(:css, "textarea[name='body']").send_keys("hey there")
    driver.find_element(:css, ".communication_sub_message .submit_button").click
    wait_for_ajax_requests
    messages = find_all_with_jquery(".communication_message.conversation .communication_sub_message:visible")

    # messages[-1] is the reply form
    messages[-2].text.should =~ /hey there/
  end

  it "should display assignment in to do list" do
    course_with_student_logged_in

    due_date = Time.now.utc + 2.days
    @assignment = assignment_model({:due_at => due_date, :course => @course})
    get "/"
    driver.find_element(:css, '.events_list .event a').should include_text(@assignment.title)
  end

  it "should display assignment to grade in to do list and assignments menu for a teacher" do
    course_with_teacher_logged_in
    assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
    student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    assignment.reload
    assignment.submit_homework(student, {:submission_type => 'online_text_entry'})
    assignment.reload
    get "/"

    #verify assignment is in to do list
    driver.find_element(:css, '.to-do-list > li').should include_text('Grade ' + assignment.title)

    #verify assignment is in drop down
    assignment_menu = driver.find_element(:link, 'Assignments').find_element(:xpath, '..')
    driver.action.move_to(assignment_menu).perform
    assignment_menu.should include_text("Needing Grading")
    assignment_menu.should include_text(assignment.title)
  end

  it "should display assignments to do in to do list and assignments menu for a student" do
    course_with_student_logged_in
    notification_model(:name => 'Assignment Due Date Changed')
    notification_policy_model(:notification_id => @notification.id)
    assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
    assignment.due_at = Time.now + 60
    assignment.created_at = 1.month.ago
    assignment.save!

    get "/"

    #verify assignment changed notice is in messages
    driver.find_element(:css, '#topic_list .topic_message').should include_text('Assignment Due Date Changed')
    #verify assignment is in to do list
    driver.find_element(:css, '.to-do-list > li').should include_text(assignment.submission_action_string)

    #verify assignment is in drop down
    assignment_menu = driver.find_element(:link, 'Assignments').find_element(:xpath, '..')
    driver.action.move_to(assignment_menu).perform
    assignment_menu.should include_text("To Turn In")
    assignment_menu.should include_text(assignment.title)
  end

  it "should display student groups in course menu" do
    course_with_student_logged_in
    @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
    Enrollment.update_all(["created_at = ?", 1.minute.ago])

    get "/"

    course_menu = driver.find_element(:link, 'Courses').find_element(:xpath, '..')

    driver.action.move_to(course_menu).perform
    course_menu.should include_text('My Courses')
    course_menu.should include_text(@course.name)
  end


  it "should display student groups in course menu" do
    course_with_student_logged_in
    group = Group.create!(:name=>"group1", :context => @course)
    group.add_user(@user)
    @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
    Enrollment.update_all(["created_at = ?", 1.minute.ago])

    get "/"

    course_menu = driver.find_element(:link, 'Courses & Groups').find_element(:xpath, '..')

    driver.action.move_to(course_menu).perform
    course_menu.should include_text('Current Groups')
    course_menu.should include_text(group.name)
  end

  context "course menu customization" do
    it "should not allow customization if there are insufficient courses" do
      course_with_teacher_logged_in

      get "/"

      course_menu = driver.find_element(:link, 'Courses').find_element(:xpath, '..')
      driver.action.move_to(course_menu).perform
      course_menu.should include_text('My Courses')
      course_menu.should_not include_text('Customize')
    end

    it "should allow customization if there are sufficient courses" do
      course_with_teacher_logged_in
      20.times { course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}) }

      get "/"

      course_menu = driver.find_element(:link, 'Courses').find_element(:xpath, '..')
      driver.action.move_to(course_menu).perform
      course_menu.should include_text('My Courses')
      course_menu.should include_text('Customize')
      course_menu.should include_text('View all courses')
    end

    it "should allow customization if there are sufficient course invitations" do
      course_with_teacher_logged_in(:active_cc => true)
      20.times { course_with_teacher({:user => user_with_communication_channel(:user_state => :creation_pending), :active_course => true}) }

      get "/"

      course_menu = driver.find_element(:link, 'Courses').find_element(:xpath, '..')
      driver.action.move_to(course_menu).perform
      course_menu.should include_text('My Courses')
      course_menu.should include_text('Customize')
      course_menu.should include_text('View all courses')
    end

    it "should allow customization if all courses are already favorited" do
      course_with_teacher_logged_in
      @user.favorites.create(:context => @course)
      20.times {
        course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true})
        @user.favorites.create(:context => @course)
      }

      get "/"

      course_menu = driver.find_element(:link, 'Courses').find_element(:xpath, '..')
      driver.action.move_to(course_menu).perform
      course_menu.should include_text('My Courses')
      course_menu.should include_text('Customize')
    end

    it "should allow customization even before the course ajax request comes back" do
      course_with_teacher_logged_in
      20.times { course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}) }

      get "/"

      # Now artificially make the next ajax request slower. We want to make sure that we click the
      # customize button before the ajax request returns. Delaying the request by 1s should
      # be enough.
      UsersController.before_filter { sleep 1; true }

      course_menu = driver.find_element(:link, 'Courses').find_element(:xpath, '..')
      driver.execute_script(%{$("#menu li.menu-item:first").trigger('mouseenter')})
      sleep 0.4 # there's a fixed 300ms delay before the menu will display

      # For some reason, a normal webdriver click here causes strangeness on FF in XP with
      # firebug installed.
      driver.execute_script("$('#menu .customListOpen:first').click()")
      wait_for_ajaximations

      UsersController.filter_chain.pop

      course_menu.should include_text('My Courses')
      course_menu.should include_text('View all courses')
      course_menu.find_element(:css, '.customListWrapper').should be_displayed
    end
  end

  it "should display scheduled web conference in stream" do
    PluginSetting.create!(:name => "dim_dim", :settings => {"domain" => "dimdim.instructure.com"})

    course_with_student_logged_in
    @conference = @course.web_conferences.build({:title => "my Conference", :conference_type => "DimDim", :duration => 60})
    @conference.user = @user
    @conference.save!
    @conference.add_initiator(@user)
    @conference.add_invitee(@user)
    @conference.save!

    get "/"

    driver.find_element(:css, '#topic_list .topic_message:last-child .header_title').should include_text(@conference.title)
  end

  it "should display calendar events in the coming up list" do
    course_with_student_logged_in(:active_all => true)
    calendar_event_model({
      :title => "super fun party",
      :description => 'celebrating stuff',
      :start_at => 5.minutes.from_now,
      :end_at => 10.minutes.from_now
    })
    get "/"
    driver.find_element(:css, 'div.events_list .event a').should include_text(@event.title)
  end

  it "should add comment to announcement" do
    course_with_student_logged_in(:active_all => true)
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
    course_with_student_logged_in(:active_all => true)
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
    Enrollment.update_all(["created_at = ?", 1.minute.ago]) # need to make created_at and updated_at different

    get "/"

    driver.find_element(:id, 'no_topics_message').should_not include_text('No Recent Messages')

    get "/courses/#{@second_course.id}"

    driver.find_element(:id, 'no_topics_message').should include_text('No Recent Messages')

  end

end

describe "dashboard Windows-Firefox-Tests" do
  it_should_behave_like "dashboard selenium tests"
end
