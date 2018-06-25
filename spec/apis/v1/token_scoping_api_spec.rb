#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "ApplicationController Token Scoping", type: :request do
  describe "url scopes" do
    let(:user) { @user }
    let(:course) { @course }
    let(:quiz) do
      quiz = course.quizzes.create!(title: 'Quiz')
      quiz.publish!
      quiz
    end
    let(:valid_scopes) do
      [
        "url:GET|/api/v1/courses/:course_id/quizzes",
        "url:GET|/api/v1/courses/:course_id/quizzes/:id",
        "url:GET|/api/v1/courses/:course_id/users",
        "url:GET|/api/v1/courses/:id",
        "url:GET|/api/v1/users/:user_id/profile",
        "url:POST|/api/v1/courses/:course_id/assignments",
        "url:POST|/api/v1/courses/:course_id/quizzes",
        "url:PUT|/api/v1/courses/:course_id/quizzes/:id"
      ]
    end
    let(:account) { course.account }
    let(:developer_key) { account.developer_keys.create!(require_scopes: true, scopes: valid_scopes) }

    before(:once) do
      course_with_teacher(user: user_with_pseudonym, active_all: true)
      Account.site_admin.enable_feature!(:developer_key_management_and_scoping)
      Account.default.enable_feature!(:developer_key_management_and_scoping)
    end

    before { enable_developer_key_account_binding!(developer_key) }

    context "Verificient lti" do
      let(:access_token) do
        AccessToken.create!(
          user: user,
          developer_key: developer_key,
          scopes: valid_scopes
        )
      end

      it "validates access token" do
        api_call(:get, "/api/v1/users/#{user.id}/profile", {
          :controller => 'profile',
          :action => 'settings',
          :format => 'json',
          :user_id => user.id.to_s
        }, {}, { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "has access to course" do
        api_call(:get, "/api/v1/courses/#{course.id}", {
          :controller => 'courses',
          :action => 'show',
          :format => 'json',
          :id => course.id.to_s
        }, {}, { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "fetches quizzes" do
        api_call(:get, "/api/v1/courses/#{course.id}/quizzes", {
          :controller => 'quizzes/quizzes_api',
          :action => 'index',
          :format => 'json',
          :course_id => course.id.to_s
        }, {}, { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "fetches quiz details" do
        api_call(:get, "/api/v1/courses/#{course.id}/quizzes/#{quiz.id}", {
          :controller => 'quizzes/quizzes_api',
          :action => 'show',
          :format => 'json',
          :course_id => course.id.to_s,
          :id => quiz.id.to_s
        }, {}, { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "fetches user info from course" do
        api_call(:get, "/api/v1/courses/#{course.id}/users", {
          :controller => 'courses',
          :action => 'users',
          :format => 'json',
          :course_id => course.id.to_s
        }, {}, { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "has ability to create assignments" do
        api_call(:post, "/api/v1/courses/#{course.id}/assignments", {
          :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => course.id.to_s
        },
        { :assignment => { 'name' => 'Assignment Example'} },
        { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 201 })
      end

      it "has ability to create quizzes" do
        api_call(:post, "/api/v1/courses/#{course.id}/quizzes", {
          :controller => 'quizzes/quizzes_api',
          :action => 'create',
          :format => 'json',
          :course_id => course.id.to_s
        },
        { :quiz => { 'title' => 'Quiz Example', 'published' => true } },
        { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "has ability to update quizzes" do
        api_call(:put, "/api/v1/courses/#{course.id}/quizzes/#{quiz.id}", {
          :controller => 'quizzes/quizzes_api',
          :action => 'update',
          :format => 'json',
          :course_id => course.id.to_s,
          :id => quiz.id.to_s
        },
        { :quiz => { 'published' => false } },
        { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 200 })
      end

      it "is not permissible to use unscoped routes" do
        api_call(:get, "/api/v1/courses/#{course.id}/files", {
          :controller => 'files',
          :action => 'api_index',
          :format => 'json',
          :course_id => course.id.to_s
        }, {}, { 'Authorization' => "Bearer #{access_token.full_token}" },
        { expected_status: 401 })
      end
    end

  end
end
