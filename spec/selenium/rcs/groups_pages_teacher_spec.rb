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
    end
  end
end
