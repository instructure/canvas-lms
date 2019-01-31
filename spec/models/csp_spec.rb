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
require_relative '../spec_helper'

describe Csp do
  def create_tool(context, attrs)
    context.context_external_tools.create!({:name => "a", :consumer_key => '12345', :shared_secret => 'secret'}.merge(attrs))
  end

  describe "account setting inheritance" do
    before :once do
      @root = Account.create!
      @sub1 = @root.sub_accounts.create!
      @sub2 = @sub1.sub_accounts.create!
      @accounts = [@root, @sub1, @sub2]
    end

    it "should not be enabled by default" do
      @accounts.each{|a| expect(a.csp_enabled?).to eq false }
    end

    it "should inherit settings" do
      @root.enable_csp!
      @accounts.each do |a|
        expect(a.csp_enabled?).to eq true
        expect(a.csp_account_id).to eq @root.global_id
      end
    end

    it "should override inherited settings if explicitly set down the chain" do
      @root.enable_csp!
      @sub1.disable_csp!
      expect(@sub2.csp_enabled?).to eq false
    end

    it "should cache" do
      expect_any_instantiation_of(@sub1).to receive(:calculate_inherited_setting).once
      enable_cache do
        @sub1.csp_enabled?
        Account.find(@sub1.id).csp_enabled?
      end
    end

    it "should invalidate caches on changes" do
      enable_cache do
        expect(@sub2.csp_enabled?).to eq false
        @root.enable_csp!
        expect(Account.find(@sub2.id).csp_enabled?).to eq true
      end
    end
  end

  describe "course setting" do
    before :once do
      @root = Account.create!
      @sub = @root.sub_accounts.create!
      @course = @sub.courses.create!
    end

    it "should by disabled by default" do
      expect(@course.csp_enabled?).to eq false
    end

    it "should inherit from account" do
      @root.enable_csp!
      expect(@course.csp_enabled?).to eq true
    end

    it "should be disabled if set on course" do
      @root.enable_csp!
      @course.csp_disabled = true
      @course.save!
      expect(@course.reload.csp_enabled?).to eq false
    end
  end

  describe "domain whitelist" do
    before :once do
      @root = Account.create!
      @root.enable_csp!
      @sub = @root.sub_accounts.create!
    end

    it "should add, remove and reactivate domains" do
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

    it "should cache" do
      enable_cache do
        domain = "example.com"
        expect(Csp::Domain).to receive(:domains_for_account).with(@root.global_id).and_return([domain]).once
        expect(@sub.csp_whitelisted_domains).to eq [domain]
        expect(Account.find(@sub.id).csp_whitelisted_domains).to eq [domain]
      end
    end

    it "should invalidate the cache after saving" do
      enable_cache do
        domain1 = "blah.example.com"
        domain2 = "bloo.example.com"

        @root = Account.create!
        @root.enable_csp!
        @root.add_domain!(domain1)
        @sub = @root.sub_accounts.create!
        expect(@sub.csp_whitelisted_domains).to eq [domain1]

        @root.add_domain!(domain2)
        expect(@sub.csp_whitelisted_domains).to match_array([domain1, domain2])

        @root.remove_domain!(domain1)
        expect(@sub.csp_whitelisted_domains).to match_array([domain2])
      end
    end
  end

  describe "tool whitelist" do
    before :once do
      @root = Account.create!
      @root.enable_csp!
      @sub1 = @root.sub_accounts.create!
      @sub2 = @sub1.sub_accounts.create!
    end

    it "should get all tool domains in the chain" do
      root_tool = create_tool(@root, :domain => "example1.com")
      sub1_tool = create_tool(@sub1, :domain => "example2.com")
      sub2_tool = create_tool(@sub2, :url => "https://example3.com/launchnstuff")

      expect(@sub1.cached_tool_domains).to match_array(["example1.com", "example2.com"])
      expect(@sub2.cached_tool_domains).to match_array(["example1.com", "example2.com", "example3.com"])
    end

    it "should cache the tool domains" do
      enable_cache do
        expect(@sub2).to receive(:get_account_tool_domains).and_return(["example.com"]).once
        @sub2.csp_whitelisted_domains
        Account.find(@sub2.id).csp_whitelisted_domains
      end
    end

    it "should invalidate the tool domain cache" do
      enable_cache do
        expect(@sub2.csp_whitelisted_domains).to eq []
        root_tool = create_tool(@root, :domain => "example1.com")
        expect(Account.find(@sub2.id).csp_whitelisted_domains).to eq ["example1.com"]
        root_tool.update_attribute(:domain, "example2.com")
        expect(Account.find(@sub2.id).csp_whitelisted_domains).to eq ["example2.com"]
      end
    end
  end

  describe "course-level domain list" do
    before :once do
      @root = Account.create!
      @root.enable_csp!
      @sub = @root.sub_accounts.create!
      @course = @sub.courses.create!
    end

    it "should cache course-level tools" do
      enable_cache do
        expect(Csp::Domain).to receive(:domains_for_tools).and_return([]).once
        @course.cached_tool_domains
        Course.find(@course.id).cached_tool_domains
      end
    end

    it "should invalidate the cache for course-level tools" do
      enable_cache do
        create_tool(@course, :url => "https://course.example.com/blah")
        expect(@course.csp_whitelisted_domains).to match_array(["course.example.com"])

        Timecop.freeze(1.minute.from_now) do
          create_tool(@course, :url => "https://example2.com/whee/woo")
        end
        expect(@course.reload.csp_whitelisted_domains).to match_array(["course.example.com", "example2.com"])
      end
    end

    it "should tie all the domains together" do
      @root.add_domain!("example1.com")
      create_tool(@sub, :domain => "example2.com")
      create_tool(@course, :domain => "example3.com")
      expect(@course.csp_whitelisted_domains).to match_array(["example1.com", "example2.com", "example3.com"])
    end
  end
end
