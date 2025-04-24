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

describe CareerController do
  before :once do
    course_with_teacher(active_all: true)
    Account.site_admin.enable_feature!(:horizon_learning_provider_app)
    @course.update!(horizon_course: true)
  end

  describe "GET catch_all" do
    it "returns unauthorized without a valid session" do
      get "catch_all", params: { course_id: @course.id }
      assert_unauthorized
    end

    context "with authenticated user" do
      before do
        user_session(@teacher)
      end

      it "renders with bare layout when course_id is valid" do
        # Setup the controller to pass all the checks in set_context_from_params
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        get "catch_all", params: { course_id: @course.id }

        expect(response).to be_successful
        expect(response).to render_template("layouts/bare")
      end

      it "redirects to root path when no course_id is provided and no session course_id exists" do
        # Ensure session doesn't have a course_id
        session.delete(:career_course_id)

        get "catch_all"

        expect(response).to redirect_to(root_path)
      end

      it "uses session career_course_id when available" do
        # Setup the controller to pass all the checks
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        session[:career_course_id] = @course.id
        get "catch_all"

        expect(response).to be_successful
        expect(response).to render_template("layouts/bare")
      end
    end

    context "with student user" do
      before do
        course_with_student(active_all: true, course: @course)
        user_session(@student)
      end

      it "renders successfully when horizon_redirect_url is nil" do
        # Mock the load_canvas_career_for_student method to do nothing
        allow(controller).to receive(:load_canvas_career_for_student)

        # Mock the Account method to return nil for horizon_redirect_url
        allow_any_instance_of(Account).to receive(:horizon_redirect_url).and_return(nil)

        get "catch_all", params: { course_id: @course.id }

        expect(response).to be_successful
      end
    end
  end

  describe "#require_enabled_feature_flag" do
    before do
      user_session(@teacher)
    end

    it "redirects to root_path when horizon_learning_provider_app feature is disabled" do
      # Disable the feature flag
      Account.site_admin.disable_feature!(:horizon_learning_provider_app)

      get "catch_all", params: { course_id: @course.id }

      expect(response).to redirect_to(root_path)
    end

    it "allows access when horizon_learning_provider_app feature is enabled" do
      # Feature is already enabled in the top-level before block
      # Mock necessary methods to pass other checks
      allow(controller).to receive_messages(
        canvas_career_learning_provider_app_enabled?: true,
        canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
      )
      allow(controller).to receive(:load_canvas_career_learning_provider_app)

      get "catch_all", params: { course_id: @course.id }

      expect(response).not_to redirect_to(root_path)
      expect(response).to be_successful
    end
  end
end
