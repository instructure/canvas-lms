require_relative 'common'
require_relative 'helpers/notifications_common'

describe "dashboard" do
  include NotificationsCommon
  include_context "in-process server selenium tests"

  shared_examples_for 'load events list' do
    it "should load events list sidebar", priority: "2", test_id: 210275 do
      get "/"
      wait_for_ajaximations
      expect(f('.events_list')).to be_displayed
    end
  end

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

    def test_hiding(url)
      create_announcement
      items = @user.stream_item_instances
      expect(items.size).to eq 1
      expect(items.first.hidden).to eq false

      get url
      f('#dashboardToggleButton').click if url == '/'
      click_recent_activity_header
      item_selector = '#announcement-details tbody tr'
      expect(ff(item_selector).size).to eq 1
      f('#announcement-details .ignore-item').click
      expect(f("#content")).not_to contain_css(item_selector)

      # should still be gone on reload
      get url
      f('#dashboardToggleButton').click if url == '/'
      expect(f("#content")).not_to contain_css(item_selector)

      expect(@user.recent_stream_items.size).to eq 0
      expect(items.first.reload.hidden).to eq true
    end

    it_should_behave_like 'load events list'

    it "should allow hiding a stream item on the dashboard", priority: "1", test_id: 215577 do
      test_hiding("/")
    end

    it "should allow hiding a stream item on the course page", priority: "1", test_id: 215578 do
      test_hiding("/courses/#{@course.to_param}")
    end

    it "should not show stream items for deleted objects", priority: "1", test_id: 215579 do
      enable_cache do
        announcement = create_announcement
        item_selector = '#announcement-details tbody tr'
        Timecop.freeze(5.minutes.ago) do
          items = @user.stream_item_instances
          expect(items.size).to eq 1
          expect(items.first.hidden).to eq false

          get "/"
          f('#dashboardToggleButton').click

          click_recent_activity_header
          expect(ff(item_selector).size).to eq 1
        end

        announcement.destroy

        get "/"
        expect(f('.no_recent_messages')).to include_text('No Recent Messages')
      end
    end

    it "should not show announcement stream items without permissions" do
      @course.account.role_overrides.create!(:role => student_role, :permission => 'read_announcements', :enabled => false)

      announcement = create_announcement
      item_selector = '#announcement-details tbody tr'

      get "/"
      f('#dashboardToggleButton').click
      expect(f('.no_recent_messages')).to include_text('No Recent Messages')
    end

    def click_recent_activity_header(type='announcement')
      f(".stream-#{type} .stream_header").click
    end

    def assert_recent_activity_category_closed(type='announcement')
      expect(f(".stream-#{type} .details_container")).not_to be_displayed
    end

    def assert_recent_activity_category_is_open(type='announcement')
      expect(f(".stream-#{type} .details_container")).to be_displayed
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

    it "should expand/collapse recent activity category", priority: "1", test_id: 215580 do
      create_announcement
      get '/'
      f('#dashboardToggleButton').click
      assert_recent_activity_category_closed
      click_recent_activity_header
      assert_recent_activity_category_is_open
      click_recent_activity_header
      assert_recent_activity_category_closed
    end

    it "should not expand category when a course/group link is clicked", priority: "2", test_id: 215581 do
      create_announcement
      get '/'
      f('#dashboardToggleButton').click
      assert_recent_activity_category_closed
      disable_recent_activity_header_course_link
      click_recent_activity_course_link
      assert_recent_activity_category_closed
    end

    it "should update the item count on stream item hide"
    it "should remove the stream item category if all items are removed"

    it "should show conversation stream items on the dashboard", priority: "1", test_id: 197536 do
      c = User.create.initiate_conversation([@user, User.create])
      c.add_message('test')
      c.add_participants([User.create])

      items = @user.stream_item_instances
      expect(items.size).to eq 1

      get "/"
      f('#dashboardToggleButton').click
      expect(ff('#conversation-details tbody tr').size).to eq 1
    end

    it "shows an assignment stream item under Recent Activity in dashboard", priority: "1", test_id: 108725 do
      setup_notification(@student, name: 'Assignment Created')
      assignment_model({:submission_types => ['online_text_entry'], :course => @course})
      get "/"
      f('#dashboardToggleButton').click
      find('.toggle-details').click
      expect(fj('.fake-link:contains("Unnamed")')).to be_present
    end

    it "should show account notifications on the dashboard", priority: "1", test_id: 215582 do
      a1 = @course.account.announcements.create!(:subject => 'test',
                                                 :message => "hey there",
                                                 :start_at => Date.today - 1.day,
                                                 :end_at => Date.today + 1.day)
      a2 = @course.account.announcements.create!(:subject => 'test 2',
                                                 :message => "another annoucement",
                                                 :start_at => Date.today - 2.days,
                                                 :end_at => Date.today + 1.day)

      get "/"
      f('#dashboardToggleButton').click
      messages = ffj("#dashboard .account_notification .notification_message")
      expect(messages.size).to eq 2
      expect(messages[0].text).to eq a1.message
      expect(messages[1].text).to eq a2.message
    end

    it "should interpolate the user's domain in global notifications", priority: "1", test_id: 215583 do
      announcement = @course.account.announcements.create!(:message => "blah blah http://random-survey-startup.ly/?some_GET_parameter_by_which_to_differentiate_results={{ACCOUNT_DOMAIN}}",
                                                           :subject => 'test',
                                                           :start_at => Date.today,
                                                           :end_at => Date.today + 1.day)

      get "/"
      expect(fj("#dashboard .account_notification .notification_message").text).to eq announcement.message.gsub("{{ACCOUNT_DOMAIN}}", @course.account.domain)
    end

    it "should interpolate the user's id in global notifications", priority: "1", test_id: 215584 do
      announcement = @course.account.announcements.create!(:message => "blah blah http://random-survey-startup.ly/?surveys_are_not_really_anonymous={{CANVAS_USER_ID}}",
                                                           :subject => 'test',
                                                           :start_at => Date.today,
                                                           :end_at => Date.today + 1.day)
      get "/"
      expect(fj("#dashboard .account_notification .notification_message").text).to eq announcement.message.gsub("{{CANVAS_USER_ID}}", @user.global_id.to_s)
    end

    it "should show appointment stream items on the dashboard", priority: "2", test_id: 215585 do
      skip "we need to add this stuff back in"
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
      expect(ffj(".topic_message .communication_message.dashboard_notification").size).to eq 3
      # appointment group publish and update notifications
      expect(ffj(".communication_message.message_appointment_group_#{@appointment_group.id}").size).to eq 2
      # signup notification
      expect(ffj(".communication_message.message_group_#{@group.id}").size).to eq 1
    end

    describe "course menu" do
      before do
        @course.update_attributes(:start_at => 2.days.from_now, :conclude_at => 4.days.from_now, :restrict_enrollments_to_course_dates => false)
        Enrollment.update_all(:created_at => 1.minute.ago)
        get "/"
      end

      it "should display course name in course menu", priority: "1", test_id: 215586 do
        f('#global_nav_courses_link').click
        expect(fj(".ic-NavMenu__headline:contains('Courses')")).to be_displayed
        wait_for_ajax_requests
        expect(fj(".ic-NavMenu-list-item a:contains('#{@course.name}')")).to be_displayed
      end

      it "should display student groups in header nav", priority: "2", test_id: 215587 do
        group = Group.create!(:name => "group1", :context => @course)
        group.add_user(@user)

        other_unpublished_course = course_factory
        other_group = Group.create!(:name => "group2", :context => other_unpublished_course)
        other_group.add_user(@user)

        get "/"

        f('#global_nav_groups_link').click
        expect(fj(".ic-NavMenu__headline:contains('Groups')")).to be_displayed
        wait_for_ajax_requests

        list = fj(".ic-NavMenu-list-item")
        expect(list).to include_text(group.name)
        expect(list).to_not include_text(other_group.name)
      end

      it "should present /courses as the href of the courses nav item", priority: "2", test_id: 215612 do
        expect(f('#global_nav_courses_link').attribute('href')).to match(/\/courses$/)
      end

      it "should only open the courses menu when clicking the courses nav item", priority: "1", test_id: 215613 do
        f('#global_nav_courses_link').click
        expect(driver.current_url).not_to match(/\/courses$/)
      end

      it "should go to a course when clicking a course link from the menu", priority: "1", test_id: 215614 do
        f('#global_nav_courses_link').click
        fj(".ic-NavMenu-list-item a:contains('#{@course.name}')").click
        expect(driver.current_url).to match "/courses/#{@course.id}"
      end
    end

    it "should display scheduled web conference in stream", priority: "1", test_id: 216354 do
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
      expect(f('.conference .notification_message')).to include_text(@conference.title)
    end

    it "should end conferences from stream", priority: "1", test_id: 216355 do
      PluginSetting.create!(:name => "wimba", :settings => {"domain" => "wimba.instructure.com"})

      course_with_teacher_logged_in

      @conference = @course.web_conferences.build({:title => "my Conference", :conference_type => "Wimba", :duration => nil})
      @conference.user = @user
      @conference.save!
      @conference.restart
      @conference.add_initiator(@user)
      @conference.add_invitee(@user)
      @conference.save!

      get "/courses/#{@course.to_param}"
      f('.conference .close_conference_link').click
      expect(alert_present?).to be_truthy
      accept_alert
      wait_for_ajaximations
      expect(f('.conference')).to_not be_displayed
      @conference.reload
      expect(@conference).to be_finished
    end

    it "should create an announcement for the first course that is not visible in the second course", priority: "1", test_id: 216356 do
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
      expect(f("#content")).not_to contain_css('.no_recent_messages')

      get "/courses/#{@second_course.id}"
      expect(f('.no_recent_messages')).to include_text('No Recent Messages')
    end

    it "should validate the functionality of soft concluded courses in dropdown", priority: "1", test_id: 216372 do
      course_with_student(:active_all => true, :course_name => "a_soft_concluded_course", :user => @user)
      c1 = @course
      c1.conclude_at = 1.week.ago
      c1.start_at = 1.month.ago
      c1.restrict_enrollments_to_course_dates = true
      c1.save!
      get "/"

      f('#global_nav_courses_link').click
      expect(fj(".ic-NavMenu__headline:contains('Courses')")).to be_displayed
      expect(f(".ic-NavMenu__link-list")).not_to include_text(c1.name)
    end

    it "should show recent feedback and it should work", priority: "1", test_id: 216373 do
      assign = @course.assignments.create!(:title => 'hi', :due_at => 1.day.ago, :points_possible => 5)
      assign.grade_student(@student, grade: '4', grader: @teacher)

      get "/"
      wait_for_ajaximations

      expect(f('.recent_feedback a')).to have_attribute("href", /courses\/#{@course.id}\/assignments\/#{assign.id}\/submissions\/#{@student.id}/)
      f('.recent_feedback a').click
      wait_for_ajaximations

      # submission page should load
      expect(f('h2').text).to eq "Submission Details"
    end

    it "should validate the functionality of soft concluded courses on courses page", priority: "1", test_id: 216374 do
      term = EnrollmentTerm.new(:name => "Super Term", :start_at => 1.month.ago, :end_at => 1.week.ago)
      term.root_account_id = @course.root_account_id
      term.save!
      c1 = @course
      c1.name = 'a_soft_concluded_course'
      c1.update_attributes!(:enrollment_term => term)
      c1.reload
      get "/courses"
      expect(fj("#past_enrollments_table a[href='/courses/#{@course.id}']")).to include_text(c1.name)
    end

    context "course menu customization" do

      it "should always have a link to the courses page (with customizations)", priority: "1", test_id: 216378 do
        course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true})
        get "/"
        f('#global_nav_courses_link').click
        expect(fj('.ic-NavMenu-list-item a:contains("All Courses")')).to be_present
      end
    end
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in(:active_cc => true)
    end

    it_should_behave_like 'load events list'

    context "restricted future courses" do
      before :once do
        term = EnrollmentTerm.new(:name => "Super Term", :start_at => 1.week.from_now, :end_at => 1.month.from_now)
        term.root_account_id = Account.default.id
        term.save!
        course_with_student(:active_all => true)
        @c1 = @course
        @c1.name = 'a future course'
        @c1.update_attributes!(:enrollment_term => term)

        course_with_student(:active_course => true, :user => @student)
        @c2 = @course
        @c2.name = "a restricted future course"
        @c2.restrict_student_future_view = true
        @c2.update_attributes!(:enrollment_term => term)
      end

      before do
        user_session(@student)
      end

      it "should show future courses (even if restricted) to students on courses page" do
        get "/courses"
        expect(fj("#future_enrollments_table a[href='/courses/#{@c1.id}']")).to include_text(@c1.name)

        expect(f("#content")).not_to contain_css("#future_enrollments_table a[href='/courses/#{@c2.id}']") # should not have a link
        expect(f("#future_enrollments_table")).to include_text(@c2.name) # but should still show restricted future enrollment
      end

      it "should not show restricted future courses to students on courses page if configured on account" do
        a = @c2.account
        a.settings[:restrict_student_future_listing] = {:value => true}
        a.save!
        get "/courses"
        expect(fj("#future_enrollments_table a[href='/courses/#{@c1.id}']")).to include_text(@c1.name)
        expect(f("#future_enrollments_table")).to_not include_text(@c2.name) # shouldn't be included at all
      end
    end

    it "should display assignment to grade in to do list for a teacher", priority: "1", test_id: 216376 do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload

      User.where(:id => @teacher).update_all(:updated_at => 1.day.ago) # ensure cache refresh
      enable_cache do
        get "/"

        #verify assignment is in to do list
        expect(f('.to-do-list > li')).to include_text('Grade ' + assignment.title)

        student.enrollments.first.destroy

        get "/"

        #verify todo list is updated
        expect(f("#content")).not_to contain_css('.to-do-list > li')
      end
    end
  end
end
