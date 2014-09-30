require File.expand_path(File.dirname(__FILE__) + '/common')

describe "dashboard" do
  include_examples "in-process server selenium tests"

  context "as a student" do

    before (:each) do
      course_with_student_logged_in(:active_all => true)
    end

    def create_announcement
      factory_with_protected_attributes(Announcement, {
          :context => @course,
          :title => "hey all read this k",
          :message => "announcement"
      })
    end

    def click_recent_activity_header
      f('.stream-announcement .stream_header').click
    end

    def test_hiding(url)
      create_announcement
      items = @user.stream_item_instances
      items.size.should == 1
      items.first.hidden.should == false

      get url
      click_recent_activity_header
      item_selector = '#announcement-details tbody tr'
      ff(item_selector).size.should == 1
      f('#announcement-details .ignore-item').click
      keep_trying_until { ff(item_selector).size.should == 0 }

      # should still be gone on reload
      get url
      ff(item_selector).size.should == 0

      @user.recent_stream_items.size.should == 0
      items.first.reload.hidden.should == true
    end

    it "should allow hiding a stream item on the dashboard", :non_parallel do
      test_hiding("/")
    end

    it "should allow hiding a stream item on the course page" do
      test_hiding("/courses/#{@course.to_param}")
    end

    def click_recent_activity_header(type='announcement')
      f(".stream-#{type} .stream_header").click
    end

    def assert_recent_activity_category_closed(type='announcement')
      f(".stream-#{type} .details_container").should_not be_displayed
    end

    def assert_recent_activity_category_is_open(type='announcement')
      f(".stream-#{type} .details_container").should be_displayed
    end

    def click_recent_activity_course_link(type='announcement')
      f(".stream-#{type} .links a").click
    end

    # so we can click the link w/o a page load
    def disable_recent_activity_header_course_link
      driver.execute_script <<-JS
        $('.stream-announcement .links a').attr('href', '#');
      JS
    end

    it "should expand/collapse recent activity category" do
      create_announcement
      get '/'
      assert_recent_activity_category_closed
      click_recent_activity_header
      assert_recent_activity_category_is_open
      click_recent_activity_header
      assert_recent_activity_category_closed
    end

    it "should not expand category when a course/group link is clicked" do
      create_announcement
      get '/'
      assert_recent_activity_category_closed
      disable_recent_activity_header_course_link
      click_recent_activity_course_link
      assert_recent_activity_category_closed
    end

    it "should update the item count on stream item hide"
    it "should remove the stream item category if all items are removed"

    it "should show conversation stream items on the dashboard" do
      c = User.create.initiate_conversation([@user, User.create])
      c.add_message('test')
      c.add_participants([User.create])

      items = @user.stream_item_instances
      items.size.should == 1

      get "/"
      ff('#conversation-details tbody tr').size.should == 1
    end

    it "should show account notifications on the dashboard" do
      a1 = @course.account.announcements.create!(:subject => 'test',
                                                 :message => "hey there",
                                                 :start_at => Date.today - 1.day,
                                                 :end_at => Date.today + 1.day)
      a2 = @course.account.announcements.create!(:subject => 'test 2',
                                                 :message => "another annoucement",
                                                 :start_at => Date.today - 1.day,
                                                 :end_at => Date.today + 1.day)

      get "/"
      messages = ffj("#dashboard .global-message .message.user_content")
      messages.size.should == 2
      messages[0].text.should == a1.message
      messages[1].text.should == a2.message
    end

    it "should interpolate the user's domain in global notifications" do
      announcement = @course.account.announcements.create!(:message => "blah blah http://random-survey-startup.ly/?some_GET_parameter_by_which_to_differentiate_results={{ACCOUNT_DOMAIN}}",
                                                           :subject => 'test',
                                                           :start_at => Date.today,
                                                           :end_at => Date.today + 1.day)

      get "/"
      fj("#dashboard .global-message .message.user_content").text.should == announcement.message.gsub("{{ACCOUNT_DOMAIN}}", @course.account.domain)
    end

    it "should interpolate the user's id in global notifications" do
      announcement = @course.account.announcements.create!(:message => "blah blah http://random-survey-startup.ly/?surveys_are_not_really_anonymous={{CANVAS_USER_ID}}",
                                                           :subject => 'test',
                                                           :start_at => Date.today,
                                                           :end_at => Date.today + 1.day)
      get "/"
      fj("#dashboard .global-message .message.user_content").text.should == announcement.message.gsub("{{CANVAS_USER_ID}}", @user.global_id.to_s)
    end

    it "should show appointment stream items on the dashboard" do
      pending "we need to add this stuff back in"
      Notification.create(:name => 'Appointment Group Published', :category => "Appointment Availability")
      Notification.create(:name => 'Appointment Group Updated', :category => "Appointment Availability")
      Notification.create(:name => 'Appointment Reserved For User', :category => "Appointment Signups")
      @me = @user
      student_in_course(:active_all => true, :course => @course)
      @other_student = @user
      @user = @me

      @group = group_category.groups.create(context: @course)
      @group.users << @other_student << @user
      # appointment group publish notification and signup notification
      appointment_participant_model(:course => @course, :participant => @group, :updating_user => @other_student)
      # appointment group update notification
      @appointment_group.update_attributes(:new_appointments => [[Time.now.utc + 2.hour, Time.now.utc + 3.hour]])

      get "/"
      ffj(".topic_message .communication_message.dashboard_notification").size.should == 3
      # appointment group publish and update notifications
      ffj(".communication_message.message_appointment_group_#{@appointment_group.id}").size.should == 2
      # signup notification
      ffj(".communication_message.message_group_#{@group.id}").size.should == 1
    end

    it "should display assignment in to do list" do
      due_date = Time.now.utc + 2.days
      @assignment = assignment_model({:due_at => due_date, :course => @course})
      get "/"
      f('.events_list .event a').should include_text(@assignment.title)
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

      due_date = Time.now.utc + 2.days
      names = ['locked discussion assignment', 'locked quiz']
      @course.assignments.create(:name => names[0], :submission_types => 'discussion', :due_at => due_date, :lock_at => Time.now, :unlock_at => due_date)
      q = @course.quizzes.create!(:title => names[1], :due_at => due_date, :lock_at => Time.now, :unlock_at => due_date)
      q.workflow_state = 'available'
      q.save
      q.reload
      get "/"

      # No "To Do" list shown
      f('.right-side-list.to-do-list').should be_nil
      coming_up_list = f('.right-side-list.events')

      2.times { |i| check_list_text(coming_up_list, names[i]) }
    end

    it "should limit the number of visible items in the to do list" do
      due_date = Time.now.utc + 2.days
      20.times do
        assignment_model :due_at => due_date, :course => @course, :submission_types => 'online_text_entry'
      end

      get "/"

      keep_trying_until { ffj(".to-do-list li:visible").size.should == 5 + 1 } # +1 is the see more link
      f(".more_link").click
      wait_for_ajaximations
      ffj(".to-do-list li:visible").size.should == 20
    end

    it "should display assignments to do in to do list for a student" do
      notification_model(:name => 'Assignment Due Date Changed')
      notification_policy_model(:notification_id => @notification.id)
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      get "/"

      #verify assignment changed notice is in messages
      f('.stream-assignment .stream_header').click
      f('#assignment-details').should include_text('Assignment Due Date Changed')
      #verify assignment is in to do list
      f('.to-do-list > li').should include_text(assignment.submission_action_string)
    end

    it "should display course name in course menu" do
      @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
      Enrollment.update_all(:created_at => 1.minute.ago)

      get "/"
      driver.execute_script %{$('#courses_menu_item').addClass('hover');}
      wait_for_ajaximations
      f('#courses_menu_item').should include_text('My Courses')
      f('#courses_menu_item').should include_text(@course.name)
    end

    it "should display should display student groups in course menu" do
      pending('broken')
      group = Group.create!(:name => "group1", :context => @course)
      group.add_user(@user)
      @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
      Enrollment.update_all(:created_at => 1.minute.ago)

      get "/"
      driver.execute_script %{$('#courses_menu_item').addClass('hover');}
      wait_for_ajaximations
      f('#courses_menu_item').should include_text(group.name)
      f('#courses_menu_item').should include_text('Current Groups')
    end

    it "should present /courses as the href of the courses nav item" do
      @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
      Enrollment.update_all(:created_at => 1.minute.ago)

      get '/'

      keep_trying_until do
        f('#courses_menu_item a').attribute('href').should include('courses')
      end
    end

    it "should display scheduled web conference in stream" do
      PluginSetting.create!(:name => "wimba", :settings => {"domain" => "wimba.instructure.com"})

      # NOTE: recently changed the behavior here: conferences only display on
      # the course page, and they only display when they are in progress
      @conference = @course.web_conferences.build({:title => "my Conference", :conference_type => "Wimba", :duration => 60})
      @conference.user = @user
      @conference.save!
      @conference.restart
      @conference.add_initiator(@user)
      @conference.add_invitee(@user)
      @conference.save!

      get "/courses/#{@course.to_param}"
      f('.conference .message').should include_text(@conference.title)
    end

    it "should display calendar events in the coming up list" do
      calendar_event_model({
                               :title => "super fun party",
                               :description => 'celebrating stuff',
                               :start_at => 5.minutes.from_now,
                               :end_at => 10.minutes.from_now
                           })
      get "/"
      f('.events_list .event a').should include_text(@event.title)
    end

    it "should display quiz submissions with essay questions as submitted in coming up list" do
      quiz_with_graded_submission([:question_data => {:id => 31,
                                                      :name => "Quiz Essay Question 1",
                                                      :question_type => 'essay_question',
                                                      :question_text => 'qq1',
                                                      :points_possible => 10}],
                                  {:user => @student, :course => @course}) do
        {
            "question_31" => "<p>abeawebawebae</p>",
            "question_text" => "qq1"
        }
      end

      @assignment.due_at = Time.now.utc + 1.week
      @assignment.save!

      get "/"
      keep_trying_until { ffj(".events_list .event .tooltip_wrap").size.should > 0 }
      driver.execute_script("$('.events_list .event .tooltip_wrap, .events_list .event .tooltip_text').css('visibility', 'visible')")
      f('.events_list .event .tooltip_wrap').should include_text 'submitted'
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
      Enrollment.update_all(:created_at => 1.minute.ago) # need to make created_at and updated_at different

      get "/"
      f('.no-recent-messages').should be_nil

      get "/courses/#{@second_course.id}"
      f('.no-recent-messages').should include_text('No Recent Messages')
    end

    it "should validate the functionality of soft concluded courses in dropdown" do
      course_with_student(:active_all => true, :course_name => "a_soft_concluded_course", :user => @user)
      c1 = @course
      c1.conclude_at = 1.week.ago
      c1.start_at = 1.month.ago
      c1.restrict_enrollments_to_course_dates = true
      c1.save!
      get "/"

      driver.execute_script %{$('#courses_menu_item').addClass('hover');}
      item = fj('#menu_enrollments')
      item.should be_displayed
      item.should_not include_text(c1.name)
    end

    it "should show recent feedback and it should work" do
      assign = @course.assignments.create!(:title => 'hi', :due_at => 1.day.ago, :points_possible => 5)
      assign.grade_student(@student, :grade => '4')

      get "/"
      wait_for_ajaximations

      f('.recent_feedback a').attribute('href').should match /courses\/#{@course.id}\/assignments\/#{assign.id}\/submissions\/#{@student.id}/
      f('.recent_feedback a').click
      wait_for_ajaximations

      # submission page should load
      f('h2').text.should == "Submission Details"
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
      fj("#past_enrollments_table a[href='/courses/#{@course.id}']").should include_text(c1.name)
    end

    it "should display assignment to grade in to do list for a teacher" do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        #verify assignment is in to do list
        f('.to-do-list > li').should include_text('Grade ' + assignment.title)
      end
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
      Quizzes::SubmissionGrader.new(qs).grade_submission
      get "/"

      todo_list = f('.to-do-list')
      todo_list.should_not be_nil
      todo_list.should include_text(quiz_title)
    end

    context "course menu customization" do

      it "should always have a link to the courses page (with customizations)" do
        20.times { course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}) }

        get "/"

        driver.execute_script %{$('#courses_menu_item').addClass('hover');}
        wait_for_ajaximations

        fj('#courses_menu_item').should include_text('My Courses')
        fj('#courses_menu_item').should include_text('View All or Customize')
      end
    end
  end
end
