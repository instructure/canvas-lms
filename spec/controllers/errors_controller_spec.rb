# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe ErrorsController do
  def authenticate_user!
    @user = User.create!
    Account.site_admin.account_users.create!(user: @user)
    user_session(@user)
  end

  describe "index" do
    before { authenticate_user! }

    it "does not error" do
      get "index"
    end
  end

  describe "POST create" do
    def assert_recorded_error(msg = "Thanks for your help!  We'll get right on this")
      expect(flash[:notice]).to eql(msg)
      expect(response).to be_redirect
      expect(response).to redirect_to(root_url)
    end

    it "creates a new error report" do
      authenticate_user!
      post "create", params: {
        error: {
          url: "someurl",
          message: "BigError",
          email: "testerrors42@example.com",
          user_roles: "user,student"
        }
      }
      assert_recorded_error
      expect(ErrorReport.last.email).to eq("testerrors42@example.com")
      expect(ErrorReport.last.data["user_roles"]).to eq("user,student")
    end

    it "doesnt need authentication" do
      post "create", params: { error: { message: "BigError" } }
      assert_recorded_error
    end

    it "is successful without data" do
      post "create"
      assert_recorded_error
    end

    it "is successful with limited data" do
      post "create", params: { error: { title: "ugly", message: "bacon", fried_ham: "stupid" } }
      assert_recorded_error
    end

    it "does not choke on non-integer ids" do
      post "create", params: { error: { id: "garbage" } }
      assert_recorded_error
      expect(ErrorReport.last.message).not_to eq "Error Report Creation failed"
    end

    it "does not return nil.id if report creation failed" do
      expect(ErrorReport).to receive(:where).once.and_raise("failed!")
      post "create", params: { error: { id: 1 } }, format: "json"
      expect(response.parsed_body).to eq({ "logged" => true, "id" => nil })
    end

    it "does not record the user as nil.id if report creation failed" do
      expect(ErrorReport).to receive(:where).once.and_raise("failed!")
      post "create", params: { error: { id: 1 } }
      expect(ErrorReport.last.user_id).to be_nil
    end

    it "records the user if report creation failed" do
      user = User.create!
      user_session(user)
      expect(ErrorReport).to receive(:where).once.and_raise("failed!")
      post "create", params: { error: { id: 1 } }
      expect(ErrorReport.last.user_id).to eq user.id
    end

    it "infers user_roles" do
      student_in_course(active_all: true)
      user_session(@student)
      post "create", params: { error: { id: 1, message: "it broke :(" } }
      assert_recorded_error
      expect(ErrorReport.order(:id).last.data["user_roles"]).to eq("user,student")
    end

    it "records the real user if they are in student view" do
      authenticate_user!
      svs = course_factory.student_view_student
      session[:become_user_id] = svs.id
      post "create", params: { error: { message: "test message" } }
      expect(ErrorReport.order(:id).last.user_id).to eq @user.id
    end

    it "records the masqueradee user if not in student view" do
      other_user = user_with_pseudonym(name: "other", active_all: true)
      authenticate_user! # reassigns @user
      session[:become_user_id] = other_user.id
      post "create", params: { eerror: { message: "test message" } }
      expect(ErrorReport.order(:id).last.user_id).to eq other_user.id
    end

    it "doesn't create a report if we're out of region" do
      expect(Shard.current).to receive(:in_current_region?).and_return(false)
      expect do
        post "create", params: { error: { id: "garbage" } }
      end.not_to change { ErrorReport.count }
    end

    it "400s if we're out of region" do
      expect(Shard.current).to receive(:in_current_region?).and_return(false)
      post "create", params: { error: { id: "garbage" } }
      expect(response).to be_bad_request
    end

    it "400s if username is sent" do
      post "create", params: { error: { username: "causes_error" } }
      expect(response).to be_bad_request
    end

    describe "captcha validation" do
      before do
        allow(subject).to receive(:captcha_server_key).and_return("test_key")
      end

      it "skips validation if captcha key is not configured" do
        allow(subject).to receive(:captcha_server_key).and_return(nil)
        post "create", params: { error: { message: "test" } }
        assert_recorded_error
      end

      it "skips validation for authenticated users" do
        user_session(user_factory)
        post "create", params: { error: { message: "test" } }
        assert_recorded_error
      end

      it "validates captcha for unauthenticated users" do
        response_double = double(code: "200", body: { success: true, hostname: "test.host" }.to_json)
        allow(CanvasHttp).to receive(:post).and_return(response_double)

        post "create", params: { :error => { message: "test" }, "g-recaptcha-response" => "valid_response" }
        assert_recorded_error
      end

      it "returns error on captcha validation failure" do
        response_double = double(code: "200", body: { success: false, "error-codes": ["invalid-input"] }.to_json)
        allow(CanvasHttp).to receive(:post).and_return(response_double)

        post "create", params: { :error => { message: "test" }, "g-recaptcha-response" => "invalid_response" }, format: :json
        expect(response).to be_bad_request
        expect(response.parsed_body["errors"]).to eq(["invalid-input"])
      end

      it "returns error on hostname mismatch" do
        response_double = double(code: "200", body: { success: true, hostname: "wrong.host" }.to_json)
        allow(CanvasHttp).to receive(:post).and_return(response_double)

        post "create", params: { :error => { message: "test" }, "g-recaptcha-response" => "valid_response" }, format: :json
        expect(response).to be_bad_request
        expect(response.parsed_body["errors"]).to eq(["invalid-hostname"])
      end

      it "raises error if captcha service is unavailable" do
        response_double = double(code: "500")
        allow(CanvasHttp).to receive(:post).and_return(response_double)
        post "create", params: { :error => { message: "test" }, "g-recaptcha-response" => "valid_response" }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
