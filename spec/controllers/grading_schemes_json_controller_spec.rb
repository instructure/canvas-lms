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

  before(:once) do
    Account.site_admin.disable_feature!(:archived_grading_schemes)
  end

  let(:test_data) do
    [{ "name" => "A", "value" => 0.92 },
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
  end

  context "account admin" do
    before(:once) do
      @account = Account.default
      @admin = account_admin_user(account: @account)
    end

    describe "POST 'archive'" do
      before(:once) do
        @data = GradingSchemesJsonController.to_grading_standard_data(test_data)
      end

      it "archive grading standard" do
        account_level_grading_standard = @account.grading_standards.create!(title: "My Grading Scheme",
                                                                            scaling_factor: 1.0,
                                                                            data: @data,
                                                                            points_based: false,
                                                                            workflow_state: "active")
        user_session(@admin)
        post "/accounts/#{@account.id}/grading_schemes/#{account_level_grading_standard.id}/archive", as: :json
        expect(response).to have_http_status(:ok)
        account_level_grading_standard.reload
        expect(account_level_grading_standard.workflow_state).to eq("archived")
      end

      it "does not archive deleted grading standard" do
        account_level_grading_standard = @account.grading_standards.create!(title: "My Grading Scheme",
                                                                            scaling_factor: 1.0,
                                                                            data: @data,
                                                                            points_based: false,
                                                                            workflow_state: "deleted")
        user_session(@admin)
        post "/accounts/#{@account.id}/grading_schemes/#{account_level_grading_standard.id}/archive", as: :json
        expect(response).to have_http_status(:not_found)
        account_level_grading_standard.reload
        expect(account_level_grading_standard.workflow_state).to eq("deleted")
      end
    end

    describe "POST 'unarchive'" do
      before(:once) do
        @data = GradingSchemesJsonController.to_grading_standard_data(test_data)
      end

      it "archive grading standard" do
        account_level_grading_standard = @account.grading_standards.create!(title: "My Grading Scheme",
                                                                            scaling_factor: 1.0,
                                                                            data: @data,
                                                                            points_based: false,
                                                                            workflow_state: "archived")
        user_session(@admin)
        post "/accounts/#{@account.id}/grading_schemes/#{account_level_grading_standard.id}/unarchive", as: :json
        expect(response).to have_http_status(:ok)
        account_level_grading_standard.reload
        expect(account_level_grading_standard.workflow_state).to eq("active")
      end

      it "does not unarchive active grading standard" do
        account_level_grading_standard = @account.grading_standards.create!(title: "My Grading Scheme",
                                                                            scaling_factor: 1.0,
                                                                            data: @data,
                                                                            points_based: false,
                                                                            workflow_state: "active")
        user_session(@admin)
        post "/accounts/#{@account.id}/grading_schemes/#{account_level_grading_standard.id}/unarchive", as: :json
        expect(response).to have_http_status(:not_found)
        account_level_grading_standard.reload
        expect(account_level_grading_standard.workflow_state).to eq("active")
      end
    end

    describe "get grading schemes with archived feature" do
      before(:once) do
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        @root_account = Account.default
        course_with_teacher(active_all: true, account: @root_account)
      end

      it "doesn't return unrelated archived schemes" do
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          scaling_factor: 1.0,
                                                                          points_based: false,
                                                                          workflow_state: "archived")
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first).to be_nil
      end

      it "returns related archived schemes" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data:,
                                                                          scaling_factor: 1.0,
                                                                          workflow_state: "archived",
                                                                          points_based: false)
        account_level_grading_standard.save
        @account.update(grading_standard: account_level_grading_standard)
        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first["title"]).to eq("My Grading Scheme")
      end

      it "returns archived schemes if the parameter is included" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        course_level_grading_standard = @course.grading_standards.build(title: "My Grading Scheme",
                                                                        data:,
                                                                        scaling_factor: 1.0,
                                                                        points_based: false,
                                                                        workflow_state: "archived")
        course_level_grading_standard.save
        user_session(@admin)
        get "/courses/#{@course.id}/grading_schemes?include_archived=true", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first["title"]).to eq("My Grading Scheme")
      end

      it "does not return archived schemes if the parameter is not included" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        course_level_grading_standard = @course.grading_standards.build(title: "My Grading Scheme",
                                                                        data:,
                                                                        scaling_factor: 1.0,
                                                                        points_based: false,
                                                                        workflow_state: "archived")
        course_level_grading_standard.save
        user_session(@admin)
        get "/courses/#{course_level_grading_standard.context_id}/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first).to be_nil
      end
    end

    describe "get grouped schemes list by workflow_state" do
      before(:once) do
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        @data = GradingSchemesJsonController.to_grading_standard_data(test_data)
      end

      it "returns schemes by workflow_state" do
        @account.grading_standards.create!(title: "My Archived Scheme",
                                           scaling_factor: 1.0,
                                           data: @data,
                                           points_based: false,
                                           workflow_state: "archived")
        @account.grading_standards.create!(title: "My Active Scheme",
                                           scaling_factor: 1.0,
                                           data: @data,
                                           points_based: false,
                                           workflow_state: "active")

        user_session(@admin)
        get "/accounts/#{@account.id}/grading_scheme_grouped", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json["archived"][0]["title"]).to eq("My Archived Scheme")
        expect(response_json["active"][0]["title"]).to eq("My Active Scheme")
      end
    end

    describe "get grading schemes" do
      it "returns account level grading schemes json" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data:,
                                                                          scaling_factor: 1.0,
                                                                          points_based: false)
        account_level_grading_standard.save

        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first).to eq({ "id" => account_level_grading_standard.id.to_s,
                                            "title" => "My Grading Scheme",
                                            "context_type" => "Account",
                                            "context_id" => @account.id,
                                            "context_name" => "Default Account",
                                            "data" => test_data,
                                            "permissions" => { "manage" => true },
                                            "assessed_assignment" => false,
                                            "points_based" => false,
                                            "scaling_factor" => 1.0,
                                            "used_as_default" => false,
                                            "workflow_state" => "active" })
      end

      it "doesn't return parent account grading schemes" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data:,
                                                                          scaling_factor: 1.0,
                                                                          points_based: false)
        account_level_grading_standard.save

        sub_account = Account.create(parent_account: @account, name: "Test subaccount")
        sub_admin = account_admin_user(account: sub_account)

        Account.site_admin.enable_feature!(:archived_grading_schemes)

        user_session(sub_admin)

        get "/accounts/#{sub_account.id}/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        expect(response_json.first).to be_nil
      end
    end

    describe "get grading scheme" do
      it "returns account level grading scheme json" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data:,
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
                                      "data" => test_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => false,
                                      "scaling_factor" => 1.0,
                                      "used_as_default" => false,
                                      "workflow_state" => "active" })
      end
    end

    describe "get account default grading scheme" do
      it "returns the account default grading scheme json if one exists" do
        Account.site_admin.enable_feature! :default_account_grading_scheme
        account_scheme_data = [{ "name" => "A", "value" => 0.90 },
                               { "name" => "B", "value" => 0.80 },
                               { "name" => "C", "value" => 0.70 },
                               { "name" => "D", "value" => 0.60 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = GradingStandard.new(context: @account, workflow_state: "active", title: "My Account Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data))
        @account.grading_standard = account_level_grading_standard
        account_level_grading_standard.save
        @account.save

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes/account_default", as: :json

        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["id"]).to eq account_level_grading_standard.id.to_s
        expect(response_json["title"]).to eq account_level_grading_standard.title.to_s
      end

      it "does not return the account default grading scheme json if one does not exist" do
        Account.site_admin.enable_feature! :default_account_grading_scheme

        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/grading_schemes/account_default", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json).to be_nil
      end
    end

    describe "put account default grading scheme" do
      it "updates the account default grading scheme" do
        Account.site_admin.enable_feature! :default_account_grading_scheme
        account_scheme_data = [{ "name" => "A", "value" => 0.90 },
                               { "name" => "B", "value" => 0.80 },
                               { "name" => "C", "value" => 0.70 },
                               { "name" => "D", "value" => 0.60 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = GradingStandard.new(context: @account, workflow_state: "active", title: "My Account Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data))
        account_level_grading_standard.save
        params = {
          id: account_level_grading_standard.id.to_s,
        }

        user_session(@admin)
        put "/accounts/" + @account.id.to_s + "/grading_schemes/account_default",
            params:,
            as: :json

        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json["id"]).to eq account_level_grading_standard.id.to_s
        @account.reload
        expect(@account.grading_standard.id).to eq account_level_grading_standard.id
      end

      it "removes the account default grading scheme if nil is sent as the ID" do
        Account.site_admin.enable_feature! :default_account_grading_scheme
        account_scheme_data = [{ "name" => "A", "value" => 0.90 },
                               { "name" => "B", "value" => 0.80 },
                               { "name" => "C", "value" => 0.70 },
                               { "name" => "D", "value" => 0.60 },
                               { "name" => "F", "value" => 0.0 }]
        account_level_grading_standard = GradingStandard.new(context: @account, workflow_state: "active", title: "My Account Level Grading Standard", data: GradingSchemesJsonController.to_grading_standard_data(account_scheme_data))
        @account.grading_standard = account_level_grading_standard
        account_level_grading_standard.save
        @account.save
        params = {
          id: nil,
        }

        user_session(@admin)
        put "/accounts/" + @account.id.to_s + "/grading_schemes/account_default",
            params:,
            as: :json

        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body
        expect(response_json).to be_nil
        @account.reload
        expect(@account.grading_standard).to be_nil
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
                                            "title" => "My Account Level Grading Standard",
                                            "context_type" => account_level_grading_standard.context_type.to_s })
      end
    end

    describe "get default grading scheme" do
      it "returns default grading scheme json" do
        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes/default", as: :json
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
    end

    describe "create grading scheme" do
      it "creates non points based grading scheme at account level" do
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

        post "/accounts/#{@account.id}/grading_schemes",
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

        post "/accounts/#{@account.id}/grading_schemes",
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

        expect(GradingStandard.count).to be 1
        user_session(@admin)
        delete "/accounts/" + @account.id.to_s + "/grading_schemes/" + account_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        # it's a soft delete
        expect(GradingStandard.count).to be 1
        expect(GradingStandard.first.title).to eq "My Grading Scheme to Delete"
        expect(GradingStandard.first.workflow_state).to eq "deleted"
        expect(response_json).to eq({})
      end
    end

    describe "update grading scheme" do
      it "returns success when putting account level grading scheme" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data:,
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
                                      "scaling_factor" => 1.0,
                                      "used_as_default" => false,
                                      "workflow_state" => "active" })
      end

      it "returns success when putting account level grading scheme that is points based" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        account_level_grading_standard = @account.grading_standards.build(title: "My Grading Scheme",
                                                                          data:,
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
                                      "scaling_factor" => 5.0,
                                      "used_as_default" => false,
                                      "workflow_state" => "active" })
      end
    end

    describe "#update_account_default_grading_scheme" do
      let_once(:data1) { [["A", 0.94], ["F", 0]] }
      let_once(:data2) { [["A", 0.5], ["F", 0]] }

      before do
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        Account.site_admin.enable_feature!(:default_account_grading_scheme)
        @root_account = Account.default
        sub_account = @root_account.sub_accounts.create!
        sub_sub_account = sub_account.sub_accounts.create!
        admin = account_admin_user(account: @root_account)
        user_session(admin)
        grading_standard = GradingStandard.create!(context: @root_account, workflow_state: "active", data: data1, title: "current grading scheme")
        @new_grading_standard = GradingStandard.create!(context: @root_account, workflow_state: "active", data: data2, title: "new grading scheme")
        @root_account.update!(grading_standard_id: grading_standard.id)
        course_inheriting_from_root = course_factory(account: @root_account)
        course_not_inheriting_from_root = course_factory(account: @root_account)
        course_not_inheriting_from_root.update!(grading_standard_id: grading_standard.id)
        course_inheriting_from_sub = course_factory(account: sub_account)
        course_inheriting_from_sub_sub = course_factory(account: sub_sub_account)
        student1 = course_inheriting_from_root.enroll_user(user_factory(active_user: true), "StudentEnrollment", enrollment_state: "active").user
        student2 = course_not_inheriting_from_root.enroll_user(user_factory(active_user: true), "StudentEnrollment", enrollment_state: "active").user
        student3 = course_inheriting_from_sub.enroll_user(user_factory(active_user: true), "StudentEnrollment", enrollment_state: "active").user
        student4 = course_inheriting_from_sub_sub.enroll_user(user_factory(active_user: true), "StudentEnrollment", enrollment_state: "active").user
        assignment_root = course_inheriting_from_root.assignments.create!(title: "hi", grading_standard_id: nil, points_possible: 10, grading_type: "letter_grade")
        assignment_not_inheriting = course_not_inheriting_from_root.assignments.create!(title: "hello", grading_standard_id: nil, points_possible: 10, grading_type: "letter_grade")
        assignment_sub = course_inheriting_from_sub.assignments.create!(title: "hi2", grading_standard_id: nil, points_possible: 10, grading_type: "letter_grade")
        assignment_sub_sub = course_inheriting_from_sub_sub.assignments.create!(title: "hi3", grading_standard_id: nil, points_possible: 10, grading_type: "letter_grade")
        @submission_root = assignment_root.grade_student(student1, score: 7, grader: admin).first
        @submission_not_inheriting = assignment_not_inheriting.grade_student(student2, score: 7, grader: admin).first
        @submission_sub = assignment_sub.grade_student(student3, score: 7, grader: admin).first
        @submission_sub_sub = assignment_sub_sub.grade_student(student4, score: 7, grader: admin).first
      end

      it "updates submission grades in account inheriting courses/assignments and all sub account courses/assignments" do
        put "/accounts/#{@root_account.id}/grading_schemes/account_default",
            params: { id: @new_grading_standard.id.to_s },
            as: :json

        expect(response).to have_http_status(:ok)
        expect(@submission_root.reload.grade).to eq "A"
        expect(@submission_not_inheriting.reload.grade).to eq "F"
        expect(@submission_sub.reload.grade).to eq "A"
        expect(@submission_sub_sub.reload.grade).to eq "A"
      end

      it "updates submission grades in account inheriting courses/assignments and all sub account courses/assignments when default is set to canvas default (null)" do
        put "/accounts/#{@root_account.id}/grading_schemes/account_default",
            params: { id: nil },
            as: :json

        expect(response).to have_http_status(:ok)
        expect(@submission_root.reload.grade).to eq "C-"
        expect(@submission_not_inheriting.reload.grade).to eq "F"
        expect(@submission_sub.reload.grade).to eq "C-"
        expect(@submission_sub_sub.reload.grade).to eq "C-"
      end

      it "updates the most recent submission version in all inheriting account and sub account courses" do
        put "/accounts/#{@root_account.id}/grading_schemes/account_default",
            params: { id: @new_grading_standard.id.to_s },
            as: :json

        expect(@submission_root.reload.versions.first.model.grade).to eq "A"
        expect(@submission_not_inheriting.reload.versions.first.model.grade).to eq "F"
        expect(@submission_sub.reload.versions.first.model.grade).to eq "A"
        expect(@submission_sub_sub.reload.versions.first.model.grade).to eq "A"
      end
    end

    describe "#used_locations" do
      let_once(:data) { [["A", 94], ["F", 0]] }

      before(:once) do
        @root_account = Account.default
        course_with_teacher(active_all: true, account: @root_account)
        @admin = account_admin_user(account: @root_account)
        @student = user_factory(active_user: true)
        course_with_teacher(account: @root_account)
        @enrollment.update(workflow_state: "active")
        @grading_standard = GradingStandard.create(context: @root_account, workflow_state: "active", data:)
        @root_account.update(grading_standard_id: @grading_standard.id)
        @course.update(grading_standard_id: @grading_standard.id)
        3.times do
          assignment = @course.assignments.create!(title: "hi", grading_standard_id: @grading_standard.id)
          assignment.submissions.create!(user: @student, workflow_state: "graded")
        end
      end

      it "returns courses and assignments where the grading standard is used" do
        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes/#{@grading_standard.id}/used_locations", as: :json
        locations = response.parsed_body

        expect(locations.size).to eq(1)
        expect(locations.first["id"]).to eq(@course.id)
        expect(locations.first["assignments"].size).to eq(0)

        get "/accounts/#{@account.id}/grading_schemes/#{@grading_standard.id}/used_locations/#{@course.id}", as: :json
        assignment_locations = response.parsed_body

        expect(assignment_locations.size).to eq(3)
      end

      it "does not return courses without graded assignments" do
        another_course = course_factory
        another_course.assignments.create!(title: "hi")
        @course.assignments.create!(title: "hi")

        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes/#{@grading_standard.id}/used_locations", as: :json
        locations = response.parsed_body

        course_ids = locations.pluck("id")
        expect(course_ids).not_to include(another_course.id)
      end

      it "returns courses without grading standard but with assignment related" do
        another_course = course_factory
        another_course.assignments.create!(title: "hi")
        assignment = @course.assignments.create!(title: "hi", grading_standard_id: @grading_standard.id)
        assignment.submissions.create!(user: @student, workflow_state: "graded")

        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes/#{@grading_standard.id}/used_locations", as: :json
        locations = response.parsed_body

        course_ids = locations.pluck("id")
        expect(course_ids).to include(another_course.id)
      end

      it "ignore course if is deleted" do
        @course.destroy!
        user_session(@admin)
        get "/accounts/#{@account.id}/grading_schemes/#{@grading_standard.id}/used_locations", as: :json
        locations = response.parsed_body

        expect(locations.size).to eq(0)
      end
    end
  end

  describe "#account_used_locations" do
    let_once(:data) { [["A", 94], ["F", 0]] }

    before(:once) do
      @root_account = Account.default
      @grading_standard = GradingStandard.create(context: @root_account, workflow_state: "active", data:)
      @root_account.update(grading_standard_id: @grading_standard.id)
      @sub_account = @root_account.sub_accounts.create!
      @admin = account_admin_user(account: @root_account)
    end

    it "returns root account where the grading standard is related" do
      user_session(@admin)
      get "/accounts/#{@root_account.id}/grading_schemes/#{@grading_standard.id}/account_used_locations", as: :json
      locations = response.parsed_body

      expect(locations.size).to eq(1)
      expect(locations[0]["id"]).to eq(@root_account.id)
    end
  end

  context "course teacher" do
    before(:once) do
      @account = Account.default
      course_with_teacher(active_all: true)
    end

    describe "get grading schemes" do
      before(:once) do
        @course_scheme_data = test_data
        @course_level_grading_standard = @course.grading_standards.create!(
          title: "My Course Level Grading Standard",
          data: GradingSchemesJsonController.to_grading_standard_data(@course_scheme_data),
          points_based: false,
          scaling_factor: 1.0
        )
      end

      it "doesn't return unrelated archived schemes" do
        @course_level_grading_standard.update(workflow_state: "archived")
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json.first).to be_nil
      end

      it "returns related archived schemes" do
        @student = user_factory(active_user: true)
        assignment = @course.assignments.create!(title: "manual", grading_type: "letter_grade")
        assignment.submissions.create!(user: @student, workflow_state: "graded")
        @course_level_grading_standard.update(workflow_state: "archived")
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        user_session(@teacher)
        @course.update(grading_standard: @course_level_grading_standard)
        get "/courses/" + @course.id.to_s + "/grading_schemes", as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        expect(response_json.first["title"]).to eq("My Course Level Grading Standard")
        expect(response_json.first["workflow_state"]).to eq("archived")
      end

      it "returns the appropriate permissions for a teacher without 'Grades — Edit' access" do
        @account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: false)
        user_session(@teacher)
        get "/courses/#{@course.id}/grading_schemes", as: :json
        expect(response.parsed_body.dig(0, "permissions")).to eq({ "manage" => false })
      end

      it "returns course and account level grading schemes json" do
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
                                            "scaling_factor" => 1.0,
                                            "used_as_default" => false,
                                            "workflow_state" => "active" })

        expect(response_json[1]).to eq({ "id" => @course_level_grading_standard.id.to_s,
                                         "title" => "My Course Level Grading Standard",
                                         "context_type" => "Course",
                                         "context_id" => @course.id,
                                         "context_name" => "Unnamed Course",
                                         "data" => @course_scheme_data,
                                         "permissions" => { "manage" => true },
                                         "assessed_assignment" => false,
                                         "points_based" => false,
                                         "scaling_factor" => 1.0,
                                         "used_as_default" => false,
                                         "workflow_state" => "active" })
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
                                            "title" => "My Account Level Grading Standard",
                                            "context_type" => "Account" })

        expect(response_json[1]).to eq({ "id" => course_level_grading_standard.id.to_s,
                                         "title" => "My Course Level Grading Standard",
                                         "context_type" => "Course" })
      end
    end

    describe "create grading scheme" do
      it "creates grading scheme at course level" do
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
    end

    describe "get default grading scheme" do
      it "returns default grading scheme json" do
        user_session(@teacher)
        get "/courses/#{@course.id}/grading_schemes/default", as: :json
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

        expect(GradingStandard.count).to be 1
        user_session(@teacher)
        delete "/courses/" + @course.id.to_s + "/grading_schemes/" + course_level_grading_standard.id.to_s, as: :json
        expect(response).to have_http_status(:ok)
        response_json = response.parsed_body

        # it's a soft delete
        expect(GradingStandard.count).to be 1
        expect(GradingStandard.first.title).to eq "My Grading Scheme to Delete"
        expect(GradingStandard.first.workflow_state).to eq "deleted"
        expect(response_json).to eq({})
      end
    end

    describe "update grading scheme" do
      it "returns success when putting course level grading scheme" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        grading_standard = @course.grading_standards.build(title: "My Grading Scheme",
                                                           data:,
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
                                      "scaling_factor" => 1.0,
                                      "used_as_default" => false,
                                      "workflow_state" => "active" })
      end
    end

    describe "get grading scheme" do
      it "returns course level grading scheme json" do
        data = GradingSchemesJsonController.to_grading_standard_data(test_data)
        course_level_grading_standard = @course.grading_standards.build(title: "My Grading Scheme",
                                                                        data:,
                                                                        points_based: false,
                                                                        scaling_factor: 1.0)
        course_level_grading_standard.save

        user_session(@teacher)
        get "/courses/#{@course.id}/grading_schemes/#{course_level_grading_standard.id}", as: :json
        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body

        expect(response_json).to eq({ "id" => course_level_grading_standard.id.to_s,
                                      "title" => "My Grading Scheme",
                                      "context_type" => "Course",
                                      "context_id" => @course.id,
                                      "context_name" => "Unnamed Course",
                                      "data" => test_data,
                                      "permissions" => { "manage" => true },
                                      "assessed_assignment" => false,
                                      "points_based" => false,
                                      "scaling_factor" => 1.0,
                                      "used_as_default" => false,
                                      "workflow_state" => "active" })
      end
    end
  end
end
