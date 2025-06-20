# frozen_string_literal: true

#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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

describe "Account Reports API", type: :request do
  before :once do
    @admin = account_admin_user
    user_with_pseudonym(user: @admin)
    @report = AccountReport.new
    @report.account = @admin.account
    @report.user = @admin
    @report.progress = rand(100)
    @report.start_at = Time.zone.now
    @report.end_at = Time.zone.now + rand(60 * 60 * 4)
    @report.report_type = "student_assignment_outcome_map_csv"
    @report.parameters = ActiveSupport::HashWithIndifferentAccess["param" => "test", "error" => "failed"]

    folder = Folder.assert_path("test", @admin.account)
    @report.attachment = Attachment.create!(folder:, context: @admin.account, filename: "test.txt", uploaded_data: StringIO.new("test file"))

    @report.save!
  end

  describe "available_reports" do
    it "lists all available reports" do
      json = api_call(:get,
                      "/api/v1/accounts/#{@admin.account.id}/reports",
                      { controller: "account_reports", action: "available_reports", format: "json", account_id: @admin.account.id.to_s })
      json.each do |report|
        expect(report).to have_key("title")
        expect(report).to have_key("parameters")
        expect(report).to have_key("report")

        report[:parameters]&.each_value do |parameter|
          expect(parameter).to have_key("required")
          expect(parameter).to have_key("description")
        end
      end

      report_csv = json.find { |r| r["report"] == @report.report_type }
      expect(report_csv["last_run"]["id"]).to eq @report.id
      expect(report_csv["last_run"]["status"]).to eq @report.workflow_state
      expect(report_csv["last_run"]["progress"]).to eq @report.progress
    end

    it "includes HTML descriptions and forms if requested" do
      json = api_call(:get,
                      "/api/v1/accounts/#{@admin.account.id}/reports?include[]=description_html&include[]=parameters_html",
                      { controller: "account_reports",
                        action: "available_reports",
                        format: "json",
                        account_id: @admin.account.id.to_s,
                        include: ["description_html", "parameters_html"] })

      report_with_description = json.find { |r| r["description_html"].present? }
      expect(report_with_description["description_html"]).to include("<p>")

      report_with_parameters = json.find { |r| r["parameters_html"].present? }
      expect(report_with_parameters["parameters_html"]).to include("<form")
    end
  end

  describe "create" do
    it "creates a student report" do
      report = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                        { report: @report.report_type,
                          controller: "account_reports",
                          action: "create",
                          format: "json",
                          account_id: @admin.account.id.to_s })
      keys = %w[id progress parameters current_line status report created_at started_at ended_at file_url]
      expect(report["status"]).to eq "created"
      expect(keys - report.keys).to be_empty
    end

    it "works with parameters" do
      @admin.account.enrollment_terms.create! sis_source_id: "a_term"
      report = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                        { report: @report.report_type,
                          controller: "account_reports",
                          action: "create",
                          format: "json",
                          account_id: @admin.account.id.to_s,
                          parameters: { "enrollment_term_id" => "sis_term_id:a_term" } })
      expect(report).to have_key("id")
    end

    it "404s for non existing reports" do
      raw_api_call(:post,
                   "/api/v1/accounts/#{@admin.account.id}/reports/bad_report_csv",
                   { report: "bad_report_csv", controller: "account_reports", action: "create", format: "json", account_id: @admin.account.id.to_s })
      assert_status(404)
    end

    it "400s for invalid enrollment_term_id" do
      raw_api_call(:post,
                   "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                   { report: @report.report_type,
                     controller: "account_reports",
                     action: "create",
                     format: "json",
                     account_id: @admin.account.id.to_s,
                     parameters: { "enrollment_term_id" => "sis_term_id:invalid" } })
      assert_status(400)
    end

    it "accepts a numeric enrollment term id in the request body" do
      term_id = Account.default.enrollment_terms.pick(:id)
      report = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                        { controller: "account_reports",
                          action: "create",
                          format: "json",
                          account_id: @admin.account.id.to_s,
                          report: @report.report_type },
                        { parameters: { "enrollment_term_id" => term_id } },
                        {},
                        as: :json)
      expect(report["parameters"]).to eq({ "enrollment_term_id" => term_id })
    end

    it "accepts comma-separated enrollment_term_id param" do
      Account.default.enrollment_terms.create!
      report = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                        { report: @report.report_type,
                          controller: "account_reports",
                          action: "create",
                          format: "json",
                          account_id: @admin.account.id.to_s,
                          parameters: { "enrollment_term_id" => Account.default.enrollment_terms.pluck(:id).join(",") } })
      expect(report).to have_key("id")
    end

    it "ignores empty enrollment_term_id param" do
      report = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                        { report: @report.report_type,
                          controller: "account_reports",
                          action: "create",
                          format: "json",
                          account_id: @admin.account.id.to_s,
                          parameters: { "enrollment_term_id" => "" } })
      expect(report).to have_key("id")
    end
  end

  describe "index" do
    it "lists all generated reports" do
      json = api_call(:get,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                      { report: @report.report_type, controller: "account_reports", action: "index", format: "json", account_id: @admin.account.id.to_s })

      expect(json.length).to be >= 0
      expect(json.length).to be <= 50
      json.each do |report|
        expect(report).to have_key("id")
        expect(report).to have_key("status")
        expect(report).to have_key("progress")
        expect(report).to have_key("file_url")
      end
    end

    it "paginates reports" do
      report2 = AccountReport.new
      report2.account = @admin.account
      report2.user = @admin
      report2.progress = rand(100)
      report2.report_type = "student_assignment_outcome_map_csv"
      report2.parameters = ActiveSupport::HashWithIndifferentAccess["param" => "test", "error" => "failed"]

      folder = Folder.assert_path("test", @admin.account)
      report2.attachment = Attachment.create!(folder:,
                                              context: @admin.account,
                                              filename: "test.txt",
                                              uploaded_data: StringIO.new("test file"))
      report2.save!

      json = api_call(:get,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}?per_page=1&page=1",
                      { report: @report.report_type,
                        controller: "account_reports",
                        action: "index",
                        format: "json",
                        account_id: @admin.account.id.to_s,
                        per_page: 1,
                        page: 1 })
      expect(json.length).to eq 1
      json = api_call(:get,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}?per_page=1&page=2",
                      { report: @report.report_type,
                        controller: "account_reports",
                        action: "index",
                        format: "json",
                        account_id: @admin.account.id.to_s,
                        per_page: 1,
                        page: 2 })
      expect(json.length).to eq 1
    end
  end

  describe "show" do
    it "gets all info about a report" do
      json = api_call(:get,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}/#{@report.id}",
                      { report: @report.report_type, controller: "account_reports", action: "show", format: "json", account_id: @admin.account.id.to_s, id: @report.id.to_s })

      expect(json["id"]).to eq @report.id
      expect(json["status"]).to eq @report.workflow_state
      expect(json["progress"]).to eq @report.progress
      expect(json["file_url"]).to eq "http://www.example.com/accounts/#{@admin.account.id}/files/#{@report.attachment_id}/download"
      expect(json["start_at"]).to be_nil
      # test that attachment object is here, no need to test attachment json
      expect(json["attachment"]["id"]).to eq @report.attachment_id
      @report.parameters.each do |key, value|
        expect(json["parameters"][key]).to eq value
      end
    end
  end

  describe "destroy" do
    it "delete a report" do
      json = api_call(:delete,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}/#{@report.id}",
                      { report: @report.report_type, controller: "account_reports", action: "destroy", format: "json", account_id: @admin.account.id.to_s, id: @report.id.to_s })

      expect(json["id"]).to eq @report.id
      expect(json["status"]).to eq @report.reload.workflow_state
      expect(json["progress"]).to eq @report.progress
      expect(json["file_url"]).to eq "http://www.example.com/accounts/#{@admin.account.id}/files/#{@report.attachment.id}/download"
      @report.parameters.each do |key, value|
        expect(json["parameters"][key]).to eq value
      end
      expect(AccountReport.active.exists?(@report.id)).not_to be_truthy
    end
  end

  describe "abort" do
    it "aborts a running report" do
      @report.update!(workflow_state: "running")

      json = api_call(:put,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}/#{@report.id}/abort",
                      { report: @report.report_type, controller: "account_reports", action: "abort", format: "json", account_id: @admin.account.id.to_s, id: @report.id.to_s })

      expect(json["id"]).to eq @report.id
      expect(json["status"]).to eq "aborted"
      expect(AccountReport.running.exists?(@report.id)).to be_falsey
    end

    it "returns error on a report not started" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}/#{@report.id}/abort",
                      { report: @report.report_type, controller: "account_reports", action: "abort", format: "json", account_id: @admin.account.id.to_s, id: @report.id.to_s })

      expect(json["id"]).to be_nil
      expect(json["errors"]).to eq([{ "message" => "The specified resource does not exist." }])
      expect(AccountReport.find(@report.id).workflow_state).to eq("created")
    end
  end
end
