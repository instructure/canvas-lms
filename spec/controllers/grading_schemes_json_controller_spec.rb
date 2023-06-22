# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe GradingSchemesJsonController, type: :request do
  require_relative "../spec_helper"

  context "account admin" do
    before(:once) do
      @account = Account.default
      @admin = account_admin_user(account: @account)
    end

    describe "get grading schemes" do
      it "returns account level grading schemes json when points_based_grading_schemes ff is on" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                                          scaling_factor: 1.0,
                                                                          points_based: false)
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Grading Scheme",
                                            "context_type" => "Account",
                                            "context_id" => @account.id,
                                            "context_name" => "Default Account",
                                            "data" => data,
                                            "permissions" => { "manage" => true },
                                            "assessed_assignment" => false,
                                            "points_based" => false,
                                            "scaling_factor" => 1.0 })
      end

      it "returns account level grading schemes json when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme", data: GradingSchemesJsonController.to_grading_standard_data(data))
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Grading Scheme",
                                            "context_type" => "Account",
                                            "context_id" => @account.id,
                                            "context_name" => "Default Account",
                                            "data" => data,
                                            "permissions" => { "manage" => true },
                                            "assessed_assignment" => false })
      end
    end

    describe "get grading scheme" do
      it "returns account level grading scheme json" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                                          scaling_factor: 1.0,
                                                                          points_based: false)
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json).to eq({ "id" => account_level_grading_standard.id.to_s,
                                      "title" => "My Grading Scheme",
                                      "context_type" => "Account",
                                      "context_id" => @account.id,
                                      "context_name" => "Default Account",
                                      "data" => data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => false,
                                      "scaling_factor" => 1.0 })
      end

      it "returns account level grading scheme json when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme", data: GradingSchemesJsonController.to_grading_standard_data(data))
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json).to eq({ "id" => account_level_grading_standard.id.to_s,
                                      "title" => "My Grading Scheme",
                                      "context_type" => "Account",
                                      "context_id" => @account.id,
                                      "context_name" => "Default Account",
                                      "data" => data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false })
      end
    end

    describe "get grading scheme summaries" do
      it "returns course and account level grading scheme summary json" do
        account_scheme_data = [{ "name" => "A", "value" => 0.90 },
                               { "name" => "B", "value" => 0.80 },
                               { "name" => "C", "value" => 0.70 },
                               { "name" => "D", "value" => 0.60 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Account Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data))
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_scheme_summaries", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json.length).to eq 1

        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Account Level Grading Standard" })
      end
    end

    describe "get default grading scheme" do
      it "returns default grading scheme json" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes/default", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["title"]).to eq "Default Canvas Grading Scheme"
        expect(response_json["data"]).to eq [{ "name" => "A", "value" => 0.94 },
                                             { "name" => "A-", "value" => 0.9 },
                                             { "name" => "B+", "value" => 0.87 },
                                             { "name" => "B", "value" => 0.84 },
                                             { "name" => "B-", "value" => 0.8 },
                                             { "name" => "C+", "value" => 0.77 },
                                             { "name" => "C", "value" => 0.74 },
                                             { "name" => "C-", "value" => 0.7 },
                                             { "name" => "D+", "value" => 0.67 },
                                             { "name" => "D", "value" => 0.64 },
                                             { "name" => "D-", "value" => 0.61 },
                                             { "name" => "F", "value" => 0.0 }]
        expect(response_json["points_based"]).to be false
        expect(response_json["scaling_factor"]).to eq 1.0
      end

      it "returns default grading scheme json when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes/default", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["title"]).to eq "Default Canvas Grading Scheme"
        expect(response_json["data"]).to eq [{ "name" => "A", "value" => 0.94 },
                                             { "name" => "A-", "value" => 0.9 },
                                             { "name" => "B+", "value" => 0.87 },
                                             { "name" => "B", "value" => 0.84 },
                                             { "name" => "B-", "value" => 0.8 },
                                             { "name" => "C+", "value" => 0.77 },
                                             { "name" => "C", "value" => 0.74 },
                                             { "name" => "C-", "value" => 0.7 },
                                             { "name" => "D+", "value" => 0.67 },
                                             { "name" => "D", "value" => 0.64 },
                                             { "name" => "D-", "value" => 0.61 },
                                             { "name" => "F", "value" => 0.0 }]
      end
    end

    describe "create grading scheme" do
      it "creates non points based grading scheme at account level" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        user_session(@admin)

        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data:,
                   points_based: false,
                   scaling_factor: 1.0 }

        post "/accounts/" + @account.id.to_s + "/grading_schemes",
             params:,
             as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["context_type"]).to eq "Account"
        expect(response_json["context_id"]).to eq @account.id
        expect(response_json["title"]).to eq "My Scheme Title"
        expect(response_json["data"]).to eq data
        expect(response_json["scaling_factor"]).to eq 1.0
        expect(response_json["points_based"]).to be false
        expect(response_json["permissions"]).to eq({ "manage" => true })
      end

      it "creates points based grading scheme with scaling factor at account level" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        user_session(@admin)

        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data:,
                   points_based: true,
                   scaling_factor: 4.0 }

        post "/accounts/" + @account.id.to_s + "/grading_schemes",
             params:,
             as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["context_type"]).to eq "Account"
        expect(response_json["context_id"]).to eq @account.id
        expect(response_json["title"]).to eq "My Scheme Title"
        expect(response_json["data"]).to eq data
        expect(response_json["scaling_factor"]).to eq 4.0
        expect(response_json["points_based"]).to be true
        expect(response_json["permissions"]).to eq({ "manage" => true })
      end

      it "creates grading scheme at account level when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        user_session(@admin)

        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data: }

        post "/accounts/" + @account.id.to_s + "/grading_schemes",
             params:,
             as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["context_type"]).to eq "Account"
        expect(response_json["context_id"]).to eq @account.id
        expect(response_json["title"]).to eq "My Scheme Title"
        expect(response_json["data"]).to eq data
        expect(response_json["permissions"]).to eq({ "manage" => true })
      end
    end

    describe "delete grading scheme" do
      it "deletes grading scheme at account level" do
        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]

        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme to Delete", data: GradingSchemesJsonController.to_grading_standard_data(data))
        account_level_grading_standard.save

        expect(GradingStandard.all.count).to be 1
        user_session(@admin)
        delete "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        # it's a soft delete
        expect(GradingStandard.all.count).to be 1
        expect(GradingStandard.first.title).to eq "My Grading Scheme to Delete"
        expect(GradingStandard.first.workflow_state).to eq "deleted"
        expect(response_json).to eq({})
      end
    end

    describe "update grading scheme" do
      it "returns success when putting account level grading scheme" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                                          points_based: false,
                                                                          scaling_factor: 1.0)
        account_level_grading_standard.save

        user_session(@admin)

        updated_data = [{ "name" => "A", "value" => 0.90 },
                        { "name" => "B", "value" => 0.80 },
                        { "name" => "C", "value" => 0.70 },
                        { "name" => "D", "value" => 0.60 },
                        { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data: updated_data,
                   points_based: false,
                   scaling_factor: 1.0 }
        put "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s,
            params:,
            as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => account_level_grading_standard.id.to_s,
                                      "title" => "My Scheme Title",
                                      "context_type" => "Account",
                                      "context_id" => @account.id,
                                      "context_name" => "Default Account",
                                      "data" => updated_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => false,
                                      "scaling_factor" => 1.0 })
      end

      it "returns success when putting account level grading scheme that is points based" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                                          points_based: true,
                                                                          scaling_factor: 4.0)
        account_level_grading_standard.save

        user_session(@admin)

        updated_data = [{ "name" => "A", "value" => 0.90 },
                        { "name" => "B", "value" => 0.80 },
                        { "name" => "C", "value" => 0.70 },
                        { "name" => "D", "value" => 0.60 },
                        { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data: updated_data,
                   points_based: true,
                   scaling_factor: 5.0 }

        put "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s,
            params:,
            as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => account_level_grading_standard.id.to_s,
                                      "title" => "My Scheme Title",
                                      "context_type" => "Account",
                                      "context_id" => @account.id,
                                      "context_name" => "Default Account",
                                      "data" => updated_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => true,
                                      "scaling_factor" => 5.0 })
      end

      it "returns success when putting account level grading scheme when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme", data: GradingSchemesJsonController.to_grading_standard_data(data))
        account_level_grading_standard.save

        user_session(@admin)

        updated_data = [{ "name" => "A", "value" => 0.90 },
                        { "name" => "B", "value" => 0.80 },
                        { "name" => "C", "value" => 0.70 },
                        { "name" => "D", "value" => 0.60 },
                        { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data: updated_data }

        put "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s,
            params:,
            as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => account_level_grading_standard.id.to_s,
                                      "title" => "My Scheme Title",
                                      "context_type" => "Account",
                                      "context_id" => @account.id,
                                      "context_name" => "Default Account",
                                      "data" => updated_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false })
      end
    end
  end

  context "course teacher" do
    before(:once) do
      @account = Account.default
      course_with_teacher(active_all: true)
    end

    describe "get grading schemes" do
      it "returns course and account level grading schemes json" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        account_scheme_data = [{ "name" => "A", "value" => 0.9 },
                               { "name" => "B", "value" => 0.8 },
                               { "name" => "C", "value" => 0.7 },
                               { "name" => "D", "value" => 0.6 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Account Level Grading Standard",
                                                                          data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data),
                                                                          points_based: false,
                                                                          scaling_factor: 1.0)
        account_level_grading_standard.save

        course_scheme_data = [{ "name" => "A", "value" => 0.98 },
                              { "name" => "A-", "value" => 0.9 },
                              { "name" => "B+", "value" => 0.88 },
                              { "name" => "B", "value" => 0.85 },
                              { "name" => "B-", "value" => 0.8 },
                              { "name" => "C+", "value" => 0.78 },
                              { "name" => "C", "value" => 0.75 },
                              { "name" => "C-", "value" => 0.7 },
                              { "name" => "D+", "value" => 0.68 },
                              { "name" => "D", "value" => 0.65 },
                              { "name" => "D-", "value" => 0.61 },
                              { "name" => "F", "value" => 0.0 }]

        course_level_grading_standard = @course.grading_standards.build(title: "My Course Level Grading Standard",
                                                                        data: GradingSchemesJsonController.to_grading_standard_data(course_scheme_data),
                                                                        points_based: false,
                                                                        scaling_factor: 1.0)
        course_level_grading_standard.save

        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json.length).to eq 2

        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Account Level Grading Standard",
                                            "context_type" => "Account",
                                            "context_id" => @account.id,
                                            "context_name" => "Default Account",
                                            "data" => account_scheme_data,
                                            "permissions" => { "manage" => false },
                                            "assessed_assignment" => false,
                                            "points_based" => false,
                                            "scaling_factor" => 1.0 })

        expect(response_json[1]).to eq({ "id" => course_level_grading_standard.id.to_s,
                                         "title" => "My Course Level Grading Standard",
                                         "context_type" => "Course",
                                         "context_id" => @course.id,
                                         "context_name" => "Unnamed Course",
                                         "data" => course_scheme_data,
                                         "permissions" => { "manage" => true },
                                         "assessed_assignment" => false,
                                         "points_based" => false,
                                         "scaling_factor" => 1.0 })
      end

      it "returns course and account level grading schemes json when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        account_scheme_data = [{ "name" => "A", "value" => 0.9 },
                               { "name" => "B", "value" => 0.8 },
                               { "name" => "C", "value" => 0.7 },
                               { "name" => "D", "value" => 0.6 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Account Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data))
        account_level_grading_standard.save

        course_scheme_data = [{ "name" => "A", "value" => 0.98 },
                              { "name" => "A-", "value" => 0.9 },
                              { "name" => "B+", "value" => 0.88 },
                              { "name" => "B", "value" => 0.85 },
                              { "name" => "B-", "value" => 0.8 },
                              { "name" => "C+", "value" => 0.78 },
                              { "name" => "C", "value" => 0.75 },
                              { "name" => "C-", "value" => 0.7 },
                              { "name" => "D+", "value" => 0.68 },
                              { "name" => "D", "value" => 0.65 },
                              { "name" => "D-", "value" => 0.61 },
                              { "name" => "F", "value" => 0.0 }]

        course_level_grading_standard = @course.grading_standards.build(title: "My Course Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(course_scheme_data))
        course_level_grading_standard.save

        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json.length).to eq 2

        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Account Level Grading Standard",
                                            "context_type" => "Account",
                                            "context_id" => @account.id,
                                            "context_name" => "Default Account",
                                            "data" => account_scheme_data,
                                            "permissions" => { "manage" => false },
                                            "assessed_assignment" => false })

        expect(response_json[1]).to eq({ "id" => course_level_grading_standard.id.to_s,
                                         "title" => "My Course Level Grading Standard",
                                         "context_type" => "Course",
                                         "context_id" => @course.id,
                                         "context_name" => "Unnamed Course",
                                         "data" => course_scheme_data,
                                         "permissions" => { "manage" => true },
                                         "assessed_assignment" => false })
      end
    end

    describe "get grading scheme summaries" do
      it "returns course and account level grading scheme summary json" do
        account_scheme_data = [{ "name" => "A", "value" => 0.90 },
                               { "name" => "B", "value" => 0.80 },
                               { "name" => "C", "value" => 0.70 },
                               { "name" => "D", "value" => 0.60 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = @account.grading_standards.build(title: "My Account Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data))
        account_level_grading_standard.save

        course_scheme_data = [{ "name" => "A", "value" => 0.90 },
                              { "name" => "B", "value" => 0.80 },
                              { "name" => "C", "value" => 0.70 },
                              { "name" => "D", "value" => 0.60 },
                              { "name" => "F", "value" => 0.0 }]

        course_level_grading_standard = @course.grading_standards.build(title: "My Course Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(course_scheme_data))
        course_level_grading_standard.save

        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_scheme_summaries", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json.length).to eq 2

        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Account Level Grading Standard" })

        expect(response_json[1]).to eq({ "id" => course_level_grading_standard.id.to_s,
                                         "title" => "My Course Level Grading Standard" })
      end
    end

    describe "create grading scheme" do
      it "creates grading scheme at course level" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        user_session(@teacher)
        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]

        params = { title: "My Scheme Title",
                   data:,
                   scaling_factor: 1.0,
                   points_based: false }

        post "/courses/" + @course.id.to_s + "/grading_schemes",
             params:,
             as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["context_type"]).to eq "Course"
        expect(response_json["context_id"]).to eq @course.id
        expect(response_json["title"]).to eq "My Scheme Title"
        expect(response_json["data"]).to eq data
        expect(response_json["permissions"]).to eq({ "manage" => true })
        expect(response_json["scaling_factor"]).to eq 1.0
        expect(response_json["points_based"]).to be false
      end

      it "creates grading scheme at course level when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        user_session(@teacher)
        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]

        params = { title: "My Scheme Title",
                   data: }

        post "/courses/" + @course.id.to_s + "/grading_schemes",
             params:,
             as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["context_type"]).to eq "Course"
        expect(response_json["context_id"]).to eq @course.id
        expect(response_json["title"]).to eq "My Scheme Title"
        expect(response_json["data"]).to eq data
        expect(response_json["permissions"]).to eq({ "manage" => true })
      end
    end

    describe "get default grading scheme" do
      it "returns default grading scheme json" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes/default", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["title"]).to eq "Default Canvas Grading Scheme"
        expect(response_json["data"]).to eq [{ "name" => "A", "value" => 0.94 },
                                             { "name" => "A-", "value" => 0.9 },
                                             { "name" => "B+", "value" => 0.87 },
                                             { "name" => "B", "value" => 0.84 },
                                             { "name" => "B-", "value" => 0.8 },
                                             { "name" => "C+", "value" => 0.77 },
                                             { "name" => "C", "value" => 0.74 },
                                             { "name" => "C-", "value" => 0.7 },
                                             { "name" => "D+", "value" => 0.67 },
                                             { "name" => "D", "value" => 0.64 },
                                             { "name" => "D-", "value" => 0.61 },
                                             { "name" => "F", "value" => 0.0 }]
        expect(response_json["points_based"]).to be false
        expect(response_json["scaling_factor"]).to eq 1.0
      end

      it "returns default grading scheme json when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes/default", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["title"]).to eq "Default Canvas Grading Scheme"
        expect(response_json["data"]).to eq [{ "name" => "A", "value" => 0.94 },
                                             { "name" => "A-", "value" => 0.9 },
                                             { "name" => "B+", "value" => 0.87 },
                                             { "name" => "B", "value" => 0.84 },
                                             { "name" => "B-", "value" => 0.8 },
                                             { "name" => "C+", "value" => 0.77 },
                                             { "name" => "C", "value" => 0.74 },
                                             { "name" => "C-", "value" => 0.7 },
                                             { "name" => "D+", "value" => 0.67 },
                                             { "name" => "D", "value" => 0.64 },
                                             { "name" => "D-", "value" => 0.61 },
                                             { "name" => "F", "value" => 0.0 }]
      end
    end

    describe "delete grading scheme" do
      it "deletes grading scheme at account level" do
        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]

        course_level_grading_standard = @course.grading_standards.build(title: "My Grading Scheme to Delete", data: GradingSchemesJsonController.to_grading_standard_data(data))
        course_level_grading_standard.save

        expect(GradingStandard.all.count).to be 1
        user_session(@teacher)
        delete "/courses/" + @course.id.to_s + "/grading_schemes/" + course_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        # it's a soft delete
        expect(GradingStandard.all.count).to be 1
        expect(GradingStandard.first.title).to eq "My Grading Scheme to Delete"
        expect(GradingStandard.first.workflow_state).to eq "deleted"
        expect(response_json).to eq({})
      end
    end

    describe "update grading scheme" do
      it "returns success when putting course level grading scheme" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        grading_standard = @course.grading_standards.build(title: "My Grading Scheme",
                                                           data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                           scaling_factor: 1.0,
                                                           points_based: false)
        grading_standard.save

        user_session(@teacher)

        updated_data = [{ "name" => "A", "value" => 0.90 },
                        { "name" => "B", "value" => 0.80 },
                        { "name" => "C", "value" => 0.70 },
                        { "name" => "D", "value" => 0.60 },
                        { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data: updated_data,
                   scaling_factor: 1.0,
                   points_based: false }

        put "/courses/" + @course.id.to_s + "/grading_schemes/" + grading_standard.id.to_s,
            params:,
            as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => grading_standard.id.to_s,
                                      "title" => "My Scheme Title",
                                      "context_type" => "Course",
                                      "context_id" => @course.id,
                                      "context_name" => "Unnamed Course",
                                      "data" => updated_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => false,
                                      "scaling_factor" => 1.0 })
      end

      it "returns success when putting course level grading scheme when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        grading_standard = @course.grading_standards.build(title: "My Grading Scheme", data: GradingSchemesJsonController.to_grading_standard_data(data))
        grading_standard.save

        user_session(@teacher)

        updated_data = [{ "name" => "A", "value" => 0.90 },
                        { "name" => "B", "value" => 0.80 },
                        { "name" => "C", "value" => 0.70 },
                        { "name" => "D", "value" => 0.60 },
                        { "name" => "F", "value" => 0.0 }]
        params = { title: "My Scheme Title",
                   data: updated_data }

        put "/courses/" + @course.id.to_s + "/grading_schemes/" + grading_standard.id.to_s,
            params:,
            as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => grading_standard.id.to_s,
                                      "title" => "My Scheme Title",
                                      "context_type" => "Course",
                                      "context_id" => @course.id,
                                      "context_name" => "Unnamed Course",
                                      "data" => updated_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false })
      end
    end

    describe "get grading scheme" do
      it "returns course level grading scheme json" do
        Account.site_admin.enable_feature!(:points_based_grading_schemes)
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        course_level_grading_standard = @course.grading_standards.build(title: "My Grading Scheme",
                                                                        data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                                        points_based: false,
                                                                        scaling_factor: 1.0)
        course_level_grading_standard.save

        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes/" + course_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => course_level_grading_standard.id.to_s,
                                      "title" => "My Grading Scheme",
                                      "context_type" => "Course",
                                      "context_id" => @course.id,
                                      "context_name" => "Unnamed Course",
                                      "data" => data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => false,
                                      "scaling_factor" => 1.0 })
      end

      it "returns course level grading scheme json when points_based_grading_schemes ff is off" do
        # TODO: remove this test case once points_based_grading_schemes ff is globally turned on
        data = [{ "name" => "A", "value" => 0.92 },
                { "name" => "A-", "value" => 0.9 },
                { "name" => "B+", "value" => 0.87 },
                { "name" => "B", "value" => 0.82 },
                { "name" => "B-", "value" => 0.8 },
                { "name" => "C+", "value" => 0.77 },
                { "name" => "C", "value" => 0.72 },
                { "name" => "C-", "value" => 0.7 },
                { "name" => "D+", "value" => 0.67 },
                { "name" => "D", "value" => 0.62 },
                { "name" => "D-", "value" => 0.61 },
                { "name" => "F", "value" => 0.0 }]
        course_level_grading_standard = @course.grading_standards.build(title: "My Grading Scheme", data: GradingSchemesJsonController.to_grading_standard_data(data))
        course_level_grading_standard.save

        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes/" + course_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => course_level_grading_standard.id.to_s,
                                      "title" => "My Grading Scheme",
                                      "context_type" => "Course",
                                      "context_id" => @course.id,
                                      "context_name" => "Unnamed Course",
                                      "data" => data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false })
      end
    end
  end
end
