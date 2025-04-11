# frozen_string_literal: true

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

describe SmartSearchController do
  before do
    allow(SmartSearch).to receive(:bedrock_client).and_return(double)
    course_with_student_logged_in
  end

  describe "show" do
    context "when feature is disabled" do
      it "returns unauthorized" do
        get "show", params: { course_id: @course.id }
        expect(response).to be_unauthorized
      end
    end

    context "when feature is enabled" do
      before do
        @course.enable_feature!(:smart_search)
      end

      context "when tab is enabled" do
        it "renders smart search page" do
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("smart_search/show")
        end
      end

      context "when tab is disabled" do
        before do
          @course.update!(tab_configuration: [{ id: Course::TAB_SEARCH, hidden: true }])
        end

        it "redirects to course page" do
          get "show", params: { course_id: @course.id }
          expect(response).to redirect_to(@course)
        end
      end
    end
  end
end
