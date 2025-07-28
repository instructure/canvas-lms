# frozen_string_literal: true

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

describe Pseudonym do
  describe ".normalize" do
    delegate :normalize, to: :Pseudonym

    it "normalizes according to RFC4518" do
      # Ⅳ ligature gets decomposed to IV (and downcased)
      expect(normalize("Ⅳ")).to eql "iv"
      expect(normalize("interior  spaces")).to eql "interior spaces"
      expect(normalize("  leading")).to eql "leading"
      expect(normalize("trailing  ")).to eql "trailing"
      expect(normalize("  leading  trailing Ⅳ  ")).to eql "leading trailing iv"
      expect(normalize(" ")).to eql " "
      expect(normalize("   ")).to eql " "
      expect(normalize("\u200fcody")).to eql "cody"
      expect(normalize("cody\u200f")).to eql "cody"
      expect(normalize("\u202a\u202a\u202acody\u202c\u202c\u202c")).to eql "cody"
      expect(normalize("\u200f\u202acody\u202c\u200f")).to eql "cody"
    end
  end

  it "creates a new instance given valid attributes" do
    user_model
    expect { Pseudonym.create!(valid_pseudonym_attributes) }.to change(Pseudonym, :count).by(1)
  end

  it "allows single character usernames" do
    user_model
    pseudonym_model
    @pseudonym.unique_id = "c"
    expect(@pseudonym.save).to be true
  end

  it "allows a username that starts with a special character" do
    user_model
    pseudonym_model
    @pseudonym.unique_id = "+c"
    expect(@pseudonym.save).to be true
  end

  it "allows apostrophes in usernames" do
    pseudonym = Pseudonym.new(unique_id: "o'brien@example.com",
                              password: "password",
                              password_confirmation: "password")
    pseudonym.user_id = 1
    expect(pseudonym).to be_valid
  end

  it "normalizes on validation (preserving the original input)" do
    # Ⅳ ligature gets decomposed to IV
    pseudonym = Pseudonym.new(unique_id: "HenryⅣ@instructure.com",
                              password: "password",
                              password_confirmation: "password")
    pseudonym.user_id = 1
    expect(pseudonym).to be_valid
    expect(pseudonym.unique_id).to eql "HenryⅣ@instructure.com"
    expect(pseudonym.unique_id_normalized).to eql "henryiv@instructure.com"
  end

  it "validates the presence of user and infer default account" do
    Account.default
    u = User.create!
    p = Pseudonym.new(unique_id: "cody@instructure.com")
    expect(p.save).to be_falsey

    p.user_id = u.id
    expect(p.save).to be_truthy
    expect(p.account_id).to eq Account.default.id

    # make sure a password was generated
    expect(p.password).not_to be_nil
    expect(p.password).not_to match(/tmp-pw/)
    expect(p.login_attribute).to be_nil
  end

  it "does not allow active duplicates" do
    u = User.create!
    p1 = Pseudonym.create!(unique_id: "cody@instructure.com", user: u)
    p2 = Pseudonym.create(unique_id: "cody@instructure.com", user: u)
    # Failed; p1 is still active
    expect(p2).to be_new_record
    p2.workflow_state = "deleted"
    p2.save!
    # Duplicates okay in the deleted state
    p1.workflow_state = "deleted"
    p1.save!
    # Should allow creating a new active one if the others are deleted
    Pseudonym.create!(unique_id: "cody@instructure.com", user: u)

    # Failed; conflicts with the nil auth provider version
    expect do
      Pseudonym.create!(unique_id: "cody@instructure.com",
                        user: u,
                        authentication_provider: Account.default.canvas_authentication_provider)
    end.to raise_error(ActiveRecord::RecordInvalid)
    Pseudonym.create!(unique_id: "cody2@instructure.com",
                      user: u,
                      authentication_provider: Account.default.canvas_authentication_provider)
    # Failed; conflicts with the canvas auth provider version
    expect do
      Pseudonym.create!(unique_id: "cody2@instructure.com", user: u)
    end.to raise_error(ActiveRecord::RecordInvalid)

    saml1 = Account.default.authentication_providers.create!(auth_type: "saml")
    saml2 = Account.default.authentication_providers.create!(auth_type: "saml")

    # duplicates across SAML auth providers or SAML-and-Canvas are okay
    Pseudonym.create!(unique_id: "cody3@instructure.com", user: u, authentication_provider: saml1)
    Pseudonym.create!(unique_id: "cody3@instructure.com", user: u, authentication_provider: saml2)
    Pseudonym.create!(unique_id: "cody2@instructure.com", user: u, authentication_provider: saml1)

    # duplicates between no auth provider and SAML are not okay
    # and vice versa
    expect { Pseudonym.create!(unique_id: "cody@instructure.com", user: u, authentication_provider: saml1) }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect { Pseudonym.create!(unique_id: "cody3@instructure.com", user: u) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows deleted duplicates" do
    saml = Account.default.authentication_providers.create!(auth_type: "saml")
    canvas = Account.default.canvas_authentication_provider
    u = User.create!

    # each of these cases creates an active pseudonym, then two deleted, then vice verse
    # in order to ensure the trigger is okay with multiples, and order of creation
    # doesn't matter

    # duplication within the same auth provider
    Pseudonym.create!(unique_id: "a@instructure.com", user: u)
    Pseudonym.create!(unique_id: "a@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "a@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "b@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "b@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "b@instructure.com", user: u)
    Pseudonym.create!(unique_id: "c@instructure.com", user: u, authentication_provider: saml)
    Pseudonym.create!(unique_id: "c@instructure.com", user: u, authentication_provider: saml, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "c@instructure.com", user: u, authentication_provider: saml, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "d@instructure.com", user: u, authentication_provider: saml, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "d@instructure.com", user: u, authentication_provider: saml, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "d@instructure.com", user: u, authentication_provider: saml)
    Pseudonym.create!(unique_id: "c@instructure.com", user: u, authentication_provider: canvas)
    Pseudonym.create!(unique_id: "c@instructure.com", user: u, authentication_provider: canvas, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "c@instructure.com", user: u, authentication_provider: canvas, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "d@instructure.com", user: u, authentication_provider: canvas, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "d@instructure.com", user: u, authentication_provider: canvas, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "d@instructure.com", user: u, authentication_provider: canvas)

    # duplication across a specific auth provider and no auth provider
    Pseudonym.create!(unique_id: "e@instructure.com", user: u, authentication_provider: saml)
    Pseudonym.create!(unique_id: "e@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "e@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "f@instructure.com", user: u)
    Pseudonym.create!(unique_id: "f@instructure.com", user: u, authentication_provider: saml, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "f@instructure.com", user: u, authentication_provider: saml, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "g@instructure.com", user: u, authentication_provider: canvas)
    Pseudonym.create!(unique_id: "g@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "g@instructure.com", user: u, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "h@instructure.com", user: u)
    Pseudonym.create!(unique_id: "h@instructure.com", user: u, authentication_provider: canvas, workflow_state: "deleted")
    Pseudonym.create!(unique_id: "h@instructure.com", user: u, authentication_provider: canvas, workflow_state: "deleted")
  end

  it "does not allow a login_attribute without an authentication provider" do
    u = User.create!
    expect { u.pseudonyms.create!(unique_id: "a@b.com", login_attribute: "b") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "infers the login_attribute on a new pseudonym for an auth provider that uses them" do
    u = User.create!
    ap = Account.default.authentication_providers.create!(auth_type: "microsoft", tenant: "microsoft")
    p = u.pseudonyms.create!(unique_id: "a@b.com", authentication_provider: ap)
    expect(p.login_attribute).to eq "sub"

    p.update!(authentication_provider_id: nil)
    expect(p.reload.login_attribute).to be_nil
  end

  describe ".by_unique_id" do
    it "finds the correct pseudonym for logins" do
      user = User.create!
      p1 = Pseudonym.create!(unique_id: "Cody@instructure.com", user:)
      Pseudonym.create!(unique_id: "codY@instructure.com", user:) { |p| p.workflow_state = "deleted" }
      expect(Pseudonym.active.by_unique_id("cody@instructure.com").first).to eq p1
      account = Account.create!
      p3 = Pseudonym.create!(unique_id: "cOdy@instructure.com", account:, user:)
      expect(Pseudonym.active.by_unique_id("cody@instructure.com").sort).to eq [p1, p3]
      p4 = Pseudonym.create!(unique_id: "c①dy@instructure.com", account:, user:)
      expect(Pseudonym.active.by_unique_id("c①dy@instructure.com")).to eq [p4]

      scope = Pseudonym.active
      shard = instance_double(Shard)
      allow(shard).to receive(:settings).and_return({})
      allow(shard).to receive(:is_a?).with(Shard).and_return(true)
      allow(shard).to receive(:is_a?).with(Switchman::DefaultShard).and_return(false)
      # return our double once for the named scope, then the real thing for the query
      allow(scope).to receive(:primary_shard).and_return(shard, Shard.default)
      expect(scope.by_unique_id("c1dy@instructure.com")).not_to exist

      # mark the migration as complete, and it will start doing a normalized lookup
      allow(shard).to receive(:settings).and_return({ "pseudonyms_normalized" => true })
      allow(scope).to receive(:primary_shard).and_return(shard, Shard.default)
      expect(scope.by_unique_id("c1dy@instructure.com")).to eq [p4]
    end

    it "does not blow up if by_unique_id is passed a non-string" do
      expect(Pseudonym.active.by_unique_id(123)).to eq []
    end
  end

  it "associates to another user" do
    user_model
    pseudonym_model
    expect(@pseudonym.user).to eql(@user)
  end

  it "orders by position" do
    user_model
    p1 = pseudonym_model(user_id: @user.id)
    p2 = pseudonym_model(user_id: @user.id)
    p3 = pseudonym_model(user_id: @user.id)
    p1.move_to_bottom
    p3.move_to_top
    expect(Pseudonym.all.sort.map(&:id)).to eql([p3.id, p2.id, p1.id])
  end

  it "updates user account associations on CRUD" do
    account_model
    user_model
    account1 = account_model
    account_model
    expect(@user.user_account_associations.length).to be(0)

    pseudonym_model(user: @user, account: account1)
    @user.reload
    expect(@user.user_account_associations.length).to be(1)
    expect(@user.user_account_associations.first.account).to eql(account1)

    account2 = account_model
    @pseudonym.account = account2
    @pseudonym.save
    @user.reload
    expect(@user.user_account_associations.length).to be(1)
    expect(@user.user_account_associations.first.account).to eql(account2)

    @pseudonym.destroy
    @user.reload
    expect(@user.user_account_associations).to eq []
  end

  describe "#encryption_type" do
    subject(:encryption_type) { pseudonym.encryption_type }

    let(:pseudonym) { pseudonym_model }

    context "when crypted_password is blank" do
      before { pseudonym.update_column(:crypted_password, "") }

      it { is_expected.to be_nil }
    end

    context "when sis_ssha is present" do
      before { pseudonym.update_column(:sis_ssha, "$SSHA$Q0pF5X/UfUyxZQ2FZgFzYmFhZGViYTRkYTAyMzg3ZjE=$") }

      it { is_expected.to eq :SSHA }
    end

    context "when crypted_password is scrypt" do
      let(:scrypt_password) { ScryptProvider.new("4000$8$1$").encrypt("plaintext_password") }

      before { pseudonym.update_column(:crypted_password, scrypt_password) }

      it { is_expected.to eq :SCRYPT }
    end

    context "when crypted_password is sha512" do
      let(:sha512_password) { Authlogic::CryptoProviders::Sha512.encrypt("plaintext_password") }

      before { pseudonym.update_column(:crypted_password, sha512_password) }

      it { is_expected.to eq :SHA512 }
    end

    context "when the encryption type is not recognized" do
      before { pseudonym.update_column(:crypted_password, "unknown_encryption_type") }

      it { is_expected.to eq :UNKNOWN }
    end
  end

  describe "#destroy" do
    it "allows deleting pseudonyms" do
      user_with_pseudonym(active_all: true)
      expect(@pseudonym.destroy).to be(true)
      expect(@pseudonym).to be_deleted
    end

    it "records an audit log record" do
      pseudonym_model
      @pseudonym.destroy
      expect(@pseudonym.auditor_records.where(action: "deleted")).to exist
    end

    context "with current_user specified" do
      it "records an audit log with the current_user" do
        pseudonym_model
        performing_user = user_model
        @pseudonym.current_user = performing_user
        @pseudonym.destroy
        expect(@pseudonym.auditor_records.where(action: "deleted", performing_user: performing_user.id)).to exist
      end
    end

    context "with additional arguments" do
      let(:pseudonym) { pseudonym_model }

      it "passes additional arguments to #save" do
        expect(pseudonym).to receive(:save).with(validate: false)

        pseudonym.destroy(custom_deleted_at: Time.now.utc, validate: false)
      end
    end
  end

  it "allows deleting system-generated pseudonyms" do
    user_with_pseudonym(active_all: true)
    @pseudonym.sis_user_id = "something_cool"
    @pseudonym.save!
    @pseudonym.account.authentication_providers.create!(auth_type: "ldap")
    expect(@pseudonym.destroy).to be(true)
    expect(@pseudonym).to be_deleted
  end

  it "defaults to nil for blank integration_id and sis_user_id" do
    user_factory
    pseudonym = Pseudonym.new(user: @user, unique_id: "test@example.com", password: "passwd123")
    pseudonym.password_confirmation = "passwd123"
    pseudonym.sis_user_id = ""
    pseudonym.integration_id = ""
    expect(pseudonym).to be_valid
    expect(pseudonym.sis_user_id).to be_nil
    expect(pseudonym.integration_id).to be_nil
  end

  context "LDAP errors" do
    before :once do
      require "net/ldap"
      user_with_pseudonym(active_all: true)
      @aac = @pseudonym.account.authentication_providers.create!(
        auth_type: "ldap",
        auth_base: "ou=people,dc=example,dc=com",
        auth_host: "ldap.example.com",
        auth_username: "cn=query,dc=example,dc=com",
        auth_port: 636,
        auth_filter: "(uid={{login}})",
        auth_over_tls: true
      )
    end

    it "gracefully handles unreachable LDAP servers" do
      expect_any_instance_of(Net::LDAP).to receive(:bind_as).and_raise(Net::LDAP::Error, "no connection to server")
      expect(Canvas::Errors).to receive(:capture) do |ex, data, level|
        expect(ex.class).to eq(Net::LDAP::Error)
        expect(data[:account]).to eq(@pseudonym.account)
        expect(level).to eq(:warn)
      end.and_call_original
      expect { @pseudonym.ldap_bind_result("blech") }.not_to raise_error
    end

    it "passes a success result through" do
      expect_any_instance_of(Net::LDAP).to receive(:bind_as).and_return(true)
      expect(@pseudonym.ldap_bind_result("yay!")).to be_truthy
    end

    it "sets last_timeout_failure on LDAP servers that timeout" do
      expect_any_instance_of(Net::LDAP).to receive(:bind_as).once.and_raise(Timeout::Error, "timed out")
      expect(Canvas::Errors).to receive(:capture_exception) do |_subsystem, e, level|
        expect(e.class.to_s).to eq("Timeout::Error")
        expect(level).to eq(:warn)
      end
      expect(@pseudonym.ldap_bind_result("test")).to be_falsey
      expect(@aac.reload.last_timeout_failure).to be > 1.minute.ago
    end

    it "only checks an explicit LDAP provider" do
      aac2 = @pseudonym.account.authentication_providers.create!(auth_type: "ldap")
      @pseudonym.update_attribute(:authentication_provider, aac2)
      expect_any_instantiation_of(@aac).not_to receive(:ldap_bind_result)
      expect(aac2).to receive(:ldap_bind_result).and_return(42)
      expect(@pseudonym.ldap_bind_result("stuff")).to eq 42
    end

    it "doesn't even check LDAP for a Canvas pseudonym" do
      @pseudonym.update_attribute(:authentication_provider, @pseudonym.account.canvas_authentication_provider)
      expect_any_instantiation_of(@aac).not_to receive(:ldap_bind_result)
      expect(@pseudonym.ldap_bind_result("stuff")).to be_nil
    end
  end

  it "does not error on malformed SSHA password" do
    pseudonym_model
    @pseudonym.sis_ssha = "{SSHA}garbage"
    expect(@pseudonym.valid_ssha?("garbage")).to be_falsey
  end

  it "does not attempt validating a blank password" do
    pseudonym_model
    expect(@pseudonym).not_to receive(:sis_ssha)
    @pseudonym.valid_ssha?("")

    expect(@pseudonym).not_to receive(:ldap_bind_result)
    @pseudonym.valid_ldap_credentials?("")
  end

  context "Needs a pseudonym with an active user" do
    before :once do
      user_model
      pseudonym_model
    end

    it "offers the user code as the user's uuid" do
      expect(@pseudonym.user).to eql(@user)
      expect(@pseudonym.user_code).to eql(@user.uuid)
    end

    it "is able to change the user email" do
      @pseudonym.email = "admin@example.com"
      @pseudonym.reload
      expect(@pseudonym.user.email_channel.path).to eql("admin@example.com")
    end

    it "offers the user sms if there is one" do
      communication_channel_model(path_type: "sms")
      @user.communication_channels << @cc
      @user.save!
      expect(@user.sms).to eql(@cc.path)
      expect(@pseudonym.sms).to eql(@user.sms)
    end
  end

  it "determines if the password is managed" do
    u = User.create!
    p = Pseudonym.create!(unique_id: "jt@instructure.com", user: u)
    p.sis_user_id = "jt"
    expect(p).not_to be_managed_password
    ap = p.account.authentication_providers.create!(auth_type: "ldap")
    expect(p).to be_managed_password
    p.sis_user_id = nil
    expect(p).not_to be_managed_password
    p.authentication_provider = ap
    expect(p).to be_managed_password
    p.sis_user_id = "jt"
    p.authentication_provider = p.account.canvas_authentication_provider
  end

  it "determines if the password is settable" do
    u = User.create!
    p = Pseudonym.create!(unique_id: "jt@instructure.com", user: u)
    expect(p).to be_passwordable
    ap = p.account.authentication_providers.create!(auth_type: "ldap")
    expect(p).to be_passwordable
    p.authentication_provider = ap
    expect(p).to_not be_passwordable
    p.account.canvas_authentication_provider.destroy
    p.authentication_provider = nil
    p.save!
    p.reload
    expect(p).to_not be_passwordable
  end

  context "login assertions" do
    it "creates a CC if LDAP gave an e-mail we don't have" do
      account = Account.create!
      account.authentication_providers.create!(auth_type: "ldap")
      u = User.create!
      u.register
      pseudonym = u.pseudonyms.create!(unique_id: "jt", account:) { |p| p.sis_user_id = "jt" }
      pseudonym.instance_variable_set(:@ldap_result, { mail: ["jt@instructure.com"] })

      pseudonym.add_ldap_channel
      u.reload
      expect(u.communication_channels.length).to eq 1
      expect(u.email_channel.path).to eq "jt@instructure.com"
      expect(u.email_channel).to be_active
      u.email_channel.destroy

      pseudonym.add_ldap_channel
      u.reload
      expect(u.communication_channels.length).to eq 1
      expect(u.email_channel.path).to eq "jt@instructure.com"
      expect(u.email_channel).to be_active
      u.email_channel.update_attribute(:workflow_state, "unconfirmed")

      pseudonym.add_ldap_channel
      u.reload
      expect(u.communication_channels.length).to eq 1
      expect(u.email_channel.path).to eq "jt@instructure.com"
      expect(u.email_channel).to be_active
    end

    it "does not persist the auth provider if inferred" do
      account = Account.create!
      ap = account.authentication_providers.create!(auth_type: "ldap")
      u = User.create!
      u.register
      pseudonym = u.pseudonyms.create!(unique_id: "jt", account:) { |p| p.sis_user_id = "jt" }
      pseudonym.instance_variable_set(:@ldap_result, { mail: ["jt@instructure.com"] })

      pseudonym.infer_auth_provider(ap)
      pseudonym.add_ldap_channel
      expect(pseudonym.reload.authentication_provider).to be_nil
    end
  end

  describe "valid_arbitrary_credentials?" do
    it "ignores password if canvas authentication is disabled" do
      user_with_pseudonym(password: "qwertyuiop")
      expect(@pseudonym.valid_arbitrary_credentials?("qwertyuiop")).to be_truthy
      # once auth provider is required, this whole spec can go away, because the situation will
      # not be possible
      @pseudonym.update!(authentication_provider: nil)

      Account.default.authentication_providers.scope.delete_all
      Account.default.authentication_providers.create!(auth_type: "ldap")
      @pseudonym.reload

      allow(@pseudonym).to receive(:valid_ldap_credentials?).and_return(false)
      expect(@pseudonym.valid_arbitrary_credentials?("qwertyuiop")).to be_falsey

      allow(@pseudonym).to receive(:valid_ldap_credentials?).and_return(true)
      expect(@pseudonym.valid_arbitrary_credentials?("anything")).to be_truthy
    end
  end

  describe "authenticate" do
    context "sharding" do
      specs_require_sharding
      let_once(:account2) { @shard1.activate { Account.create! } }
      before(:once) do
        # need these instantiated before we set up our mocks
        Account.default
        account2
      end

      it "only queries the pertinent shard" do
        expect(Pseudonym).to receive(:associated_shards).with("abc").and_return([@shard1])
        expect(Pseudonym).to receive(:active_only).once.and_return(Pseudonym.none)
        allow(GlobalLookups).to receive(:enabled?).and_return(true)
        Pseudonym.authenticate({ unique_id: "abc", password: "def" }, [Account.default.id, account2])
      end

      it "queries all pertinent shards" do
        expect(Pseudonym).to receive(:associated_shards).with("abc").and_return([Shard.default, @shard1])
        expect(Pseudonym).to receive(:active_only).twice.and_return(Pseudonym.none)
        allow(GlobalLookups).to receive(:enabled?).and_return(true)
        Pseudonym.authenticate({ unique_id: "abc", password: "def" }, [Account.default.id, account2])
      end

      it "won't attempt silly queries" do
        wat = " " * 3000
        unique_id = "asdf#{wat}asdf"
        creds = { unique_id:, password: "foobar" }
        expect(Pseudonym.authenticate(creds, [Account.default.id])).to eq(:impossible_credentials)
      end
    end
  end

  context "cas" do
    let!(:cas_ticket) { CanvasUuid::Uuid.generate_securish_uuid }
    let!(:redis_key) { "cas_session_slo:#{cas_ticket}" }

    before(:once) do
      user_with_pseudonym
    end

    before do
      allow(Canvas.redis).to receive_messages(redis_enabled?: true, ttl: 1.day)
    end

    it "checks cas ticket expiration" do
      expect(Canvas.redis).to receive(:get).with(redis_key, failsafe: nil).and_return(nil)
      expect(@pseudonym.cas_ticket_expired?(cas_ticket)).to be_falsey

      expect(Canvas.redis).to receive(:get).with(redis_key, failsafe: nil).and_return(true)
      expect(@pseudonym.cas_ticket_expired?(cas_ticket)).to be_truthy
    end

    it "expires a cas ticket" do
      expect(Canvas.redis).to receive(:set).once.and_return(true)
      expect(Pseudonym.expire_cas_ticket(cas_ticket, nil)).to be_truthy
    end
  end

  describe "#verify_unique_sis_user_id" do
    it "is true if there is no sis_user_id" do
      expect(Pseudonym.new.verify_unique_sis_user_id).to be_truthy
    end

    describe "when a pseudonym already exists" do
      let(:sis_user_id) { "1234554321" }

      before :once do
        user_with_pseudonym
        @pseudonym.sis_user_id = sis_user_id
        @pseudonym.save!
      end

      it "returns false if the sis_user_id is already taken" do
        new_pseudonym = Pseudonym.new(account: @pseudonym.account)
        new_pseudonym.sis_user_id = sis_user_id
        expect { new_pseudonym.verify_unique_sis_user_id }.to throw_symbol(:abort)
      end

      it "also can validate if the new sis_user_id is an integer" do
        new_pseudonym = Pseudonym.new(account: @pseudonym.account)
        new_pseudonym.sis_user_id = sis_user_id.to_i
        expect { new_pseudonym.verify_unique_sis_user_id }.to throw_symbol(:abort)
      end
    end
  end

  describe "permissions" do
    let(:account1) do
      a = Account.default
      a.settings[:admins_can_view_notifications] = true
      a.save!
      a
    end
    let(:account2) { Account.create! }

    let(:sally) do
      account_admin_user(
        user: student_in_course(account: account2).user,
        account: account1
      )
    end

    let(:bob) do
      student_in_course(
        user: student_in_course(account: account2).user,
        course: course_factory(account: account1)
      ).user
    end

    let(:charlie) { student_in_course(account: account2).user }

    let(:alice) do
      account_admin_user_with_role_changes(
        account: account1,
        role: custom_account_role("StrongerAdmin", account: account1),
        role_changes: { view_notifications: true }
      )
    end

    describe ":create" do
      it "grants admins :create for themselves on the account" do
        expect(account1.pseudonyms.build(user: sally)).to be_grants_right(sally, :create)
      end

      it "grants admins :create for others on the account" do
        expect(account1.pseudonyms.build(user: bob)).to be_grants_right(sally, :create)
      end

      it "does not grant non-admins :create for themselves on the account" do
        expect(account1.pseudonyms.build(user: bob)).not_to be_grants_right(bob, :create)
      end

      it "only grants admins :create on accounts they admin" do
        expect(account2.pseudonyms.build(user: sally)).not_to be_grants_right(sally, :create)
        expect(account2.pseudonyms.build(user: bob)).not_to be_grants_right(sally, :create)
      end

      it "does not grant admins :create for others from other accounts" do
        expect(account1.pseudonyms.build(user: charlie)).not_to be_grants_right(sally, :create)
      end

      it "does not grant subadmins :create on stronger admins" do
        expect(account1.pseudonyms.build(user: alice)).not_to be_grants_right(sally, :create)
      end
    end

    describe ":update" do
      it "grants admins :update for their own pseudonyms" do
        expect(account1.pseudonyms.build(user: sally)).to be_grants_right(sally, :update)
      end

      it "grants admins :update for others on the account" do
        expect(account1.pseudonyms.build(user: bob)).to be_grants_right(sally, :update)
      end

      it "does not grant non-admins :update for their own pseudonyms" do
        expect(account1.pseudonyms.build(user: bob)).not_to be_grants_right(bob, :update)
      end

      it "only grants admins :update for others on accounts they admin" do
        expect(account2.pseudonyms.build(user: bob)).not_to be_grants_right(sally, :update)
      end

      it "does not grant admins :update for their own pseudonyms on accounts they don't admin" do
        expect(account2.pseudonyms.build(user: sally)).not_to be_grants_right(sally, :update)
      end

      it "does not grant subadmins :update on stronger admins" do
        expect(account1.pseudonyms.build(user: alice)).not_to be_grants_right(sally, :update)
      end
    end

    describe ":change_password" do
      context "with :admins_can_change_passwords true on the account" do
        before do
          account1.settings[:admins_can_change_passwords] = true
          account1.save!
        end

        it "grants admins :change_password for others on the account" do
          expect(pseudonym(bob, account: account1)).to be_grants_right(sally, :change_password)
        end

        it "grants non-admins :change_password for their own pseudonyms" do
          expect(pseudonym(bob, account: account1)).to be_grants_right(bob, :change_password)
        end

        it "grants admins :change_password for their own pseudonyms on accounts they don't admin" do
          expect(pseudonym(sally, account: account2)).to be_grants_right(sally, :change_password)
        end
      end

      context "with :admins_can_change_passwords false on the account" do
        before do
          account1.settings[:admins_can_change_passwords] = false
          account1.save!
        end

        it "no longer grant admins :change_password for existing pseudonyms for others on the account" do
          expect(pseudonym(bob, account: account1)).not_to be_grants_right(sally, :change_password)
        end

        it "still grants admins :change_password for new pseudonym for others on the account" do
          expect(account1.pseudonyms.build(user: bob)).to be_grants_right(sally, :change_password)
        end

        it "still grants admins :change_password for their own pseudonym" do
          expect(pseudonym(sally, account: account1)).to be_grants_right(sally, :change_password)
        end

        it "still grants non-admins :change_password for their own pseudonym" do
          expect(pseudonym(bob, account: account1)).to be_grants_right(bob, :change_password)
        end
      end

      context "with managed passwords and :admins_can_change_passwords true" do
        before do
          account1.settings[:admins_can_change_passwords] = true
          account1.save!
        end

        context "with canvas authentication enabled on the account" do
          it "still grants admins :change_password for others on the account" do
            expect(managed_pseudonym(bob, account: account1)).to be_grants_right(sally, :change_password)
          end

          it "still grants admins :change_password for their own pseudonym" do
            expect(managed_pseudonym(sally, account: account1)).to be_grants_right(sally, :change_password)
          end

          it "still grants non-admins :change_password for their own pseudonym" do
            expect(managed_pseudonym(bob, account: account1)).to be_grants_right(bob, :change_password)
          end
        end

        context "without canvas authentication enabled on the account" do
          before do
            account1.authentication_providers.scope.delete_all
          end

          it "no longer grants admins :change_password for others on the account" do
            expect(managed_pseudonym(bob, account: account1)).not_to be_grants_right(sally, :change_password)
          end

          it "no longer grants admins :change_password for their own pseudonym" do
            expect(managed_pseudonym(sally, account: account1)).not_to be_grants_right(sally, :change_password)
          end

          it "no longer grants non-admins :change_password for their own pseudonym" do
            expect(managed_pseudonym(bob, account: account1)).not_to be_grants_right(bob, :change_password)
          end
        end
      end
    end

    describe ":manage_sis" do
      context "with :manage_sis permission on account" do
        before do
          account1.role_overrides.create!(permission: "manage_sis", role: admin_role, enabled: true)
        end

        it "grants admins :manage_sis for their own pseudonyms on that account" do
          expect(account1.pseudonyms.build(user: sally)).to be_grants_right(sally, :manage_sis)
        end

        it "grants admins :manage_sis for others on that account" do
          expect(account1.pseudonyms.build(user: bob)).to be_grants_right(sally, :manage_sis)
        end

        it "does not grant admins :manage_sis for others on other accounts" do
          expect(account2.pseudonyms.build(user: bob)).not_to be_grants_right(sally, :manage_sis)
        end

        it "does not grant admins :manage_sis for their own pseudonyms on other accounts" do
          expect(account2.pseudonyms.build(user: sally)).not_to be_grants_right(sally, :manage_sis)
        end
      end

      context "without :manage_sis permission on account" do
        before do
          account1.role_overrides.create!(permission: "manage_sis", role: admin_role, enabled: false)
        end

        it "does not grant admins :manage_sis for others" do
          expect(account1.pseudonyms.build(user: bob)).not_to be_grants_right(sally, :manage_sis)
        end

        it "does not grant admins :manage_sis even for their own pseudonyms" do
          expect(account1.pseudonyms.build(user: sally)).not_to be_grants_right(sally, :manage_sis)
        end
      end
    end

    describe ":delete" do
      it "grantses users :delete on pseudonyms they can update" do
        expect(account1.pseudonyms.build(user: sally)).to be_grants_right(sally, :delete)
        expect(account1.pseudonyms.build(user: bob)).to be_grants_right(sally, :delete)
        expect(account2.pseudonyms.build(user: sally)).not_to be_grants_right(bob, :delete)
        expect(account2.pseudonyms.build(user: bob)).not_to be_grants_right(sally, :delete)
        expect(account1.pseudonyms.build(user: alice)).not_to be_grants_right(sally, :delete)
      end

      context "system-created pseudonyms" do
        let(:system_pseudonym) do
          p = account1.pseudonyms.build(user: sally)
          p.sis_user_id = "sis"
          p
        end

        it "grants admins :delete if they can :manage_sis" do
          account1.role_overrides.create!(permission: "manage_sis", role: admin_role, enabled: true)
          expect(system_pseudonym).to be_grants_right(sally, :manage_sis)
        end

        it "does not grant admins :delete if they can't :manage_sis" do
          account1.role_overrides.create!(permission: "manage_sis", role: admin_role, enabled: false)
          expect(system_pseudonym).not_to be_grants_right(sally, :manage_sis)
        end
      end
    end
  end

  describe ".for_auth_configuration" do
    let!(:bob) { user_model }
    let!(:new_pseud) { Account.default.pseudonyms.create!(user: bob, unique_id: "BobbyRicky") }

    context "with legacy auth types" do
      let!(:aac) { Account.default.authentication_providers.create!(auth_type: "ldap") }

      it "filters down by unique ID" do
        pseud = Account.default.pseudonyms.for_auth_configuration("BobbyRicky", aac)
        expect(pseud).to eq(new_pseud)
      end

      it "excludes inactive pseudonyms" do
        new_pseud.destroy
        pseud = Account.default.pseudonyms.for_auth_configuration("BobbyRicky", aac)
        expect(pseud).to be_nil
      end
    end

    context "with contemporary auth types" do
      let!(:aac) { Account.default.authentication_providers.create!(auth_type: "microsoft", tenant: "microsoft", login_attribute: "sub") }

      before do
        new_pseud.authentication_provider_id = aac.id
        new_pseud.save!
      end

      it "finds the first related pseudonym" do
        pseud = Account.default.pseudonyms.for_auth_configuration("BobbyRicky", aac)
        expect(pseud).to eq(new_pseud)
      end

      it "will not load an AAC related pseudonym if you don't provide an AAC" do
        pseud = Account.default.pseudonyms.for_auth_configuration("BobbyRicky", nil)
        expect(pseud).to be_nil
      end

      context "with a hash of unique ids" do
        it "only matches against the proper login attribute" do
          new_pseud.update_attribute(:login_attribute, "sub")
          Account.default.pseudonyms.create!(user: bob,
                                             unique_id: "BobbyRicky",
                                             authentication_provider: aac,
                                             login_attribute: "oid")

          pseud = Account.default.pseudonyms.for_auth_configuration({ "sub" => "BobbyRicky" }, aac)
          expect(pseud).to eq(new_pseud)
        end

        it "still matches against a null login attribute" do
          pseud = Account.default.pseudonyms.for_auth_configuration({ "sub" => "BobbyRicky" }, aac)
          expect(pseud).to eq(new_pseud)
        end

        it "matches against the proper login attribute before a null login_attribute" do
          proper_pseud = Account.default.pseudonyms.create!(user: bob,
                                                            unique_id: "BobbyRicky",
                                                            authentication_provider: aac,
                                                            login_attribute: "sub")

          pseud = Account.default.pseudonyms.for_auth_configuration({ "sub" => "BobbyRicky" }, aac)
          expect(pseud).to eq(proper_pseud)
        end
      end
    end
  end

  it "allows duplicate unique_ids, in different providers" do
    u = User.create!
    aac = Account.default.authentication_providers.create!(auth_type: "facebook")
    u.pseudonyms.create!(unique_id: "a", account: Account.default)
    p2 = u.pseudonyms.new(unique_id: "a", account: Account.default)
    expect(p2).to_not be_valid
    expect(p2.errors.details[:unique_id].first[:error]).to eq :taken
    p2.authentication_provider = aac
    expect(p2).to be_valid
  end

  describe ".find_all_by_arbtrary_credentials" do
    let_once(:p) do
      u = User.create!
      u.pseudonyms.create!(unique_id: "a", account: Account.default, password: "abcdefgh", password_confirmation: "abcdefgh")
    end

    it "finds a valid pseudonym" do
      expect(Pseudonym.find_all_by_arbitrary_credentials({ unique_id: "a", password: "abcdefgh" }, [Account.default.id])).to eq [p]
    end

    it "doesn't choke on if global lookups is down" do
      expect(GlobalLookups).to receive(:enabled?).and_return(true)
      expect(Pseudonym).to receive(:associated_shards).and_raise("an error")
      expect(Pseudonym.find_all_by_arbitrary_credentials({ unique_id: "a", password: "abcdefgh" }, [Account.default.id])).to eq [p]
    end

    it "throws an error if your credentials are absurd" do
      wat = " " * 3000
      unique_id = "asdf#{wat}asdf"
      creds = { unique_id:, password: "foobar" }
      expect { Pseudonym.find_all_by_arbitrary_credentials(creds, [Account.default.id]) }.to raise_error(ImpossibleCredentialsError)
    end

    it "doesn't find deleted pseudonyms" do
      p.update!(workflow_state: "deleted")
      expect(Pseudonym.find_all_by_arbitrary_credentials({ unique_id: "a", password: "abcdefgh" }, [Account.default.id])).to eq []
    end

    it "doesn't find suspended pseudonyms" do
      p.update!(workflow_state: "suspended")
      expect(Pseudonym.find_all_by_arbitrary_credentials({ unique_id: "a", password: "abcdefgh" }, [Account.default.id])).to eq []
    end
  end

  describe "migrate_login_attribute" do
    before :once do
      user_factory(active_all: true, active_cc: true)
      Notification.create!(name: "Account Verification", subject: "Test", category: "Registration", delay_for: 0)
      @authentication_provider = Account.default.authentication_providers.create!(auth_type: "microsoft", tenant: "common", login_attribute: "tid+oid")
      @authentication_provider.settings["old_login_attribute"] = "email"
      @authentication_provider.save!
      @pseudonym = @user.pseudonyms.create!(unique_id: "foo@example.com", authentication_provider: @authentication_provider)
      @pseudonym.begin_login_attribute_migration!({ "email" => "foo@example.com", "tid+oid" => "67890#abcde" })
    end

    it "allows the user to migrate to the new login attribute via the emailed code" do
      message = @user.messages.find_by(notification_name: "Account Verification")
      expect(message).to be_present
      code = message.body.match(/use the following code to complete your login: (\w+)/)[1]
      expect(@pseudonym.migrate_login_attribute(code:)).to be true
      expect(@pseudonym.reload.unique_id).to eq "67890#abcde"
    end

    it "rejects an invalid code" do
      expect(@pseudonym.migrate_login_attribute(code: "invalid")).to be false
      expect(@pseudonym.reload.unique_id).to eq "foo@example.com"
    end

    it "allows an admin to migrate the login attribute" do
      expect(@pseudonym.migrate_login_attribute(admin_user: account_admin_user)).to be true
      expect(@pseudonym.reload.unique_id).to eq "67890#abcde"
    end

    it "rejects a user without permission to modify the login" do
      expect(@pseudonym.migrate_login_attribute(admin_user: user_factory)).to be false
      expect(@pseudonym.reload.unique_id).to eq "foo@example.com"
    end

    it "keeps the verification token if a new login attempt is made within 5 minutes" do
      token = @pseudonym.verification_token
      @pseudonym.begin_login_attribute_migration!({ "email" => "foo@example.com", "tid+oid" => "67890#abcde" })
      expect(@pseudonym.reload.verification_token).to eq token
      expect(@user.messages.where(notification_name: "Account Verification").count).to eq 2
    end

    it "regenerates the verification token if a new login attempt is made after 5 minutes" do
      token = @pseudonym.verification_token
      Timecop.travel(10.minutes.from_now) do
        @pseudonym.begin_login_attribute_migration!({ "email" => "foo@example.com", "tid+oid" => "67890#abcde" })
      end
      expect(@pseudonym.reload.verification_token).not_to eq token
      expect(@user.messages.where(notification_name: "Account Verification").count).to eq 2
    end
  end

  describe "#validate_password" do
    let(:pseudonym) { Pseudonym.new }
    let(:attr) { :password }
    let(:val) { "new_password" }

    before do
      allow(Canvas::Security::PasswordPolicy).to receive(:validate)
    end

    context "when password_auto_generated? is true and canvas_generated_password? is true" do
      before do
        allow(pseudonym).to receive_messages(password_auto_generated?: true, canvas_generated_password?: true)
      end

      it "does not call Canvas::Security::PasswordPolicy.validate" do
        pseudonym.validate_password(attr, val)
        expect(Canvas::Security::PasswordPolicy).not_to have_received(:validate)
      end
    end

    context "when password_auto_generated? is false" do
      before do
        allow(pseudonym).to receive_messages(password_auto_generated?: false, canvas_generated_password?: true)
      end

      it "calls Canvas::Security::PasswordPolicy.validate" do
        pseudonym.validate_password(attr, val)
        expect(Canvas::Security::PasswordPolicy).to have_received(:validate).with(pseudonym, attr, val)
      end
    end

    context "when canvas_generated_password? is false" do
      before do
        allow(pseudonym).to receive_messages(password_auto_generated?: true, canvas_generated_password?: false)
      end

      it "calls Canvas::Security::PasswordPolicy.validate" do
        pseudonym.validate_password(attr, val)
        expect(Canvas::Security::PasswordPolicy).to have_received(:validate).with(pseudonym, attr, val)
      end
    end
  end

  describe "#infer_defaults" do
    let(:pseudonym) do
      Pseudonym.new.tap do |p|
        p.user = user_model
        p.account = Account.default
        p.unique_id = "some_unique_id"
      end
    end

    before do
      expect(pseudonym).to receive(:infer_defaults).once.and_call_original
    end

    it "sets @canvas_generated_password to true if generate temporary password conditions are met" do
      pseudonym.save!
      expect(pseudonym.instance_variable_get(:@canvas_generated_password)).to be true
    end

    it "does not set @canvas_generated_password if generate temporary password conditions are not met" do
      pseudonym.password = "password"
      pseudonym.password_confirmation = "password"
      pseudonym.save!

      expect(pseudonym.instance_variable_get(:@canvas_generated_password)).to be_nil
    end
  end
end
