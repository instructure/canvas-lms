#
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
require_relative '../announcements/pages/announcement_index_page'
require_relative '../announcements/pages/announcement_new_edit_page'
require_relative '../helpers/groups_common'
require_relative '../helpers/legacy_announcements_common'
require_relative '../helpers/discussions_common'
require_relative '../helpers/wiki_and_tiny_common'
require_relative '../helpers/files_common'
require_relative '../helpers/conferences_common'
require_relative '../helpers/course_common'
require_relative '../helpers/groups_shared_examples'

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
      enable_all_rcs @course.account
      @teacher = teacher_in_course(course: @course, name: 'teacher', active_all: true).user
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students,@testgroup.first)
    end

    before :each do
      user_session(@teacher)
      stub_rcs_config
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "home page" do
      it_behaves_like 'home_page', :teacher
    end

    describe "announcements page v2" do
      # will fix the below shared tests in a separate commit
      # it_behaves_like 'announcements_page_v2', :teacher

      it "should allow teachers to see announcements", ignore_js_errors: true do
        @announcement = @testgroup.first.announcements.create!(
          title: 'Group Announcement',
          message: 'Group',
          user: @students.first
        )
        AnnouncementIndex.visit_groups_index(@testgroup.first)
        expect(ff('.ic-announcement-row').size).to eq 1
      end

      it "should allow teachers to create an announcement", ignore_js_errors: true do
        # Checks that initial user can create an announcement
        AnnouncementNewEdit.create_group_announcement(@testgroup.first,
                                                      "Announcement by #{@teacher.name}", 'sup')
        get announcements_page
        expect(ff('.ic-announcement-row').size).to eq 1
      end

      it "should allow teachers to delete their own group announcements", ignore_js_errors: true do
        skip_if_safari(:alert)
        @testgroup.first.announcements.create!(
          title: 'Student Announcement',
          message: 'test message',
          user: @teacher
        )

        get announcements_page
        expect(ff('.ic-announcement-row').size).to eq 1
        AnnouncementIndex.delete_announcement_manually("Student Announcement")
        expect(f(".announcements-v2__wrapper")).not_to contain_css('.ic-announcement-row')
      end

      it "should allow teachers to delete group member announcements", ignore_js_errors: true do
        skip_if_safari(:alert)
        @testgroup.first.announcements.create!(
          title: 'Student Announcement',
          message: 'test message', user:
            @students.first
        )

        get announcements_page
        expect(ff('.ic-announcement-row').size).to eq 1
        AnnouncementIndex.delete_announcement_manually("Student Announcement")
        expect(f(".announcements-v2__wrapper")).not_to contain_css('.ic-announcement-row')
      end

      it "should let teachers see announcement details", ignore_js_errors: true do
        announcement = @testgroup.first.announcements.create!(
          title: 'Test Announcement',
          message: 'test message',
          user: @teacher
        )
        get announcements_page
        expect_new_page_load { AnnouncementIndex.click_on_announcement(announcement.title) }
        expect(f('.discussion-title').text).to eq 'Test Announcement'
        expect(f('.message').text).to eq 'test message'
      end

      it "edit button from announcement details works on teachers announcement" do
        announcement = @testgroup.first.announcements.create!(
          title: 'Test Announcement',
          message: 'test message',
          user: @teacher
        )
        url_base = AnnouncementNewEdit.full_individual_announcement_url(
          @testgroup.first,
          announcement
        )
        get url_base
        expect_new_page_load { f('.edit-btn').click }
        expect(driver.current_url).to include "#{url_base}/edit"
        expect(f('#content-wrapper')).not_to contain_css('#sections_autocomplete_root input')
      end

      it "edit page should succeed for their own announcements" do
        announcement = @testgroup.first.announcements.create!(
          title: "Announcement by #{@user.name}",
          message: 'The Force Awakens',
          user: @teacher
        )
        AnnouncementNewEdit.edit_group_announcement(@testgroup.first, announcement,
                                                    "Canvas will be rewritten in chicken")
        announcement.reload
        # Editing *appends* to existing message, and the resulting announcement's
        # message is wrapped in paragraph tags
        expect(announcement.message).to eq("<p>The Force AwakensCanvas will be rewritten in chicken</p>")
      end

      it "should let teachers edit group member announcements" do
        announcement = @testgroup.first.announcements.create!(
          title: 'Your Announcement',
          message: 'test message',
          user: @students.first
        )
        url_base = AnnouncementNewEdit.full_individual_announcement_url(
          @testgroup.first,
          announcement
        )
        get url_base
        expect_new_page_load { f('.edit-btn').click }
        expect(driver.current_url).to include "#{url_base}/edit"
        expect(f('#content-wrapper')).not_to contain_css('#sections_autocomplete_root input')
      end

      it "edit page should succeed for group member announcements" do
        announcement = @testgroup.first.announcements.create!(
          title: "Announcement by #{@user.name}",
          message: 'The Force Awakens',
          user: @students.first
        )
        AnnouncementNewEdit.edit_group_announcement(@testgroup.first, announcement,
                                                    "Canvas will be rewritten in chicken")
        announcement.reload
        # Editing *appends* to existing message, and the resulting announcement's
        # message is wrapped in paragraph tags
        expect(announcement.message).to eq("<p>The Force AwakensCanvas will be rewritten in chicken</p>")
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
  end
end
