#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "site-wide" do
  before do
    consider_all_requests_local(false)
  end

  after do
    consider_all_requests_local(true)
  end

  let(:x_frame_options) { 'X-Frame-Options' }
  let(:x_canvas_meta) { 'X-Canvas-Meta' }
  let(:x_canvas_user_id) { 'X-Canvas-User-Id' }
  let(:x_canvas_real_user_id) { 'X-Canvas-Real-User-Id' }

  it "should render 404 when user isn't logged in" do
    Setting.set 'show_feedback_link', 'true'
    get "/dashbo"
    assert_status(404)
  end

  it "should set the x-ua-compatible http header" do
    get "/login"
    key = 'X-UA-Compatible'
    expect(response[key]).to eq "IE=Edge,chrome=1"
  end

  it "should set no-cache headers for html requests" do
    get "/login"
    expect(response['Pragma']).to match(/no-cache/)
    expect(response['Cache-Control']).to match(/must-revalidate/)
  end

  it "should NOT set no-cache headers for API/xhr requests" do
    get "/api/v1/courses"
    expect(response['Pragma']).to be_nil
    expect(response['Cache-Control']).not_to match(/must-revalidate/)
  end

  it "should set the x-frame-options http header" do
    get "/login"
    expect(assigns[:files_domain]).to be_falsey
    expect(response[x_frame_options]).to eq "SAMEORIGIN"
  end

  it "should not set x-frame-options when on a files domain" do
    user_session user_factory(active_all: true)
    attachment_model(:context => @user)
    FilesController.any_instance.expects(:files_domain?).returns(true)
    get "http://files-test.host/files/#{@attachment.id}/download"
    expect(response[x_frame_options]).to be_nil
  end

  context "x-canvas-meta header" do
    it "should set action information in API requests" do
      course_with_teacher_logged_in
      get "/api/v1/courses/#{@course.id}"
      expect(response[x_canvas_meta]).to match(%r{o=courses;n=show;})
    end

    it "should set page view information in user requests" do
      course_with_teacher_logged_in
      Setting.set('enable_page_views', 'db')
      get "/courses/#{@course.id}"
      expect(response[x_canvas_meta]).to match(%r{o=courses;n=show;})
      expect(response[x_canvas_meta]).to match(%r{t=Course;})
      expect(response[x_canvas_meta]).to match(%r{x=5.0;})
    end
  end

  context "user headers" do
    before(:each) do
      course_with_teacher

      student_in_course
      user_with_pseudonym :user => @student, :username => 'student@example.com', :password => 'password'
      @student_pseudonym = @pseudonym

      account_admin_user :account => Account.site_admin
      user_with_pseudonym :user => @admin, :username => 'admin@example.com', :password => 'password'
    end

    it "should not set the logged in user headers when no one is logged in" do
      get "/"
      expect(response[x_canvas_user_id]).to be_nil
      expect(response[x_canvas_real_user_id]).to be_nil
    end

    it "should set them when a user is logged in" do
      user_session(@student, @student_pseudonym)
      get "/"
      expect(response[x_canvas_user_id]).to eq @student.global_id.to_s
      expect(response[x_canvas_real_user_id]).to be_nil
    end

    it "should set them when masquerading" do
      user_session(@admin, @admin.pseudonyms.first)
      post "/users/#{@student.id}/masquerade"
      get "/"
      expect(response[x_canvas_user_id]).to eq @student.global_id.to_s
      expect(response[x_canvas_real_user_id]).to eq @admin.global_id.to_s
    end
  end

  context "breadcrumbs" do
    it "should be absent for error pages" do
      get "/apagethatdoesnotexist"
      expect(response.body).not_to match(%r{id="breadcrumbs"})
    end

    it "should be absent for error pages with user info" do
      course_with_teacher
      get "/users/#{@user.id}/files/apagethatdoesnotexist"
      expect(response.body.to_s).not_to match(%r{id="breadcrumbs"})
    end
  end

  context "policy cache" do
    it "should clear the in-process policy cache between requests" do
      AdheresToPolicy::Cache.expects(:clear).with(nil).once
      get '/'
    end
  end

  it "should use the real user's timezone and locale setting when masquerading as a fake student" do
    @fake_user = course_factory(active_all: true).student_view_student

    user_with_pseudonym(:active_all => true)
    account_admin_user(:user => @user)
    @user.time_zone = "Hawaii"
    @user.locale = "es"
    @user.save!

    user_session(@user)

    post "/users/#{@fake_user.id}/masquerade"
    get "/"

    expect(assigns[:real_current_user]).to eq @user
    expect(Time.zone.name).to eq "Hawaii"
    expect(I18n.locale).to eq :es
  end

  it "should use the masqueree's timezone and locale setting when masquerading" do
    @other_user = user_with_pseudonym(:active_all => true)
    @other_user.time_zone = "Hawaii"
    @other_user.locale = "es"
    @other_user.save!

    user_with_pseudonym(:active_all => true)
    account_admin_user(:user => @user)
    user_session(@user)

    post "/users/#{@other_user.id}/masquerade"
    get "/"

    expect(assigns[:real_current_user]).to eq @user
    expect(Time.zone.name).to eq "Hawaii"
    expect(I18n.locale).to eq :es
  end

  context "csrf protection" do
    it "returns a real status code for csrf errors" do
      enable_forgery_protection do
        course_with_teacher
        student_in_course
        user_with_pseudonym(:user => @student, :username => 'student@example.com', :password => 'password')

        account_admin_user(:account => Account.site_admin)
        user_with_pseudonym(:user => @admin, :username => 'admin@example.com', :password => 'password')

        user_session(@admin, @admin.pseudonyms.first)
        post "/users/#{@student.id}/masquerade"

        expect(response.status).to eq 422
      end
    end
  end

  context "error templates" do
    it "returns an html error page even for non-html requests" do
      Canvas::Errors.expects(:capture).once.returns({})
      get "/courses/blah.png"
    end
  end

  context "stringifying ids" do
    it "stringifies ids when objects are passed to render" do
      course_with_teacher_logged_in
      user_with_pseudonym :username => 'blah'
      post "/courses/#{@course.id}/user_lists.json",
           { :user_list => ['blah'], :search_type => 'unique_id', :v2 => true },
           { 'Accept' => 'application/json+canvas-string-ids' }
      json = JSON.parse response.body
      expect(json['users'][0]['user_id']).to be_a String
    end
  end
end
