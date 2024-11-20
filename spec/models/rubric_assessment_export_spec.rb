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

describe RubricAssessmentExport do
  describe "#generate_file" do
    let(:options) { nil }

    before do
      course_with_teacher_logged_in(active_all: true)
      rubric_assessment_model(user: @user, context: @course, purpose: "grading")
      @export = described_class.new(rubric_association: @rubric_association, user: @user, options:)
    end

    context "when not filters applied" do
      it "returns only one row" do
        csv_content = @export.generate_file
        rows = CSV.parse(csv_content, headers: true)

        expect(rows.size).to eq(1)
      end
    end

    context "when filter all is applied" do
      let(:options) { { filter: "all" } }

      it "returns only one row" do
        csv_content = @export.generate_file
        rows = CSV.parse(csv_content, headers: true)

        expect(rows.size).to eq(1)
      end
    end

    context "when filter non-completed is applied" do
      let(:options) { { filter: "non-completed" } }

      it "returns only one row" do
        csv_content = @export.generate_file
        rows = CSV.parse(csv_content, headers: true)

        expect(rows.size).to eq(0)
      end
    end

    context "when filter completed is applied" do
      let(:options) { { filter: "completed" } }

      it "returns only one row" do
        csv_content = @export.generate_file
        rows = CSV.parse(csv_content, headers: true)

        expect(rows.size).to eq(1)
      end
    end
  end
end
