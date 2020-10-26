# frozen_string_literal: true

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

require_relative '../../helpers/assignments_common'
require_relative '../../helpers/discussions_common'
require_relative '../../helpers/files_common'

describe "discussion assignments" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include FilesCommon
  include AssignmentsCommon

  before(:each) do
    @domain_root_account = Account.default
    course_with_teacher_logged_in
    stub_rcs_config
  end

  context "created with 'more options'" do
    it "should redirect to the discussion new page and maintain parameters", priority: "1", test_id: 209966 do
      ag = @course.assignment_groups.create!(:name => "Stuff")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { build_assignment_with_type("Discussion", :assignment_group_id => ag.id, :name => "More options created discussion", :points => '30', :more_options => true)}
      #check the content of the discussion page for our set point value and name and the URL to make sure were in /discussions
      expect(driver.current_url).to include("discussion_topics/new?assignment_group_id=#{ag.id}&due_at=null&points_possible=30&title=More+options+created+discussion")
      expect(f('#discussion-title')).to have_value "More options created discussion"
      expect(f('#discussion_topic_assignment_points_possible')).to have_value "30"
    end
  end

  context "edited with 'more options'" do
    it "should redirect to the discussion edit page and maintain parameters", priority: "2", test_id: 209968 do
      assign = @course.assignments.create!(:name => "Discuss!", :points_possible => "5", :submission_types => "discussion_topic")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load{ edit_assignment(assign.id, :name => "Rediscuss!", :points => "10", :more_options => true) }
      expect(f('#discussion-title')).to have_value "Rediscuss!"
      expect(f('#discussion_topic_assignment_points_possible')).to have_value "10"
    end
  end

end
