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
    account = @course.root_account
    account.settings[:horizon_domain] = "test.canvasforcareer.com"
    account.save!
  end

  before do
    @context = Course.find(@course.id)
    controller.instance_variable_set(:@context, @context)
    request.path = "/courses/#{@course.id}"
  end

  context "when course is not a Horizon course" do
    it "does not redirect" do
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end
  end

  context "when course is a Horizon course" do
    before :once do
      Account.site_admin.enable_feature!(:horizon_course_setting)
      @course.update!(horizon_course: true)
    end

    it "does not redirect if user is not student" do
      user_session(@teacher)
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end

    it "does not redirect if user is account admin" do
      admin = account_admin_user(account: @course.account)
      user_session(admin)
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end

    it "redirects to horizon if user is student" do
      user_session(@student)
      get :show, params: { id: @course.id }
      expect(response).to redirect_to("https://test.canvasforcareer.com/redirect?canvas_url=%2Fcourses%2F#{@course.id}&preview=false&reauthenticate=false")
    end

    it "does not redirect if horizon domain is not set, even if student" do
      @course.account.settings[:horizon_domain] = nil
      @course.account.save!
      user_session(@student)
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end

    context "canvas career learning provider app" do
      before :once do
        Account.site_admin.enable_feature!(:horizon_learning_provider_app)
      end

      it "identifies when learning provider app is enabled" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        get :show, params: { id: @course.id }
        expect(controller.canvas_career_learning_provider_app_enabled?).to be true
      end

      it "does not enable learning provider app when feature flag is off" do
        Account.site_admin.disable_feature!(:horizon_learning_provider_app)
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        get :show, params: { id: @course.id }
        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "does not enable learning provider app for non-admin users" do
        user_session(@student)
        get :show, params: { id: @course.id }
        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns the correct learning provider app launch URL" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        get :show, params: { id: @course.id }
        expected_url = "https://test.canvasforcareer.com/learning-provider/remoteEntry.js"
        expect(controller.canvas_career_learning_provider_app_launch_url).to eq expected_url
      end
    end

    context "horizon_course? method" do
      it "returns true when context is a Course with horizon_course flag" do
        expect(controller.horizon_course?).to be true
      end

      it "returns false when context is a Course without horizon_course flag" do
        non_horizon_course = course_factory(active_all: true)
        non_horizon_course.update!(horizon_course: false)
        controller.instance_variable_set(:@context, non_horizon_course)
        expect(controller.horizon_course?).to be false
      end

      it "returns false when context is not a Course" do
        account = Account.default
        controller.instance_variable_set(:@context, account)
        expect(controller.horizon_course?).to be false
      end
    end

    context "horizon_account? method" do
      it "returns true when context is an Account with horizon_account flag" do
        account = Account.default
        account.update!(horizon_account: true)
        controller.instance_variable_set(:@context, account)
        expect(controller.horizon_account?).to be true
      end

      it "returns false when context is an Account without horizon_account flag" do
        account = Account.default
        account.update!(horizon_account: false)
        controller.instance_variable_set(:@context, account)
        expect(controller.horizon_account?).to be false
      end

      it "returns false when context is not an Account" do
        expect(controller.horizon_account?).to be false
      end
    end

    context "horizon_student? method" do
      it "returns true when user is a student" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow_any_instance_of(Course).to receive(:user_is_admin?).and_return(false)
        allow_any_instance_of(Course).to receive(:cached_account_users_for).and_return([])

        expect(controller.horizon_student?).to be true
      end

      it "returns false when user is a teacher" do
        user_session(@teacher)
        controller.instance_variable_set(:@current_user, @teacher)

        allow_any_instance_of(Course).to receive(:user_is_admin?).and_return(true)

        expect(controller.horizon_student?).to be false
      end

      it "returns false when user is an account admin" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow_any_instance_of(Course).to receive(:user_is_admin?).and_return(true)

        expect(controller.horizon_student?).to be false
      end
    end

    context "horizon_admin? method" do
      it "returns true when user has admin rights" do
        user_session(@teacher)
        controller.instance_variable_set(:@current_user, @teacher)

        allow_any_instance_of(Course).to receive(:grants_right?).and_return(true)

        expect(controller.horizon_admin?).to be true
      end

      it "returns true when user is an account admin" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow_any_instance_of(Course).to receive(:grants_right?).and_return(true)

        expect(controller.horizon_admin?).to be true
      end

      it "returns false when user is a student" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow_any_instance_of(Course).to receive(:grants_right?).and_return(false)

        expect(controller.horizon_admin?).to be false
      end
    end

    context "load_canvas_career_for_student" do
      before do
        request.path = "/courses/#{@course.id}"
      end

      it "redirects student to horizon_redirect_url" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow(controller).to receive_messages(
          horizon_course?: true,
          horizon_student?: true
        )
        expected_url = "https://test.canvasforcareer.com/redirect?canvas_url=%2Fcourses%2F#{@course.id}&preview=false&reauthenticate=false"
        allow_any_instance_of(Account).to receive(:horizon_redirect_url).and_return(expected_url)

        expect(controller).to receive(:redirect_to).with(expected_url)
        controller.load_canvas_career_for_student
      end

      it "does not redirect when invitation param is present" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)
        controller.params[:invitation] = "some_value"

        expect(controller).not_to receive(:redirect_to)
        controller.load_canvas_career_for_student
      end

      it "does not redirect when not a horizon course" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow(controller).to receive(:horizon_course?).and_return(false)

        expect(controller).not_to receive(:redirect_to)
        controller.load_canvas_career_for_student
      end

      it "does not redirect when user is not a student" do
        user_session(@teacher)
        controller.instance_variable_set(:@current_user, @teacher)

        allow(controller).to receive(:horizon_student?).and_return(false)

        expect(controller).not_to receive(:redirect_to)
        controller.load_canvas_career_for_student
      end

      it "does not redirect when horizon_redirect_url is nil" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow(controller).to receive_messages(
          horizon_course?: true,
          horizon_student?: true
        )
        allow_any_instance_of(Account).to receive(:horizon_redirect_url).and_return(nil)

        expect(controller).not_to receive(:redirect_to)
        controller.load_canvas_career_for_student
      end
    end

    context "canvas career loading" do
      it "does not redirect when force_classic param is true" do
        user_session(@student)
        controller.params[:force_classic] = "true"

        expect(controller).not_to receive(:load_canvas_career_for_student)
        expect(controller).not_to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "calls both student and provider methods in correct order" do
        user_session(@teacher)
        controller.instance_variable_set(:@current_user, @teacher)

        allow(controller).to receive(:performed?).and_return(false)

        expect(controller).to receive(:load_canvas_career_for_student).ordered
        expect(controller).to receive(:load_canvas_career_for_provider).ordered

        controller.load_canvas_career
      end

      it "does not call provider method if student method performed a redirect" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow(controller).to receive(:performed?).and_return(true)

        expect(controller).to receive(:load_canvas_career_for_student)
        expect(controller).not_to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end

      it "tries student path first for student users" do
        user_session(@student)
        get :show, params: { id: @course.id }
        expect(response).to redirect_to("https://test.canvasforcareer.com/redirect?canvas_url=%2Fcourses%2F#{@course.id}&preview=false&reauthenticate=false")
      end

      it "tries provider path for admin users when feature is enabled" do
        Account.site_admin.enable_feature!(:horizon_learning_provider_app)
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive(:load_canvas_career_for_student)
        allow(controller).to receive(:performed?).and_return(false)

        expect(controller).to receive(:load_canvas_career_for_provider)

        controller.load_canvas_career
      end
    end

    context "load_canvas_career_learning_provider_app" do
      it "calls remote_env and deferred_js_bundle when app is enabled" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive_messages(
          canvas_career_learning_provider_app_enabled?: true,
          canvas_career_learning_provider_app_launch_url: "https://test.canvasforcareer.com/learning-provider/remoteEntry.js"
        )

        expect(controller).to receive(:remote_env).with(canvascareer: "https://test.canvasforcareer.com/learning-provider/remoteEntry.js")
        expect(controller).to receive(:deferred_js_bundle).with(:canvas_career)

        controller.load_canvas_career_learning_provider_app
      end
    end

    context "canvas_career_learning_provider_app_enabled?" do
      before do
        Account.site_admin.enable_feature!(:horizon_learning_provider_app)
      end

      it "returns false when course is not a horizon course and account is not a horizon account" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive_messages(horizon_course?: false, horizon_account?: false)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns false when user is not an admin" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow(controller).to receive(:horizon_admin?).and_return(false)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns false when launch URL is blank" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive_messages(
          horizon_course?: true,
          horizon_admin?: true,
          canvas_career_learning_provider_app_launch_url: ""
        )

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns false when feature flag is disabled" do
        Account.site_admin.disable_feature!(:horizon_learning_provider_app)

        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        expect(controller.canvas_career_learning_provider_app_enabled?).to be false
      end

      it "returns true when all conditions are met" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive_messages(
          horizon_course?: true,
          horizon_admin?: true,
          canvas_career_learning_provider_app_launch_url: "https://test.canvasforcareer.com/learning-provider/remoteEntry.js"
        )

        expect(controller.canvas_career_learning_provider_app_enabled?).to be true
      end

      it "returns true when account is a horizon account and all other conditions are met" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive_messages(
          horizon_course?: false,
          horizon_account?: true,
          horizon_admin?: true,
          canvas_career_learning_provider_app_launch_url: "https://test.canvasforcareer.com/learning-provider/remoteEntry.js"
        )

        expect(controller.canvas_career_learning_provider_app_enabled?).to be true
      end
    end

    context "load_canvas_career_for_provider" do
      before do
        Account.site_admin.enable_feature!(:horizon_learning_provider_app)
      end

      it "redirects to /career path for admin users" do
        admin = account_admin_user(account: @course.account)
        user_session(admin)
        controller.instance_variable_set(:@current_user, admin)

        allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(true)

        request.path = "/courses/#{@course.id}/settings"

        expect(controller).to receive(:redirect_to).with("/courses/#{@course.id}/career")

        controller.load_canvas_career_for_provider
      end

      it "does not redirect for non-admin users" do
        user_session(@student)
        controller.instance_variable_set(:@current_user, @student)

        allow(controller).to receive(:canvas_career_learning_provider_app_enabled?).and_return(false)

        expect(controller).not_to receive(:redirect_to)

        controller.load_canvas_career_for_provider
      end
    end
  end
end
