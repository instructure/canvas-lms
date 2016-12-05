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

require File.expand_path(File.dirname(__FILE__) + '/../apis/api_spec_helper')

describe EpubExportsController do

  before :once do
    Account.default.enable_feature!(:epub_export)
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "GET index, format html" do
    context "without user" do
      it "should require user to be logged in to access the page" do
        get 'index'
        assert_unauthorized
      end
    end

    context "with user" do
      before(:once) do
        @n = @student.courses.count
        @n_more = 4
        create_courses(@n_more, {
          enroll_user: @student,
          enrollment_type: 'StudentEnrollment'
        })
        @student.enrollments.last.update_attribute(
          :workflow_state, 'completed'
        )
      end

      before(:each) do
        user_session(@student)
      end

      it "should assign collection of courses and render" do
        get :index

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:success)
        expect(assigns(:courses).size).to eq(@n + @n_more)
      end
    end
  end

  describe "GET :index.json", type: :request do
    before(:once) do
      @n = @student.courses.count
      @n_more = 4
      create_courses(@n_more, {
        enroll_user: @student,
        enrollment_type: 'StudentEnrollment'
      })
      @student.enrollments.last.update_attribute(
        :workflow_state, 'completed'
      )
    end

    it "should return course epub exports" do
      json = api_call_as_user(@student, :get, "/api/v1/epub_exports", {
        controller: :epub_exports,
        action: :index,
        format: 'json'
      })

      expect(json['courses'].size).to eq(@n + @n_more)
    end
  end

  describe "GET :show.json", type: :request do
    let_once(:epub_export) do
      @course.epub_exports.create({
        user: @student
      })
    end

    it "should be success" do
      json = api_call_as_user(@student, :get, "/api/v1/courses/#{@course.id}/epub_exports/#{epub_export.id}", {
        controller: :epub_exports,
        action: :show,
        course_id: @course.to_param,
        id: epub_export.to_param,
        format: 'json'
      })

      expect(json['id']). to eq(@course.id)
      expect(json['epub_export']['id']). to eq(epub_export.id)
    end
  end

  describe "POST :create.json", type: :request do
    before :each do
      EpubExport.any_instance.stubs(:export).returns(true)
    end

    let_once(:url) do
      "/api/v1/courses/#{@course.id}/epub_exports"
    end

    context "when epub_export doesn't exist" do
      it "should return json with newly created epub_export" do
        json = api_call_as_user(@student, :post, url, {
          action: :create,
          controller: :epub_exports,
          course_id: @course.id,
          format: 'json'
        })

        expect(json['epub_export']['workflow_state']).to eq('created')
      end

      it "should create one epub_export" do
        expect {
          api_call_as_user(@student, :post, url, {
            action: :create,
            controller: :epub_exports,
            course_id: @course.id,
            format: 'json'
          })
        }.to change{EpubExport.count}.from(0).to(1)
      end
    end

    context "when there is a running epub_export" do
      let_once(:epub_export) do
        @course.epub_exports.create({
          user: @student
        })
      end

      it "should not create one epub_export" do
        expect {
          api_call_as_user(@student, :post, url, {
            action: :create,
            controller: :epub_exports,
            course_id: @course.id,
            format: 'json'
          }, {}, {}, {
            expected_status: 422
          })
        }.not_to change{EpubExport.count}
      end
    end
  end
end
