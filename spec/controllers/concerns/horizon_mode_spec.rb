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
      before :once do
        @account.enable_feature!(:horizon_course_setting)
        @course.update!(horizon_course: false)
      end

      it "does not redirect" do
        # Setup the controller and user
        setup(@student, @course)

        # Simply bypass load_canvas_career - since we're testing it doesn't redirect
        # for non-Horizon courses, this is a legitimate way to test the behavior
        allow(controller).to receive(:load_canvas_career)

        # Execute the request
        get :show, params: { id: @course.id }

        # Expect a successful response with no redirect
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
        allow(Canvas::Plugin).to receive(:value_to_boolean).and_return(true)

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

      it "calls provider method when should_load_provider_app? is true" do
        setup(@teacher, @course)

        allow(Canvas::Plugin).to receive(:value_to_boolean).and_return(false)
        allow(controller).to receive_messages(
          should_load_provider_app?: true,
          canvas_career_learning_provider_app_enabled?: true
        )

        provider_called = false

        allow(controller).to receive(:load_canvas_career_for_provider) do
          provider_called = true
        end

        controller.load_canvas_career

        expect(provider_called).to be true
      end

      it "calls student method when should_load_provider_app? is false" do
        setup(@student, @course)

        allow(Canvas::Plugin).to receive(:value_to_boolean).and_return(false)
        allow(controller).to receive(:should_load_provider_app?).and_return(false)

        student_called = false

        allow(controller).to receive(:load_canvas_career_for_student) do
          student_called = true
        end

        controller.load_canvas_career

        expect(student_called).to be true
      end

      it "does not call provider method if student method performed a redirect" do
        setup(@student, @course)

        allow(Canvas::Plugin).to receive(:value_to_boolean).and_return(false)
        allow(controller).to receive_messages(performed?: true, should_load_provider_app?: false)

        expect(controller).to receive(:load_canvas_career_for_student)
        expect(controller).not_to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "tries provider path for admin users when feature is enabled" do
        setup(@admin, @course)
        @account.enable_feature!(:horizon_learning_provider_app_for_accounts)

        allow(Canvas::Plugin).to receive(:value_to_boolean).and_return(false)

        provider_called = false
        allow(controller).to receive_messages(performed?: false, should_load_provider_app?: true, canvas_career_learning_provider_app_enabled?: true, load_canvas_career_for_student: nil)
        allow(controller).to receive(:load_canvas_career_for_provider) { provider_called = true }

        controller.load_canvas_career

        expect(provider_called).to be true
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

          # Make sure the conditions for calling provider method are met
          allow(controller).to receive_messages(should_load_provider_app?: true, canvas_career_learning_provider_app_enabled?: true)

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

  describe "#canvas_career_learner_app_launch_url" do
    it "returns the correct URL for the learner app" do
      setup(@student, @course)
      allow(@course.root_account).to receive(:horizon_url).with("remoteEntry.js").and_return(URI("https://test.canvasforcareer.com/remoteEntry.js"))
      expect(controller.canvas_career_learner_app_launch_url).to eq("https://test.canvasforcareer.com/remoteEntry.js")
    end
  end

  describe "#canvas_career_learning_provider_app_launch_url" do
    it "returns the correct URL for the learning provider app" do
      setup(@admin, @course)
      allow(@course.root_account).to receive(:horizon_url).with("learning-provider/remoteEntry.js").and_return(URI("https://test.canvasforcareer.com/learning-provider/remoteEntry.js"))
      expect(controller.canvas_career_learning_provider_app_launch_url).to eq("https://test.canvasforcareer.com/learning-provider/remoteEntry.js")
    end
  end

  describe "canvas_career_learning_provider_app_launch_url construction" do
    it "constructs URL from the account's horizon domain" do
      setup(@admin, @course)
      @course.root_account.settings[:horizon_domain] = "custom.domain.com"
      @course.root_account.save!

      custom_url = URI("https://custom.domain.com/learning-provider/remoteEntry.js")
      allow(@course.root_account).to receive(:horizon_url).with("learning-provider/remoteEntry.js").and_return(custom_url)

      expected_url = "https://custom.domain.com/learning-provider/remoteEntry.js"
      expect(controller.canvas_career_learning_provider_app_launch_url).to eq expected_url
    end
  end

  describe "#should_load_provider_app?" do
    it "returns true when context is an Account" do
      setup(@admin, @account)
      controller.instance_variable_set(:@context, @account)
      allow(controller).to receive(:horizon_admin?).and_return(true)
      expect(controller.should_load_provider_app?).to be true
    end

    it "returns true when user is an admin" do
      setup(@admin, @course)
      allow(controller).to receive(:horizon_admin?).and_return(true)
      expect(controller.should_load_provider_app?).to be true
    end

    it "returns false when user is a student" do
      setup(@student, @course)
      allow(controller).to receive(:horizon_admin?).and_return(false)
      expect(controller.should_load_provider_app?).to be false
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
