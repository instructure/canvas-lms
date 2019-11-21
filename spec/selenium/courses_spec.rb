#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    before(:each) do
      account = Account.default
      account.settings = {:open_registration => true, :no_enrollments_can_create_courses => true, :teachers_can_create_courses => true}
      account.save!
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:new_user_tutorial).and_return(false)
    end

    context 'draft state' do
      before(:each) do
        course_with_teacher_logged_in
        @course.default_view = 'feed'
        @course.save
      end

      def validate_action_button(postion, validation_text)
        action_button = ff('#course_status_actions button').send(postion)
        expect(action_button).to have_class('disabled')
        expect(action_button.text).to eq validation_text
      end

      it "should allow publishing of the course through the course status actions" do
        @course.workflow_state = 'claimed'
        @course.lock_all_announcements = true
        @course.save!
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect(course_status_buttons.first).to have_class('disabled')
        expect(course_status_buttons.first.text).to eq 'Unpublished'
        expect(course_status_buttons.last).not_to have_class('disabled')
        expect(course_status_buttons.last.text).to eq 'Publish'
        expect_new_page_load { course_status_buttons.last.click }
        validate_action_button(:last, 'Published')

        @course.reload
        expect(@course.lock_all_announcements).to be_truthy
      end

      it "should display a creative commons license when set", priority: "1", test_id: 272274 do
        @course.license =  'cc_by_sa'
        @course.save!
        get "/courses/#{@course.id}"
        wait_for_ajaximations
        expect(f('.public-license-text').text).to include('This course content is offered under a')
      end

      it "should allow unpublishing of a course through the course status actions" do
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect(course_status_buttons.first).not_to have_class('disabled')
        expect(course_status_buttons.first.text).to eq ' Unpublish'
        expect(course_status_buttons.last).to have_class('disabled')
        expect(course_status_buttons.last.text).to eq 'Published'
        expect_new_page_load { course_status_buttons.first.click }
        validate_action_button(:first, 'Unpublished')
      end

      it "should allow publishing even if graded submissions exist" do
        course_with_student_submissions({submission_points: true, unpublished: true})
        @course.default_view = 'feed'
        @course.save
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect(course_status_buttons.first).to have_class('disabled')
        expect(course_status_buttons.first.text).to eq 'Unpublished'
        expect(course_status_buttons.last).not_to have_class('disabled')
        expect(course_status_buttons.last.text).to eq 'Publish'
        expect_new_page_load { course_status_buttons.last.click }
        @course.reload
        expect(@course).to be_available
      end

      it "should not show course status if published and graded submissions exist" do
        course_with_student_submissions({submission_points: true})
        @course.default_view = 'feed'
        @course.save
        get "/courses/#{@course.id}"
        expect(f("#content")).not_to contain_css('#course_status')
      end

      it "should allow unpublishing of the course if submissions have no score or grade" do
        skip('flaky alert. ADMIN-3022')
        course_with_student_submissions
        @course.default_view = 'feed'
        @course.save
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        course_status_buttons.first.click
        wait_for(method: nil, timeout: 5) {
          assert_flash_notice_message('successfully updated')
        }
        validate_action_button(:first, 'Unpublished')
      end

      it "should allow publishing/unpublishing with only change_course_state permission" do
        @course.account.role_overrides.create!(:permission => :manage_course_content, :role => teacher_role, :enabled => false)
        @course.account.role_overrides.create!(:permission => :manage_courses, :role => teacher_role, :enabled => false)

        get "/courses/#{@course.id}"
        expect_new_page_load { ff('#course_status_actions button').first.click }
        validate_action_button(:first, 'Unpublished')
        expect_new_page_load { ff('#course_status_actions button').last.click }
        validate_action_button(:last, 'Published')
      end

      it "should not allow publishing/unpublishing without change_course_state permission" do
        @course.account.role_overrides.create!(:permission => :change_course_state, :role => teacher_role, :enabled => false)

        get "/courses/#{@course.id}"
        expect(f("#content")).not_to contain_css('#course_status_actions')
      end
    end


    it "should correctly update the course quota" do
      course_with_admin_logged_in

      # first try setting the quota explicitly
      get "/courses/#{@course.id}/settings"
      f("#ui-id-1").click
      form = f("#course_form")
      expect(form).to be_displayed
      quota_input = form.find_element(:css, "input#course_storage_quota_mb")
      replace_content(quota_input, "10")
      submit_form(form)
      value = f("#course_form input#course_storage_quota_mb")['value']
      expect(value).to eq "10"
    end

    it "should save quota when not changed" do
      # then try just saving it (without resetting it)
      course_with_admin_logged_in
      @course.update_attributes!(storage_quota: 10.megabytes)
      get "/courses/#{@course.id}/settings"
      form = f("#course_form")
      submit_form(form)
      value = @course.storage_quota
      expect(value).to eq 10.megabytes
    end

    it "should redirect to the gradebook when switching courses when viewing a students grades" do
      teacher = user_with_pseudonym(:username => 'teacher@example.com', :active_all => 1)
      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)

      course1 = course_with_teacher_logged_in(:user => teacher, :active_all => 1, :course_name => 'course1').course
      student_in_course(:user => student, :active_all => 1)

      course2 = course_with_teacher(:user => teacher, :active_all => 1, :course_name => 'course2').course
      student_in_course(:user => student, :active_all => 1)

      create_session(student.pseudonyms.first)

      get "/courses/#{course1.id}/grades/#{student.id}"

      select = f('#course_select_menu')
      options = select.find_elements(:css, 'option')
      expect(options.length).to eq 2
      wait_for_ajaximations
      click_option('#course_select_menu', course2.name)
      expect_new_page_load { f('#apply_select_menus').click }
      expect(f('#breadcrumbs .home + li a')).to include_text(course2.name)
    end

    it "should load the users page using ajax" do
      skip('flaky alert. ADMIN-3022')
      course_with_teacher_logged_in

      # Set up the course with > 50 users (to test scrolling)
      create_users_in_course @course, 60

      @course.enroll_user(user_factory, 'TaEnrollment')

      # Test that the page loads properly the first time.
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      expect_no_flash_message :error
      expect(ff('.roster .rosterUser').length).to eq 50
    end

    it "should only show users that a user has permissions to view" do
      # Set up the test
      course_factory(active_course: true)
      %w[One Two].each do |name|
        section = @course.course_sections.create!(:name => name)
        @course.enroll_student(user_factory, :section => section).accept!
      end
      user_logged_in
      enrollment = @course.enroll_ta(@user)
      enrollment.accept!
      enrollment.update_attributes(:limit_privileges_to_course_section => true,
                                   :course_section => CourseSection.where(name: 'Two').first)

      # Test that only users in the approved section are displayed.
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      expect(ff('.roster .rosterUser').length).to eq 2
    end

    it "should display users section name" do
      course_with_teacher_logged_in(:active_all => true)
      user1, user2 = [user_factory, user_factory]
      section1 = @course.course_sections.create!(:name => 'One')
      section2 = @course.course_sections.create!(:name => 'Two')
      @course.enroll_student(user1, :section => section1).accept!
      [section1, section2].each do |section|
        e = user2.student_enrollments.build
        e.workflow_state = 'active'
        e.course = @course
        e.course_section = section
        e.save!
      end

      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      sections = ff('.roster .section')
      expect(sections.map(&:text).sort).to eq ["One", "One", "Two", "Unnamed Course", "Unnamed Course"]
    end

    context "course_home_sub_navigation lti apps" do
      def create_course_home_sub_navigation_tool(options = {})
        defaults = {
          name: options[:name] || "external tool",
          consumer_key: 'test',
          shared_secret: 'asdf',
          url: 'http://example.com/ims/lti',
          course_home_sub_navigation: { icon_url: '/images/delete.png' },
        }
        @course.context_external_tools.create!(defaults.merge(options))
      end

      it "should display course_home_sub_navigation lti apps", priority: "1", test_id: 2624910 do
        course_with_teacher_logged_in(active_all: true)
        num_tools = 2
        num_tools.times { |index| create_course_home_sub_navigation_tool(name: "external tool #{index}") }
        get "/courses/#{@course.id}"
        expect(ff(".course-home-sub-navigation-lti").size).to eq num_tools
      end

      it "should include launch type parameter", priority: "1", test_id: 2624911 do
        course_with_teacher_logged_in(active_all: true)
        create_course_home_sub_navigation_tool
        get "/courses/#{@course.id}"
        expect(f('.course-home-sub-navigation-lti')).to have_attribute("href", /launch_type=course_home_sub_navigation/)
      end

      it "should only display active tools", priority: "1", test_id: 2624912 do
        course_with_teacher_logged_in(active_all: true)
        tool = create_course_home_sub_navigation_tool
        tool.workflow_state = 'deleted'
        tool.save!
        get "/courses/#{@course.id}"
        expect(f("#content")).not_to contain_css(".course-home-sub-navigation-lti")
      end

      it "should not display admin tools to students", priority: "1", test_id: 2624913 do
        course_with_teacher_logged_in(active_all: true)
        tool = create_course_home_sub_navigation_tool
        tool.course_home_sub_navigation['visibility'] = 'admins'
        tool.save!
        get "/courses/#{@course.id}"
        expect(ff(".course-home-sub-navigation-lti").size).to eq 1

        course_with_student_logged_in(course: @course, active_all: true)
        get "/courses/#{@course.id}"
        expect(f("#content")).not_to contain_css(".course-home-sub-navigation-lti")
      end
    end

  end

  context "course as a student" do

    def enroll_student(student, accept_invitation)
      if accept_invitation
        @course.enroll_student(student).accept
      else
        @course.enroll_student(student)
      end
    end

    before (:each) do
      course_with_teacher(:active_all => true, :name => 'discussion course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      Account.default.settings[:allow_invitation_previews] = true
      Account.default.save!
    end

    it "should auto-accept the course invitation if previews are not allowed" do
      skip('flaky alert. ADMIN-3022')
      Account.default.settings[:allow_invitation_previews] = false
      Account.default.save!
      enroll_student(@student, false)

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}"
      wait_for_ajaximations
      assert_flash_notice_message "Invitation accepted!"
      expect(f("#content")).not_to contain_css(".ic-notification button[name='accept'] ")
    end

    it "should accept the course invitation" do
      skip('flaky alert. ADMIN-3022')
      enroll_student(@student, false)

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}"
      f(".ic-notification button[name='accept'] ").click
      wait_for(method: nil, timeout: 5) {
        assert_flash_notice_message "Invitation accepted!"
      }
    end

    it "should reject a course invitation" do
      skip('flaky alert. ADMIN-3022')
      enroll_student(@student, false)

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}"
      f(".ic-notification button[name=reject]").click
      assert_flash_notice_message "Invitation canceled."
    end

    it "should display user groups on courses page" do
      group = Group.create!(:name => "group1", :context => @course)
      group.add_user(@student)
      enroll_student(@student, true)

      create_session(@student.pseudonym)
      get '/courses'

      content = f('#content')
      expect(content).to include_text('My Groups')
      expect(content).to include_text('group1')
    end

    it "should reset cached permissions when enrollment is activated by date" do
      enable_cache do
        enroll_student(@student, true)

        @course.start_at = 1.day.from_now
        @course.restrict_enrollments_to_course_dates = true
        @course.restrict_student_future_view = true
        @course.save!

        user_session(@student)

        User.where(:id => @student).update_all(:updated_at => 5.minutes.ago) # make sure that touching the user resets the cache

        get "/courses/#{@course.id}"

        # cache unauthorized permission
        expect(f('#unauthorized_message')).to be_displayed

        # manually trigger a stale enrollment - should recalculate on visit if it didn't already in the background
        Course.where(:id => @course).update_all(:start_at => 1.day.ago)
        Enrollment.where(:id => @student.student_enrollments).update_all(:updated_at => 1.minute.from_now) # because of enrollment date caching
        EnrollmentState.where(:enrollment_id => @student.student_enrollments).update_all(:state_is_current => false)

        refresh_page
        expect(f('#course_home_content')).to be_displayed
      end
    end
  end

  it "shouldn't cache unauth permissions for semi-public courses from sessionless permission checks" do
    course_factory(active_all: true)
    @course.update_attribute(:is_public_to_auth_users, true)

    user_factory(active_all: true)
    user_session(@user)

    enable_cache do
      # previously was cached by visiting "/courses/#{@course.id}/assignments/syllabus"
      expect(@course.grants_right?(@user, :read)).to be_falsey # requires session[:user_id] - caches a false value

      get "/courses/#{@course.id}"

      expect(f('#course_home_content')).to be_displayed
    end
  end

  it "should display announcements on course home page if enabled and is wiki" do
    course_with_teacher_logged_in :active_all => true

    text = "here's some html or whatever"
    html = "<p>#{text}</p>"
    @course.announcements.create!(:title => "something", :message => html)

    @course.wiki_pages.create!(:title => 'blah').set_as_front_page!

    @course.reload
    @course.default_view = "wiki"
    @course.show_announcements_on_home_page = true
    @course.home_page_announcement_limit = 5
    @course.save!

    get "/courses/#{@course.id}"

    expect(f('#announcements_on_home_page')).to be_displayed
    expect(f('#announcements_on_home_page')).to include_text(text)
    expect(f('#announcements_on_home_page')).to_not include_text(html)
  end
end
