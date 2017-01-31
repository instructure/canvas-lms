require_relative 'common'
require_relative 'helpers/groups_common'
require_relative 'helpers/announcements_common'
require_relative 'helpers/discussions_common'
require_relative 'helpers/wiki_and_tiny_common'
require_relative 'helpers/files_common'
require_relative 'helpers/conferences_common'
require_relative 'helpers/course_common'
require_relative 'helpers/groups_shared_examples'

describe "groups" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon
  include ConferencesCommon
  include CourseCommon
  include DiscussionsCommon
  include FilesCommon
  include GroupsCommon
  include WikiAndTinyCommon

  setup_group_page_urls

  context "as a teacher" do
    before :once do
      @course = course_model.tap(&:offer!)
      @teacher = teacher_in_course(course: @course, name: 'teacher', active_all: true).user
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students,@testgroup.first)
    end

    before :each do
      user_session(@teacher)
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "home page" do
      it_behaves_like 'home_page', :teacher
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "announcements page" do
      it_behaves_like 'announcements_page', :teacher

      it "should allow teachers to see announcements", priority: "1", test_id: 287049 do
        @announcement = @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group', user: @students.first)
        verify_member_sees_announcement
      end

      it "should allow teachers to create an announcement", priority: "1", test_id: 287050 do

        # Checks that initial user can create an announcement
        create_group_announcement_manually("Announcement by #{@teacher.name}",'sup')
        expect(ff('.discussion-topic').size).to eq 1
      end

      it "should allow teachers to delete their own group announcements", priority: "1", test_id: 326522 do
        @testgroup.first.announcements.create!(title: 'Student Announcement', message: 'test message', user: @teacher)

        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
        delete_via_gear_menu
        expect(f("#content")).not_to contain_css('.discussion-topic')
      end

      it "should allow teachers to delete group member announcements", priority: "1", test_id: 326523 do
        @testgroup.first.announcements.create!(title: 'Student Announcement', message: 'test message', user: @students.first)

        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
        delete_via_gear_menu
        expect(f("#content")).not_to contain_css('.discussion-topic')
      end

      it "should let teachers edit their own announcements", priority: "1", test_id: 312865 do
        @testgroup.first.announcements.create!(title: 'Test Announcement', message: 'test message', user: @teacher)
        edit_group_announcement
      end

      it "should let teachers edit group member announcements", priority: "2", test_id: 323325 do
        @testgroup.first.announcements.create!(title: 'Your Announcement', message: 'test message', user: @students.first)
        edit_group_announcement
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "people page" do
      it_behaves_like 'people_page', :teacher

      it "should display and show a list of group members", priority: "2", test_id: 324929 do
        get people_page
        # Checks that all students and teachers created in setup are listed on page
        expect(ff('.student_roster .user_name').size).to eq 4
        expect(ff('.teacher_roster .user_name').size).to eq 2
      end

      it "shows both active and inactive members in groups to teachers", priority: "2", test_id: 2771091 do
        get people_page
        expect(ff('.student_roster .user_name').size).to eq 4
        student_enrollment = StudentEnrollment.last
        student_enrollment.workflow_state = "inactive"
        student_enrollment.save!
        refresh_page
        expect(ff('.student_roster .user_name').size).to eq 4
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "discussions page" do
      it_behaves_like 'discussions_page', :teacher

      it "should allow teachers to create discussions within a group", priority: "1", test_id: 285586 do
        get discussions_page
        expect_new_page_load { f('#new-discussion-btn').click }
        # This creates the discussion and also tests its creation
        edit_topic('from a teacher', 'tell me a story')
      end

      it "should have three options when creating a discussion", priority: "1", test_id: 285584 do
        get discussions_page
        expect_new_page_load { f('#new-discussion-btn').click }
        expect(f('#threaded')).to be_displayed
        expect(f('#allow_rating')).to be_displayed
        expect(f('#podcast_enabled')).to be_displayed
      end

      it "should allow teachers to access a discussion", priority: "1", test_id: 285585 do
        dt = DiscussionTopic.create!(context: @testgroup.first, user: @students.first,
                                     title: 'Discussion Topic', message: 'hi dudes')
        get discussions_page
        # Verifies teacher can access the group discussion & that it's the correct discussion
        expect_new_page_load { f('.discussion-title').click }
        expect(f('.message.user_content')).to include_text(dt.message)
      end

      it "should allow teachers to delete their group discussions", priority: "1", test_id: 329627 do
        DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                                title: 'Group Discussion', message: 'Group')
        get discussions_page
        f('.al-trigger-gray').click
        wait_for_ajaximations
        f('.icon-trash.ui-corner-all').click
        driver.switch_to.alert.accept
        wait_for_animations
        expect(f("#content")).not_to contain_link('Group Discussion')
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "pages page" do
      it_behaves_like 'pages_page', :teacher

      it "should allow teachers to create a page", priority: "1", test_id: 289993 do
        get pages_page
        manually_create_wiki_page('stuff','it happens')
      end

      it "should allow teachers to access a page", priority: "1", test_id: 289992 do
        @page = @testgroup.first.wiki.wiki_pages.create!(title: "Page", user: @students.first)
        # Verifies teacher can access the group page & that it's the correct page
        verify_member_sees_group_page
      end

      it "has unique pages in the cloned groups", priority: "2", test_id: 1041949 do
        @page = @testgroup.first.wiki.wiki_pages.create!(title: "Page", user: @students.first)
        get pages_page
        expect(f('.index-content')).to contain_css('.wiki-page-link')

        category = @course.group_categories.create!(:name => "Group Category")
        @group_category.first.clone_groups_and_memberships(category)
        category.reload
        new_group = category.groups.first

        get "/groups/#{new_group.id}/pages"
        expect(f('.index-content')).not_to contain_css('.wiki-page-link')
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "Files page" do
      it_behaves_like 'files_page', :teacher

      it "should allow teacher to add a new folder", priority: "2", test_id: 303703 do
        get files_page
        add_folder
        expect(ff('.ef-name-col__text').first.text).to eq 'new folder'
      end

      it "should allow teacher to delete a folder", priority: "2", test_id: 304184 do
        get files_page
        add_folder
        delete(0, :toolbar_menu)
        expect(f("body")).not_to contain_css('.ef-item-row')
      end

      it "should allow a teacher to delete a file", priority: "2", test_id: 304183 do
        add_test_files
        get files_page
        delete(0, :toolbar_menu)
        wait_for_ajaximations
        expect(f("body")).not_to contain_css('.ef-item-row')
      end

      it "should allow teachers to move a file", priority: "2", test_id: 304185 do
        add_test_files
        get files_page
        add_folder('destination_folder')
        move_file_to_folder('example.pdf','destination_folder')
      end

      it "should allow teachers to move a folder", priority: "2", test_id: 304667 do
        get files_page
        create_folder_structure
        move_folder(@inner_folder)
      end

      it "hides the publish cloud", priority: "1", test_id: 304673 do
        add_test_files
        get files_page
        expect(f('#content')).not_to contain_css('.btn-link.published-status')
      end

      it "does not allow teachers to restrict access to a file", priority: "1", test_id: 304900 do
        add_test_files
        get files_page
        f('.ef-item-row .ef-date-created-col').click
        expect(f('.ef-header')).to contain_css('.ef-header__secondary')
        expect(f('.ef-header__secondary')).not_to contain_css('.btn-restrict')
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "conferences page" do
      before(:once) do
        PluginSetting.create!(name: "wimba", settings: {"domain" => "wimba.instructure.com"})
      end

      it_behaves_like 'conferences_page', :teacher
    end
  end
end
