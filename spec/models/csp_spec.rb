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
require_relative "../spec_helper"

describe Csp do
  def create_tool(context, attrs)
    context.context_external_tools.create!({ name: "a", consumer_key: "12345", shared_secret: "secret" }.merge(attrs))
  end

  before do
    allow(HostUrl).to receive(:context_host).with(Account.default, anything).and_return(nil)
  end

  describe "account setting inheritance" do
    before :once do
      @root = Account.create!
      @sub1 = @root.sub_accounts.create!
      @sub2 = @sub1.sub_accounts.create!
      @accounts = [@root, @sub1, @sub2]
    end

    it "is not enabled by default" do
      @accounts.each { |a| expect(a.csp_enabled?).to be false }
    end

    it "inherits settings" do
      @root.enable_csp!
      @accounts.each do |a|
        expect(a.csp_enabled?).to be true
        expect(a.csp_account_id).to eq @root.global_id
      end
    end

    it "overrides inherited settings if explicitly set down the chain" do
      @root.enable_csp!
      @sub1.disable_csp!
      expect(@sub2.csp_enabled?).to be false
    end

    it "does not override inherited settings if explicitly set down the chain but locked" do
      @root.enable_csp!
      @sub1.disable_csp!
      @root.lock_csp!
      @accounts.each do |a|
        expect(a.csp_enabled?).to be true
        expect(a.csp_account_id).to eq @root.global_id
      end
    end

    it "caches" do
      expect_any_instantiation_of(@sub1).to receive(:calculate_inherited_setting).once
      enable_cache do
        @sub1.csp_enabled?
        Account.find(@sub1.id).csp_enabled?
      end
    end

    it "invalidates caches on changes" do
      enable_cache do
        expect(@sub2.csp_enabled?).to be false
        @root.enable_csp!
        expect(Account.find(@sub2.id).csp_enabled?).to be true
      end
    end

    it "invalidates caches on lock changes" do
      @root.enable_csp!
      @sub1.disable_csp!
      @root.lock_csp!
      enable_cache do
        expect(@sub2.csp_enabled?).to be true
        @root.unlock_csp!
        expect(Account.find(@sub2.id).csp_enabled?).to be false
      end
    end
  end

  describe "course setting" do
    before :once do
      @root = Account.create!
      @sub = @root.sub_accounts.create!
      @course = @sub.courses.create!
    end

    it "bies disabled by default" do
      expect(@course.csp_enabled?).to be false
    end

    it "inherits from account" do
      @root.enable_csp!
      expect(@course.reload.csp_enabled?).to be true
    end

    it "is disabled if set on course" do
      @root.enable_csp!
      @course.csp_disabled = true
      @course.save!
      expect(@course.reload.csp_enabled?).to be false
    end

    it "does not allow overriding if locked by account" do
      @root.enable_csp!
      @course.csp_disabled = true
      @course.save!
      @root.lock_csp!
      expect(@course.reload.csp_enabled?).to be true
      expect(@course.csp_locked?).to be true
    end
  end

  describe "domain whitelist" do
    before :once do
      @root = Account.create!
      @root.enable_csp!
      @sub = @root.sub_accounts.create!
    end

    it "add,s remove and reactivate domains" do
      domain = "example.com"

      @root.add_domain!(domain)
      record = @root.reload.csp_domains.first
      expect(record.domain).to eq domain
      expect(record).to be_active

      @root.remove_domain!(domain)
      expect(record.reload).to be_deleted

      @root.add_domain!(domain)
      expect(record.reload).to be_active
    end

    it "caches" do
      enable_cache do
        domain = "example.com"
        expect(Csp::Domain).to receive(:domains_for_account).with(@root.global_id).and_return([domain]).once
        expect(@sub.csp_whitelisted_domains(include_files: false, include_tools: false)).to eq [domain]
        expect(Account.find(@sub.id).csp_whitelisted_domains(include_files: false, include_tools: false)).to eq [domain]
      end
    end

    it "invalidates the cache after saving" do
      enable_cache do
        domain1 = "blah.example.com"
        domain2 = "bloo.example.com"

        @root.enable_csp!
        @root.add_domain!(domain1)
        @sub = @root.sub_accounts.create!
        expect(@sub.csp_whitelisted_domains(include_files: false, include_tools: false)).to eq [domain1]

        @root.add_domain!(domain2)
        expect(@sub.csp_whitelisted_domains(include_files: false, include_tools: false)).to match_array([domain1, domain2])

        @root.remove_domain!(domain1)
        expect(@sub.csp_whitelisted_domains(include_files: false, include_tools: false)).to match_array([domain2])
      end
    end

    it "includes the global whitelist Setting" do
      allow(Setting).to receive(:get).with("csp.global_whitelist", "").and_return("some-domain.com,another.net, a-third.io")
      expect(@sub.csp_whitelisted_domains(include_files: false, include_tools: false)).to match_array(["some-domain.com", "another.net", "a-third.io"])
    end
  end

  describe "tool whitelist" do
    before :once do
      @root, @sub1, @sub2 = create_accounts
    end

    def create_accounts
      root = Account.create!
      root.enable_csp!
      sub1 = root.sub_accounts.create!
      sub2 = sub1.sub_accounts.create!
      [root, sub1, sub2]
    end

    def create_some_tools
      [
        create_tool(@root, domain: "example1.com"),
        create_tool(@sub1, domain: "example2.com"),
        create_tool(@sub2, url: "https://example3.com/launchnstuff")
      ]
    end

    def example_domains(*numbers)
      numbers.flat_map { |n| ["*.example#{n}.com", "example#{n}.com"] }
    end

    it "gets all tool domains in the chain" do
      create_some_tools

      expect(@sub1.cached_tool_domains).to match_array example_domains(1, 2)
      expect(@sub2.cached_tool_domains).to match_array example_domains(1, 2, 3)
    end

    context "when internal_service_only: true is passed in" do
      it "gets only tools with dev keys with internal_service=true, and does not cache them together" do
        _, t2, t3 = create_some_tools
        t2.update! developer_key: DeveloperKey.create!(account: @sub1)
        t3.update! developer_key: DeveloperKey.create!(account: @sub2, internal_service: true)

        expect(@sub2.cached_tool_domains(internal_service_only: false)).to match_array example_domains(1, 2, 3)
        expect(@sub2.cached_tool_domains(internal_service_only: true)).to match_array example_domains(3)
      end

      context "when the developer key is on another shard" do
        specs_require_sharding

        def create_dk(shard, account, internal_service)
          shard.activate { DeveloperKey.create!(account:, internal_service:) }
        end

        it "gets only tools with dev keys with internal_service=true" do
          sa_shard = Account.site_admin.shard
          non_sa_shard = ([@shard1, @shard2] - [sa_shard]).first

          root, sub1, _sub2 = non_sa_shard.activate { create_accounts }
          dk1 = create_dk(sa_shard, Account.site_admin, false)
          dk2 = create_dk(sa_shard, Account.site_admin, true)
          dk3 = create_dk(non_sa_shard, root, false)
          dk4 = create_dk(non_sa_shard, root, true)

          non_sa_shard.activate do
            create_tool(sub1, domain: "example1.com", developer_key: dk1)
            create_tool(sub1, domain: "example2.com", developer_key: dk2)
            create_tool(sub1, domain: "example3.com", developer_key: dk3)
            create_tool(sub1, domain: "example4.com", developer_key: dk4)

            expect(sub1.cached_tool_domains(internal_service_only: false)).to match_array example_domains(1, 2, 3, 4)
            expect(sub1.cached_tool_domains(internal_service_only: true)).to match_array example_domains(2, 4)
          end
        end
      end
    end

    it "invalidates the tool domain cache" do
      enable_cache do
        expect(@sub2.csp_whitelisted_domains(include_files: false, include_tools: true)).to eq []
        root_tool = create_tool(@root, domain: "example1.com")
        expect(Account.find(@sub2.id).csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array ["example1.com", "*.example1.com"]
        expect(Account.find(@root.id).csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array ["example1.com", "*.example1.com"]
        root_tool.update_attribute(:domain, "example2.com")
        expect(Account.find(@sub2.id).csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array ["example2.com", "*.example2.com"]
        expect(Account.find(@root.id).csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array ["example2.com", "*.example2.com"]
        root_tool.update_attribute(:workflow_state, "deleted")
        expect(Account.find(@sub2.id).csp_whitelisted_domains(include_files: false, include_tools: true)).to eq []
        expect(Account.find(@root.id).csp_whitelisted_domains(include_files: false, include_tools: true)).to eq []
      end
    end

    it "groups tools by domain" do
      root_tool = create_tool(@root, domain: "example1.com")
      sub1_tool = create_tool(@sub1, domain: "example2.com")
      sub2_tool = create_tool(@sub2, domain: "example2.com")

      expect(@sub1.csp_tools_grouped_by_domain).to eq({
                                                        "example1.com" => [root_tool],
                                                        "*.example1.com" => [root_tool],
                                                        "example2.com" => [sub1_tool],
                                                        "*.example2.com" => [sub1_tool]
                                                      })
      expect(@sub2.csp_tools_grouped_by_domain).to eq({
                                                        "example1.com" => [root_tool],
                                                        "*.example1.com" => [root_tool],
                                                        "example2.com" => [sub1_tool, sub2_tool],
                                                        "*.example2.com" => [sub1_tool, sub2_tool]
                                                      })
    end
  end

  describe "course-level domain list" do
    before :once do
      @root = Account.create!
      @root.enable_csp!
      @sub = @root.sub_accounts.create!
      @course = @sub.courses.create!
    end

    it "caches course-level tools" do
      enable_cache do
        tool = create_tool(@course, domain: "example.com")
        expect(Csp::Domain).to receive(:domains_for_tool).with(tool).once.and_return(["example.com"])
        @course.cached_tool_domains
        Course.find(@course.id).cached_tool_domains
      end
    end

    it "invalidates the cache for course-level tools" do
      enable_cache do
        create_tool(@course, url: "https://course.example.com/blah")
        expect(@course.csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array(["course.example.com", "*.course.example.com"])

        Timecop.freeze(1.minute.from_now) do
          create_tool(@course, url: "https://example2.com/whee/woo")
        end
        expect(@course.reload.csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array(["course.example.com", "*.course.example.com", "example2.com", "*.example2.com"])
      end
    end

    it "ties all the domains together" do
      @root.add_domain!("example1.com")
      create_tool(@sub, domain: "example2.com")
      create_tool(@course, domain: "example3.com")
      expect(@course.csp_whitelisted_domains(include_files: false, include_tools: true)).to match_array(["example1.com", "example2.com", "*.example2.com", "example3.com", "*.example3.com"])
    end
  end
end
