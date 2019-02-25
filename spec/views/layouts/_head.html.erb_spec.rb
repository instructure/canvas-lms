#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "layouts/_head" do
  context "content security policy enabled" do

    let(:sub_account) { Account.default.sub_accounts.create! }
    let(:sub_2_account) { sub_account.sub_accounts.create! }

    def csp_tag
      'meta[http-equiv="Content-Security-Policy"]'
    end

    def csp_tag_with_domains(*domain_list)
      content_tags = domain_list.map do |domain|
        # periods in the domain need to be escaped with a backslash
        "[content*=#{domain.gsub('.', '\.')}]"
      end

      # This will produce a string that looks like:
      # meta[http-equiv="Content-Security-Policy"][content*=test1\.com][content*=test2\.com]
      # Which will match the tag:
      # <meta http-equiv="Content-Security-Policy" content="test1.com test2.com">
      csp_tag + content_tags.join
    end

    before :each do
      Account.default.enable_csp!
      Account.default.enable_feature!(:javascript_csp)

      Account.default.add_domain!("root_account.test")
      Account.default.add_domain!("root_account2.test")
      sub_account.add_domain!("sub_account.test")
      # Note: the sub_2_account's domain needs to NOT be a substring
      # of the sub_account's domain, otherwise the *= CSS selector will
      # consider it a match for sub_account's domain.
      sub_2_account.add_domain!("sub_2_account.test")
    end

    context "on root account" do
      before :each do
        assign(:context, Account.default)
      end

      it "should add meta tag" do
        render
        expect(response).to have_tag(csp_tag)
      end

      it "should have domain list" do
        render
        expect(response).to have_tag(csp_tag_with_domains('root_account.test', 'root_account2.test'))
      end
    end

    context "on sub-sub-account" do
      before :each do
        assign(:context, sub_2_account)
      end

      it "should inherit settings from parent account" do
        sub_account.enable_csp!
        sub_2_account.inherit_csp!
        render
        expect(response).to have_tag(csp_tag_with_domains('sub_account.test'))
        expect(response).not_to have_tag(csp_tag_with_domains('sub_2_account.test'))
      end

      it "should inherit settings through two levels of accounts" do
        sub_account.inherit_csp!
        sub_2_account.inherit_csp!
        render
        expect(response).to have_tag(csp_tag_with_domains('root_account.test', 'root_account2.test'))
      end

      it "should use own list and not inherit" do
        sub_account.enable_csp!
        sub_2_account.enable_csp!
        render
        expect(response).to have_tag(csp_tag_with_domains('sub_2_account.test'))
        expect(response).not_to have_tag(csp_tag_with_domains('sub_account.test'))
      end

      it "should inherit from parent with parent off" do
        sub_account.disable_csp!
        sub_2_account.inherit_csp!
        render
        expect(response).not_to have_tag(csp_tag)
      end

      it "should be off when disabled, ignoring enabled parent" do
        sub_account.enable_csp!
        sub_2_account.disable_csp!
        render
        expect(response).not_to have_tag(csp_tag)
      end
    end
  end
end
