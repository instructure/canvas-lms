# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "site-wide" do
  around do |example|
    consider_all_requests_local(false, &example)
  end

  let(:x_canvas_meta) { "X-Canvas-Meta" }
  let(:x_canvas_user_id) { "X-Canvas-User-Id" }
  let(:x_canvas_real_user_id) { "X-Canvas-Real-User-Id" }
  let(:content_security_policy) { "Content-Security-Policy" }

  it "renders 404 when user isn't logged in" do
    get "/dashbo"
    assert_status(404)
  end

  it "sets no-cache headers for html requests" do
    get "/login"
    expect(response["Pragma"]).to match(/no-cache/)
    expect(response["Cache-Control"]).to match(/no-store/)
  end

  it "does not set no-cache headers for API/xhr requests" do
    get "/api/v1/courses"
    expect(response["Pragma"]).to be_nil
    expect(response["Cache-Control"]).not_to match(/no-store/)
  end

  it "sets the content-security-policy http header" do
    get "/login"
    expect(assigns[:files_domain]).to be_falsey
    expect(response[content_security_policy]).to eq "frame-ancestors 'self' ;"
  end

  it "does not set content-security-policy when on a files domain" do
    user_session user_factory(active_all: true)
    attachment_model(context: @user)
    expect_any_instance_of(FilesController).to receive(:files_domain?).and_return(true)
    get "http://files-test.host/files/#{@attachment.id}/download"
    expect(response[content_security_policy]).to be_nil
  end

  describe "with javascript_csp flag enabled" do
    before :once do
      Account.default.enable_feature! :javascript_csp
      Account.default.enable_csp!
    end

    it "does not override the existing content-security-policy header" do
      course_with_teacher_logged_in

      get "/"
      expect(response[content_security_policy]).to eq "frame-src 'self' blob: localhost; frame-ancestors 'self' ;"
    end
  end

  context "x-canvas-meta header" do
    it "sets action information in API requests" do
      course_with_teacher_logged_in
      get "/api/v1/courses/#{@course.id}"
      expect(response[x_canvas_meta]).to match(/o=courses;n=show;/)
    end

    it "sets controller#action information in API requests on 500" do
      course_with_teacher_logged_in
      allow_any_instance_of(CoursesController).to receive(:index).and_raise(ArgumentError)
      get "/api/v1/courses"

      assert_status(500)
      expect(response[x_canvas_meta]).to match(/o=courses;n=index;/)
    end

    it "sets page view information in user requests" do
      course_with_teacher_logged_in
      Setting.set("enable_page_views", "db")
      get "/courses/#{@course.id}"
      expect(response[x_canvas_meta]).to match(/o=courses;n=show;/)
      expect(response[x_canvas_meta]).to match(/t=Course;/)
      expect(response[x_canvas_meta]).to match(/x=5.0;/)
    end
  end

  context "user headers" do
    before do
      course_with_teacher

      student_in_course
      user_with_pseudonym user: @student, username: "student@example.com", password: "password"
      @student_pseudonym = @pseudonym

      account_admin_user account: Account.site_admin
      user_with_pseudonym user: @admin, username: "admin@example.com", password: "password"
    end

    it "does not set the logged in user headers when no one is logged in" do
      get "/"
      expect(response[x_canvas_user_id]).to be_nil
      expect(response[x_canvas_real_user_id]).to be_nil
    end

    it "sets them when a user is logged in" do
      user_session(@student, @student_pseudonym)
      get "/"
      expect(response[x_canvas_user_id]).to eq @student.global_id.to_s
      expect(response[x_canvas_real_user_id]).to be_nil
    end

    it "sets them when masquerading" do
      user_session(@admin, @admin.pseudonyms.first)
      post "/users/#{@student.id}/masquerade"
      get "/"
      expect(response[x_canvas_user_id]).to eq @student.global_id.to_s
      expect(response[x_canvas_real_user_id]).to eq @admin.global_id.to_s
    end
  end

  context "breadcrumbs" do
    it "is absent for error pages" do
      get "/apagethatdoesnotexist"
      expect(response.body).not_to match(/id="breadcrumbs"/)
    end

    it "is absent for error pages with user info" do
      course_with_teacher
      get "/users/#{@user.id}/files/apagethatdoesnotexist"
      expect(response.body.to_s).not_to match(/id="breadcrumbs"/)
    end
  end

  context "policy cache" do
    it "clears the in-process policy cache between requests" do
      expect(AdheresToPolicy::Cache).to receive(:clear).with(no_args).once
      get "/"
    end
  end

  it "uses the real user's timezone and locale setting when masquerading as a fake student" do
    @fake_user = course_factory(active_all: true).student_view_student

    user_with_pseudonym(active_all: true)
    account_admin_user(user: @user)
    @user.time_zone = "Hawaii"
    @user.locale = "es"
    @user.save!

    user_session(@user)

    post "/users/#{@fake_user.id}/masquerade"

    allow(I18n).to receive(:locale=)

    get "/"

    expect(assigns[:real_current_user]).to eq @user
    expect(Time.zone.name).to eq "Hawaii"
    expect(I18n).to have_received(:locale=).with("es")
  end

  it "uses the masqueree's timezone and locale setting when masquerading" do
    @other_user = user_with_pseudonym(active_all: true)
    @other_user.time_zone = "Hawaii"
    @other_user.locale = "es"
    @other_user.save!

    user_with_pseudonym(active_all: true)
    account_admin_user(user: @user)
    user_session(@user)

    post "/users/#{@other_user.id}/masquerade"

    allow(I18n).to receive(:locale=)

    get "/"

    expect(assigns[:real_current_user]).to eq @user
    expect(Time.zone.name).to eq "Hawaii"
    expect(I18n).to have_received(:locale=).with("es").at_least(:once)
  end

  context "csrf protection" do
    it "returns a real status code for csrf errors" do
      enable_forgery_protection do
        course_with_teacher
        student_in_course
        user_with_pseudonym(user: @student, username: "student@example.com", password: "password")

        account_admin_user(account: Account.site_admin)
        user_with_pseudonym(user: @admin, username: "admin@example.com", password: "password")

        user_session(@admin, @admin.pseudonyms.first)
        post "/users/#{@student.id}/masquerade"

        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  context "error templates" do
    it "returns an html error page even for non-html requests" do
      expect(Canvas::Errors).to receive(:capture).once.and_return({})
      get "/courses/blah.png"
    end
  end

  context "stringifying ids" do
    it "stringifies ids when objects are passed to render" do
      course_with_teacher_logged_in
      user_with_pseudonym username: "blah"
      post "/courses/#{@course.id}/user_lists.json",
           params: { user_list: ["blah"], search_type: "unique_id", v2: true },
           headers: { "Accept" => "application/json+canvas-string-ids" }
      json = JSON.parse response.body
      expect(json["users"][0]["user_id"]).to be_a String
    end
  end
end
