# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe HorizonMode do
  controller(CoursesController) do
    def show
      render json: {}
    end

    def test_performed?
      performed?
    end
  end

  before :once do
    @course = course_factory(active_all: true)
    course_with_student(active_all: true)
    @admin = account_admin_user(account: @account)
    root_account = @course.root_account
    root_account.settings[:horizon_domain] = "test.canvasforcareer.com"
    root_account.save!
    @account = @course.account
  end

  before do
    request.path = "/courses/#{@course.id}"
  end

  def setup(user, context)
    user_session(user)
    controller.instance_variable_set(:@current_user, user)
    controller.instance_variable_set(:@context, context)
  end

  describe "#load_canvas_career" do
    context "when course is not a Horizon course" do
      it "does not redirect" do
        setup(@student, @course)
        get :show, params: { id: @course.id }
        expect(response).to have_http_status :ok
      end
    end

    context "when course is a Horizon course" do
      before :once do
        @account.enable_feature!(:horizon_course_setting)
        @course.update!(horizon_course: true)
      end

      it "does not redirect when force_classic param is true" do
        setup(@student, @course)
        controller.params[:force_classic] = "true"

        expect(controller).not_to receive(:load_canvas_career_for_student)
        expect(controller).not_to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "does not redirect when api_request?" do
        setup(@student, @course)

        allow(controller).to receive(:api_request?).and_return(true)

        expect(controller).not_to receive(:load_canvas_career_for_student)
        expect(controller).not_to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "calls both student and provider methods in correct order" do
        setup(@teacher, @course)

        allow(controller).to receive(:performed?).and_return(false)

        expect(controller).to receive(:load_canvas_career_for_student).ordered
        expect(controller).to receive(:load_canvas_career_for_provider).ordered

        controller.load_canvas_career
      end

      it "does not call provider method if student method performed a redirect" do
        setup(@student, @course)

        allow(controller).to receive(:performed?).and_return(true)

        expect(controller).to receive(:load_canvas_career_for_student)
        expect(controller).not_to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "tries student path first for student users" do
        setup(@student, @course)
        get :show, params: { id: @course.id }
        expect(response).to redirect_to("https://test.canvasforcareer.com/redirect?canvas_url=%2Fcourses%2F#{@course.id}&preview=false&reauthenticate=false")
      end

      it "tries provider path for admin users when feature is enabled" do
        setup(@admin, @course)
        @account.enable_feature!(:horizon_learning_provider_app_for_accounts)

        allow(controller).to receive(:performed?).and_return(false)

        expect(controller).to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "does not redirect if user is not student" do
        setup(@teacher, @course)
        get :show, params: { id: @course.id }
        expect(response).to have_http_status :ok
      end

      it "does not redirect if user is account admin" do
        setup(@admin, @course)
        get :show, params: { id: @course.id }
        expect(response).to have_http_status :ok
      end

      it "does not redirect if horizon domain is not set, even if student" do
        setup(@student, @course)
        @course.root_account.settings[:horizon_domain] = nil
        @course.root_account.save!
        get :show, params: { id: @course.id }
        expect(response).to have_http_status :ok
      end

      it "does not redirect when invitation param is present" do
        setup(@student, @course)
        get :show, params: { id: @course.id, invitation: "some_value" }
        expect(response).to have_http_status :ok
      end

      context "when context is an Account" do
        before :once do
          @account.horizon_account = true
          @account.save!
        end

        it "only tries provider path for account contexts" do
          setup(@admin, @account)

          expect(controller).not_to receive(:load_canvas_career_for_student)
          expect(controller).to receive(:load_canvas_career_for_provider)

          controller.load_canvas_career
        end

        it "redirects to account career path" do
          setup(@admin, @account)
          @account.enable_feature!(:horizon_learning_provider_app_for_accounts)

          request.path = "/accounts/#{@account.id}/settings"

          expect(controller).to receive(:redirect_to).with("/career/accounts/#{@account.id}/settings")

          controller.load_canvas_career
        end
      end

      context "when context is a Course" do
        it "redirects to course career path when appropriate" do
          setup(@admin, @course)
          @account.enable_feature!(:horizon_learning_provider_app_for_courses)

          allow(controller).to receive(:performed?).and_return(false)

          request.path = "/courses/#{@course.id}/settings"

          expect(controller).to receive(:redirect_to).with("/career/courses/#{@course.id}/settings")

          controller.load_canvas_career
        end

        it "does not redirect when path already includes /career" do
          setup(@admin, @course)
          @account.enable_feature!(:horizon_learning_provider_app_for_courses)

          request.path = "/career/courses/#{@course.id}/settings"

          get :show, params: { id: @course.id }
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe "#canvas_career_learning_provider_app_launch_url" do
    it "returns the correct learning provider app launch URL" do
      setup(@admin, @course)
      expected_url = "https://test.canvasforcareer.com/learning-provider/remoteEntry.js"
      expect(controller.canvas_career_learning_provider_app_launch_url).to eq expected_url
    end

    it "constructs URL from the account's horizon domain" do
      setup(@admin, @course)
      @course.root_account.settings[:horizon_domain] = "custom.domain.com"
      @course.root_account.save!

      expected_url = "https://custom.domain.com/learning-provider/remoteEntry.js"
      expect(controller.canvas_career_learning_provider_app_launch_url).to eq expected_url
    end
  end

  describe "#canvas_career_learning_provider_app_enabled?" do
    before :once do
      @account.enable_feature!(:horizon_course_setting)
      @course.update!(horizon_course: true)
      @account.enable_feature!(:horizon_learning_provider_app_for_accounts)
      @account.enable_feature!(:horizon_learning_provider_app_for_courses)
    end

    context "for Course contexts" do
      it "identifies when learning provider app is enabled" do
        @course.update!(horizon_course: true)
        setup(@admin, @course)
        expect(controller.canvas_career_learning_provider_app_enabled?).to be true
      end

      it "does not enable learning provider app when feature flag is off" do
        setup(@admin, @course)
        @account.disable_feature!(:horizon_learning_provider_app_for_courses)
        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "does not enable learning provider app for non-admin users" do
        setup(@student, @course)
        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns false when course is not a horizon course" do
        @course.update!(horizon_course: false)
        setup(@admin, @course)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns false when launch URL is blank" do
        setup(@admin, @course)

        allow(controller).to receive(:canvas_career_learning_provider_app_launch_url).and_return("")

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end
    end

    context "for Account contexts" do
      before :once do
        @account.horizon_account = true
        @account.save!
      end

      it "returns true when account is a horizon account and all other conditions are met" do
        setup(@admin, @account)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be true
      end

      it "returns false when feature flag is disabled" do
        setup(@admin, @account)
        @account.disable_feature!(:horizon_learning_provider_app_for_accounts)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns false when account is not a horizon account" do
        @account.update!(horizon_account: false)
        setup(@admin, @account)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end
    end

    it "returns false when user is not an admin" do
      setup(@student, @course)

      expect(controller.canvas_career_learning_provider_app_enabled?).to be false
    end
  end
end
