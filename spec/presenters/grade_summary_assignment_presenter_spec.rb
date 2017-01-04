#
# Copyright (C) 2015 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradeSummaryAssignmentPresenter do
  before :each do
    attachment_model
    course_factory(active_all: true)
    student_in_course active_all: true
    teacher_in_course active_all: true
    @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12,
                                                tool_settings_tool: @tool)
    @attachment.context = @student
    @attachment.save!
    @submission = @assignment.submit_homework(@student, attachments: [@attachment])
  end

  let(:summary) {
    GradeSummaryPresenter.new :first, :second, :third
  }

  let(:presenter) {
    GradeSummaryAssignmentPresenter.new(summary,
                                        @student,
                                        @assignment,
                                        @submission)
  }

  context '#is_plagiarism_attachment?' do
    it 'returns true if the attachment has an OriginalityReport' do
      OriginalityReport.create(originality_score: 0.8,
                               attachment: @attachment,
                               submission: @submission,
                               workflow_state: 'pending')

      expect(presenter.is_plagiarism_attachment?(@attachment)).to be_truthy
    end
  end

  context '#originality_report' do
    it 'returns true when an originality report exists' do
      report = OriginalityReport.create(originality_score: 0.8,
                                        attachment: @attachment,
                                        submission: @submission,
                                        workflow_state: 'pending')
      expect(presenter.originality_report?).to be_truthy
    end

    it 'returns false if no originailty report exists' do
      expect(presenter.originality_report?).not_to be_truthy
    end
  end

  context "#grade_distribution" do
    context "when a summary's assignment_stats is empty" do
      before { summary.stubs(:assignment_stats).returns({}) }

      it "does not raise an error " do
        expect { presenter.grade_distribution }.to_not raise_error
      end

      it "returns nil when a summary's assignment_stats is empty" do
        expect(presenter.grade_distribution).to be_nil
      end
    end
  end
end
