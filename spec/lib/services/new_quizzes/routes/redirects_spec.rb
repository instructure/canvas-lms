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

require "spec_helper"

module Services
  describe NewQuizzes::Routes::Redirects do
    let(:course) { course_model }
    let(:account) { account_model }
    let(:assignment) { assignment_model(course:) }
    let(:tool) { external_tool_model(context: course) }

    describe ".item_bank_launch" do
      context "with a course context" do
        it "returns the course item banks path" do
          path = described_class.item_bank_launch(context: course, tool:)
          expect(path).to start_with("/courses/#{course.id}/banks")
        end
      end

      context "with an account context" do
        let(:tool) { external_tool_model(context: account) }

        it "returns the account item banks path" do
          path = described_class.item_bank_launch(context: account, tool:)
          expect(path).to start_with("/accounts/#{account.id}/banks")
        end
      end

      context "with an invalid context" do
        it "raises an ArgumentError" do
          expect do
            described_class.item_bank_launch(context: "invalid", tool:)
          end.to raise_error(ArgumentError, "Context must be a Course or Account")
        end
      end
    end

    describe ".assignment_launch" do
      it "returns the assignment launch path" do
        path = described_class.assignment_launch(context: course, assignment:)
        expect(path).to eq("/courses/#{course.id}/assignments/#{assignment.id}/launch")
      end

      it "forwards additional query parameters" do
        path = described_class.assignment_launch(
          context: course,
          assignment:,
          module_item_id: "42",
          return_url: "http://example.com/courses/1/modules"
        )
        uri = URI.parse(path)
        query_params = Rack::Utils.parse_query(uri.query)

        expect(uri.path).to eq("/courses/#{course.id}/assignments/#{assignment.id}/launch")
        expect(query_params["module_item_id"]).to eq("42")
        expect(query_params["return_url"]).to eq("http://example.com/courses/1/modules")
      end
    end
  end
end
