#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../apis/api_spec_helper')

describe WebZipExportsController do

  before :once do
    account = Account.default
    account.settings[:enable_offline_web_export] = true
    account.save!
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  before(:each) do
    user_session(@student)
  end

  describe "GET :index.json", type: :request do
    before(:once) do
      @course.web_zip_exports.create!(user: @student)
      @course.web_zip_exports.create!(user: @student)
    end

    it "should return all course web zip exports" do
      json = api_call_as_user(@student, :get, "/api/v1/courses/#{@course.id}/web_zip_exports", {
        controller: :web_zip_exports,
        action: :index,
        course_id: @course.to_param,
        format: 'json'
      })

      expect(json.size).to eq 2
    end

    it "should not return web zip exports for other users" do
      @course.web_zip_exports.create!(user: @teacher)
      json = api_call_as_user(@student, :get, "/api/v1/courses/#{@course.id}/web_zip_exports", {
        controller: :web_zip_exports,
        action: :index,
        course_id: @course.to_param,
        format: 'json'
      })

      expect(json.size).to eq 2
    end
  end

  describe "GET :show.json", type: :request do
    let_once(:web_zip_export) do
      @course.web_zip_exports.create!({
        user: @student
      })
    end

    it "should be success" do
      json = api_call_as_user(@student, :get, "/api/v1/courses/#{@course.id}/web_zip_exports/#{web_zip_export.id}", {
        controller: :web_zip_exports,
        action: :show,
        course_id: @course.to_param,
        id: web_zip_export.to_param,
        format: 'json'
      })

      expect(json['id']).to eq(web_zip_export.id)
    end

    it "should not show web zip exports for other users" do
      student_in_course(active_all: true)
      response = raw_api_call(:get, "/api/v1/courses/#{@course.id}/web_zip_exports/#{web_zip_export.id}", {
        controller: :web_zip_exports,
        action: :show,
        course_id: @course.to_param,
        id: web_zip_export.to_param,
        format: 'json'
      })

      expect(response).to eq 401
    end
  end

end
