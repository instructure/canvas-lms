# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe BlockEditorTemplate do
  before do
    course_with_teacher
  end

  it "should have a valid factory" do
    template = BlockEditorTemplate.new({
                                         context_type: "Course",
                                         context_id: @course.id,
                                         name: "name",
                                         description: "description",
                                         node_tree: '{"ROOT": {}}',
                                         editor_version: "1.0",
                                         template_type: "block"
                                       })
    expect(template).to be_valid
    expect(template.workflow_state).to eq("unpublished")
  end

  it "should soft delete" do
    template = BlockEditorTemplate.create!({
                                             context_type: "Course",
                                             context_id: @course.id,
                                             name: "name",
                                             description: "description",
                                             node_tree: '{"ROOT": {}}',
                                             editor_version: "1.0",
                                             template_type: "block"
                                           })
    template.destroy
    expect(BlockEditorTemplate.find_by(id: template.id).workflow_state).to eq("deleted")
  end

  it "should be active when published" do
    template = BlockEditorTemplate.create!({
                                             context_type: "Course",
                                             context_id: @course.id,
                                             name: "name",
                                             description: "description",
                                             node_tree: '{"ROOT": {}}',
                                             editor_version: "1.0",
                                             template_type: "block"
                                           })
    expect(template.active?).to be_falsey
    expect(template.published?).to be_falsey
    template.publish
    expect(template.active?).to be_truthy
    expect(template.published?).to be_truthy
  end
end
