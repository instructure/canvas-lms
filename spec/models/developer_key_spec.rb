#
# Copyright (C) 2011 - present Instructure, Inc.
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
  let(:account) { Account.create! }

  let(:developer_key_saved) do
    DeveloperKey.create(
      name:         'test',
      email:        'test@test.com',
      redirect_uri: 'http://test.com',
      account_id:    account.id
    )
  end

  # Tests that use this key will run faster because they don't need to
  # save an account and a developer_key to the db
  let(:developer_key_not_saved) do
    DeveloperKey.new(
      name:         'test',
      email:        'test@test.com',
      redirect_uri: 'http://test.com',
    )
  end

  describe "sets a default value" do
    it "when visible is not specified" do
      expect(developer_key_not_saved.valid?).to eq(true)
      expect(developer_key_not_saved.visible).to eq(false)
    end

    it "is false for site admin generated keys" do
      key = DeveloperKey.create!(
        name:         'test',
        email:        'test@test.com',
        redirect_uri: 'http://test.com',
        account_id:   nil
      )

      expect(key.visible).to eq(false)
    end

    it "is true for non site admin generated keys" do
      key = DeveloperKey.create!(
        name:         'test',
        email:        'test@test.com',
        redirect_uri: 'http://test.com',
        account_id:   account.id
      )

      expect(key.visible).to eq(true)
    end
  end

  describe "default" do
    context "sharding" do
      specs_require_sharding

      it "should always create the default key on the default shard" do
        @shard1.activate do
          expect(DeveloperKey.default.shard).to be_default
        end
      end

      it 'sets new developer keys to auto expire tokens' do
        expect(developer_key_saved.auto_expire_tokens).to be_truthy
      end

      it 'uses integer special keys properly because the query does not like strings' do
        # this test mirrors what happens in production when retrieving keys, but does not test it
        # directly because there's a short circuit clause in 'get_special_key' that pops out with a
        # different finder because of the transactions-in-test issue. this confirms that setting
        # a key id does not translate it to a string and therefore can be used with 'where(id: key_id)'
        # safely

        Setting.set('rspec_developer_key_id', developer_key_saved.id)
        key_id = Setting.get('rspec_developer_key_id', nil)
        expect(DeveloperKey.where(id: key_id).first).to eq(developer_key_saved)
      end
    end
  end

  it "allows non-http redirect URIs" do
    developer_key_not_saved.redirect_uri = 'tealpass://somewhere.edu/authentication'
    developer_key_not_saved.redirect_uris = ['tealpass://somewhere.edu/authentication']
    expect(developer_key_not_saved).to be_valid
  end

  it "returns the correct count of access_tokens" do
    expect(developer_key_saved.access_token_count).to eq 0

    AccessToken.create!(:user => user_model, :developer_key => developer_key_saved)
    AccessToken.create!(:user => user_model, :developer_key => developer_key_saved)
    AccessToken.create!(:user => user_model, :developer_key => developer_key_saved)

    expect(developer_key_saved.access_token_count).to eq 3
  end

  it "returns the last_used_at value for a key" do
    expect(developer_key_saved.last_used_at).to be_nil
    at = AccessToken.create!(:user => user_model, :developer_key => developer_key_saved)
    at.used!
    expect(developer_key_saved.last_used_at).not_to be_nil
  end

  describe "#redirect_domain_matches?" do
    it "should match domains exactly, and sub-domains" do
      developer_key_not_saved.redirect_uri = "http://example.com/a/b"

      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/a/b")).to be_truthy

      # other paths on the same domain are ok
      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/other")).to be_truthy

      # completely separate domain
      expect(developer_key_not_saved.redirect_domain_matches?("http://example2.com/a/b")).to be_falsey

      # not a sub-domain
      expect(developer_key_not_saved.redirect_domain_matches?("http://wwwexample.com/a/b")).to be_falsey
      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com.evil/a/b")).to be_falsey
      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com.evil/a/b")).to be_falsey

      # sub-domains are ok
      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com/a/b")).to be_truthy
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/a/b")).to be_truthy
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/other")).to be_truthy
    end

    it "does not allow subdomains when it matches in redirect_uris" do
      developer_key_not_saved.redirect_uris << "http://example.com/a/b"

      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/a/b")).to eq true

      # other paths on the same domain are NOT ok
      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/other")).to eq false
      # sub-domains are not ok either
      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com/a/b")).to eq false
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/a/b")).to eq false
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/other")).to eq false
    end
  end

  context "Account scoped keys" do
    shared_examples "authorized_for_account?" do

      it "should allow access to its own account" do
        expect(@key.authorized_for_account?(Account.find(@account.id))).to be true
      end

      it "shouldn't allow access to a foreign account" do
        expect(@key.authorized_for_account?(@not_sub_account)).to be false
      end

      it "allows access if the account is in its account chain" do
        sub_account = Account.create!(parent_account: @account)
        expect(@key.authorized_for_account?(sub_account)).to be true
      end
    end

    context 'with sharding' do
      specs_require_sharding

      before :once do
        @account = Account.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b", account: @account)
      end

      include_examples "authorized_for_account?"

      describe '#by_cached_vendor_code' do
        let(:vendor_code) { 'tool vendor code' }
        let(:not_site_admin_shard) { Shard.create! }

        it 'finds keys in the current shard and site admin shard' do
          site_admin_key = nil
          local_key = nil

          Account.site_admin.shard.activate do
            site_admin_key = DeveloperKey.create!(vendor_code: vendor_code)
          end
          not_site_admin_shard.activate do
            local_key = DeveloperKey.create!(vendor_code: vendor_code)
            expect(DeveloperKey.by_cached_vendor_code(vendor_code)).to include local_key
            expect(DeveloperKey.by_cached_vendor_code(vendor_code)).to include site_admin_key
          end
        end
      end
    end

    context 'without sharding' do
      before :once do
        @account = Account.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b", account: @account)
      end

      include_examples "authorized_for_account?"
    end
  end

  it "doesn't allow the default key to be deleted" do
    expect { DeveloperKey.default.destroy }.to raise_error "Please never delete the default developer key"
    expect { DeveloperKey.default.deactivate }.to raise_error "Please never delete the default developer key"
  end
end
