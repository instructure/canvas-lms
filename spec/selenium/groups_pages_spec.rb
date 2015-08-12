require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/announcements_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')

describe "groups" do
  include_context "in-process server selenium tests"

  let(:url) {"/groups/#{@testgroup.first.id}"}
  let(:announcements_page) {url + '/announcements'}
  let(:people_page) {url + '/users'}
  let(:discussions_page) {url + '/discussion_topics'}

  context "as a student" do
    before do
      course_with_student_logged_in(active_all: true)
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students + [@user],@testgroup.first)
    end

    describe "announcements page" do
      it "should center the add announcement button if no announcements are present", priority: "1", test_id: 273606 do
        get announcements_page
        expect(f('#content.container-fluid div')).to have_attribute(:style, 'text-align: center;')
        expect(f('.btn.btn-large.btn-primary')).to be_displayed
      end

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

      it "should list all announcements", priority: "1", test_id: 273608 do
        # Create 5 announcements in the group
        announcements = []
        5.times do |n|
          announcements << @testgroup.first.announcements.create!(title: "Announcement #{n+1}", message: "Message #{n+1}",user: @teacher)
        end

        get announcements_page
        expect(ff('.discussion-topic').size).to eq 5
      end

      it "should only list in-group announcements in the content right pane", priority: "1", test_id: 273621 do
        # create group and course announcements
        @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
        @course.announcements.create!(title: 'Course Announcement', message: 'Course',user: @teacher)

        get announcements_page
        expect_new_page_load { f('.btn-primary').click }
        fj(".ui-accordion-header a:contains('Announcements')").click
        expect(fln('Group Announcement')).to be_displayed
        expect(fln('Course Announcement')).to be_nil
      end

      it "should allow all group members to see announcements", priority: "1", test_id: 273613 do
        @announcement = @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
        # Verifying with a few different group members should be enough to ensure all group members can see it
        verify_member_sees_announcement

        user_session(@students.first)
        verify_member_sees_announcement
      end
    end

    describe "people page" do
      it "should display and show a list of group members", priority: "1", test_id: 273614 do
        get people_page
        # Checks that all students and teachers created in setup are listed on page
        expect(ff('.student_roster .user_name').size).to eq 5
        expect(ff('.teacher_roster .user_name').size).to eq 1
      end
    end

    describe "discussions page" do
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

      it "should only list in-group discussions in the content right pane", priority: "1", test_id: 273622 do
        # create group and course announcements
        group_dt = DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                                           title: 'Group Discussion', message: 'Group')
        course_dt = DiscussionTopic.create!(context: @course, user: @teacher,
                                            title: 'Course Discussion', message: 'Course')

        get discussions_page
        expect_new_page_load { f('.btn-primary').click }
        fj(".ui-accordion-header a:contains('Discussions')").click
        expect(fln("#{group_dt.title}")).to be_displayed
        expect(fln("#{course_dt.title}")).to be_nil
      end
    end
  end

  context "as a teacher" do
    before do
      course_with_teacher_logged_in(active_all: true)
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students,@testgroup.first)
    end

    describe "announcements page" do
      it "should allow teachers to see announcements", priority: "1", test_id: 287049 do
        @announcement = @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @students.first)
        verify_member_sees_announcement
      end

      it "should allow teachers to create an announcement", priority: "1", test_id: 287050 do
        get announcements_page

        # Checks that initial user can create an announcement
        create_group_announcement_manually("Announcement by #{@teacher.name}",'sup')
        wait_for_ajaximations
        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
      end
    end

    describe "discussions page" do
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
        # Verifies group member can access the teacher's group discussion & that it's the correct discussion
        expect_new_page_load { f('.discussion-title').click }
        expect(f('.message.user_content')).to include_text(dt.message)
      end
    end
  end
end
