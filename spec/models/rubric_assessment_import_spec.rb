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

describe RubricAssessmentImport do
  before :once do
    account_model
    course_model(account: @account)
    assignment_model(course: @course)
    user_factory
  end

  def create_import(attachment = nil, assignment = @assignment)
    RubricAssessmentImport.create_with_attachment(assignment, attachment, @user)
  end

  it "should create a new rubric assessment import" do
    import = create_import(stub_file_data("test.csv", "abc", "text"))
    expect(import.workflow_state).to eq("created")
    expect(import.progress).to eq(0)
    expect(import.error_count).to eq(0)
    expect(import.error_data).to eq([])
    expect(import.assignment_id).to eq(@assignment.id)
    expect(import.course_id).to eq(@course.id)
    expect(import.attachment_id).to eq(Attachment.last.id)
  end
end
