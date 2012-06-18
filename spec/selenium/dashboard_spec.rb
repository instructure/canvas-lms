require File.expand_path(File.dirname(__FILE__) + '/common')

describe "dashboard" do
  it_should_behave_like "in-process server selenium tests"

  context "as a student" do

    before (:each) do
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

      @user.recent_stream_items.size.should == 0
      items.first.reload.hidden.should == true
    end

    it "should allow hiding a stream item on the dashboard" do
      test_hiding("/")
    end

    it "should allow hiding a stream item on the course page" do
      test_hiding("/courses/#{@course.to_param}")
    end

    it "should show conversation stream items on the dashboard" do
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
      c = User.create.initiate_conversation([@user.id, User.create.id])
      c.add_message('test')

      get "/"
      driver.find_element(:css, ".reply_message .textarea").click
      driver.find_element(:css, "textarea[name='body']").send_keys("hey there")
      submit_form(".communication_sub_message")
      wait_for_ajax_requests
      messages = find_all_with_jquery(".communication_message.conversation .communication_sub_message:visible")

      # messages[-1] is the reply form
      messages[-2].text.should =~ /hey there/
    end

    it "should show appointment stream items on the dashboard" do
      Notification.create(:name => 'Appointment Group Published', :category => "Appointment Availability")
      Notification.create(:name => 'Appointment Group Updated', :category => "Appointment Availability")
      Notification.create(:name => 'Appointment Reserved For User', :category => "Appointment Signups")
      @me = @user
      student_in_course(:active_all => true, :course => @course)
      @other_student = @user
      @user = @me

      @group = @course.group_categories.create.groups.create(:context => @course)
      @group.users << @other_student << @user
      # appointment group publish notification and signup notification
      appointment_participant_model(:course => @course, :participant => @group, :updating_user => @other_student)
      # appointment group update notification
      @appointment_group.update_attributes(:new_appointments => [[Time.now.utc + 2.hour, Time.now.utc + 3.hour]])

      get "/"
      ffj(".topic_message div.communication_message.dashboard_notification").size.should == 3
      # appointment group publish and update notifications
      ffj("div.communication_message.message_appointment_group_#{@appointment_group.id}").size.should == 2
      # signup notification
      ffj("div.communication_message.message_group_#{@group.id}").size.should == 1
    end

    it "should display assignment in to do list" do
      due_date = Time.now.utc + 2.days
      @assignment = assignment_model({:due_at => due_date, :course => @course})
      get "/"
      driver.find_element(:css, '.events_list .event a').should include_text(@assignment.title)
      # use jQuery to get the text since selenium can't figure it out when the elements aren't displayed
      driver.execute_script("return $('.event a .tooltip_text').text()").should match(@course.short_name)
    end

    it "should put locked graded discussions / quizzes in the coming up list only" do
      def check_list_text(list_element, text, should_have_text = true)
        if should_have_text
          list_element.should include_text(text)
        else
          list_element.should_not include_text(text)
        end
      end

      DUE_DATE = Time.now.utc + 2.days
      names = ['locked discussion assignment', 'locked quiz']
      @course.assignments.create(:name => names[0], :submission_types => 'discussion', :due_at => DUE_DATE, :lock_at => Time.now, :unlock_at => DUE_DATE)
      q = @course.quizzes.create!(:title => names[1], :due_at => DUE_DATE, :lock_at => Time.now, :unlock_at => DUE_DATE)
      q.workflow_state = 'available'
      q.save
      q.reload
      get "/"

      # No "To Do" list shown
      f('.right-side-list.to-do-list').should be_nil
      coming_up_list = driver.find_element(:css, '.right-side-list.events')

      2.times { |i| check_list_text(coming_up_list, names[i]) }
    end

    it "should limit the number of visible items in the to do list" do
      due_date = Time.now.utc + 2.days
      20.times do
        assignment_model :due_at => due_date, :course => @course, :submission_types => 'online_text_entry'
      end

      get "/"

      find_all_with_jquery(".to-do-list li:visible").size.should == 5 + 1 # +1 is the see more link
      driver.find_element(:css, ".more_link").click
      wait_for_animations
      find_all_with_jquery(".to-do-list li:visible").size.should == 20
    end

    it "should display assignments to do in to do list and assignments menu for a student" do
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
      assignment_menu = driver.find_element(:id, 'assignments_menu_item')
      driver.action.move_to(assignment_menu).perform
      assignment_menu.should include_text("To Turn In")
      assignment_menu.should include_text(assignment.title)
    end

    it "should display student groups in course menu" do
      @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
      Enrollment.update_all(["created_at = ?", 1.minute.ago])

      get "/"

      course_menu = driver.find_element(:id, 'courses_menu_item')

      driver.action.move_to(course_menu).perform
      course_menu.should include_text('My Courses')
      course_menu.should include_text(@course.name)
    end


    it "should display student groups in course menu" do
      group = Group.create!(:name => "group1", :context => @course)
      group.add_user(@user)
      @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
      Enrollment.update_all(["created_at = ?", 1.minute.ago])

      get "/"

      course_menu = driver.find_element(:id, 'courses_menu_item')

      driver.action.move_to(course_menu).perform
      course_menu.should include_text('Current Groups')
      course_menu.should include_text(group.name)
    end

    it "should display scheduled web conference in stream" do
      PluginSetting.create!(:name => "dim_dim", :settings => {"domain" => "dimdim.instructure.com"})

      @conference = @course.web_conferences.build({:title => "my Conference", :conference_type => "DimDim", :duration => 60})
      @conference.user = @user
      @conference.save!
      @conference.add_initiator(@user)
      @conference.add_invitee(@user)
      @conference.save!

      get "/"

      find_with_jquery('#topic_list .topic_message:last-child .header_title').should include_text(@conference.title)
    end

    it "should display calendar events in the coming up list" do
      calendar_event_model({
                               :title => "super fun party",
                               :description => 'celebrating stuff',
                               :start_at => 5.minutes.from_now,
                               :end_at => 10.minutes.from_now
                           })
      get "/"
      driver.find_element(:css, 'div.events_list .event a').should include_text(@event.title)
    end

    it "should display quiz submissions with essay questions as submitted in coming up list" do
      quiz_with_graded_submission([:question_data => {:id => 31, 
                                                      :name => "Quiz Essay Question 1", 
                                                      :question_type => 'essay_question', 
                                                      :question_text => 'qq1', 
                                                      :points_possible => 10}],
                                  {:user => @student, :course => @course}) do
        {
          "question_31"   => "<p>abeawebawebae</p>", 
          "question_text" => "qq1"
        }
      end

      @assignment.due_at = Time.now.utc + 1.week
      @assignment.save!

      get "/"
      driver.execute_script("$('.events_list .event .tooltip_wrap, .events_list .event .tooltip_text').css('visibility', 'visible')")
      f('.events_list .event .tooltip_wrap').should include_text 'submitted'
    end

    it "should add comment to announcement" do
      @context = @course
      announcement_model({:title => "hey all read this k", :message => "announcement"})
      get "/"
      driver.find_element(:css, '.topic_message .add_entry_link').click
      driver.find_element(:name, 'discussion_entry[plaintext_message]').send_keys('first comment')
      submit_form('.add_sub_message_form')
      wait_for_ajax_requests
      wait_for_animations
      driver.find_element(:css, '.topic_message .subcontent').should include_text('first comment')
    end

    it "should create an announcement for the first course that is not visible in the second course" do
      @context = @course
      announcement_model({:title => "hey all read this k", :message => "announcement"})
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

    it "should validate the functionality of soft concluded courses in dropdown" do
      course_with_student(:active_all => true, :course_name => "a_soft_concluded_course", :user => @user)
      c1 = @course
      c1.conclude_at = 1.week.ago
      c1.start_at = 1.month.ago
      c1.restrict_enrollments_to_course_dates = true
      c1.save!
      get "/"

      driver.action.move_to(driver.find_element(:id, 'courses_menu_item')).perform
      course_menu = driver.find_element(:id, 'menu_enrollments')
      course_menu.should be_displayed
      course_menu.should_not include_text(c1.name)
    end
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in(:active_cc => true)
    end

    it "should validate the functionality of soft concluded courses on courses page" do
      term = EnrollmentTerm.new(:name => "Super Term", :start_at => 1.month.ago, :end_at => 1.week.ago)
      term.root_account_id = @course.root_account_id
      term.save!
      c1 = @course
      c1.name = 'a_soft_concluded_course'
      c1.update_attributes!(:enrollment_term => term)
      c1.reload

      get "/courses"
      driver.find_element(:css, '.past_enrollments').should include_text(c1.name)
    end

    it "should display assignment to grade in to do list and assignments menu for a teacher" do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      get "/"

      #verify assignment is in to do list
      driver.find_element(:css, '.to-do-list > li').should include_text('Grade ' + assignment.title)

      #verify assignment is in drop down
      assignment_menu = driver.find_element(:id, 'assignments_menu_item')
      driver.action.move_to(assignment_menu).perform
      assignment_menu.should include_text("To Grade")
      assignment_menu.should include_text(assignment.title)
    end

    it "should display appointment groups in todo list" do
      ag = AppointmentGroup.create! :title => "appointment group",
                                    :contexts => [@course],
                                    :new_appointments => [[Time.now.utc + 2.hour, Time.now.utc + 3.hour]]
      student_in_course(:course => @course, :active_all => true)
      ag.appointments.first.reserve_for(@student, @student)
      get "/"
      f('#right-side .events_list').text.should include 'appointment group'
    end

    it "should show submitted essay quizzes in the todo list" do
      quiz_title = 'new quiz'
      student_in_course(:active_all => true)
      q = @course.quizzes.create!(:title => quiz_title)
      q.quiz_questions.create!(:question_data => {:id => 31, :name => "Quiz Essay Question 1", :question_type => 'essay_question', :question_text => 'qq1', :points_possible => 10})
      q.generate_quiz_data
      q.workflow_state = 'available'
      q.save
      q.reload
      qs = q.generate_submission(@user)
      qs.mark_completed
      qs.submission_data = {"question_31" => "<p>abeawebawebae</p>", "question_text" => "qq1"}
      qs.grade_submission
      get "/"

      todo_list = f('.to-do-list')
      todo_list.should_not be_nil
      todo_list.should include_text(quiz_title)
    end

    context "course menu customization" do

      it "should allow customization if there are sufficient courses" do
        20.times { course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}) }

        get "/"

        course_menu = driver.find_element(:id, 'courses_menu_item')
        driver.action.move_to(course_menu).perform
        course_menu.should include_text('My Courses')
        course_menu.should include_text('Customize')
        course_menu.should include_text('View all courses')
      end

      it "should allow customization if there are sufficient course invitations" do
        20.times { course_with_teacher({:user => user_with_communication_channel(:user_state => :creation_pending), :active_course => true}) }

        get "/"

        course_menu = driver.find_element(:id, 'courses_menu_item')
        driver.action.move_to(course_menu).perform
        course_menu.should include_text('My Courses')
        course_menu.should include_text('Customize')
        course_menu.should include_text('View all courses')
      end

      it "should allow customization if all courses are already favorited" do
        @user.favorites.create(:context => @course)
        20.times {
          course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true})
          @user.favorites.create(:context => @course)
        }

        get "/"

        course_menu = driver.find_element(:id, 'courses_menu_item')
        driver.action.move_to(course_menu).perform
        course_menu.should include_text('My Courses')
        course_menu.should include_text('Customize')
      end

      it "should allow customization even before the course ajax request comes back" do
        20.times { course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}) }

        get "/"

        # Now artificially make the next ajax request slower. We want to make sure that we click the
        # customize button before the ajax request returns. Delaying the request by 1s should
        # be enough.
        UsersController.before_filter { sleep 1; true }

        course_menu = driver.find_element(:id, 'courses_menu_item')
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
  end
end

