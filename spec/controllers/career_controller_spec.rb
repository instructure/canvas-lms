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
    @course.account.enable_feature!(:horizon_learning_provider_app_for_accounts)
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

        get :catch_all, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(response).to render_template("layouts/bare")
      end

      it "sets course context for content-libraries route" do
        allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(true)

        get :catch_all, params: { path: "content-libraries", course_id: @course.id }

        expect(assigns(:context)).to eq(@course)
        expect(response).to be_successful
      end

      it "calls remote_env and deferred_js_bundle when app is enabled" do
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://test.canvasforcareer.com/learning-provider/remoteEntry.js"
        )

        expect(controller).to receive(:remote_env).with(canvascareer: "https://test.canvasforcareer.com/learning-provider/remoteEntry.js")
        expect(controller).to receive(:deferred_js_bundle).with(:canvas_career)

        get :catch_all, params: { course_id: @course.id }
      end

      it "adds career features to js_env" do
        @course.account.enable_feature!(:horizon_crm_integration)
        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://example.com/app.js"
        )

        get :catch_all, params: { course_id: @course.id }

        expect(assigns[:js_env][:CANVAS_CAREER][:FEATURES][:horizon_crm_integration]).to be(true)
      end
    end

    context "with student user" do
      before do
        course_with_student(active_all: true, course: @course)
        user_session(@student)
      end

      it "renders successfully when horizon_redirect_url is nil" do
        allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(true)
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
  end

  describe "HorizonMode inclusion" do
    it "includes the HorizonMode module" do
      expect(CareerController.included_modules).to include(HorizonMode)
    end
  end
end
