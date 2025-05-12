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
      get :catch_all, params: { course_id: @course.id }
      assert_unauthorized
    end

    context "with authenticated user" do
      before do
        user_session(@teacher)
      end

      it "renders with bare layout when course_id is valid" do
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        get :catch_all, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(response).to render_template("layouts/bare")
      end

      it "uses session career_course_id when available" do
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        allow(controller).to receive(:require_context) do
          controller.instance_variable_set(:@context, @course)
        end

        session[:career_course_id] = @course.id
        get :catch_all, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(response).to render_template("layouts/bare")
      end

      it "sets course context for content-libraries route" do
        allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(true)
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        get :catch_all, params: { path: "content-libraries", course_id: @course.id }

        expect(assigns(:context)).to eq(@course)
        expect(response).to be_successful
      end

      it "sets correct js_env variables and career_path for course context" do
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        get :catch_all, params: { course_id: @course.id }

        expect(controller.js_env[:career_path]).to eq("/courses/#{@course.id}/career")
      end

      it "sets correct career_path for account context" do
        account = Account.default
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )
        allow(controller).to receive(:load_canvas_career_learning_provider_app)

        get :catch_all, params: { account_id: account.id }

        expect(controller.js_env[:career_path]).to eq("/accounts/#{account.id}/career")
      end
    end

    context "with student user" do
      before do
        course_with_student(active_all: true, course: @course)
        user_session(@student)
      end

      it "renders successfully when horizon_redirect_url is nil" do
        allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(true)
        allow(controller).to receive(:load_canvas_career_learning_provider_app)
        allow_any_instance_of(Account).to receive(:horizon_redirect_url).and_return(nil)

        get :catch_all, params: { course_id: @course.id }

        expect(response).to be_successful
      end
    end
  end

  describe "#require_enabled_learning_provider_app" do
    before do
      user_session(@teacher)
    end

    it "redirects to root_path when canvas_career_learning_provider_app_enabled? returns false" do
      allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(false)

      get :catch_all, params: { course_id: @course.id }

      expect(response).to redirect_to(root_path)
    end

    it "allows access when canvas_career_learning_provider_app_enabled? returns true" do
      allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(true)
      allow(controller).to receive(:load_canvas_career_learning_provider_app)

      get :catch_all, params: { course_id: @course.id }

      expect(response).not_to redirect_to(root_path)
      expect(response).to be_successful
    end
  end

  describe "#require_context" do
    before do
      user_session(@teacher)

      allow(controller).to receive_messages(
        canvas_career_learning_provider_app_enabled?: true,
        canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
      )
      allow(controller).to receive(:load_canvas_career_learning_provider_app)
    end

    it "sets context from params when course_id is provided" do
      get :catch_all, params: { course_id: @course.id }

      expect(assigns(:context)).to eq(@course)
    end

    it "sets context from params when account_id is provided" do
      account = Account.default
      get :catch_all, params: { account_id: account.id }

      expect(assigns(:context)).to eq(account)
    end

    it "uses session career_course_id when no context params are provided" do
      expect(controller).to receive(:require_context) do
        controller.instance_variable_set(:@context, Course.find(session[:career_course_id]))
      end

      session[:career_course_id] = @course.id
      get :catch_all, params: { course_id: @course.id }

      expect(assigns(:context)).to eq(@course)
    end
  end

  describe "HorizonMode inclusion" do
    it "includes the HorizonMode module" do
      expect(CareerController.included_modules).to include(HorizonMode)
    end
  end
end
