# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "files/index" do
  it "renders" do
    course_with_student
    view_context
    assign(:attachment, @course.attachments.create!(uploaded_data: default_uploaded_data))
    render "files/show"
    expect(response).not_to be_nil
  end

  it "displays a message that the file is locked if user is a student and the file is locked/unpublished" do
    course_with_student
    view_context
    attachment = @course.attachments.create!(uploaded_data: default_uploaded_data)
    attachment.locked = true
    attachment.save!
    assign(:attachment, attachment)
    render "files/show"
    expect(rendered).to match(/This file is currently locked/)
  end
end
