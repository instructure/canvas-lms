require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe "groups" do
  include_context "in-process server selenium tests"

  context "as a student" do
    before do
      course_with_student_logged_in(active_all: true)
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students + [@user],@testgroup.first)
    end

    let(:url) {"/groups/#{@testgroup.first.id}"}
    let(:announcements_page) {url + '/announcements'}
    let(:people_page) {url + '/users'}

    describe "announcement page" do
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
    end

    describe "people page" do
      it "should display and show a list of group members", priority: "1", test_id: 273614 do
        get people_page
        # Checks that all students and teachers created in setup are listed on page
        expect(ff('.student_roster .user_name').size).to eq 5
        expect(ff('.teacher_roster .user_name').size).to eq 1
      end
    end
  end
end