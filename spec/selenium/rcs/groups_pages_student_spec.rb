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
require_relative '../helpers/conferences_common'
require_relative '../helpers/course_common'
require_relative '../helpers/discussions_common'
require_relative '../helpers/files_common'
require_relative '../helpers/google_drive_common'
require_relative '../helpers/groups_common'
require_relative '../helpers/groups_shared_examples'
require_relative '../helpers/wiki_and_tiny_common'
require_relative '../discussions/pages/discussions_index_page'
require_relative '../announcements/announcement_index_page'

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
    describe "announcements page" do
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

      it "should allow all group members to see announcements", priority: "1", test_id: 273613 do
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
