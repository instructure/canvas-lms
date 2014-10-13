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

describe Pseudonym do

  it "should create a new instance given valid attributes" do
    user_model
    factory_with_protected_attributes(Pseudonym, valid_pseudonym_attributes)
  end

  it "should allow single character usernames" do
    user_model
    pseudonym_model
    @pseudonym.unique_id = 'c'
    @pseudonym.save!
  end

  it "should allow apostrophes in usernames" do
    pseudonym = Pseudonym.new(:unique_id => "o'brien@example.com",
                              :password => 'password',
                              :password_confirmation => 'password')
    pseudonym.user_id = 1
    expect(pseudonym).to be_valid
  end

  it "should validate the presence of user and infer default account" do
    u = User.create!
    p = Pseudonym.new(:unique_id => 'cody@instructure.com')
    expect(p.save).to be_falsey

    p.user_id = u.id
    expect(p.save).to be_truthy
    expect(p.account_id).to eq Account.default.id

    # make sure a password was generated
    expect(p.password).not_to be_nil
    expect(p.password).not_to match /tmp-pw/
  end

  it "should not allow active duplicates" do
    u = User.create!
    p1 = Pseudonym.create!(:unique_id => 'cody@instructure.com', :user => u)
    p2 = Pseudonym.create(:unique_id => 'cody@instructure.com', :user => u)
    # Failed; p1 is still active
    expect(p2).to be_new_record
    p2.workflow_state = 'deleted'
    p2.save!
    # Duplicates okay in the deleted state
    p1.workflow_state = 'deleted'
    p1.save!
    # Should allow creating a new active one if the others are deleted
    Pseudonym.create!(:unique_id => 'cody@instructure.com', :user => u)
  end

  it "should share a root_account_id with its account" do
    pseudonym = Pseudonym.new
    pseudonym.stubs(:account).returns(stub(root_account_id: 1, id: 2))

    expect(pseudonym.root_account_id).to eq 1
  end

  it "should use its account_id as a root_account_id if its account has no root" do
    pseudonym = Pseudonym.new
    pseudonym.stubs(:account).returns(stub(root_account_id: nil, id: 1))

    expect(pseudonym.root_account_id).to eq 1
  end
  
  it "should find the correct pseudonym for logins" do
    user = User.create!
    p1 = Pseudonym.create!(:unique_id => 'Cody@instructure.com', :user => user)
    p2 = Pseudonym.create!(:unique_id => 'codY@instructure.com', :user => user) { |p| p.workflow_state = 'deleted' }
    expect(Pseudonym.active.by_unique_id('cody@instructure.com').first).to eq p1
    account = Account.create!
    p3 = Pseudonym.create!(:unique_id => 'cOdy@instructure.com', :account => account, :user => user)
    expect(Pseudonym.active.by_unique_id('cody@instructure.com').sort).to eq [p1, p3]
  end

  it "should associate to another user" do
    user_model
    pseudonym_model
    expect(@pseudonym.user).to eql(@user)
  end
  
  it "should order by position" do
    user_model
    p1 = pseudonym_model(:user_id => @user.id)
    p2 = pseudonym_model(:user_id => @user.id)
    p3 = pseudonym_model(:user_id => @user.id)
    p1.move_to_bottom
    p3.move_to_top
    expect(Pseudonym.all.sort.map(&:id)).to eql([p3.id, p2.id, p1.id])
  end
  
  it "should update user account associations on CRUD" do
    account_model
    user_model
    account1 = account_model
    account2 = account_model
    expect(@user.user_account_associations.length).to eql(0)
    
    pseudonym_model(:user => @user, :account => account1)
    @user.reload
    expect(@user.user_account_associations.length).to eql(1)
    expect(@user.user_account_associations.first.account).to eql(account1)
    
    account2 = account_model
    @pseudonym.account = account2
    @pseudonym.save
    @user.reload
    expect(@user.user_account_associations.length).to eql(1)
    expect(@user.user_account_associations.first.account).to eql(account2)

    @pseudonym.destroy
    @user.reload
    expect(@user.user_account_associations).to eq []
  end

  it "should allow deleting pseudonyms" do
    user_with_pseudonym(:active_all => true)
    expect(@pseudonym.destroy(true)).to eql(true)
    expect(@pseudonym).to be_deleted
  end

  it "should not allow deleting system-generated pseudonyms by default" do
    user_with_pseudonym(:active_all => true)
    @pseudonym.sis_user_id = 'something_cool'
    @pseudonym.save!
    @pseudonym.account.account_authorization_configs.create!(:auth_type => 'ldap')
    expect{ @pseudonym.destroy}.to raise_error("Cannot delete system-generated pseudonyms")
    expect(@pseudonym).not_to be_deleted
  end

  it "should not allow deleting system-generated pseudonyms by default" do
    user_with_pseudonym(:active_all => true)
    @pseudonym.sis_user_id = 'something_cool'
    @pseudonym.save!
    expect(@pseudonym.destroy(true)).to eql(true)
    expect(@pseudonym).to be_deleted
  end

  it "should change a blank sis_user_id to nil" do
    user
    pseudonym = Pseudonym.new(:user => @user, :unique_id => 'test@example.com', :password => 'pwd123')
    pseudonym.password_confirmation = 'pwd123'
    pseudonym.sis_user_id = ''
    expect(pseudonym).to be_valid
    expect(pseudonym.sis_user_id).to be_nil
  end

  context "LDAP errors" do
    before :once do
      require 'net/ldap'
      user_with_pseudonym(:active_all => true)
      @aac = @pseudonym.account.account_authorization_configs.create!(
        :auth_type      => 'ldap',
        :auth_base      => "ou=people,dc=example,dc=com",
        :auth_host      => "ldap.example.com",
        :auth_username  => "cn=query,dc=example,dc=com",
        :auth_port      => 636,
        :auth_filter    => "(uid={{login}})",
        :auth_over_tls  => true
      )
    end

    it "should gracefully handle unreachable LDAP servers" do
      Net::LDAP.any_instance.expects(:bind_as).raises(Net::LDAP::LdapError, "no connection to server")
      expect{ @pseudonym.ldap_bind_result('blech') }.not_to raise_error
      expect(ErrorReport.last.message).to eql("no connection to server")
      Net::LDAP.any_instance.expects(:bind_as).returns(true)
      expect(@pseudonym.ldap_bind_result('yay!')).to be_truthy
    end

    it "should set last_timeout_failure on LDAP servers that timeout" do
      Net::LDAP.any_instance.expects(:bind_as).once.raises(Timeout::Error, "timed out")
      expect(@pseudonym.ldap_bind_result('test')).to be_falsey
      expect(ErrorReport.last.message).to match(/timed out/)
      expect(@aac.reload.last_timeout_failure).to be > 1.minute.ago
    end
  end

  it "should not error on malformed SSHA password" do
    pseudonym_model
    @pseudonym.sis_ssha = '{SSHA}garbage'
    expect(@pseudonym.valid_ssha?('garbage')).to be_falsey
  end

  it "should not attempt validating a blank password" do
    pseudonym_model
    @pseudonym.expects(:sis_ssha).never
    @pseudonym.valid_ssha?('')

    @pseudonym.expects(:ldap_bind_result).never
    @pseudonym.valid_ldap_credentials?('')
  end

  context "Needs a pseudonym with an active user" do
    before :once do
      user_model
      pseudonym_model
    end
    
    it "should offer login as the unique id" do
      expect(@pseudonym.login).to eql(@pseudonym.unique_id)
    end

    it "should be able to set the login" do
      @pseudonym.login = 'another'
      expect(@pseudonym.login).to eql('another')
      expect(@pseudonym.unique_id).to eql('another')
    end

    it "should know if the login changed" do
      @pseudonym.login = 'another'
      expect(@pseudonym.login_changed?).to be_truthy
    end

    it "should offer the user code as the user's uuid" do
      expect(@pseudonym.user).to eql(@user)
      expect(@pseudonym.user_code).to eql(@user.uuid)
    end

    it "should be able to change the user email" do
      @pseudonym.email = 'admin@example.com'
      @pseudonym.reload
      expect(@pseudonym.user.email_channel.path).to eql('admin@example.com')
    end

    it "should offer the user sms if there is one" do
      communication_channel_model(:path_type => 'sms')
      @user.communication_channels << @cc
      @user.save!
      expect(@user.sms).to eql(@cc.path)
      expect(@pseudonym.sms).to eql(@user.sms)
    end
  end

  it "should determine if the password is managed" do
    u = User.create!
    p = Pseudonym.create!(:unique_id => 'jt@instructure.com', :user => u)
    p.sis_user_id = 'jt'
    expect(p).not_to be_managed_password
    p.account.account_authorization_configs.create!(:auth_type => 'ldap')
    expect(p).to be_managed_password
    p.sis_user_id = nil
    expect(p).not_to be_managed_password
  end

  context "login assertions" do
    it "should create a CC if LDAP gave an e-mail we don't have" do
      account = Account.create!
      account.account_authorization_configs.create!(:auth_type => 'ldap')
      u = User.create!
      u.register
      p = u.pseudonyms.create!(:unique_id => 'jt', :account => account) { |p| p.sis_user_id = 'jt' }
      p.instance_variable_set(:@ldap_result, {:mail => ['jt@instructure.com']})

      p.add_ldap_channel
      u.reload
      expect(u.communication_channels.length).to eq 1
      expect(u.email_channel.path).to eq 'jt@instructure.com'
      expect(u.email_channel).to be_active
      u.email_channel.destroy

      p.add_ldap_channel
      u.reload
      expect(u.communication_channels.length).to eq 1
      expect(u.email_channel.path).to eq 'jt@instructure.com'
      expect(u.email_channel).to be_active
      u.email_channel.update_attribute(:workflow_state, 'unconfirmed')

      p.add_ldap_channel
      u.reload
      expect(u.communication_channels.length).to eq 1
      expect(u.email_channel.path).to eq 'jt@instructure.com'
      expect(u.email_channel).to be_active
    end
  end

  describe 'valid_arbitrary_credentials?' do
    it "should ignore password if canvas authentication is disabled" do
      user_with_pseudonym(:password => 'qwerty')
      expect(@pseudonym.valid_arbitrary_credentials?('qwerty')).to be_truthy

      Account.default.settings = { :canvas_authentication => false }
      Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
      Account.default.save!
      @pseudonym.reload

      @pseudonym.stubs(:valid_ldap_credentials?).returns(false)
      expect(@pseudonym.valid_arbitrary_credentials?('qwerty')).to be_falsey

      @pseudonym.stubs(:valid_ldap_credentials?).returns(true)
      expect(@pseudonym.valid_arbitrary_credentials?('anything')).to be_truthy
    end
  end

  describe "authenticate" do
    context "sharding" do
      specs_require_sharding
      let_once(:account2) { @shard1.activate { Account.create! } }

      it "should only query pertinent shards" do
        Pseudonym.expects(:associated_shards).with('abc').returns([@shard1])
        Pseudonym.expects(:active).once.returns(Pseudonym.none)
        GlobalLookups.stubs(:enabled?).returns(true)
        Pseudonym.authenticate({ unique_id: 'abc', password: 'def' }, [Account.default.id, account2])
      end

      it "should only query pertinent shards" do
        Pseudonym.expects(:associated_shards).with('abc').returns([Shard.default, @shard1])
        Pseudonym.expects(:active).twice.returns(Pseudonym.none)
        GlobalLookups.stubs(:enabled?).returns(true)
        Pseudonym.authenticate({ unique_id: 'abc', password: 'def' }, [Account.default.id, account2])
      end
    end
  end

  context 'cas' do
    let!(:cas_ticket) { CanvasUuid::Uuid.generate_securish_uuid }
    let!(:redis_key) { "cas_session:#{cas_ticket}" }

    before(:once) do
      user_with_pseudonym

      Canvas.redis.stubs(:redis_enabled?).returns(true)
      Canvas.redis.stubs(:ttl).returns(1.day)
    end

    it 'should claim a cas ticket' do
      Canvas.redis.expects(:expire).with(redis_key, 1.day).returns(false).once
      Canvas.redis.expects(:set).with(redis_key, @pseudonym.global_id, { ex: 1.day, nx: true }).once
      @pseudonym.claim_cas_ticket(cas_ticket)
    end

    it 'should refresh a cas ticket' do
      Canvas.redis.expects(:expire).with(redis_key, 1.day).returns(true).once
      Canvas.redis.expects(:setex).never
      @pseudonym.claim_cas_ticket(cas_ticket)
    end

    it 'should check cas ticket expiration' do
      Canvas.redis.expects(:get).with(redis_key).returns(@pseudonym.global_id.to_s)
      expect(@pseudonym.cas_ticket_expired?(cas_ticket)).to be_falsey

      Canvas.redis.expects(:get).with(redis_key).returns(Pseudonym::CAS_TICKET_EXPIRED)
      expect(@pseudonym.cas_ticket_expired?(cas_ticket)).to be_truthy
    end

    it 'should expire a cas ticket' do
      Canvas.redis.expects(:getset).once.returns(@pseudonym.global_id.to_s)
      expect(Pseudonym.expire_cas_ticket(cas_ticket)).to be_truthy

      Canvas.redis.expects(:getset).once.returns(Pseudonym::CAS_TICKET_EXPIRED)
      expect(Pseudonym.expire_cas_ticket(cas_ticket)).to be_falsey
    end
  end

  describe '#verify_unique_sis_user_id' do

    it 'is true if there is no sis_user_id' do
      expect(Pseudonym.new.verify_unique_sis_user_id).to be_truthy
    end

    describe 'when a pseudonym already exists' do

      let(:sis_user_id) { "1234554321" }

      before :once do
        user_with_pseudonym
        @pseudonym.sis_user_id = sis_user_id
        @pseudonym.save!
      end

      it 'returns false if the sis_user_id is already taken' do
        new_pseudonym = Pseudonym.new(:account => @pseudonym.account)
        new_pseudonym.sis_user_id = sis_user_id
        expect(new_pseudonym.verify_unique_sis_user_id).to be_falsey
      end

      it 'also can validate if the new sis_user_id is an integer' do
        new_pseudonym = Pseudonym.new(:account => @pseudonym.account)
        new_pseudonym.sis_user_id = sis_user_id.to_i
        expect(new_pseudonym.verify_unique_sis_user_id).to be_falsey
      end

    end
  end

  describe "permissions" do
    let(:account1) { Account.default }
    let(:account2) { Account.create! }

    let(:sally) { account_admin_user(
      user: student_in_course(account: account2).user,
      account: account1) }

    let(:bob) { student_in_course(
      user: student_in_course(account: account2).user,
      course: course(account: account1)).user }

    let(:charlie) { student_in_course(account: account2).user }

    let(:alice) { account_admin_user_with_role_changes(
      account: account1,
      membership_type: 'StrongerAdmin',
      role_changes: { view_notifications: true }) }

    describe ":create" do
      it "should grant admins :create for themselves on the account" do
        expect(account1.pseudonyms.build(user: sally)).to be_grants_right(sally, :create)
      end

      it "should grant admins :create for others on the account" do
        expect(account1.pseudonyms.build(user: bob)).to be_grants_right(sally, :create)
      end

      it "should not grant non-admins :create for themselves on the account" do
        expect(account1.pseudonyms.build(user: bob)).not_to be_grants_right(bob, :create)
      end

      it "should only grant admins :create on accounts they admin" do
        expect(account2.pseudonyms.build(user: sally)).not_to be_grants_right(sally, :create)
        expect(account2.pseudonyms.build(user: bob)).not_to be_grants_right(sally, :create)
      end

      it "should not grant admins :create for others from other accounts" do
        expect(account1.pseudonyms.build(user: charlie)).not_to be_grants_right(sally, :create)
      end

      it "should not grant subadmins :create on stronger admins" do
        expect(account1.pseudonyms.build(user: alice)).not_to be_grants_right(sally, :create)
      end
    end
  end
end

