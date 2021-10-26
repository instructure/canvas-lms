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
#

require 'spec_helper'

describe DataFixup::DeleteExtraPlaceholderSubmissions do
  before(:once) do
    course_with_student
    assignment_model(course: @course)
  end

  it "soft-deletes a submission that no longer has visibility" do
    @assignment.update_column(:only_visible_to_overrides, true)
    expect {
      DataFixup::DeleteExtraPlaceholderSubmissions.run
    }.to change { Submission.active.count }.from(1).to(0)
  end

  it "does not soft-delete a submission that is still visible" do
    expect {
      DataFixup::DeleteExtraPlaceholderSubmissions.run
    }.not_to change { Submission.active.count }
  end
end
