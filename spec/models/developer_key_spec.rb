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

  describe 'callbacks' do
    describe 'public_jwk validations' do
      subject do
        developer_key_saved.save
      end

      before { developer_key_saved.generate_rsa_keypair! }

      context 'when the kty is not "RSA"' do
        before { developer_key_saved.public_jwk['kty'] = 'foo' }

        it { is_expected.to eq false }
      end

      context 'when the alg is not "RS256"' do
        before { developer_key_saved.public_jwk['alg'] = 'foo' }

        it { is_expected.to eq false }
      end

      context 'when required claims are missing' do
        before { developer_key_saved.update public_jwk: {foo: 'bar'} }

        it { is_expected.to eq false }
      end
    end

    it 'does validate scopes' do
      expect do
        DeveloperKey.create!(
          scopes: ['not_a_valid_scope']
        )
      end.to raise_exception ActiveRecord::RecordInvalid
    end

    context 'when api token scoping FF is enabled' do
      let(:valid_scopes) do
        %w(url:POST|/api/v1/courses/:course_id/quizzes/:id/validate_access_code
          url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id/graders/:grader_id)
      end

      describe 'after_update' do
        let(:user) { user_model }
        let(:developer_key_with_scopes) { DeveloperKey.create!(scopes: valid_scopes) }
        let(:access_token) { user.access_tokens.create!(developer_key: developer_key_with_scopes) }
        let(:valid_scopes) do
          [
            "url:GET|/api/v1/courses/:course_id/quizzes",
            "url:GET|/api/v1/courses/:course_id/quizzes/:id",
            "url:GET|/api/v1/courses/:course_id/users",
            "url:GET|/api/v1/courses/:id",
            "url:GET|/api/v1/users/:user_id/profile",
            "url:POST|/api/v1/courses/:course_id/assignments",
            "url:POST|/api/v1/courses/:course_id/quizzes",
          ]
        end

        before { access_token }

        it 'deletes its associated access tokens if scopes are removed' do
          developer_key_with_scopes.update!(scopes: [valid_scopes.first])
          expect(developer_key_with_scopes.access_tokens).to be_empty
        end

        it 'does not delete its associated access tokens if scopes are not changed' do
          developer_key_with_scopes.update!(email: 'test@test.com')
          expect(developer_key_with_scopes.access_tokens).to match_array [access_token]
        end

        it 'does not delete its associated access tokens if a new scope was added' do
          developer_key_with_scopes.update!(scopes: valid_scopes.push("url:PUT|/api/v1/courses/:course_id/quizzes/:id"))
          expect(developer_key_with_scopes.access_tokens).to match_array [access_token]
        end
      end

      it 'raises an error if scopes contain invalid scopes' do
        expect do
          DeveloperKey.create!(
            scopes: ['not_a_valid_scope']
          )
        end.to raise_exception('Validation failed: Scopes cannot contain not_a_valid_scope')
      end

      it 'does not raise an error if all scopes are valid scopes' do
        expect do
          DeveloperKey.create!(
            scopes: valid_scopes
          )
        end.not_to raise_exception
      end

      it 'does not set "require_scopes" to true if scopes are present and require_scopes is false' do
        key = DeveloperKey.create!(scopes: valid_scopes, require_scopes: false)
        expect(key.require_scopes).to eq false
      end

      it 'does not set "require_scopes" to false if scopes are blank and require_scopes is true' do
        key = DeveloperKey.create!(require_scopes: true)
        expect(key.require_scopes).to eq true
      end
    end

    context 'when site admin' do
      it 'it creates a binding on save' do
        key = DeveloperKey.create!(account: nil)
        expect(key.developer_key_account_bindings.find_by(account: Account.site_admin)).to be_present
      end
    end

    context 'when not site admin' do
      it 'it creates a binding on save' do
        key = DeveloperKey.create!(account: account)
        expect(key.developer_key_account_bindings.find_by(account: account)).to be_present
      end
    end
  end

  describe 'associations' do
    let(:developer_key_account_binding) { developer_key_saved.developer_key_account_bindings.first }

    it 'destroys developer key account bindings when destroyed' do
      binding_id = developer_key_account_binding.id
      developer_key_saved.destroy_permanently!
      expect(DeveloperKeyAccountBinding.find_by(id: binding_id)).to be_nil
    end

    it 'has many context external tools' do
      tool = ContextExternalTool.create!(
        context: account,
        consumer_key: 'key',
        shared_secret: 'secret',
        name: 'test tool',
        url: 'http://www.tool.com/launch',
        developer_key: developer_key_saved
      )
      expect(developer_key_saved.context_external_tools).to match_array [
        tool
      ]
    end
  end

  describe '#account_binding_for' do
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }
    let(:root_account_key) { DeveloperKey.create!(account: root_account) }
    let(:root_account) { account_model }

    context 'when account passed is nil' do
      it 'returns nil' do
        expect(site_admin_key.account_binding_for(nil)).to be_nil
        expect(root_account_key.account_binding_for(nil)).to be_nil
      end
    end

    context 'when site admin' do
      context 'when binding state is "allow"' do
        before do
          site_admin_key.developer_key_account_bindings.create!(
            account: root_account, workflow_state: DeveloperKeyAccountBinding::ALLOW_STATE
          )
        end

        it 'finds the site admin binding when requesting site admin account' do
          binding = site_admin_key.account_binding_for(Account.site_admin)
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the root account binding when requesting root account' do
          site_admin_key.developer_key_account_bindings.first.update!(workflow_state: DeveloperKeyAccountBinding::ALLOW_STATE)
          binding = site_admin_key.account_binding_for(root_account)
          expect(binding.account).to eq root_account
        end
      end

      context 'when binding state is "on" or "off"' do
        before do
          site_admin_key.developer_key_account_bindings.create!(account: root_account, workflow_state: 'on')
          sa_binding = site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin)
          sa_binding.update!(workflow_state: 'off')
        end

        it 'finds the site admin binding when requesting site admin account' do
          binding = site_admin_key.account_binding_for(Account.site_admin)
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the site admin binding when requesting root account' do
          binding = site_admin_key.account_binding_for(root_account)
          expect(binding.account).to eq Account.site_admin
        end
      end
    end

    context 'when not site admin' do
      context 'when binding state is "allow"' do
        it 'finds the root account binding when requesting root account' do
          binding = root_account_key.account_binding_for(root_account)
          expect(binding.account).to eq root_account
        end
      end

      context 'when binding state is "on" or "off"' do
        before do
          root_account_key.developer_key_account_bindings.create!(account: Account.site_admin, workflow_state: 'on')
          ra_binding = root_account_key.developer_key_account_bindings.find_by(account: root_account)
          ra_binding.update!(workflow_state: 'off')
        end

        it 'finds the site admin binding when requesting site admin account' do
          binding = root_account_key.account_binding_for(Account.site_admin)
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the root account binding when requesting root account' do
          binding = root_account_key.account_binding_for(root_account)
          expect(binding.account).to eq root_account
        end
      end
    end

    context 'sharding' do
      specs_require_sharding

      let(:root_account_shard) { Shard.create! }
      let(:root_account) { root_account_shard.activate { account_model } }
      let(:sa_developer_key) { Account.site_admin.shard.activate { DeveloperKey.create!(name: 'SA Key') } }
      let(:root_account_binding) do
        root_account_shard.activate do
          DeveloperKeyAccountBinding.create!(
            account_id: root_account.id,
            developer_key_id: sa_developer_key.global_id
          )
        end
      end
      let(:sa_account_binding) { sa_developer_key.developer_key_account_bindings.find_by(account: Account.site_admin) }

      context 'when developer key binding is on the site admin shard' do
        it 'finds the site admin binding if it is set to "on"' do
          root_account_binding.update!(workflow_state: 'on')
          sa_account_binding.update!(workflow_state: 'off')
          binding = root_account_shard.activate { sa_developer_key.account_binding_for(root_account) }
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the site admin binding if it is set to "off"' do
          root_account_binding.update!(workflow_state: 'off')
          sa_account_binding.update!(workflow_state: 'on')
          binding = root_account_shard.activate { sa_developer_key.account_binding_for(root_account) }
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the root account binding if site admin binding is set to "allow"' do
          root_account_binding.update!(workflow_state: 'on')
          sa_account_binding.update!(workflow_state: 'allow')
          binding = root_account_shard.activate { sa_developer_key.account_binding_for(root_account) }
          expect(binding.account).to eq root_account
        end
      end
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

  describe '#generate_rsa_keypair!' do
    context 'when "public_jwk" is already set' do
      subject do
        developer_key.generate_rsa_keypair!
        developer_key
      end

      let(:developer_key) do
        key = DeveloperKey.create!
        key.generate_rsa_keypair!
        key.save!
        key
      end
      let(:public_jwk) { developer_key.public_jwk }

      context 'when "override" is false' do
        it 'does not change the "public_jwk"' do
          expect(subject.public_jwk).to eq public_jwk
        end

        it 'does not change the "private_jwk" attribute' do
          previous_private_key = developer_key.private_jwk
          expect(subject.private_jwk).to eq previous_private_key
        end
      end

      context 'when "override: is true' do
        subject do
          developer_key.generate_rsa_keypair!(overwrite: true)
          developer_key
        end

        it 'does change the "public_jwk"' do
          previous_public_key = developer_key.public_jwk
          expect(subject.public_jwk).not_to eq previous_public_key
        end

        it 'does change the "private_jwk"' do
          previous_private_key = developer_key.private_jwk
          expect(subject.private_jwk).not_to eq previous_private_key
        end
      end
    end

    context 'when "public_jwk" is not set' do
      subject { DeveloperKey.new }

      before { subject.generate_rsa_keypair! }

      it 'populates the "public_jwk" column with a public key' do
        expect(subject.public_jwk['kty']).to eq Lti::RSAKeyPair::KTY
      end

      it 'populates the "private_jwk" attribute with a private key' do
        expect(subject.private_jwk['kty']).to eq Lti::RSAKeyPair::KTY.to_sym
      end
    end
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
        enable_developer_key_account_binding!(@key)
      end

      include_examples "authorized_for_account?"

      describe '#by_cached_vendor_code' do
        let(:vendor_code) { 'tool vendor code' }
        let(:not_site_admin_shard) { Shard.create! }

        it 'finds keys in the site admin shard' do
          site_admin_key = nil

          Account.site_admin.shard.activate do
            site_admin_key = DeveloperKey.create!(vendor_code: vendor_code)
          end

          not_site_admin_shard.activate do
            expect(DeveloperKey.by_cached_vendor_code(vendor_code)).to include site_admin_key
          end
        end

        it 'finds keys in the current shard' do
          local_key = DeveloperKey.create!(vendor_code: vendor_code, account: account_model)
          expect(DeveloperKey.by_cached_vendor_code(vendor_code)).to include local_key
        end
      end
    end

    context 'without sharding' do
      before :once do
        @account = Account.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b", account: @account)
        enable_developer_key_account_binding!(@key)
      end

      include_examples "authorized_for_account?"
    end
  end

  it "doesn't allow the default key to be deleted" do
    expect { DeveloperKey.default.destroy }.to raise_error "Please never delete the default developer key"
    expect { DeveloperKey.default.deactivate }.to raise_error "Please never delete the default developer key"
  end
end
