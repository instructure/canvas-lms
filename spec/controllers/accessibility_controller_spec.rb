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

require "spec_helper"

describe AccessibilityController do
  render_views

  let(:course) { Course.create!(name: "Test Course", id: 42) }

  before do
    allow_any_instance_of(AccessibilityController).to receive(:require_context).and_return(true)
    allow_any_instance_of(AccessibilityController).to receive(:require_user).and_return(true)
    allow_any_instance_of(AccessibilityController).to receive(:authorized_action).and_return(true)
    controller.instance_variable_set(:@context, course)
  end

  describe "#index" do
    context "when tab is enabled" do
      before do
        allow_any_instance_of(AccessibilityController).to receive(:tab_enabled?)
          .with(Course::TAB_ACCESSIBILITY).and_return(true)
      end

      it "renders the accessibility checker container" do
        get :index, params: { course_id: 42 }
        expect(response).to be_successful
        expect(response.body).to include("accessibility-checker-container")
      end
    end

    context "when tab is disabled" do
      before do
        allow_any_instance_of(AccessibilityController).to receive(:tab_enabled?)
          .with(Course::TAB_ACCESSIBILITY).and_return(false)
      end

      it "returns nothing if not allowed" do
        get :index, params: { course_id: 42 }
        expect(response.body).not_to include("accessibility-checker-container")
      end
    end
  end
end
