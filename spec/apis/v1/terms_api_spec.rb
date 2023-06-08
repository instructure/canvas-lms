# frozen_string_literal: true

#
# Copyright (C) 2014 Instructure, Inc.
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

describe TermsApiController, type: :request do
  describe "index" do
    before :once do
      @account = Account.create(name: "new")
      account_admin_user(account: @account)
      @account.enrollment_terms.scope.delete_all
      @term1 = @account.enrollment_terms.create(name: "Term 1")
      @term2 = @account.enrollment_terms.create(name: "Term 2")
    end

    def get_terms(body_params = {})
      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/terms",
                      { controller: "terms_api", action: "index", format: "json", account_id: @account.to_param },
                      body_params)
      json["enrollment_terms"]
    end

    it "shows sis_batch_id" do
      @term2.destroy
      sis_batch = @term1.root_account.sis_batches.create
      @term1.sis_batch_id = sis_batch.id
      @term1.save!
      json = get_terms
      expect(json.first["sis_import_id"]).to eq sis_batch.id
    end

    describe "filtering by state" do
      before :once do
        @term2.destroy
      end

      it "lists all active terms by default" do
        json = get_terms
        names = json.pluck("name")
        expect(names).to include(@term1.name)
        expect(names).not_to include(@term2.name)
      end

      it "lists active terms with state=active" do
        json = get_terms(workflow_state: "active")
        names = json.pluck("name")
        expect(names).to include(@term1.name)
        expect(names).not_to include(@term2.name)
      end

      it "lists deleted terms with state=deleted" do
        json = get_terms(workflow_state: "deleted")
        names = json.pluck("name")
        expect(names).not_to include(@term1.name)
        expect(names).to include(@term2.name)
      end

      it "lists all terms, active and deleted, with state=all" do
        json = get_terms(workflow_state: "all")
        names = json.pluck("name")
        expect(names).to include(@term1.name)
        expect(names).to include(@term2.name)
      end

      it "does not blow up for invalid state parameters" do
        json = get_terms(workflow_state: ["blall"])
        names = json.pluck("name")
        expect(names).to include(@term1.name)
        expect(names).not_to include(@term2.name)
      end

      it "lists all terms, active and deleted, with state=[all]" do
        json = get_terms(workflow_state: ["all"])
        names = json.pluck("name")
        expect(names).to include(@term1.name)
        expect(names).to include(@term2.name)
      end
    end

    describe "ordering" do
      it "orders by start_at first" do
        @term1.update(start_at: 1.day.ago, end_at: 5.days.from_now)
        @term2.update(start_at: 2.days.ago, end_at: 6.days.from_now)

        json = get_terms
        expect(json.first["name"]).to eq @term1.name
        expect(json.last["name"]).to eq @term2.name
      end

      it "orders by end_at second" do
        start_at = 1.day.ago
        @term1.update(start_at:, end_at: 6.days.from_now)
        @term2.update(start_at:, end_at: 5.days.from_now)

        json = get_terms
        expect(json.first["name"]).to eq @term1.name
        expect(json.last["name"]).to eq @term2.name
      end

      it "orders by id last" do
        start_at = 1.day.ago
        end_at = 5.days.from_now
        @term1.update(start_at:, end_at:)
        @term2.update(start_at:, end_at:)

        json = get_terms
        expect(json.first["name"]).to eq @term1.name
        expect(json.last["name"]).to eq @term2.name
      end
    end

    it "paginates" do
      json = get_terms(per_page: 1)
      expect(json.size).to eq 1
      expect(response.headers).to include("Link")
      expect(response.headers["Link"]).to match(/rel="next"/)
    end

    it "includes overrides if requested" do
      @term1.set_overrides(@account, "StudentEnrollment" => { end_at: "2017-01-20T00:00:00Z" })
      json = get_terms(include: ["overrides"])
      expect(json.pluck("overrides")).to match_array([
                                                       {}, { "StudentEnrollment" => { "start_at" => nil, "end_at" => "2017-01-20T00:00:00Z" } }
                                                     ])
    end

    it "includes course count if requested" do
      2.times { course_factory(active_all: true, account: @account, enrollment_term_id: @term1.id) }
      json = get_terms(include: ["course_count"])
      expect(json.pluck("course_count")).to match_array([2, 0])
    end

    describe "authorization" do
      def expect_terms_index_401
        api_call(:get,
                 "/api/v1/accounts/#{@account.id}/terms",
                 { controller: "terms_api", action: "index", format: "json", account_id: @account.to_param },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "requires auth for the right account" do
        other_account = Account.create(name: "other")
        account_admin_user(account: other_account)
        expect_terms_index_401
      end

      it "allows sub-account admins to view" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: subaccount)
        res = get_terms.pluck("name")
        expect(res).to match_array([@term1.name, @term2.name])
      end

      it "allows teachers to view" do
        c = @account.courses.create!(enrollment_term: @term1)
        teacher_in_course(course: c, active_all: true)
        res = get_terms.pluck("name")
        expect(res).to match_array([@term1.name, @term2.name])
      end

      it "does not allow other enrollment types to view" do
        c = @account.courses.create!(enrollment_term: @term1)
        student_in_course(course: c, active_all: true)
        expect_terms_index_401
      end

      it "requires context to be root_account and error nicely" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: @account)
        json = api_call(:get,
                        "/api/v1/accounts/#{subaccount.id}/terms",
                        { controller: "terms_api", action: "index", format: "json", account_id: subaccount.to_param },
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to eq "Terms only belong to root_accounts."
      end

      it "allows account admins without manage_account_settings to view" do
        role = custom_account_role("custom")
        account_admin_user_with_role_changes(account: @account, role:)
        res = get_terms.pluck("name")
        expect(res).to match_array([@term1.name, @term2.name])
      end
    end
  end

  describe "show" do
    before :once do
      @account = Account.create(name: "new")
      account_admin_user(account: @account)
      @account.enrollment_terms.scope.delete_all
      @term = @account.enrollment_terms.create(name: "Term")
    end

    def get_term(body_params = {})
      api_call(:get,
               "/api/v1/accounts/#{@account.id}/terms/#{@term.id}",
               { controller: "terms_api", action: "show", format: "json", account_id: @account.to_param, id: @term.to_param },
               body_params)
    end

    it "shows sis_batch_id" do
      sis_batch = @account.sis_batches.create
      @term.sis_batch_id = sis_batch.id
      @term.save!
      json = get_term
      expect(json["sis_import_id"]).to eq sis_batch.id
    end

    it "includes overrides" do
      @term.set_overrides(@account, "StudentEnrollment" => { end_at: "2017-01-20T00:00:00Z" })
      json = get_term
      expect(json["overrides"]).to eq({ "StudentEnrollment" => { "start_at" => nil, "end_at" => "2017-01-20T00:00:00Z" } })
    end

    it "includes course count" do
      course_factory(active_all: true, account: @account, enrollment_term_id: @term.id)
      json = get_term
      expect(json["course_count"]).to eq 1
    end

    describe "authorization" do
      def expect_terms_show_401
        api_call(:get,
                 "/api/v1/accounts/#{@account.id}/terms/#{@term.id}",
                 { controller: "terms_api", action: "show", format: "json", account_id: @account.to_param, id: @term.to_param },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "requires auth for the right account" do
        other_account = Account.create(name: "other")
        account_admin_user(account: other_account)
        expect_terms_show_401
      end

      it "allows sub-account admins to view" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: subaccount)
        res = get_term
        expect(res["id"]).to eq @term.id
      end

      it "requires context to be root_account and error nicely" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: @account)
        json = api_call(:get,
                        "/api/v1/accounts/#{subaccount.id}/terms/#{@term.id}",
                        { controller: "terms_api", action: "show", format: "json", account_id: subaccount.to_param, id: @term.to_param },
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to eq "Terms only belong to root_accounts."
      end

      it "allows account admins without manage_account_settings to view" do
        role = custom_account_role("custom")
        account_admin_user_with_role_changes(account: @account, role:)
        res = get_term
        expect(res["id"]).to eq @term.id
      end
    end
  end
end

describe TermsController, type: :request do
  before :once do
    @account = Account.create(name: "new")
    account_admin_user(account: @account)
    @account.enrollment_terms.scope.delete_all
    @term1 = @account.enrollment_terms.create(name: "Term 1")
  end

  describe "create" do
    it "allows creating a term" do
      start_at = 3.days.ago
      end_at = 3.days.from_now
      json = api_call(:post,
                      "/api/v1/accounts/#{@account.id}/terms",
                      { controller: "terms", action: "create", format: "json", account_id: @account.to_param },
                      { enrollment_term: { name: "Term 2", start_at: start_at.iso8601, end_at: end_at.iso8601 } })

      expect(json["id"]).to be_present
      expect(json["name"]).to eq "Term 2"
      expect(json["start_at"]).to eq start_at.iso8601
      expect(json["end_at"]).to eq end_at.iso8601

      new_term = @account.reload.enrollment_terms.find(json["id"])
      expect(new_term.name).to eq "Term 2"
      expect(new_term.start_at.to_i).to eq start_at.to_i
      expect(new_term.end_at.to_i).to eq end_at.to_i
    end

    describe "sis_term_id" do
      it "allows specifying sis_term_id with :manage_sis permission" do
        expect(@account.grants_right?(@user, :manage_sis)).to be_truthy
        json = api_call(:post,
                        "/api/v1/accounts/#{@account.id}/terms",
                        { controller: "terms", action: "create", format: "json", account_id: @account.to_param },
                        { enrollment_term: { name: "Term 2", sis_term_id: "SIS Term 2" } })

        expect(json["sis_term_id"]).to eq "SIS Term 2"
        new_term = @account.reload.enrollment_terms.find(json["id"])
        expect(new_term.sis_source_id).to eq "SIS Term 2"
      end

      it "rejects invalid sis ids" do
        api_call(:post,
                 "/api/v1/accounts/#{@account.id}/terms",
                 { controller: "terms", action: "create", format: "json", account_id: @account.to_param },
                 { enrollment_term: { name: "Term 2", sis_term_id: { fail: true } } },
                 {},
                 { expected_status: 400 })
      end

      it "rejects non unique sis ids" do
        @account.enrollment_terms.create!(name: "term", sis_source_id: "sis1")
        json = api_call(:post,
                        "/api/v1/accounts/#{@account.id}/terms",
                        { controller: "terms", action: "create", format: "json", account_id: @account.to_param },
                        { enrollment_term: { name: "Term 2", sis_term_id: "sis1" } },
                        { expected_status: 400 })

        expect(json["errors"]["sis_source_id"].first.values).to eq ["sis_source_id", "SIS ID \"sis1\" is already in use", "SIS ID \"sis1\" is already in use"]
      end

      it "rejects sis_term_id without :manage_sis permission" do
        account_with_role_changes(account: @account, role_changes: { manage_sis: false })
        expect(@account.grants_right?(@user, :manage_sis)).to be_falsey
        json = api_call(:post,
                        "/api/v1/accounts/#{@account.id}/terms",
                        { controller: "terms", action: "create", format: "json", account_id: @account.to_param },
                        { enrollment_term: { name: "Term 2", sis_term_id: "SIS Term 2" } })

        expect(json["sis_term_id"]).to be_nil
        new_term = @account.reload.enrollment_terms.find(json["id"])
        expect(new_term.sis_source_id).to be_nil
      end
    end

    describe "authorization" do
      def expect_terms_create_401
        api_call(:post,
                 "/api/v1/accounts/#{@account.id}/terms",
                 { controller: "terms", action: "create", format: "json", account_id: @account.to_param },
                 { enrollment_term: { name: "Term 2" } },
                 {},
                 { expected_status: 401 })
      end

      it "requires auth for the right account" do
        other_account = Account.create(name: "other")
        account_admin_user(account: other_account)
        expect_terms_create_401
      end

      it "requires root domain auth" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: subaccount)
        expect_terms_create_401
      end
    end
  end

  describe "update" do
    it "allows updating a term" do
      start_at = 3.days.ago
      end_at = 3.days.from_now
      json = api_call(:put,
                      "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                      { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                      { enrollment_term: { name: "Term 2", start_at: start_at.iso8601, end_at: end_at.iso8601 } })

      expect(json["id"]).to eq @term1.id
      expect(json["name"]).to eq "Term 2"
      expect(json["start_at"]).to eq start_at.iso8601
      expect(json["end_at"]).to eq end_at.iso8601

      @term1.reload
      expect(@term1.name).to eq "Term 2"
      expect(@term1.start_at.to_i).to eq start_at.to_i
      expect(@term1.end_at.to_i).to eq end_at.to_i
    end

    it "allows removing sis ids" do
      term = @account.enrollment_terms.create!(name: "term", sis_source_id: "sis1")
      json = api_call(:put,
                      "/api/v1/accounts/#{@account.id}/terms/#{term.id}",
                      { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: term.to_param },
                      { enrollment_term: { name: "Term 2", sis_source_id: "" } })
      expect(json["sis_term_id"]).to be_nil
      expect(term.reload.sis_source_id).to be_nil
    end

    it "requires valid dates" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                      { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                      { enrollment_term: { name: "Term 2", start_at: 3.days.ago.iso8601, end_at: 5.days.ago.iso8601 } },
                      {},
                      { expected_status: 400 })
      expect(json["errors"]["base"].first["message"]).to eq "End dates cannot be before start dates"
    end

    describe "sis_term_id" do
      it "allows specifying sis_term_id with :manage_sis permission" do
        expect(@account.grants_right?(@user, :manage_sis)).to be_truthy
        json = api_call(:put,
                        "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                        { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                        { enrollment_term: { sis_term_id: "SIS Term 2" } })

        expect(json["sis_term_id"]).to eq "SIS Term 2"
        expect(@term1.reload.sis_source_id).to eq "SIS Term 2"
      end

      it "allows removing sis_term_id with :manage_sis permission" do
        @term1.update(sis_source_id: "SIS Term 2")
        expect(@account.grants_right?(@user, :manage_sis)).to be_truthy
        json = api_call(:put,
                        "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                        { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                        { enrollment_term: { name: "Term 2", sis_term_id: "" } })

        expect(json.keys).to include "sis_term_id"
        expect(json["sis_term_id"]).to be_nil
        expect(@term1.reload.sis_source_id).to be_nil
      end

      it "rejects sis_term_id without :manage_sis permission" do
        account_with_role_changes(account: @account, role_changes: { manage_sis: false })
        expect(@account.grants_right?(@user, :manage_sis)).to be_falsey
        json = api_call(:put,
                        "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                        { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                        { enrollment_term: { name: "Term 2", sis_term_id: "SIS Term 2" } })

        expect(json["sis_term_id"]).to be_nil
        expect(@term1.reload.sis_source_id).to be_nil
      end
    end

    describe "overrides" do
      it "sets override dates for enrollments" do
        overrides_hash = {
          "StudentEnrollment" => { "start_at" => "2017-01-20T20:00:00Z", "end_at" => "2017-03-20T20:00:00Z" },
          "TeacherEnrollment" => { "start_at" => "2017-01-16T20:00:00Z", "end_at" => "2017-03-22T20:00:00Z" }
        }
        json = api_call(:put,
                        "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                        { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                        { enrollment_term: { overrides: overrides_hash } })
        expect(json["overrides"]).to eq overrides_hash
        teacher_override = @term1.enrollment_dates_overrides.where(enrollment_type: "TeacherEnrollment").first
        expect(teacher_override.start_at.iso8601).to eq "2017-01-16T20:00:00Z"
        expect(teacher_override.end_at.iso8601).to eq "2017-03-22T20:00:00Z"
        student_override = @term1.enrollment_dates_overrides.where(enrollment_type: "StudentEnrollment").first
        expect(student_override.start_at.iso8601).to eq "2017-01-20T20:00:00Z"
        expect(student_override.end_at.iso8601).to eq "2017-03-20T20:00:00Z"
      end

      it "requires valid dates for overrides" do
        overrides_hash = { "StudentEnrollment" => { "start_at" => "2017-04-20T20:00:00Z", "end_at" => "2017-03-20T20:00:00Z" }, }
        json = api_call(:put,
                        "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                        { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                        { enrollment_term: { overrides: overrides_hash } },
                        {},
                        { expected_status: 400 })
        expect(json["errors"]["base"].first["message"]).to eq "End dates cannot be before start dates"
      end

      it "rejects override for invalid enrollment type", priority: "1" do
        result = @term1.enrollment_dates_overrides.where(enrollment_type: "ObserverEnrollment").to_a
        api_call(:put,
                 "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                 { controller: "terms",
                   action: "update",
                   format: "json",
                   account_id: @account.to_param,
                   id: @term1.to_param },
                 { enrollment_term: { overrides: { ObserverEnrollment: {
                   start_at: "2017-01-17T20:00:00Z", end_at: "2017-01-17T20:00:00Z"
                 } } } },
                 {},
                 { expected_status: 400 })
        expect(result).to eq(@term1.enrollment_dates_overrides.where(enrollment_type: "ObserverEnrollment").to_a)
      end
    end

    describe "authorization" do
      def expect_terms_update_401
        api_call(:put,
                 "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                 { controller: "terms", action: "update", format: "json", account_id: @account.to_param, id: @term1.to_param },
                 { enrollment_term: { name: "Term 2" } },
                 {},
                 { expected_status: 401 })
      end

      it "requires auth for the right account" do
        other_account = Account.create(name: "other")
        account_admin_user(account: other_account)
        expect_terms_update_401
      end

      it "requires root domain auth" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: subaccount)
        expect_terms_update_401
      end
    end
  end

  describe "destroy" do
    it "allows deleting a term" do
      json = api_call(:delete,
                      "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                      { controller: "terms", action: "destroy", format: "json", account_id: @account.to_param, id: @term1.to_param })

      expect(json["id"]).to eq @term1.id
      expect(@term1.reload).to be_deleted
    end

    describe "authorization" do
      def expect_terms_destroy_401
        api_call(:delete,
                 "/api/v1/accounts/#{@account.id}/terms/#{@term1.id}",
                 { controller: "terms", action: "destroy", format: "json", account_id: @account.to_param, id: @term1.to_param },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "requires auth for the right account" do
        other_account = Account.create(name: "other")
        account_admin_user(account: other_account)
        expect_terms_destroy_401
      end

      it "requires root domain auth" do
        subaccount = @account.sub_accounts.create!(name: "subaccount")
        account_admin_user(account: subaccount)
        expect_terms_destroy_401
      end
    end
  end
end
