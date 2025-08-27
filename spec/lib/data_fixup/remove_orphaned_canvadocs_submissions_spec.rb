# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe DataFixup::RemoveOrphanedCanvadocsSubmissions do
  before do
    course_with_student_submissions
    @canvadocs_submission = @student.submissions.first.canvadocs_submissions.create!(canvadoc_id: 1)
    CanvadocsSubmission.insert_all([
                                     { submission_id: 123, canvadoc_id: 2 },
                                     { submission_id: 123, canvadoc_id: 3 }
                                   ])
  end

  it "removes orphaned Canvadocs submissions" do
    expect(CanvadocsSubmission.count).to eq(3)
    DataFixup::RemoveOrphanedCanvadocsSubmissions.run
    expect(CanvadocsSubmission.count).to eq(1)
    expect(CanvadocsSubmission.first).to eq(@canvadocs_submission)
  end
end
