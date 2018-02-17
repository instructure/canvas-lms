#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe DataFixup::FixupGroupOriginalityReports do
  let(:submission_one) { submission_model }
  let(:submission_two) { submission_model({assignment: submission_one.assignment}) }
  let!(:submission_three) { submission_model({assignment: submission_one.assignment}) }
  let(:user_one) { submission_one.user }
  let(:user_two) { submission_two.user }
  let(:course) { submission_one.assignment.course }
  let!(:group) do
    group = course.groups.create!(name: 'group one')
    group.add_user(user_one)
    group.add_user(user_two)
    submission_one.update!(group: group)
    submission_two.update!(group: group)
    group
  end
  let(:originality_score) { 23.2 }
  let!(:originality_report) do
    OriginalityReport.create!(
      originality_score: originality_score,
      submission: submission_one
    )
  end

  it 'creates an originality report for each other submission in the group' do
    expect do
      DataFixup::FixupGroupOriginalityReports.run
    end.to change(OriginalityReport, :count).from(1).to(2)
  end

  it 'propagates originality reports to all group submissions' do
    DataFixup::FixupGroupOriginalityReports.run
    expect(submission_two.originality_reports.last.originality_score).to eq originality_score
  end

  it 'does not create originality reports for submissions outside of the group' do
    DataFixup::FixupGroupOriginalityReports.run
    expect(submission_three.originality_reports).to be_blank
  end
end
