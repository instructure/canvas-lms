# frozen_string_literal: true

#
# Copyright (C) 2011-14 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe GradingStandardsApiController, type: :request do
  let(:account) { Account.default }
  let(:course) { Course.create! }
  let(:account_standard) { grading_standard_for account }
  let(:course_standard) { grading_standard_for course }

  let(:account_resources_path) { "/api/v1/accounts/#{account.id}/grading_standards" }
  let(:course_resources_path) { "/api/v1/courses/#{course.id}/grading_standards" }
  let(:account_resource_path) { "#{account_resources_path}/#{account_standard.id}" }
  let(:course_resource_path) { "#{course_resources_path}/#{course_standard.id}" }

  let(:account_resources_params) do
    {
      controller: "grading_standards_api",
      action: "context_index",
      format: "json",
      account_id: account.id.to_s
    }
  end
  let(:course_resources_params) do
    {
      controller: "grading_standards_api",
      action: "context_index",
      format: "json",
      course_id: course.id.to_s
    }
  end
  let(:account_resource_params) do
    account_resources_params.merge({
                                     action: "context_show",
                                     grading_standard_id: account_standard.id
                                   })
  end
  let(:course_resource_params) do
    course_resources_params.merge({
                                    action: "context_show",
                                    grading_standard_id: course_standard.id
                                  })
  end
  let(:account_create_params) do
    account_resources_params.merge({
                                     action: "create"
                                   })
  end
  let(:course_create_params) do
    course_resources_params.merge({
                                    action: "create"
                                  })
  end
  let(:account_destroy_params) do
    account_resources_params.merge({
                                     action: "destroy",
                                     grading_standard_id: account_standard.id
                                   })
  end
  let(:course_destroy_params) do
    course_resources_params.merge({
                                    action: "destroy",
                                    grading_standard_id: course_standard.id
                                  })
  end

  context "account admin" do
    before do
      account_admin_user
    end

    describe "get grading standards" do
      it "returns a list of account grading standards" do
        account_standard
        res = api_call(:get, account_resources_path, account_resources_params)
        expect(res.first["context_type"]).to eq "Account"
        expect(res.first["context_id"]).to eq account.id
      end

      it "returns a list of course grading standards" do
        course_standard
        res = api_call(:get, course_resources_path, course_resources_params)
        expect(res.first["context_type"]).to eq "Course"
        expect(res.first["context_id"]).to eq course.id
      end
    end

    describe "#context_show" do
      it "returns a single account grading standard" do
        res = api_call(:get, account_resource_path, account_resource_params)
        expect(res["context_type"]).to eq "Account"
        expect(res["context_id"]).to eq account.id
        expect(res["id"]).to eq account_standard.id
        expect(res["points_based"]).to be false
        expect(res["scaling_factor"]).to eq 1.0
      end

      it "returns a single course grading standard" do
        res = api_call(:get, course_resource_path, course_resource_params)
        expect(res["context_type"]).to eq "Course"
        expect(res["context_id"]).to eq course.id
        expect(res["id"]).to eq course_standard.id
        expect(res["points_based"]).to be false
        expect(res["scaling_factor"]).to eq 1.0
      end

      it "returns a 404 if the grading standard does not exist" do
        api_call(:get, "#{course_resources_path}/5", course_resource_params.merge(grading_standard_id: "5"), {}, {}, { expected_status: 404 })
      end

      describe "points based grading standards" do
        let(:grading_scheme_entry) do
          [
            { "name" => "A", "value" => "9" },
            { "name" => "B", "value" => "8" },
            { "name" => "C", "value" => "7" },
            { "name" => "D", "value" => "0" },
          ]
        end

        it "returns a scaling factor and points based flag for course grading standards" do
          course_standard.update!(points_based: true, scaling_factor: 10.0)
          res = api_call(:get, course_resource_path, course_resource_params)
          expect(res["points_based"]).to be true
          expect(res["scaling_factor"]).to eq 10.0
        end

        it "returns a scaling factor and points based flag for account grading standards" do
          account_standard.update!(points_based: true, scaling_factor: 10.0)
          res = api_call(:get, account_resource_path, account_resource_params)
          expect(res["points_based"]).to be true
          expect(res["scaling_factor"]).to eq 10.0
        end

        it "creates a points based grading standard" do
          post_params = { "title" => "points based grading standard", "points_based" => true, "scaling_factor" => 10.0, "grading_scheme_entry" => grading_scheme_entry }
          res = api_call(:post, account_resources_path, account_create_params, post_params, {}, { expected_status: 200 })
          expect(res["points_based"]).to be true
          expect(res["scaling_factor"]).to eq 10.0

          grading_scheme = res["grading_scheme"]
          expect(grading_scheme.count).to eq 4
          expect(grading_scheme[0]).to eq({ "name" => "A", "value" => 0.9, "calculated_value" => 9.0 })
          expect(grading_scheme[1]).to eq({ "name" => "B", "value" => 0.8, "calculated_value" => 8.0 })
          expect(grading_scheme[2]).to eq({ "name" => "C", "value" => 0.7, "calculated_value" => 7.0 })
          expect(grading_scheme[3]).to eq({ "name" => "D", "value" => 0.0, "calculated_value" => 0.0 })
        end
      end
    end

    describe "grading standards creation" do
      let(:grading_scheme_entry) do
        [
          { "name" => "A", "value" => "90" },
          { "name" => "B", "value" => "80" },
          { "name" => "C", "value" => "70" },
          { "name" => "D", "value" => "0" },
        ]
      end

      it "creates account level grading standards" do
        post_params = { "title" => "account grading standard", "grading_scheme_entry" => grading_scheme_entry }
        json = api_call(:post, account_resources_path, account_create_params, post_params)
        expect(json["title"]).to eq "account grading standard"
        expect(json["context_id"]).to eq account.id
        expect(json["context_type"]).to eq "Account"
        expect(json["points_based"]).to be false
        expect(json["scaling_factor"]).to eq 1.0
        data = json["grading_scheme"]
        expect(data.count).to eq 4
        expect(data[0]).to eq({ "name" => "A", "value" => 0.9, "calculated_value" => 90.0 })
        expect(data[1]).to eq({ "name" => "B", "value" => 0.8, "calculated_value" => 80.0 })
        expect(data[2]).to eq({ "name" => "C", "value" => 0.7, "calculated_value" => 70.0 })
        expect(data[3]).to eq({ "name" => "D", "value" => 0.0, "calculated_value" => 0.0 })
      end

      it "creates course level grading standards" do
        post_params = { "title" => "course grading standard", "grading_scheme_entry" => grading_scheme_entry }
        json = api_call(:post, course_resources_path, course_create_params, post_params)
        expect(json["title"]).to eq "course grading standard"
        expect(json["context_id"]).to eq course.id
        expect(json["context_type"]).to eq "Course"
        expect(json["points_based"]).to be false
        expect(json["scaling_factor"]).to eq 1.0
        data = json["grading_scheme"]
        expect(data.count).to eq 4
        expect(data[0]).to eq({ "name" => "A", "value" => 0.9, "calculated_value" => 90.0 })
        expect(data[1]).to eq({ "name" => "B", "value" => 0.8, "calculated_value" => 80.0 })
        expect(data[2]).to eq({ "name" => "C", "value" => 0.7, "calculated_value" => 70.0 })
        expect(data[3]).to eq({ "name" => "D", "value" => 0.0, "calculated_value" => 0.0 })
      end

      it "returns error if no grading scheme provided" do
        post_params = { "title" => "account grading standard" }
        json = api_call(:post, account_resources_path, account_create_params, post_params, {}, { expected_status: 400 })
        expect(json).to eq({ "errors" => { "data" => [{ "attribute" => "data", "type" => "blank", "message" => "can't be blank" }] } })
      end

      it "returns error if grading scheme does not contain a grade for 0%" do
        grading_standard_without_zero = [
          { "name" => "A", "value" => "90" },
          { "name" => "B", "value" => "80" },
          { "name" => "C", "value" => "70" },
        ]
        post_params = { "title" => "course grading standard", "grading_scheme_entry" => grading_standard_without_zero }
        json = api_call(:post, account_resources_path, account_create_params, post_params, {}, { expected_status: 400 })
        expected_json = {
          "errors" => {
            "data" => [
              {
                "attribute" => "data",
                "type" => "grading schemes must have 0% for the lowest grade",
                "message" => "grading schemes must have 0% for the lowest grade"
              }
            ]
          }
        }
        expect(json).to eq(expected_json)
      end

      it "returns error if grading scheme contains negative values" do
        negative_grading_standard = [
          { "name" => "A", "value" => "-90" },
          { "name" => "B", "value" => "80" },
          { "name" => "C", "value" => "70" },
          { "name" => "D", "value" => "0" }
        ]
        post_params = { "title" => "course grading standard", "grading_scheme_entry" => negative_grading_standard }
        json = api_call(:post, account_resources_path, account_create_params, post_params, {}, { expected_status: 400 })
        expected_json = {
          "errors" => {
            "data" => [
              {
                "attribute" => "data",
                "type" => "grading scheme values cannot be negative",
                "message" => "grading scheme values cannot be negative"
              }
            ]
          }
        }
        expect(json).to eq(expected_json)
      end

      it "returns error if grading scheme contains duplicate values" do
        duplicate_grading_standard = [
          { "name" => "A", "value" => "90" },
          { "name" => "B", "value" => "80" },
          { "name" => "C", "value" => "90" },
          { "name" => "D", "value" => "0" }
        ]
        post_params = { "title" => "course grading standard", "grading_scheme_entry" => duplicate_grading_standard }
        json = api_call(:post, account_resources_path, account_create_params, post_params, {}, { expected_status: 400 })
        expected_json = {
          "errors" => {
            "data" => [
              {
                "attribute" => "data",
                "type" => "grading scheme cannot contain duplicate values",
                "message" => "grading scheme cannot contain duplicate values"
              }
            ]
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    describe "#destroy" do
      it "deletes an account grading standard" do
        standard_id = account_standard.id
        res = api_call(:delete, account_resource_path, account_destroy_params)
        expect(res["id"]).to eq standard_id
        expect(res["context_type"]).to eq "Account"
        expect(res["context_id"]).to eq account.id
        deleted_standard = GradingStandard.find_by(id: standard_id)
        expect(deleted_standard.workflow_state).to eq "deleted"
      end

      it "deletes a course grading standard" do
        standard_id = course_standard.id
        res = api_call(:delete, course_resource_path, course_destroy_params)
        expect(res["id"]).to eq standard_id
        expect(res["context_type"]).to eq "Course"
        expect(res["context_id"]).to eq course.id
        deleted_standard = GradingStandard.find_by(id: standard_id)
        expect(deleted_standard.workflow_state).to eq "deleted"
      end

      it "returns a 404 if the grading standard does not exist" do
        api_call(:delete, "#{course_resources_path}/999", course_destroy_params.merge(grading_standard_id: "999"), {}, {}, { expected_status: 404 })
      end
    end
  end

  context "teacher" do
    let(:grading_scheme_entry) do
      [
        { "name" => "A", "value" => "90" },
        { "name" => "B", "value" => "80" },
        { "name" => "C", "value" => "70" },
        { "name" => "D", "value" => "0" },
      ]
    end

    before do
      user_factory
      enrollment = course.enroll_teacher(@user)
      enrollment.accept!
    end

    describe "grading standard creation" do
      it "returns forbidden for account grading standards" do
        post_params = { "title" => "account grading standard", "grading_scheme_entry" => grading_scheme_entry }
        api_call(:post, account_resources_path, account_create_params, post_params, {}, { expected_status: 403 })
      end

      it "returns ok for course grading standards" do
        post_params = { "title" => "course grading standard", "grading_scheme_entry" => grading_scheme_entry }
        api_call(:post, course_resources_path, course_create_params, post_params, {}, { expected_status: 200 })
      end
    end

    describe "#context_show" do
      it "returns a single account grading standard" do
        res = api_call(:get, account_resource_path, account_resource_params)
        expect(res["context_type"]).to eq "Account"
        expect(res["context_id"]).to eq account.id
        expect(res["id"]).to eq account_standard.id
      end

      it "returns a single course grading standard" do
        res = api_call(:get, course_resource_path, course_resource_params)
        expect(res["context_type"]).to eq "Course"
        expect(res["context_id"]).to eq course.id
        expect(res["id"]).to eq course_standard.id
      end
    end

    describe "#destroy" do
      it "returns forbidden for account grading standards" do
        api_call(:delete, account_resource_path, account_destroy_params, {}, {}, { expected_status: 403 })
      end

      it "deletes course grading standards" do
        standard_id = course_standard.id
        res = api_call(:delete, course_resource_path, course_destroy_params)
        expect(res["id"]).to eq standard_id
        expect(res["context_type"]).to eq "Course"
        expect(res["context_id"]).to eq course.id
        deleted_standard = GradingStandard.find_by(id: standard_id)
        expect(deleted_standard.workflow_state).to eq "deleted"
      end
    end
  end
end
