# coding: utf-8
#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ContextExternalToolAssignmentLookup do
  describe "tool_lookup" do
    before :each do
      course_with_teacher_logged_in
      @tool = @course.context_external_tools.create(name: "a",
                                                   domain: "google.com",
                                                   consumer_key: '12345',
                                                   shared_secret: 'secret')
      @tool.settings[:assignment_configuration] = {url: "http://www.example.com",
                                                   icon_url: "http://www.example.com"}.with_indifferent_access
      @tool.save!

      @assignment = @course.assignments.create!(title: "some assignment",
                                              assignment_group: @group,
                                              points_possible: 12,
                                              tool_settings_tools:[@tool])
    end

    it "finds the tool with the specified id associated with the assignment" do
      tool = ContextExternalToolAssignmentLookup.tool_lookup(@assignment.id, @tool.id)
      expect(tool).to equal(tool)
    end

    it "returns nil if the specified tool is not associated with the assignment" do
      @assignment.tool_settings_tools = []
      @assignment.save!
      tool = ContextExternalToolAssignmentLookup.tool_lookup(@assignment.id, @tool.id)
      expect(tool).to be_nil
    end
  end
end
