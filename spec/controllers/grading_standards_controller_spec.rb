# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe GradingStandardsController do
  describe "POST 'create'" do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    let(:default_grading_standard) do
      [["A", 0.94],
       ["A-", 0.9],
       ["B+", 0.87],
       ["B", 0.84],
       ["B-", 0.8],
       ["C+", 0.77],
       ["C", 0.74],
       ["C-", 0.7],
       ["D+", 0.67],
       ["D", 0.64],
       ["D-", 0.61],
       ["F", 0]]
    end

    let!(:teacher_session) { user_session(@teacher) }
    let(:json_response) { json_parse["grading_standard"]["data"] }

    it "responds with a 200 with a valid user, course id, and json format" do
      post "create", params: { course_id: @course.id }, format: "json"
      expect(response).to be_ok
    end

    it "uses the default grading standard if no standard data is provided" do
      post "create", params: { course_id: @course.id }, format: "json"
      expect(json_response).to eq(default_grading_standard)
    end

    it "allows the user to send in a :data param to set the standard" do
      standard = {
        title: "New Grading Standard!",
        data: [["A", 0.61], ["F", 0.00]]
      }
      # send the request as JSON, so that the nested arrays are preserved
      request.content_type = "application/json"
      post "create", params: { course_id: @course.id, grading_standard: standard }, format: "json"
      expect(json_response).to eq(standard[:data])
    end

    it "allows the user to send in a :standard_data param to set the standard" do
      standard = {
        title: "New Grading Standard!",
        standard_data: {
          scheme_1: { name: "A", value: 61 },
          scheme_2: { name: "F", value: 0 }
        }
      }
      post "create", params: { course_id: @course.id, grading_standard: standard }, format: "json"
      expected_response_data = [["A", 0.61], ["F", 0.00]]
      expect(json_response).to eq(expected_response_data)
    end

    it "strips out leading and trailing whitespace for scheme names when passing data" do
      standard = {
        title: "New Grading Standard!",
        data: [["   A ", 0.61], ["F", 0.00]]
      }
      # send the request as JSON, so that the nested arrays are preserved
      request.content_type = "application/json"
      post :create, params: { course_id: @course.id, grading_standard: standard }, format: :json
      expect(json_response).to eq [["A", 0.61], ["F", 0.0]]
    end

    it "strips out leading and trailing whitespace for scheme names when passing standard_data" do
      standard = {
        title: "New Grading Standard!",
        standard_data: {
          scheme_1: { name: "   A ", value: 61 },
          scheme_2: { name: "F", value: 0 }
        }
      }
      post :create, params: { course_id: @course.id, grading_standard: standard }, format: :json
      expect(json_response).to eq [["A", 0.61], ["F", 0.0]]
    end
  end

  describe "POST 'update'" do
    let(:json_response) { json_parse["grading_standard"]["data"] }

    before(:once) do
      course_with_teacher(active_all: true)
      @standard = @course.grading_standards.create!(
        title: "grading standard",
        standard_data: {
          scheme_0: {
            name: "A", value: "95"
          },
          scheme_1: {
            name: "F", value: "0"
          }
        }
      )
    end

    before do
      user_session(@teacher)
    end

    it "strips out leading and trailing whitespace for scheme names when passing data" do
      standard = {
        title: "New Grading Standard!",
        data: [["   A ", 0.61], ["F", 0.00]]
      }
      # send the request as JSON, so that the nested arrays are preserved
      request.content_type = "application/json"
      put :update, params: { course_id: @course.id, grading_standard: standard, id: @standard.id }, format: :json
      expect(json_response).to eq [["A", 0.61], ["F", 0.0]]
    end

    it "strips out leading and trailing whitespace for scheme names when passing standard_data" do
      standard = {
        title: "New Grading Standard!",
        standard_data: {
          scheme_1: { name: "   A ", value: 61 },
          scheme_2: { name: "F", value: 0 }
        }
      }
      put :update, params: { course_id: @course.id, grading_standard: standard, id: @standard.id }, format: :json
      expect(json_response).to eq [["A", 0.61], ["F", 0.0]]
    end
  end

  describe "GET 'index'" do
    context "context is an account" do
      subject { get :index, params: { account_id: @account.id } }

      before(:once) do
        @account = Account.default
        @admin = account_admin_user(account: @account)
      end

      it "returns a 200 for a valid request" do
        user_session(@admin)
        expect(subject).to be_ok
      end

      it "renders the 'account_index' template" do
        user_session(@admin)
        expect(subject).to render_template(:account_index)
      end
    end

    context "context is a course" do
      subject { get :index, params: { course_id: @course.id } }

      before(:once) do
        course_with_teacher(active_all: true)
      end

      it "returns a 200 for a valid request" do
        user_session(@teacher)
        expect(subject).to be_ok
      end

      it "renders the 'course_index' template" do
        user_session(@teacher)
        expect(subject).to render_template(:course_index)
      end
    end
  end
end
