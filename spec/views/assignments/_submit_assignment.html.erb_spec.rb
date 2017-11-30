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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/assignments/_submit_assignment" do
  let(:course) { course_model }
  let(:assignment) { assignment_model(course: course) }
  let(:user) { user_model }
  let(:external_tools) {
    [
      external_tool_model(context: course),
      external_tool_model(context: course),
      external_tool_model(context: course),
      external_tool_model(context: course)
    ]
  }
  let(:group) { group_model(context: course) }

  it 'renders an individual file upload path' do
    assign(:assignment, assignment)
    assign(:context, course)
    assign(:external_tools, external_tools)
    assign(:current_user, user)
    render '/assignments/_submit_assignment'
    expect(rendered).to match(/\/api\/v1\/courses\/#{course.id}\/assignments\/#{assignment.id}\/submissions\/#{user.id}\/files/)
  end

  it 'renders a group file upload path' do
    assign(:assignment, assignment)
    group_category = double()
    allow(group_category).to receive(:group_for).and_return(group)
    allow(assignment).to receive(:group_category).and_return(group_category)
    assign(:context, course)
    assign(:external_tools, external_tools)
    assign(:current_user, user)
    render '/assignments/_submit_assignment'
    expect(rendered).to match(/\/api\/v1\/groups\/#{group.id}\/files/)
  end
end
