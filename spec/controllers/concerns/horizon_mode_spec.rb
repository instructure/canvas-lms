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

    def test_redirect
      redirect_to params[:url]
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
  let(:config) { instance_double(CanvasCareer::Config) }

  before do
    # Define route for the anonymous controller
    routes.draw do
      get "show" => "anonymous#show"
      get "test_redirect" => "anonymous#test_redirect"
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

      it "redirects to the career path without horizon parameters" do
        get :show
        expect(response.location).to include("/career/courses/#{course.id}")
        expect(response.location).not_to include("content_only=true")
        expect(response.location).not_to include("instui_theme=career")
        expect(response.location).not_to include("force_classic=true")
      end
    end

    context "when ExperienceResolver returns CAREER_LEARNER" do
      before do
        allow(resolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNER)
      end

      it "redirects to the career path without horizon parameters" do
        get :show
        expect(response.location).to include("/career/courses/#{course.id}")
        expect(response.location).not_to include("content_only=true")
        expect(response.location).not_to include("instui_theme=career")
        expect(response.location).not_to include("force_classic=true")
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

  describe "redirect_to override" do
    let_once(:horizon_account) { account_model }

    before do
      allow(horizon_account).to receive(:horizon_account?).and_return(true)
    end

    context "when @context is a horizon account" do
      before do
        controller.instance_variable_set(:@context, horizon_account)
      end

      it "adds horizon parameters to string URLs" do
        get :test_redirect, params: { url: "/dashboard" }

        expect(response.location).to include("content_only=true")
        expect(response.location).to include("instui_theme=career")
        expect(response.location).to include("force_classic=true")
        expect(response.location).to start_with("http://test.host/dashboard?")
      end

      it "preserves existing query parameters" do
        get :test_redirect, params: { url: "/dashboard?existing=param" }

        expect(response.location).to include("existing=param")
        expect(response.location).to include("content_only=true")
        expect(response.location).to include("instui_theme=career")
        expect(response.location).to include("force_classic=true")
      end

      it "does not add horizon parameters to URLs containing /career/" do
        get :test_redirect, params: { url: "/career/dashboard" }

        expect(response.location).not_to include("content_only=true")
        expect(response.location).not_to include("instui_theme=career")
        expect(response.location).not_to include("force_classic=true")
        expect(response).to redirect_to("/career/dashboard")
      end

      it "does not add horizon parameters to URLs containing /career/ with existing params" do
        get :test_redirect, params: { url: "/career/courses/123?existing=param" }

        expect(response.location).to include("existing=param")
        expect(response.location).not_to include("content_only=true")
        expect(response.location).not_to include("instui_theme=career")
        expect(response.location).not_to include("force_classic=true")
        expect(response).to redirect_to("/career/courses/123?existing=param")
      end

      it "does not modify non-string redirect options" do
        allow(controller).to receive(:root_url).and_return("/root")

        # Mock the original redirect_to behavior for non-string options
        original_redirect_to = controller.method(:redirect_to).super_method
        expect(controller).to receive(:redirect_to).and_wrap_original do |method, *args|
          if args.first.is_a?(String)
            method.call(*args)
          else
            original_redirect_to.call(*args)
          end
        end

        get :test_redirect, params: { url: { action: :show } }
      end
    end

    context "when @context is a horizon course" do
      before do
        allow(course).to receive(:horizon_course?).and_return(true)
        controller.instance_variable_set(:@context, course)
      end

      it "adds horizon parameters by checking course's horizon_course? method" do
        get :test_redirect, params: { url: "/dashboard" }

        expect(response.location).to include("content_only=true")
        expect(response.location).to include("instui_theme=career")
        expect(response.location).to include("force_classic=true")
      end

      it "does not add horizon parameters to URLs containing /career/" do
        get :test_redirect, params: { url: "/career/dashboard" }

        expect(response.location).not_to include("content_only=true")
        expect(response.location).not_to include("instui_theme=career")
        expect(response.location).not_to include("force_classic=true")
        expect(response).to redirect_to("/career/dashboard")
      end

      it "does not add horizon parameters to URLs containing /career/ with existing params" do
        get :test_redirect, params: { url: "/career/courses/123?existing=param" }

        expect(response.location).to include("existing=param")
        expect(response.location).not_to include("content_only=true")
        expect(response.location).not_to include("instui_theme=career")
        expect(response.location).not_to include("force_classic=true")
        expect(response).to redirect_to("/career/courses/123?existing=param")
      end
    end

    context "when @context is a non-horizon course" do
      before do
        allow(course).to receive(:horizon_course?).and_return(false)
        controller.instance_variable_set(:@context, course)
      end

      it "does not add horizon parameters" do
        get :test_redirect, params: { url: "/dashboard" }

        expect(response).to redirect_to("/dashboard")
      end
    end

    context "when @context is nil" do
      before do
        controller.instance_variable_set(:@context, nil)
      end

      it "does not add horizon parameters" do
        get :test_redirect, params: { url: "/dashboard" }

        expect(response).to redirect_to("/dashboard")
      end
    end

    context "when @context is neither Account nor Course" do
      let(:other_context) { double("other_context", id: 123) }

      before do
        controller.instance_variable_set(:@context, other_context)
      end

      it "does not add horizon parameters" do
        get :test_redirect, params: { url: "/dashboard" }

        expect(response).to redirect_to("/dashboard")
      end
    end
  end

  describe "should_add_horizon_params?" do
    subject { controller.send(:should_add_horizon_params?) }

    context "when @context is nil" do
      before { controller.instance_variable_set(:@context, nil) }

      it { is_expected.to be false }
    end

    context "when @context is a horizon account" do
      before do
        allow(account).to receive(:horizon_account?).and_return(true)
        controller.instance_variable_set(:@context, account)
      end

      it { is_expected.to be true }
    end

    context "when @context is a non-horizon account" do
      before do
        allow(account).to receive(:horizon_account?).and_return(false)
        controller.instance_variable_set(:@context, account)
      end

      it { is_expected.to be false }
    end

    context "when @context is a horizon course" do
      before do
        allow(course).to receive(:horizon_course?).and_return(true)
        controller.instance_variable_set(:@context, course)
      end

      it { is_expected.to be true }
    end

    context "when @context is a non-horizon course" do
      before do
        allow(course).to receive(:horizon_course?).and_return(false)
        controller.instance_variable_set(:@context, course)
      end

      it { is_expected.to be false }
    end

    context "when @context is neither Account nor Course" do
      let(:other_context) { double("other_context") }

      before do
        controller.instance_variable_set(:@context, other_context)
      end

      it { is_expected.to be false }
    end

    context "when entering student view for a horizon course" do
      before do
        allow(course).to receive(:horizon_course?).and_return(true)
        controller.instance_variable_set(:@context, course)
        allow(controller).to receive_messages(controller_name: "courses", action_name: "student_view")
      end

      it { is_expected.to be false }
    end

    context "when in student view session for a horizon course" do
      let(:fake_student) { course.student_view_student }

      before do
        allow(course).to receive(:horizon_course?).and_return(true)
        controller.instance_variable_set(:@context, course)
        controller.instance_variable_set(:@current_user, fake_student)
      end

      it { is_expected.to be false }
    end

    context "when POST to student_view path for a horizon course" do
      before do
        allow(course).to receive(:horizon_course?).and_return(true)
        controller.instance_variable_set(:@context, course)
        allow(controller).to receive_messages(controller_name: "courses", action_name: "show")
        allow(request).to receive_messages(path: "/courses/14/student_view/1", method: "POST")
      end

      it { is_expected.to be false }
    end
  end

  describe "add_horizon_params_to_url" do
    it "adds academic content only career theme params to the URL" do
      url = "https://example.com/path"
      result = controller.send(:add_horizon_params_to_url, url)

      expect(result).to include("content_only=true")
      expect(result).to include("instui_theme=career")
      expect(result).to include("force_classic=true")
    end

    it "preserves existing query parameters" do
      url = "https://example.com/path?existing=value"
      result = controller.send(:add_horizon_params_to_url, url)

      expect(result).to include("existing=value")
      expect(result).to include("content_only=true")
      expect(result).to include("instui_theme=career")
      expect(result).to include("force_classic=true")
    end

    it "merges with existing horizon params" do
      url = "https://example.com/path?content_only=false"
      result = controller.send(:add_horizon_params_to_url, url)

      expect(result).to include("content_only=true")
      expect(result).to include("instui_theme=career")
      expect(result).to include("force_classic=true")
    end
  end
end
