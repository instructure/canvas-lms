require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/announcements_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/conferences_common')

describe "groups" do
  include_context "in-process server selenium tests"

  setup_group_page_urls

  context "as a student" do
    before do
      course_with_student_logged_in(active_all: true)
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students + [@user],@testgroup.first)
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "home page" do
      it_behaves_like 'home_page', 'student'

      it "should only allow group members to access the group home page", priority: "1", test_id: 319908 do
        get url
        expect(f('.recent-activity-header')).to be_displayed
        verify_no_course_user_access(url)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "announcements page" do
      it_behaves_like 'announcements_page', 'student'

      it "should allow any group member to create an announcement", priority: "1", test_id: 273607 do
        get announcements_page

        # Checks that initial user can create an announcement
        create_group_announcement_manually("Announcement by #{@user.name}",'sup')
        wait_for_ajaximations

        # Log in as a new student to verify the last group was created and that they can also create a group
        user_session(@students.first)
        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
        create_group_announcement_manually("Announcement by #{@students.first.name}",'yo')
        get announcements_page
        expect(ff('.discussion-topic').size).to eq 2
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
      it_behaves_like 'people_page', 'student'

      it "should display and show a list of group members", priority: "1", test_id: 273614 do
        get people_page
        # Checks that all students and teachers created in setup are listed on page
        expect(ff('.student_roster .user_name').size).to eq 5
        expect(ff('.teacher_roster .user_name').size).to eq 1
      end

      it "should allow access to people page only within the scope of a group", priority: "1", test_id: 319906 do
        get people_page
        expect(f('.roster.student_roster')).to be_displayed
        verify_no_course_user_access(people_page)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "discussions page" do
      it_behaves_like 'discussions_page', 'student'

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
        expect(f('#podcast_enabled')).to be_nil
      end

      it "should only allow group members to access discussions", priority: "1", test_id: 315332 do
        get discussions_page
        expect(f('#new-discussion-btn')).to be_displayed
        verify_no_course_user_access(discussions_page)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "pages page" do
      it_behaves_like 'pages_page', 'student'

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
        expect(fj('.btn-primary:contains("Page")')).to be_displayed
        verify_no_course_user_access(pages_page)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "Files page" do
      it_behaves_like 'files_page', 'student'

      it "should allow group members to add a new folder", priority: "1", test_id: 273625 do
        get files_page
        add_folder
        expect(ff('.media-body').first.text).to eq 'new folder'
      end

      it "should allow group members to delete a folder", priority: "1", test_id: 273631 do
        get files_page
        add_folder
        delete(0, :cog_icon)
        expect(get_all_files_folders.count).to eq 0
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
        expect(get_all_files_folders.count).to eq 1
        # Now try to delete the other one using toolbar menu
        delete(0, :toolbar_menu)
        expect(get_all_files_folders.count).to eq 0
      end

      it "should allow group members to move a file", priority: "1", test_id: 273633 do
        add_test_files
        get files_page
        add_folder('destination_folder')
        move_file_to_folder('example.pdf','destination_folder')
      end

      it "should allow group members to publish and unpublish a file", priority: "1", test_id: 273628 do
        add_test_files
        get files_page
        set_item_permissions(:unpublish,:toolbar_menu)
        expect(f('.btn-link.published-status.unpublished')).to be_displayed
        set_item_permissions(:publish,:toolbar_menu)
        expect(f('.btn-link.published-status.published')).to be_displayed
      end

      it "should allow group members to restrict access to a file", priority: "1", test_id: 304672 do
        add_test_files
        get files_page
        set_item_permissions(:restricted_access, :available_with_link, :cloud_icon)
        expect(f('.btn-link.published-status.hiddenState')).to be_displayed
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "conferences page" do
      before(:all) do
        PluginSetting.create!(name: "wimba", settings: {"domain" => "wimba.instructure.com"})
      end

      it_behaves_like 'conferences_page', 'student'

      it "should allow access to conferences only within the scope of a group", priority: "1", test_id: 273638 do
        get conferences_page
        expect(f('.new-conference-btn')).to be_displayed
        verify_no_course_user_access(conferences_page)
      end
    end
  end
end
