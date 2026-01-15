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

describe CareerController do
  before :once do
    course_with_teacher(active_all: true)
    @account = @course.account
    @course.update!(horizon_course: true)
  end

  let(:config) { double("Config", learning_provider_app_launch_url: "https://example.com/lp", learner_app_launch_url: "https://example.com/learner", public_app_config: { some: "config" }) }
  let(:resolver) { instance_double(CanvasCareer::ExperienceResolver) }

  before do
    allow(CanvasCareer::ExperienceResolver).to receive(:new).and_return(resolver)
    allow(CanvasCareer::Config).to receive(:new).with(@course.root_account, anything).and_return(config)
  end

  describe "GET show" do
    it "returns unauthorized without a valid session" do
      get :show
      assert_unauthorized
    end

    context "with authenticated user" do
      before do
        user_session(@teacher)
        allow(controller).to receive(:deferred_js_bundle)
        allow(controller).to receive(:remote_env)
      end

      context "when ExperienceResolver returns ACADEMIC" do
        before do
          allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::ACADEMIC)
        end

        it "redirects to root path" do
          get :show, params: { course_id: @course.id }
          expect(response).to redirect_to(root_path)
        end
      end

      context "when ExperienceResolver returns CAREER_LEARNING_PROVIDER" do
        before do
          allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER)
        end

        it "sets up the JS environment with features" do
          get :show, params: { course_id: @course.id }

          expect(assigns[:js_env][:CANVAS_CAREER][:FEATURES]).to include(
            horizon_role_dashboards: false,
            horizon_dashboard_ai_widgets: false,
            horizon_hris_integrations: false,
            horizon_user_profile_page: false,
            horizon_manual_dashboard_builder: false,
            horizon_learning_library: false,
            horizon_chart_view: false,
            horizon_native_permissions_page: false,
            horizon_course_academic_switcher: false,
            horizon_syncable_objects_redesign: false,
            horizon_help_navigation: false
          )
        end

        it "sets up the JS environment with MAX_GROUP_CONVERSATION_SIZE" do
          Setting.set("max_group_conversation_size", 2)

          get :show, params: { course_id: @course.id }

          expect(assigns[:js_env][:MAX_GROUP_CONVERSATION_SIZE]).to eq(2)
        end

        it "calls remote_env with learning provider URL" do
          expect(controller).to receive(:remote_env).with(
            canvas_career_learning_provider: "https://example.com/lp"
          )
          get :show, params: { course_id: @course.id }
        end

        it "calls deferred_js_bundle with :canvas_career" do
          expect(controller).to receive(:deferred_js_bundle).with(:canvas_career)
          get :show, params: { course_id: @course.id }
        end

        it "renders with bare layout" do
          get :show, params: { course_id: @course.id }
          expect(response).to render_template("layouts/bare")
        end

        it "assigns @include_masquerade_layout to true" do
          allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER)
          get :show, params: { course_id: @course.id }
          expect(assigns(:include_masquerade_layout)).to be(true)
        end
      end

      context "when ExperienceResolver returns CAREER_LEARNER" do
        before do
          allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNER)
        end

        it "calls remote_env with learner URL" do
          expect(controller).to receive(:remote_env).with(
            canvas_career_learner: "https://example.com/learner"
          )
          get :show, params: { course_id: @course.id }
        end

        it "calls deferred_js_bundle with :canvas_career" do
          expect(controller).to receive(:deferred_js_bundle).with(:canvas_career)
          get :show, params: { course_id: @course.id }
        end
      end

      it "injects canvas_career_config" do
        allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNER)

        get :show, params: { course_id: @course.id }
        expect(controller).to have_received(:remote_env).with(canvas_career_config: { some: "config" })
      end
    end
  end
end
