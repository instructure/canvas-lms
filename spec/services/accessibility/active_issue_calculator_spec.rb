# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Accessibility::ActiveIssueCalculator do
  let(:course) { course_model }
  let(:statistic) { AccessibilityCourseStatistic.create!(course:) }
  let(:service) { described_class.new(statistic:) }

  describe "#calculate" do
    context "when there are no issues" do
      it "sets active_issue_count to 0" do
        service.calculate
        expect(statistic.active_issue_count).to eq(0)
      end
    end

    context "when there are active issues" do
      before do
        3.times { accessibility_issue_model(course:, workflow_state: "active") }
      end

      it "sets active_issue_count to the count of active issues" do
        service.calculate
        expect(statistic.active_issue_count).to eq(3)
      end
    end

    context "when there are issues with different workflow states" do
      before do
        5.times { accessibility_issue_model(course:, workflow_state: "active") }
        2.times { accessibility_issue_model(course:, workflow_state: "resolved") }
        3.times { accessibility_issue_model(course:, workflow_state: "dismissed") }
      end

      it "sets active_issue_count to only the count of active issues" do
        service.calculate
        expect(statistic.active_issue_count).to eq(5)
      end
    end

    context "when there are issues in multiple courses" do
      let(:other_course) { course_model }

      before do
        3.times { accessibility_issue_model(course:, workflow_state: "active") }
        5.times { accessibility_issue_model(course: other_course, workflow_state: "active") }
      end

      it "sets active_issue_count only for the specified course" do
        service.calculate
        expect(statistic.active_issue_count).to eq(3)
      end
    end
  end
end
