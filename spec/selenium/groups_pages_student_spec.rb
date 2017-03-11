require_relative 'common'
require_relative 'helpers/announcements_common'
require_relative 'helpers/conferences_common'
require_relative 'helpers/course_common'
require_relative 'helpers/discussions_common'
require_relative 'helpers/files_common'
require_relative 'helpers/google_drive_common'
require_relative 'helpers/groups_common'
require_relative 'helpers/groups_shared_examples'
require_relative 'helpers/wiki_and_tiny_common'

describe "groups" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon
  include ConferencesCommon
  include CourseCommon
  include DiscussionsCommon
  include FilesCommon
  include GoogleDriveCommon
  include GroupsCommon
  include WikiAndTinyCommon

  setup_group_page_urls

  context "as a student" do
    before :once do
      @student = User.create!(name: "Student 1")
      @teacher = User.create!(name: "Teacher 1")
      course_with_student({user: @student, :active_course => true, :active_enrollment => true})
      @course.enroll_teacher(@teacher).accept!
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students + [@student],@testgroup.first)
    end

    before :each do
      user_session(@student)
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "home page" do
      it_behaves_like 'home_page', :student

      it "should only allow group members to access the group home page", priority: "1", test_id: 319908 do
        get url
        expect(f('.recent-activity-header')).to be_displayed
        verify_no_course_user_access(url)
      end

      it "hides groups for inaccessible courses in groups list", priority: "2", test_id: 927757 do
        term = EnrollmentTerm.find(@course.enrollment_term_id)
        term.end_at = Time.zone.now-2.days
        term.save!
        @course.restrict_student_past_view = true
        @course.save
        get '/groups'
        expect(f('#content')).not_to contain_css('.previous_groups')
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "announcements page" do
      it_behaves_like 'announcements_page', :student

      it "should allow group members to delete their own announcements", priority: "1", test_id: 326521 do
        create_group_announcement_manually("Announcement by #{@students.first.name}",'yo ho, yo ho')
        expect(ff('.discussion-topic').size).to eq 1
        delete_via_gear_menu
        expect(f("#content")).not_to contain_css('.discussion-topic')
      end

      it "should allow any group member to create an announcement", priority: "1", test_id: 273607 do

        # Checks that initial user can create an announcement
        create_group_announcement_manually("Announcement by #{@user.name}",'sup')

        # Log in as a new student to verify the last group was created and that they can also create a group
        user_session(@students.first)
        expect(ff('.discussion-topic').size).to eq 1
        create_group_announcement_manually("Announcement by #{@students.first.name}",'yo')
        expect(ff('.discussion-topic').size).to eq 2
      end

      it "should allow group members to edit their own announcements", priority: "1", test_id: 312867 do
        create_group_announcement_manually("Announcement by #{@students.first.name}",'The Force Awakens')
        expect(ff('.discussion-topic').size).to eq 1
        f('.discussion-title').click
        f('.edit-btn').click
        expect(driver.title).to eq 'Edit Announcement'
        type_in_tiny('textarea[name=message]','Rey is Yodas daughter')
        f('.btn-primary').click
        wait_for_ajaximations
        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
        expect(f('.discussion-summary')).to include_text('Rey is Yodas daughter')
      end

      it "should not allow group members to edit someone else's announcement", priority: "1", test_id: 327111 do
        create_group_announcement_manually("Announcement by #{@user.name}",'sup')
        user_session(@students.first)
        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
        f('.discussion-title').click
        expect(f("#content")).not_to contain_css('.edit-btn')
      end

      it "should allow all group members to see announcements", priority: "1", test_id: 273613 do
        @announcement = @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
        # Verifying with a few different group members should be enough to ensure all group members can see it
        verify_member_sees_announcement

        user_session(@students.first)
        verify_member_sees_announcement
      end

      it "should only allow group members to access announcements", priority: "1", test_id: 315329 do
        get announcements_page
        expect(fj('.btn-primary:contains("Announcement")')).to be_displayed
        verify_no_course_user_access(announcements_page)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "people page" do
      it_behaves_like 'people_page', :student

      it "should display and show a list of group members", priority: "1", test_id: 273614 do
        get people_page
        # Checks that all students and teachers created in setup are listed on page
        expect(ff('.student_roster .user_name').size).to eq 5
        expect(ff('.teacher_roster .user_name').size).to eq 1
      end

      it "shows only active members in groups to students", priority: "2", test_id: 840142 do
        get people_page
        student_enrollment = StudentEnrollment.last
        student = User.find(student_enrollment.user_id)
        expect(f('.student_roster')).to contain_css("a[href*='#{student.id}']")
        student_enrollment.workflow_state = "inactive"
        student_enrollment.save!
        refresh_page
        expect(f('.student_roster')).not_to contain_css("a[href*='#{student.id}']")
      end

      it "should allow access to people page only within the scope of a group", priority: "1", test_id: 319906 do
        get people_page
        expect(f('.roster.student_roster')).to be_displayed
        verify_no_course_user_access(people_page)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "discussions page" do
      it_behaves_like 'discussions_page', :student

      it "should allow discussions to be created within a group", priority: "1", test_id: 273615 do
        get discussions_page
        expect_new_page_load { f('#new-discussion-btn').click }
        # This creates the discussion and also tests its creation
        edit_topic('from a student', 'tell me a story')
      end

      it "should allow group members to access a discussion", priority: "1", test_id: 273616 do
        dt = DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                                     title: 'Discussion Topic', message: 'hi dudes')
        get discussions_page
        # Verifies group member can access the teacher's group discussion & that it's the correct discussion
        expect_new_page_load { f('.discussion-title').click }
        expect(f('.message.user_content')).to include_text(dt.message)
      end

      it "should have two options when creating a discussion", priority: "1", test_id: 273617 do
        get discussions_page
        expect_new_page_load { f('#new-discussion-btn').click }
        expect(f('#threaded')).to be_displayed
        expect(f('#allow_rating')).to be_displayed
        # Shouldn't be Enable Podcast Feed option
        expect(f("#content")).not_to contain_css('#podcast_enabled')
      end

      it "should only allow group members to access discussions", priority: "1", test_id: 315332 do
        get discussions_page
        expect(f('#new-discussion-btn')).to be_displayed
        verify_no_course_user_access(discussions_page)
      end

      it "should allow discussions to be deleted by their creator", priority: "1", test_id: 329626 do
        DiscussionTopic.create!(context: @testgroup.first, user: @user, title: 'Delete Me', message: 'Discussion text')
        get discussions_page
        expect(ff('.discussion-title-block').size).to eq 1
        delete_via_gear_menu
        expect(f("#content")).not_to contain_css('.discussion-title-block')
      end

      it "should not be able to delete a discussion by a different creator", priority: "1", test_id: 420009 do
        DiscussionTopic.create!(context: @testgroup.first,
                                user: @students.first,
                                title: 'Back to the Future day',
                                message: 'There are no hover boards!')
        get discussions_page
        expect(ff('.discussion-title-block').size).to eq 1
        expect(f("#content")).not_to contain_css('#manage_link')
      end

      it "should allow group members to edit their discussions", priority: "1", test_id: 312866 do
        DiscussionTopic.create!(context: @testgroup.first,
                                user: @user,
                                title: 'White Snow',
                                message: 'Where are my skis?')
        get discussions_page
        f('.discussion-title').click
        f('.edit-btn').click
        expect(driver.title).to eq 'Edit Discussion Topic'
        type_in_tiny('textarea[name=message]','The slopes are ready,')
        f('.btn-primary').click
        wait_for_ajaximations
        expect(f('.user_content')).to include_text('The slopes are ready,')
      end

      it "should not allow group member to edit discussions by other creators", priority: "1", test_id: 323327 do
        DiscussionTopic.create!(context: @testgroup.first,
                                user: @students.first,
                                title: 'White Snow',
                                message: 'Where are my skis?')
        get discussions_page
        f('.discussion-title').click
        expect(f("#content")).not_to contain_css('.edit-btn')
      end

    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "pages page" do
      it_behaves_like 'pages_page', :student

      it "should allow group members to create a page", priority: "1", test_id: 273611 do
        get pages_page
        manually_create_wiki_page('yo','this be a page')
      end

      it "should allow all group members to access a page", priority: "1", test_id: 273612 do
        @page = @testgroup.first.wiki.wiki_pages.create!(title: "Page", user: @teacher)
        # Verifying with a few different group members should be enough to ensure all group members can see it
        verify_member_sees_group_page

        user_session(@students.first)
        verify_member_sees_group_page
      end

      it "should only allow group members to access pages", priority: "1", test_id: 315331 do
        get pages_page
        expect(f('.new_page')).to be_displayed
        verify_no_course_user_access(pages_page)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "Files page" do
      it_behaves_like 'files_page', :student

      it "should allow group members to add a new folder", priority: "1", test_id: 273625 do
        get files_page
        add_folder
        expect(ff('.ef-name-col__text').first.text).to eq 'new folder'
      end

      it "should allow group members to delete a folder", priority: "1", test_id: 273631 do
        get files_page
        add_folder
        delete(0, :cog_icon)
        expect(f("body")).not_to contain_css('.ef-item-row')
      end

      it "should allow group members to move a folder", priority: "1", test_id: 273632 do
        get files_page
        create_folder_structure
        move_folder(@inner_folder)
      end

      it "should only allow group members to access files", priority: "1", test_id: 273626 do
        expect_new_page_load { get files_page }
        verify_no_course_user_access(files_page)
      end

      it "should allow a group member to delete a file", priority: "1", test_id: 273630 do
        add_test_files(false)
        get files_page
        delete(0, :cog_icon)
        wait_for_ajaximations
        expect(all_files_folders.count).to eq 1
        # Now try to delete the other one using toolbar menu
        delete(0, :toolbar_menu)
        expect(f("body")).not_to contain_css('.ef-item-row')
      end

      it "should allow group members to move a file", priority: "1", test_id: 273633 do
        add_test_files
        get files_page
        add_folder('destination_folder')
        move_file_to_folder('example.pdf','destination_folder')
      end

      it "should hide the publish cloud", priority: "1", test_id: 273628 do
        add_test_files
        get files_page
        expect(f('#content')).not_to contain_css('.btn-link.published-status')
      end

      it "does not allow group members to restrict access to a file", priority: "1", test_id: 304672 do
        add_test_files
        get files_page
        f('.ef-item-row .ef-date-created-col').click
        expect(f('.ef-header')).to contain_css('.ef-header__secondary')
        expect(f('.ef-header__secondary')).not_to contain_css('.btn-restrict')
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "conferences page" do
      before :once do
        PluginSetting.create!(name: "wimba", settings: {"domain" => "wimba.instructure.com"})
      end

      it_behaves_like 'conferences_page', :student

      it "should allow access to conferences only within the scope of a group", priority: "1", test_id: 273638 do
        get conferences_page
        expect(f('.new-conference-btn')).to be_displayed
        verify_no_course_user_access(conferences_page)
      end

      it "should not allow inviting users with inactive enrollments" do
        inactive_student = @students.first
        inactive_student.update_attribute(:name, "inactivee")
        inactive_student.enrollments.first.deactivate
        active_student = @students.last
        active_student.update_attribute(:name, "imsoactive")

        get conferences_page
        f('.new-conference-btn').click
        f('.all_users_checkbox').click

        expect(f('#members_list')).to_not include_text(inactive_student.name)
        expect(f('#members_list')).to include_text(active_student.name)
      end
    end
    #-------------------------------------------------------------------------------------------------------------------
    describe "collaborations page" do
      before :each do
        setup_google_drive
        unless PluginSetting.where(name: 'google_drive').exists?
          PluginSetting.create!(name: 'google_drive', settings: {})
        end
      end

      it 'lets student in group create a collaboration', priority: "1", test_id: 273641 do
        get collaborations_page
        replace_content(find('#collaboration_title'), "c1")
        replace_content(find('#collaboration_description'), "c1 description")
        fj('.available-users li:contains("1, Test Student") .icon-user').click
        fj('.btn:contains("Start Collaborating")').click
        # verifies collaboration will be displayed on main window
        tab1 = driver.window_handles.first
        driver.switch_to.window(tab1)
        expect(fj('.collaboration .title:contains("c1")')).to be_present
        expect(fj('.collaboration .description:contains("c1 description")')).to be_present
      end

      it 'can invite people within your group', priority: "1", test_id: 273642 do
        students_in_group = @students
        seed_students(2, 'non-group student')
        get collaborations_page
        students_in_group.each do |student|
          expect(fj(".available-users li:contains(#{student.sortable_name}) .icon-user")).to be_present
        end
      end

      it 'cannot invite people not in your group', priority: "1", test_id: 588010 do
        # overriding '@students' array with new students not included in the group
        seed_students(2, 'non-group Student')
        get collaborations_page
        users = f(".available-users")
        @students.each do |student|
          expect(users).not_to contain_jqcss("li:contains(#{student.sortable_name}) .icon-user")
        end
      end

      it 'cannot invite students with inactive enrollments' do
        inactive_student = @students.first
        inactive_student.update_attribute(:name, "inactivee")
        inactive_student.enrollments.first.deactivate

        get collaborations_page
        expect(f(".available-users")).not_to contain_jqcss("li:contains(#{inactive_student.sortable_name}) .icon-user")
      end

      it "should only allow group members to access the group collaborations page", priority: "1", test_id: 319904 do
        get collaborations_page
        expect(find('#breadcrumbs').text).to include('Collaborations')
        verify_no_course_user_access(collaborations_page)
      end
    end
  end
end
