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

describe "master courses - child courses - assignment locking" do
  include_context "in-process server selenium tests"

  before :once do
    due_date = format_date_for_view(1.month.ago)
    @copy_from = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_assmt = @copy_from.assignments.create!(
      title: "blah", description: "bloo", points_possible: 27, due_at: due_date
    )
    @tag = @template.create_content_tag_for!(@original_assmt)

    course_with_teacher(active_all: true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    # just create a copy directly instead of doing a real migration
    @assmt_copy = @copy_to.assignments.new(
      title: "blah", description: "bloo", points_possible: 27, due_at: due_date
    )
    @assmt_copy.migration_id = @tag.migration_id
    @assmt_copy.save!
  end

  before do
    stub_rcs_config
    user_session(@teacher)
  end

  it "shows the delete cog-menu options on the edit when not locked" do
    get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}/edit"

    f(".al-trigger").click
    expect(f("#edit_assignment_header")).not_to contain_css("a.delete_assignment_link.disabled")
    expect(f("#edit_assignment_header")).to contain_css("a.delete_assignment_link")
  end
end
