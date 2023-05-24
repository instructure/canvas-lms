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

require_relative "../common"

describe "master courses - child courses - external tool locking" do
  include_context "in-process server selenium tests"

  before :once do
    @copy_from = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    attributes = { name: "new tool",
                   consumer_key: "key",
                   shared_secret: "secret",
                   custom_fields: { "a" => "1", "b" => "2" },
                   url: "http://www.example.com" }
    @original_tool = @copy_from.context_external_tools.create!(attributes)
    @tag = @template.create_content_tag_for!(@original_tool)

    course_with_teacher(active_all: true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    @tool_copy = @copy_to.context_external_tools.new(attributes) # just create a copy directly instead of doing a real migration
    @tool_copy.migration_id = @tag.migration_id
    @tool_copy.save!
  end

  before do
    user_session(@teacher)
  end

  it "does not show the cog-menu options on the index when locked" do
    @tag.update(restrictions: { all: true })

    get "/courses/#{@copy_to.id}/settings#tab-tools"

    expect(f(".master-course-cell")).to contain_css(".icon-blueprint-lock")

    expect(f(".ExternalToolsTableRow")).not_to contain_css(".al-trigger")
  end

  it "shows the cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/settings#tab-tools"

    expect(f(".master-course-cell")).to contain_css(".icon-blueprint")

    expect(f(".ExternalToolsTableRow")).to contain_css(".al-trigger")
  end
end
