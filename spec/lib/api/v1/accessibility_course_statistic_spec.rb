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
#

describe Api::V1::AccessibilityCourseStatistic do
  include Api::V1::AccessibilityCourseStatistic

  describe ".accessibility_course_statistic_json" do
    let(:account) { Account.create! }
    let(:course) { course_factory(account:) }
    let(:user) { user_model }
    let(:session) { nil }

    context "when statistic is nil" do
      it "returns nil" do
        json = accessibility_course_statistic_json(nil, user, session)
        expect(json).to be_nil
      end
    end

    context "when statistic exists" do
      let(:statistic) do
        AccessibilityCourseStatistic.create!(
          course:,
          active_issue_count: 5,
          workflow_state: "active"
        )
      end

      it "serializes the statistic" do
        json = accessibility_course_statistic_json(statistic, user, session)
        expect(json["id"]).to eq statistic.id
        expect(json["course_id"]).to eq course.id
        expect(json["active_issue_count"]).to eq 5
        expect(json["workflow_state"]).to eq "active"
        expect(json["created_at"]).not_to be_nil
        expect(json["updated_at"]).not_to be_nil
      end

      it "includes all expected fields" do
        json = accessibility_course_statistic_json(statistic, user, session)
        expected_fields = %w[id course_id active_issue_count workflow_state created_at updated_at]
        expect(json.keys).to match_array(expected_fields)
      end
    end

    context "with different workflow states" do
      %w[initialized queued in_progress active failed deleted].each do |state|
        it "serializes statistic with workflow_state #{state}" do
          statistic = AccessibilityCourseStatistic.create!(
            course:,
            workflow_state: state
          )
          json = accessibility_course_statistic_json(statistic, user, session)
          expect(json["workflow_state"]).to eq state
        end
      end
    end

    context "with null active_issue_count" do
      it "serializes statistic with null active_issue_count" do
        statistic = AccessibilityCourseStatistic.create!(
          course:,
          active_issue_count: nil,
          workflow_state: "initialized"
        )
        json = accessibility_course_statistic_json(statistic, user, session)
        expect(json["active_issue_count"]).to be_nil
        expect(json["workflow_state"]).to eq "initialized"
      end
    end

    context "with zero active_issue_count" do
      it "serializes statistic with zero active_issue_count" do
        statistic = AccessibilityCourseStatistic.create!(
          course:,
          active_issue_count: 0,
          workflow_state: "active"
        )
        json = accessibility_course_statistic_json(statistic, user, session)
        expect(json["active_issue_count"]).to eq 0
        expect(json["workflow_state"]).to eq "active"
      end
    end
  end
end
