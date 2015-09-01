#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe DeveloperKey do
  describe "default" do
    context "sharding" do
      specs_require_sharding

      it "should always create the default key on the default shard" do
        @shard1.activate do
          expect(DeveloperKey.default.shard).to be_default
        end
      end

      it 'uses integer special keys properly because the query does not like strings' do
        # this test mirrors what happens in production when retrieving keys, but does not test it
        # directly because there's a short circuit clause in 'get_special_key' that pops out with a
        # different finder because of the transactions-in-test issue. this confirms that setting
        # a key id does not translate it to a string and therefore can be used with 'where(id: key_id)'
        # safely
        key = DeveloperKey.create!
        Setting.set('rspec_developer_key_id', key.id)
        key_id = Setting.get('rspec_developer_key_id', nil)
        expect(DeveloperKey.where(id: key_id).first).to eq key
      end
    end
  end

  describe "#redirect_domain_matches?" do
    it "should match domains exactly, and sub-domains" do
      key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b")
      expect(key.redirect_domain_matches?("http://example.com/a/b")).to be_truthy
      # other paths on the same domain are ok
      expect(key.redirect_domain_matches?("http://example.com/other")).to be_truthy
      # completely separate domain
      expect(key.redirect_domain_matches?("http://example2.com/a/b")).to be_falsey
      # not a sub-domain
      expect(key.redirect_domain_matches?("http://wwwexample.com/a/b")).to be_falsey
      expect(key.redirect_domain_matches?("http://example.com.evil/a/b")).to be_falsey
      expect(key.redirect_domain_matches?("http://www.example.com.evil/a/b")).to be_falsey
      # sub-domains are ok
      expect(key.redirect_domain_matches?("http://www.example.com/a/b")).to be_truthy
      expect(key.redirect_domain_matches?("http://a.b.example.com/a/b")).to be_truthy
      expect(key.redirect_domain_matches?("http://a.b.example.com/other")).to be_truthy
    end
  end

  context "Account scoped keys" do

    shared_examples "authorized_for_account?" do

      it "should allow allow access to its own account" do
        expect(@key.authorized_for_account?(Account.find(@account.id))).to be true
      end

      it "should allow allow access to ita accounts sub accounts" do
        expect(@key.authorized_for_account?(@sub_account1)).to be true
        expect(@key.authorized_for_account?(@sub_account2)).to be true
      end
      it "shouldn't allow allow access to a foreign account" do
        expect(@key.authorized_for_account?(@not_sub_account)).to be false
      end
    end

    context 'with sharding' do
      specs_require_sharding

      before :once do
        @account = Account.create!

        @shard1.activate do
          @sub_account1 = @account.sub_accounts.create!
          @sub_account2 = @account.sub_accounts.create!
        end

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b", account: @account)
      end

      include_examples "authorized_for_account?"
    end

    context 'without sharding' do
      before :once do
        @account = Account.create!
        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @account.sub_accounts.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b", account: @account)
      end

      include_examples "authorized_for_account?"
    end
  end
end
