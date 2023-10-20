# frozen_string_literal: true

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
require_relative "../api_spec_helper"

describe "CSP Settings API", type: :request do
  def create_tool(context, attrs)
    context.context_external_tools.create!({ name: "a", consumer_key: "12345", shared_secret: "secret" }.merge(attrs))
  end

  before do
    allow(HostUrl).to receive(:context_host).with(Account.default, anything).and_return("example1.com")
  end

  before :once do
    account_admin_user(active_all: true)
    @sub = Account.default.sub_accounts.create!
    @course = course_factory(account: @sub)
  end

  context "GET get_csp_settings" do
    def get_csp_settings(context, expected_status = 200)
      api_call(:get,
               "/api/v1/#{context.class.name.pluralize.downcase}/#{context.id}/csp_settings",
               { controller: "csp_settings",
                 action: "get_csp_settings",
                 format: "json",
                 "#{context.class.name.downcase}_id": context.id.to_s },
               {},
               {},
               { expected_status: })
    end

    it "requires authorization" do
      course_with_teacher(active_all: true, course: @course)
      get_csp_settings(@course, 200)
    end

    it "is unauthorized" do
      course_with_student(active_all: true, course: @course)
      get_csp_settings(@course, 401)
    end

    describe "course-level settings" do
      it "gets the default state" do
        json = get_csp_settings(@course)
        expect(json["enabled"]).to be false
        expect(json["inherited"]).to be true
        expect(json["effective_whitelist"]).to be_nil
      end

      it "gets the whitelist if enabled" do
        Account.default.enable_csp!
        Account.default.add_domain!("example1.com")
        create_tool(@sub, domain: "example2.com")

        json = get_csp_settings(@course)
        expect(json["enabled"]).to be true
        expect(json["inherited"]).to be true
        expect(json["effective_whitelist"]).to match_array(["example1.com", "example2.com", "*.example2.com"])
      end

      it "indicates if disabled explicitly on course" do
        Account.default.enable_csp!
        Account.default.add_domain!("example1.com")
        @course.disable_csp!

        json = get_csp_settings(@course)
        expect(json["enabled"]).to be false
        expect(json["inherited"]).to be false # not inherited
      end
    end

    describe "account-level settings" do
      it "gets the default state" do
        json = get_csp_settings(@sub)
        expect(json["enabled"]).to be false
        expect(json["inherited"]).to be true
        expect(json["settings_locked"]).to be false
        expect(json["effective_whitelist"]).to be_nil
      end

      it "shows when settings are locked from above" do
        Account.default.tap do |a|
          a.enable_csp!
          a.lock_csp!
        end
        json = get_csp_settings(@sub)
        expect(json["settings_locked"]).to be true
      end

      it "gets the whitelist if enabled" do
        Account.default.enable_csp!
        Account.default.add_domain!("example1.com")
        tool = create_tool(@sub, domain: "example2.com")

        json = get_csp_settings(@sub)
        expect(json["enabled"]).to be true
        expect(json["inherited"]).to be true
        expect(json["effective_whitelist"]).to match_array(["example1.com", "example2.com", "*.example2.com"])
        expect(json["tools_whitelist"]).to eq({
                                                "example2.com" => [{ "id" => tool.id, "name" => tool.name, "account_id" => @sub.id }],
                                                "*.example2.com" => [{ "id" => tool.id, "name" => tool.name, "account_id" => @sub.id }]
                                              })
        expect(json["current_account_whitelist"]).to eq []
      end

      it "lists domains added to the account even if not enabled (yet)" do
        Account.default.add_domain!("pendingdomain.example.com")

        json = get_csp_settings(Account.default)
        expect(json["current_account_whitelist"]).to eq ["pendingdomain.example.com"]
      end
    end
  end

  context "PUT set_csp_setting" do
    def set_csp_setting(context, csp_status, expected_status = 200)
      api_call(:put,
               "/api/v1/#{context.class.name.pluralize.downcase}/#{context.id}/csp_settings",
               { controller: "csp_settings",
                 action: "set_csp_setting",
                 format: "json",
                 "#{context.class.name.downcase}_id": context.id.to_s,
                 status: csp_status },
               {},
               {},
               { expected_status: })
    end

    context "setting on courses" do
      it "requires account-level enabling" do
        json = set_csp_setting(@course, "enabled", 400)
        expect(json["message"]).to eq "must be enabled on account-level first"
      end

      it "is blocked by parent account locking" do
        @sub.enable_csp!
        @sub.lock_csp!
        json = set_csp_setting(@course, "disabled", 400)
        expect(json["message"]).to eq "cannot set when locked by parent account"
      end

      it "un-disables if enabled on account-level" do
        @sub.enable_csp!
        @course.disable_csp!
        set_csp_setting(@course, "enabled")
        expect(@course.reload.csp_disabled?).to be false
      end

      it "unsets explicit disabling" do
        @course.disable_csp!
        set_csp_setting(@course, "inherited")
        expect(@course.reload.csp_disabled?).to be false
      end

      it "disables explicitly" do
        set_csp_setting(@course, "disabled")
        expect(@course.reload.csp_disabled?).to be true
      end
    end

    context "setting on accounts" do
      it "is blocked by parent account locking" do
        Account.default.tap do |a|
          a.enable_csp!
          a.lock_csp!
        end
        json = set_csp_setting(@sub, "disabled", 400)
        expect(json["message"]).to eq "cannot set when locked by parent account"
      end

      it "is not blocked when locked on self" do
        @sub.enable_csp!
        @sub.lock_csp!
        set_csp_setting(@sub, "disabled")
        expect(Account.find(@sub.id).csp_enabled?).to be false
      end

      it "enables csp" do
        set_csp_setting(@sub, "enabled")
        expect(@sub.reload.csp_directly_enabled?).to be true
      end

      it "disables csp" do
        Account.default.enable_csp!
        json = set_csp_setting(@sub, "disabled")
        expect(json["enabled"]).to be false
        expect(@sub.reload.csp_enabled?).to be false
      end

      it "inherits csp settings" do
        Account.default.enable_csp!
        @sub.disable_csp!
        set_csp_setting(@sub, "inherited")
        expect(@sub.reload.csp_enabled?).to be true
      end
    end
  end

  context "PUT set_csp_lock" do
    def set_csp_lock(context, lock_status, expected_status = 200)
      api_call(:put,
               "/api/v1/#{context.class.name.pluralize.downcase}/#{context.id}/csp_settings/lock",
               { controller: "csp_settings",
                 action: "set_csp_lock",
                 format: "json",
                 "#{context.class.name.downcase}_id": context.id.to_s,
                 settings_locked: lock_status },
               {},
               {},
               { expected_status: })
    end

    context "setting on accounts" do
      it "requires explicit setting" do
        json = set_csp_lock(@sub, true, 400)
        expect(json["message"]).to eq "CSP must be explicitly set on this account"
      end

      it "locks csp" do
        Account.default.enable_csp!
        set_csp_lock(Account.default, true)
        expect(@sub.reload.csp_locked?).to be true
      end

      it "unlocks csp" do
        Account.default.tap do |a|
          a.enable_csp!
          a.lock_csp!
        end
        set_csp_lock(Account.default, false)
        expect(@sub.reload.csp_locked?).to be false
      end
    end
  end

  describe "POST add_domain" do
    def add_domain(account, domain, expected_status = 200)
      api_call(:post,
               "/api/v1/accounts/#{account.id}/csp_settings/domains",
               { controller: "csp_settings",
                 action: "add_domain",
                 format: "json",
                 account_id: account.id.to_s,
                 domain: },
               {},
               {},
               { expected_status: })
    end

    it "adds domains even if csp isn't enabled yet" do
      domain = "custom.example.com"
      json = add_domain(@sub, domain)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to eq [domain]
      expect(json["current_account_whitelist"]).to eq [domain]
    end

    it "tries to parse the domain" do
      add_domain(@sub, "domain; default-src badexample.com", 400)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to be_empty
    end
  end

  describe "POST add_multiple_domains" do
    def add_domains(account, domains, expected_status = 200)
      api_call(:post,
               "/api/v1/accounts/#{account.id}/csp_settings/domains/batch_create",
               { controller: "csp_settings",
                 action: "add_multiple_domains",
                 format: "json",
                 account_id: account.id.to_s,
                 domains: },
               {},
               {},
               { expected_status: })
    end

    it "adds domains even if csp isn't enabled yet" do
      domains = ["custom.example.com", "custom2.example.com"]
      json = add_domains(@sub, domains)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to match_array(domains)
      expect(json["current_account_whitelist"]).to eq domains
    end

    it "tries to parse all the domains before adding any" do
      bad_domain = "domain*$&#(@*&#($*"
      json = add_domains(@sub, [bad_domain, "agoodone.example.com"], 400)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to be_empty
      expect(json["message"]).to eq "invalid domains: #{bad_domain}"
    end
  end

  describe "DELETE remove_domain" do
    def remove_domain(account, domain, expected_status = 200)
      api_call(:delete,
               "/api/v1/accounts/#{account.id}/csp_settings/domains",
               { controller: "csp_settings",
                 action: "remove_domain",
                 format: "json",
                 account_id: account.id.to_s,
                 domain: },
               {},
               {},
               { expected_status: })
    end

    it "removes domains even if csp isn't enabled yet" do
      domain1 = "custom1.example.com"
      domain2 = "custom2.example.com"
      @sub.add_domain!(domain1)
      @sub.add_domain!(domain2)
      json = remove_domain(@sub, domain1)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to eq [domain2]
      expect(json["current_account_whitelist"]).to eq [domain2]
    end
  end

  describe "GET csp_log" do
    def get_csp_log(account, expected_status)
      api_call(:get,
               "/api/v1/accounts/#{account.id}/csp_log",
               { controller: "csp_settings",
                 action: "csp_log",
                 format: "json",
                 account_id: account.id.to_param },
               {},
               {},
               { expected_status: })
    end

    it "400s for a subaccount" do
      get_csp_log(@sub, 400)
    end

    it "requires authorization" do
      course_with_teacher(active_all: true, course: @course)
      get_csp_log(Account.default, 401)
    end

    it "requires csp logging to be configured" do
      allow_any_instantiation_of(Account.default).to receive(:csp_logging_config).and_return({})
      get_csp_log(Account.default, 503)
    end

    it "just passes through the result from the external service" do
      allow_any_instantiation_of(Account.default).to receive(:csp_logging_config).and_return(
        { "host" => "http://csp_logging.docker/", "shared_secret" => "bob" }
      )
      expect(CanvasHttp).to receive(:get).with("http://csp_logging.docker/report/#{Account.default.global_id}",
                                               { "Authorization" => "Bearer bob" }).and_return(double(body: "{}"))
      res = get_csp_log(Account.default, 200)
      expect(res).to eq({})
    end
  end
end
