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
#

describe CourseReport do
  before :once do
    course_with_teacher(active_all: true)
  end

  let(:big_number) { 1_234_567_890_123_456_789 }

  it "can capture high job ids" do
    report = CourseReport.create(course: @course, user: @teacher, report_type: "course_pace_docx", root_account: @course.root_account, parameters: {})

    mock_job = {}
    allow(mock_job).to receive(:id).and_return(big_number)
    allow(Delayed::Worker).to receive(:current_job).and_return(mock_job)

    report.capture_job_id
    report.save

    expect(report.reload.job_ids).to include(big_number)
  end
end
