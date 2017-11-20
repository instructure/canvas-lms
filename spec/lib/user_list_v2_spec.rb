# coding: utf-8
#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe UserListV2 do

  before(:each) do
    @account = Account.default
    @account.settings = { :open_registration => true }
    @account.save!
  end

  it "should complain about invalid input" do
    ul = UserListV2.new "i\x01nstructure", search_type: 'unique_id'
    expect(ul.errors).to eq [{:address => "i\x01nstructure", :details => :unparseable}]
  end

  it "should not fail with unicode names" do
    ul = UserListV2.new '"senor molé" <blah@instructure.com>', search_type: 'unique_id'
    expect(ul.missing_results.map{|x| [x[:user_name], x[:address]]}).to eq [["senor molé", "blah@instructure.com"]]
  end

  it "should find by SMS number" do
    user_with_pseudonym(:name => "JT", :active_all => 1)
    cc = @user.communication_channels.create!(:path => '8015555555@txt.att.net', :path_type => 'sms')
    cc.confirm!
    ul = UserListV2.new('(801) 555-5555', search_type: "cc_path")
    expect(ul.resolved_results.first[:address]).to eq '(801) 555-5555'
    expect(ul.resolved_results.first[:user_id]).to eq @user.id
    expect(ul.resolved_results.first[:user_token]).to eq @user.token

    ul = UserListV2.new('8015555555', search_type: "cc_path")
    expect(ul.resolved_results.first[:address]).to eq '8015555555'
    expect(ul.resolved_results.first[:user_id]).to eq @user.id
    expect(ul.resolved_results.first[:user_token]).to eq @user.token
  end

  it "should find duplicates by SMS number" do
    user_with_pseudonym(:name => "JT", :active_all => 1)
    @user1 = @user
    cc = @user1.communication_channels.create!(:path => '8015555555@txt.att.net', :path_type => 'sms')
    cc.confirm!

    user_with_pseudonym(:name => "JT2", :active_all => 1)
    cc = @user.communication_channels.create!(:path => '8015555555@txt.fakeplace.net', :path_type => 'sms')
    cc.confirm!

    ul = UserListV2.new('(801) 555-5555', search_type: "cc_path")
    expect(ul.resolved_results).to be_empty
    expect(ul.duplicate_results.first.map{|r| r[:user_id]}).to match_array([@user1.id, @user.id])
    expect(ul.duplicate_results.first.map{|r| r[:user_token]}).to match_array([@user1.token, @user.token])
  end

  it "should include in duplicates if there is 1 active CC and 1 unconfirmed" do
    # maaaybe we want to preserve the old behavior with this... but whatevr  ¯\_(ツ)_/¯
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
    @user.communication_channels.create!(:path => 'jt+2@instructure.com') { |cc| cc.workflow_state = 'active' }
    @user1 = @user
    user_with_pseudonym(:name => 'JT 1', :username => 'jt+1@instructure.com', :active_all => true)
    @user.communication_channels.create!(:path => 'jt+2@instructure.com')
    ul = UserListV2.new('jt+2@instructure.com', search_type: 'cc_path')
    expect(ul.resolved_results).to be_empty
    expect(ul.duplicate_results.count).to eq 1
    expect(ul.duplicate_results.first.map{|r| r[:user_id]}).to match_array([@user1.id, @user.id])
    expect(ul.duplicate_results.first.map{|r| r[:user_token]}).to match_array([@user1.token, @user.token])
  end

  it "should not find users from untrusted accounts" do
    account = Account.create!
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
    ul = UserListV2.new('jt@instructure.com', search_type: 'unique_id')
    expect(ul.resolved_results).to be_empty
    expect(ul.missing_results.first[:address]).to eq 'jt@instructure.com'
  end

  it "doesn't find site admins if you're not a site admin" do
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => Account.site_admin)
    allow(Account.default).to receive(:trusted_account_ids).and_return([Account.site_admin.id])
    jt = @user
    user_with_pseudonym
    other = @user

    ul = UserListV2.new('jt@instructure.com', current_user: other, search_type: 'unique_id')
    expect(ul.resolved_results).to be_empty
    expect(ul.missing_results.first[:address]).to eq 'jt@instructure.com'

    # when it's the user _from_ site admin doing it, it can be found
    allow(Account.default).to receive(:trusted_account_ids).and_return([Account.site_admin.id])
    ul = UserListV2.new('jt@instructure.com', current_user: jt, search_type: 'unique_id')
    expect(ul.missing_results).to be_empty
    expect(ul.resolved_results.first[:address]).to eq 'jt@instructure.com'
  end

  it "should find users from trusted accounts" do
    account = Account.create!(:name => "naem")
    allow(Account.default).to receive(:trusted_account_ids).and_return([account.id])
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
    ul = UserListV2.new('jt@instructure.com', :search_type => "unique_id")
    expect(ul.resolved_results).to eq [{:address => 'jt@instructure.com', :user_id => @user.id, :user_token => @user.token, :user_name => 'JT', :account_id => account.id, :account_name => account.name}]
  end

  it "should show duplicates for two results from the current account and the trusted account" do
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
    @user1 = @user
    account = Account.create!
    allow(Account.default).to receive(:trusted_account_ids).and_return([account.id])
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
    ul = UserListV2.new('jt@instructure.com', :search_type => "unique_id")

    expect(ul.resolved_results).to be_empty
    expect(ul.duplicate_results.count).to eq 1
    expect(ul.duplicate_results.first.map{|r| r[:user_id]}).to match_array([@user1.id, @user.id])
    expect(ul.duplicate_results.first.map{|r| r[:user_token]}).to match_array([@user1.token, @user.token])
  end

  context 'when searching by sis id' do
    it "should raise an error without can_read_sis" do
      expect {
        UserListV2.new('SISID', root_account: @account, search_type: 'sis_user_id', can_read_sis: false)
      }.to raise_error("cannot read sis ids")
    end

    it "should show duplicates for two results from the current account and the trusted account" do
      account1 = Account.create!
      account2 = Account.create!
      allow(account1).to receive(:trusted_account_ids).and_return([account2.id])
      allow(account1).to receive(:trust_exists?).and_return(true)

      user_with_managed_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account1, :sis_user_id => "SISID")
      @user1 = @user
      user_with_managed_pseudonym(:name => 'JT', :username => 'jt2@instructure.com', :active_all => true, :account => account2, :sis_user_id => "SISID")
      ul = UserListV2.new('SISID', root_account: account1, search_type: 'sis_user_id', can_read_sis: true)

      expect(ul.resolved_results).to be_empty
      expect(ul.duplicate_results.count).to eq 1
      dup = ul.duplicate_results.first
      expect(dup.map{|r| r[:user_id]}).to match_array([@user1.id, @user.id])
      expect(dup.map{|r| r[:user_token]}).to match_array([@user1.token, @user.token])

      # should include additional idenfitying info on duplicates
      expect(dup.map{|r| r[:email]}).to match_array(['jt@instructure.com', 'jt2@instructure.com'])
      expect(dup.map{|r| r[:login_id]}).to match_array(['jt@instructure.com', 'jt2@instructure.com'])
      expect(dup.map{|r| r[:sis_user_id]}).to match_array(['SISID', 'SISID'])
    end
  end

  it "should show duplicates if there is a conflict of unique_ids from not-this-account" do
    account1 = Account.create!
    account2 = Account.create!
    allow(Account.default).to receive(:trusted_account_ids).and_return([account1.id, account2.id])

    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account1)
    allow_any_instantiation_of(@pseudonym).to receive(:works_for_account?).and_return(true)
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account2)
    allow_any_instantiation_of(@pseudonym).to receive(:works_for_account?).and_return(true)
    ul = UserListV2.new('jt@instructure.com', search_type: 'unique_id')
    expect(ul.resolved_results).to be_empty
    expect(ul.duplicate_results.count).to eq 1
    dups = ul.duplicate_results.first
    expect(dups.map{|r| r[:account_id]}).to match_array([account1.id, account2.id])
    expect(dups.map{|r| r[:login_id]}).to match_array(['jt@instructure.com', 'jt@instructure.com'])
    dups.each do |h|
      expect(h).to_not have_key(:sis_user_id) # only includes if can_read_sis is true
    end
  end

  it "should find a user with multiple not-this-account pseudonyms" do
    account1 = Account.create!
    account2 = Account.create!
    allow(Account.default).to receive(:trusted_account_ids).and_return([account1.id, account2.id])
    user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account1)
    @user.pseudonyms.create!(:unique_id => 'jt@instructure.com', :account => account2)
    ul = UserListV2.new('jt@instructure.com', search_type: 'unique_id')
    expect(ul.duplicate_results).to be_empty
    expect(ul.resolved_results.count).to eq 1
    expect(ul.resolved_results.first[:user_id]).to eq @user.id
    expect(ul.resolved_results.first[:user_token]).to eq @user.token
  end

  it "should not find a user from a different account by SMS" do
    account = Account.create!
    user_with_pseudonym(:name => "JT", :active_all => 1, :account => account)
    cc = @user.communication_channels.create!(:path => '8015555555@txt.att.net', :path_type => 'sms')
    cc.confirm!
    ul = UserListV2.new('(801) 555-5555', search_type: 'cc_path')
    expect(ul.resolved_results).to eq []
    expect(ul.missing_results.first[:address]).to eq '(801) 555-5555'
  end

  context "sharding" do
    specs_require_sharding

    it "should find a user from a trusted account in a different shard" do
      @shard1.activate do
        @account = Account.create!(:name => "accountnaem")
        user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => @account)
      end
      allow(Account.default).to receive(:trusted_account_ids).and_return([@account.id])
      ul1 = UserListV2.new('jt@instructure.com', search_type: 'sis_user_id', can_read_sis: true)
      expect(ul1.missing_results.map{|r| r[:address]}).to eq ['jt@instructure.com']

      ul2 = UserListV2.new('jt@instructure.com', search_type: 'unique_id')
      expect(ul2.resolved_results).to eq [{:address => 'jt@instructure.com', :user_id => @user.id, :user_token => @user.token, :account_id => @account.id, :user_name => 'JT', :account_name => @account.name}]
    end

    it "should not get confused when dealing with cross-shard duplicate results that actually point to the same user" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
      @shard1.activate do
        @account = Account.create!(:name => "accountnaem")
        ps = @account.pseudonyms.build(:user => @user, :unique_id => 'username', :password => 'password', :password_confirmation => 'password')
        ps.save_without_session_maintenance
        CommunicationChannel.create!(user: @user, pseudonym: ps, path_type: 'email', path: 'jt@instructure.com')
      end

      allow(Account.default).to receive(:trusted_account_ids).and_return([@account.id])

      ul = UserListV2.new('jt@instructure.com', search_type: 'cc_path')
      expect(ul.resolved_results.count).to eq 1
      r = ul.resolved_results.first
      expect(r[:user_id]).to eq @user.id
      expect(r[:user_token]).to eq @user.token
      expect(r[:account_id]).to eq Account.default.id
    end

    it "finds a user whose home shard is not the target shard" do
      @shard1.activate do
        @account = Account.create!(name: "non-local")
        user_with_pseudonym(name: 'JT', username: 'jt@instructure.com', active_all: true, account: @account)
        @pseudonym.destroy
      end
      Account.default.pseudonyms.create!(user: @user, unique_id: 'bob')

      # strictly speaking we don't want this to be necessary,
      # but I'm not ready to rely on globallookups exclusively
      # for finding appropriate shards
      allow(Account.default).to receive(:trusted_account_ids).and_return([@account.id])

      ul = UserListV2.new('jt@instructure.com', search_type: 'cc_path')
      expect(ul.resolved_results.count).to eq 1
      r = ul.resolved_results.first
      expect(r[:user_id]).to eq @user.id
      expect(r[:user_token]).to eq @user.token
      expect(r[:account_id]).to eq Account.default.id
    end

    context "global lookups" do
      before do
        @shard1.activate do
          @account1 = Account.create!
          @user1 = user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => @account1)
        end
        @shard2.activate do
          @account2 = Account.create!
          @user2 = user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => @account2)
        end

        allow(Account.default).to receive(:trusted_account_ids).and_return([Account.site_admin.id, @account1.id, @account2.id])
        allow(GlobalLookups).to receive(:enabled?).and_return(true)
      end

      it "should look on every shard if there aren't that many shards to look on" do
        Setting.set('global_lookups_shard_threshold', '3') # i.e. if we'd have to look on more than 3 shards, we should use global lookups

        expect(Pseudonym).to receive(:associated_shards_for_column).never
        ul = UserListV2.new('jt@instructure.com', search_type: 'unique_id')
        expect(ul.resolved_results).to be_empty
        expect(ul.duplicate_results.first.map{|r| r[:user_id]}).to match_array([@user1.id, @user2.id])
        expect(ul.duplicate_results.first.map{|r| r[:user_token]}).to match_array([@user1.token, @user2.token])
      end

      it "should use the global lookups to restrict searched shard if there are enough shards to look on" do
        Setting.set('global_lookups_shard_threshold', '1') # i.e. if we'd have to look on more than 1 shards, we should use global lookups

        expect(Pseudonym).to receive(:associated_shards_for_column).once.with(:unique_id, 'jt@instructure.com').and_return([@shard1]) # don't look on shard2
        ul = UserListV2.new('jt@instructure.com', search_type: 'unique_id')
        expect(ul.duplicate_results).to be_empty
        expect(ul.resolved_results.first[:user_id]).to eq @user1.id
        expect(ul.resolved_results.first[:user_token]).to eq @user1.token
      end
    end
  end
end

