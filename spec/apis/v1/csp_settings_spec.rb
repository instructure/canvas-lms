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
require_relative '../api_spec_helper'

describe "CSP Settings API", type: :request do
  def create_tool(context, attrs)
    context.context_external_tools.create!({:name => "a", :consumer_key => '12345', :shared_secret => 'secret'}.merge(attrs))
  end

  before :once do
    account_admin_user(:active_all => true)
    @sub = Account.default.sub_accounts.create!
    course_factory(:account => @sub)
  end

  context "GET get_csp_settings" do
    def get_csp_settings(context, expected_status=200)
      api_call(:get, "/api/v1/#{context.class.name.pluralize.downcase}/#{context.id}/csp_settings",
        {:controller => "csp_settings", :action => "get_csp_settings", :format => "json",
        :"#{context.class.name.downcase}_id" => "#{context.id}"}, {}, {}, {:expected_status => expected_status})
    end

    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get_csp_settings(@course, 401)
    end

    describe "course-level settings" do
      it "should get the default state" do
        json = get_csp_settings(@course)
        expect(json["enabled"]).to eq false
        expect(json["inherited"]).to eq true
        expect(json["effective_whitelist"]).to be_nil
      end

      it "should get the whitelist if enabled" do
        Account.default.enable_csp!
        Account.default.add_domain!("example1.com")
        create_tool(@sub, :domain => "example2.com")

        json = get_csp_settings(@course)
        expect(json["enabled"]).to eq true
        expect(json["inherited"]).to eq true
        expect(json["effective_whitelist"]).to match_array(["example1.com", "example2.com"])
      end

      it "should indicate if disabled explicitly on course" do
        Account.default.enable_csp!
        Account.default.add_domain!("example1.com")
        @course.disable_csp!

        json = get_csp_settings(@course)
        expect(json["enabled"]).to eq false
        expect(json["inherited"]).to eq false # not inherited
      end
    end

    describe "account-level settings" do
      it "should get the default state" do
        json = get_csp_settings(@sub)
        expect(json["enabled"]).to eq false
        expect(json["inherited"]).to eq true
        expect(json["effective_whitelist"]).to be_nil
      end

      it "should get the whitelist if enabled" do
        Account.default.enable_csp!
        Account.default.add_domain!("example1.com")
        tool = create_tool(@sub, :domain => "example2.com")

        json = get_csp_settings(@sub)
        expect(json["enabled"]).to eq true
        expect(json["inherited"]).to eq true
        expect(json["effective_whitelist"]).to match_array(["example1.com", "example2.com"])
        expect(json["tools_whitelist"]).to eq(
          {"example2.com" => [{"id" => tool.id, "name" => tool.name, "account_id" => @sub.id}]})
        expect(json["current_account_whitelist"]).to eq []
      end

      it "should list domains added to the account even if not enabled (yet)" do
        Account.default.add_domain!("pendingdomain.example.com")

        json = get_csp_settings(Account.default)
        expect(json["current_account_whitelist"]).to eq ["pendingdomain.example.com"]
      end
    end
  end

  context "PUT set_csp_setting" do
    def set_csp_setting(context, csp_status, expected_status=200)
      api_call(:put, "/api/v1/#{context.class.name.pluralize.downcase}/#{context.id}/csp_settings",
        {:controller => "csp_settings", :action => "set_csp_setting", :format => "json",
        :"#{context.class.name.downcase}_id" => "#{context.id}", :status => csp_status},
        {}, {}, {:expected_status => expected_status})
    end

    context "setting on courses" do
      it "should require account-level enabling" do
        json = set_csp_setting(@course, "enabled", 400)
        expect(json["message"]).to eq "must be enabled on account-level first"
      end

      it "should un-disable if enabled on account-level" do
        @sub.enable_csp!
        @course.disable_csp!
        set_csp_setting(@course, "enabled")
        expect(@course.reload.csp_disabled?).to eq false
      end

      it "should unset explicit disabling" do
        @course.disable_csp!
        set_csp_setting(@course, "inherited")
        expect(@course.reload.csp_disabled?).to eq false
      end

      it "should explicitly disable" do
        set_csp_setting(@course, "disabled")
        expect(@course.reload.csp_disabled?).to eq true
      end
    end

    context "setting on accounts" do
      it "should enable csp" do
        set_csp_setting(@sub, "enabled")
        expect(@sub.reload.csp_directly_enabled?).to eq true
      end

      it "should disable csp" do
        Account.default.enable_csp!
        set_csp_setting(@sub, "disabled")
        expect(@sub.reload.csp_enabled?).to eq false
      end

      it "should inherit csp settings" do
        Account.default.enable_csp!
        @sub.disable_csp!
        set_csp_setting(@sub, "inherited")
        expect(@sub.reload.csp_enabled?).to eq true
      end
    end
  end

  describe "POST add_domain" do
    def add_domain(account, domain, expected_status=200)
      api_call(:post, "/api/v1/accounts/#{account.id}/csp_settings/domains",
        {:controller => "csp_settings", :action => "add_domain", :format => "json",
          :account_id => "#{account.id}", :domain => domain},
        {}, {}, {:expected_status => expected_status})
    end

    it "should add domains even if csp isn't enabled yet" do
      domain = "custom.example.com"
      json = add_domain(@sub, domain)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to eq [domain]
      expect(json["current_account_whitelist"]).to eq [domain]
    end

    it "should try to parse the domain" do
      json = add_domain(@sub, "domain; default-src badexample.com", 400)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to be_empty
    end
  end

  describe "DELETE remove_domain" do
    def remove_domain(account, domain, expected_status=200)
      api_call(:delete, "/api/v1/accounts/#{account.id}/csp_settings/domains",
        {:controller => "csp_settings", :action => "remove_domain", :format => "json",
          :account_id => "#{account.id}", :domain => domain},
        {}, {}, {:expected_status => expected_status})
    end

    it "should remove domains even if csp isn't enabled yet" do
      domain1 = "custom1.example.com"
      domain2 = "custom2.example.com"
      @sub.add_domain!(domain1)
      @sub.add_domain!(domain2)
      json = remove_domain(@sub, domain1)
      expect(@sub.reload.csp_domains.active.pluck(:domain)).to eq [domain2]
      expect(json["current_account_whitelist"]).to eq [domain2]
    end
  end
end
