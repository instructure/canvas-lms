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

describe HorizonMode do
  controller(ApplicationController) do
    include HorizonMode

    def show
      load_canvas_career
      head :ok unless performed?
    end
  end

  let_once(:user) { user_factory(active_all: true) }
  let_once(:account) { Account.default }
  let_once(:course) { course_factory(account:, active_all: true) }

  before :once do
    course.update!(horizon_course: true)
    account.enable_feature!(:horizon_course_setting)
  end

  let(:resolver) { instance_double(CanvasCareer::ExperienceResolver) }
  let(:config) { instance_double(CanvasCareer::Config, learner_app_redirect_url: "https://canvasforcareer.com") }

  before do
    # Define route for the anonymous controller
    routes.draw do
      get "show" => "anonymous#show"
    end

    user_session(user)
    allow(CanvasCareer::ExperienceResolver).to receive(:new).and_return(resolver)
    allow(CanvasCareer::Config).to receive(:new).with(account).and_return(config)
    allow(controller).to receive(:canvas_career_path).and_return("/career")
    request.path = "/courses/#{course.id}"
    controller.instance_variable_set(:@context, course)
  end

  describe "load_canvas_career" do
    context "when force_classic param is present" do
      it "does not redirect" do
        get :show, params: { force_classic: "1" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when force_classic cookie is present" do
      before { cookies[:force_classic] = "1" }

      it "does not redirect" do
        get :show
        expect(response).to have_http_status(:ok)
      end
    end

    context "when it's an API request" do
      before { allow(controller).to receive(:api_request?).and_return(true) }

      it "does not redirect" do
        get :show
        expect(response).to have_http_status(:ok)
      end
    end

    context "when invitation param is present" do
      it "does not redirect" do
        get :show, params: { invitation: "abc123" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when no user is logged in" do
      before do
        remove_user_session
      end

      it "does not redirect and returns ok" do
        get :show
        expect(response).to have_http_status(:ok)
      end
    end

    context "when ExperienceResolver returns CAREER_LEARNING_PROVIDER" do
      before do
        allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER)
      end

      it "redirects to the career path with original path included" do
        get :show
        expect(response).to redirect_to("/career/courses/#{course.id}")
      end
    end

    context "when ExperienceResolver returns CAREER_LEARNER" do
      before do
        allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNER)
      end

      context "when horizon_learner_app feature is enabled" do
        before do
          account.enable_feature!(:horizon_learner_app)
        end

        it "redirects to the career path with original path included" do
          get :show
          expect(response).to redirect_to("/career/courses/#{course.id}")
        end
      end

      context "when horizon_learner_app feature is disabled" do
        it "redirects to the configured learner app URL if course is a horizon course" do
          get :show
          expect(response).to redirect_to("https://canvasforcareer.com")
        end

        it "does nothing if course is not a horizon course" do
          course.update!(horizon_course: false)
          get :show
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "when ExperienceResolver returns ACADEMIC" do
      before do
        allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::ACADEMIC)
      end

      it "does not redirect" do
        expect(controller).not_to receive(:redirect_to)
        get :show
      end
    end
  end
end
