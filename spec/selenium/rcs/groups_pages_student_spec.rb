# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/announcements_common'
require_relative '../helpers/legacy_announcements_common'
require_relative '../helpers/conferences_common'
require_relative '../helpers/course_common'
require_relative '../helpers/discussions_common'
require_relative '../helpers/files_common'
require_relative '../helpers/google_drive_common'
require_relative '../helpers/groups_common'
require_relative '../helpers/groups_shared_examples'
require_relative '../helpers/wiki_and_tiny_common'
require_relative '../discussions/pages/discussions_index_page'
require_relative '../announcements/pages/announcement_new_edit_page'
require_relative '../announcements/pages/announcement_index_page'

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
      enable_all_rcs @course.account
      @course.enroll_teacher(@teacher).accept!
      # This line below is terrible
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students + [@student],@testgroup.first)
    end

    before :each do
      user_session(@student)
      stub_rcs_config
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "home page" do
      it_behaves_like 'home_page', :student

      it "should only allow group members to access the group home page", priority: "1", test_id: 319908 do
        get url
        expect(f('.recent-activity-header')).to be_displayed
        verify_no_course_user_access(url)
      end

      describe "for concluded course" do
        it "should not be accessible to students" do
          course = Course.create!(name: "course 1")
          teacher = User.create!(name: "Teacher 1")
          course.enroll_teacher(teacher).accept!
          student = User.create!(name: "Student 1")
          en = course.enroll_student(student)
          en.workflow_state = 'active'
          en.save!
          course.reload

          category = course.group_categories.create!(name: 'category')
          course.groups.create!(name: "Test Group", group_category: category)
          course.groups.first.add_user student
          course.update_attributes(conclude_at: 1.day.ago, workflow_state: 'completed')

          user_session(student)
          get "/groups/#{course.groups.first.id}"

          expect(driver.current_url).to eq dashboard_url
          expect(f('.ic-flash-error')).to be_displayed
        end

        it "should be accessible to teachers" do
          course = Course.create!(name: "course 1")
          teacher = User.create!(name: "Teacher 1")
          course.enroll_teacher(teacher).accept!
          student = User.create!(name: "Student 1")
          en = course.enroll_student(student)
          en.workflow_state = 'active'
          en.save!
          course.reload

          category = course.group_categories.create!(name: 'category')
          course.groups.create!(name: "Test Group", group_category: category)
          course.groups.first.add_user student
          course.update_attributes(conclude_at: 1.day.ago, workflow_state: 'completed')

          user_session(teacher)
          url = "/groups/#{course.groups.first.id}"
          get url

          expect(driver.current_url).to end_with url
        end
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

    describe "announcements page v2" do
      # will fix the below shared tests in a separate commit
      # it_behaves_like 'announcements_page_v2', :student

      it "should allow group members to delete their own announcements", ignore_js_errors: true do
        announcement = @testgroup.first.announcements.create!(
          title: "Announcement by #{@student.name}",
          message: 'sup',
          user: @student
        )
        get announcements_page
        expect(ff('.ic-announcement-row').size).to eq 1
        AnnouncementIndex.delete_announcement_manually(announcement.title)
        expect(f(".announcements-v2__wrapper")).not_to contain_css('.ic-announcement-row')
      end

      it "should allow any group member to create an announcement" do
        @testgroup.first.announcements.create!(
          title: "Announcement by #{@user.name}",
          message: 'sup',
          user: @user
        )
        # Log in as a new student to see if we can make an announcement
        user_session(@students.first)
        AnnouncementNewEdit.visit_new(@testgroup.first)
        AnnouncementNewEdit.add_message("New Announcement")
        AnnouncementNewEdit.add_title("New Title")
        AnnouncementNewEdit.submit_announcement_form
        expect(driver.current_url).to include(AnnouncementNewEdit.
                                                individual_announcement_url(Announcement.last))
      end

      it "should allow group members to edit their own announcements", ignore_js_errors: true do
        announcement = @testgroup.first.announcements.create!(
          title: "Announcement by #{@user.name}",
          message: 'The Force Awakens',
          user: @user
        )
        get announcements_page
        expect_new_page_load { AnnouncementIndex.click_on_announcement(announcement.title) }
        expect(driver.current_url).to include AnnouncementNewEdit.individual_announcement_url(announcement)
      end

      it "edit page should succeed for their own announcements" do
        announcement = @testgroup.first.announcements.create!(
          title: "Announcement by #{@user.name}",
          message: 'The Force Awakens',
          user: @user
        )
        # note announcement_url includes a leading '/'
        AnnouncementNewEdit.edit_group_announcement(@testgroup.first, announcement,
                                                    "Canvas will be rewritten in chicken")
        announcement.reload
        # Editing *appends* to existing message, and the resulting announcement's
        # message is wrapped in paragraph tags
        expect(announcement.message).to eq("<p>The Force AwakensCanvas will be rewritten in chicken</p>")
      end

      it "student in group can see teachers announcement in index", ignore_js_errors: true do
        announcement = @testgroup.first.announcements.create!(
          title: 'Group Announcement',
          message: 'Group',
          user: @teacher
        )
        user_session(@students.first)
        AnnouncementIndex.visit_groups_index(@testgroup.first)
        expect_new_page_load { AnnouncementIndex.click_on_announcement(announcement.title) }
        expect(f('.discussion-title').text).to eq 'Group Announcement'
        expect(f('.message').text).to eq 'Group'
      end

      it "should only allow group members to access announcements" do
        get announcements_page
        verify_no_course_user_access(announcements_page)
      end

      it "should not allow group members to edit someone else's announcement", priority: "1", test_id: 327111 do
        announcement = @testgroup.first.announcements.create!(
          :title => "foobers",
          :user => @students.first,
          :message => "sup",
          :workflow_state => "published"
        )
        user_session(@student)
        get DiscussionsIndex.individual_discussion_url(announcement)
        expect(f("#content")).not_to contain_css('.edit-btn')
      end

      it "should allow all group members to see announcements", priority: "1", test_id: 273613, ignore_js_errors: true do
        @announcement = @testgroup.first.announcements.create!(
          title: 'Group Announcement',
          message: 'Group',
          user: @teacher
        )
        AnnouncementIndex.visit_groups_index(@testgroup.first)
        expect(ff('.ic-announcement-row').size).to eq 1
        expect_new_page_load { ff('.ic-announcement-row')[0].click }
        expect(f('.discussion-title')).to include_text(@announcement.title)
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "pages page" do
      it "should only allow group members to access pages", priority: "1", test_id: 315331 do
        get pages_page
        expect(f('.new_page')).to be_displayed
        verify_no_course_user_access(pages_page)
      end
    end
  end
end
