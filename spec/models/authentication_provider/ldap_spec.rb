# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe AuthenticationProvider::LDAP do
  it "should not escape auth_filter" do
    @account = Account.new
    @account_config = @account.authentication_providers.build(
      auth_type: 'ldap',
      ldap_filter: '(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))'
    )

    @account_config.save
    expect(@account_config.auth_filter).to eql("(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))")
  end

  describe "#test_ldap_search" do
    it "should validate filter syntax" do
      aac = AuthenticationProvider::LDAP.new
      aac.auth_type = 'ldap'
      aac.ldap_filter = 'bob'
      expect(aac.test_ldap_search).to be_falsey
      expect(aac.errors.full_messages.join).to match(/Invalid filter syntax/)

      aac.errors.clear
      aac.ldap_filter = '(sAMAccountName={{login}})'
      expect(aac.test_ldap_search).to be_falsey
      expect(aac.errors.full_messages.join).not_to match(/Invalid filter syntax/)
    end
  end

  context "#ldap_bind_result" do
    before(:once) do
      @account = Account.new
      @account.save!
      @aac = AuthenticationProvider::LDAP.new(account: @account)
      @aac.auth_type = 'ldap'
      @aac.ldap_filter = 'bob'
      @aac.save!
    end

    it "should not attempt to bind with a blank password" do
      aac = AuthenticationProvider::LDAP.new
      aac.auth_type = 'ldap'
      aac.ldap_filter = 'bob'
      expect(aac).to receive(:ldap_connection).never
      aac.ldap_bind_result('test', '')
    end

    context "statsd" do
      before do
        @ldap = double()
        allow(@ldap).to receive(:base)
        allow(@aac).to receive(:ldap_connection).and_return(@ldap)
        allow(@aac).to receive(:ldap_filter).and_return(nil)
        allow(@aac).to receive(:account_id).and_return(1)
        allow(@aac).to receive(:global_id).and_return(2)
        allow(@aac).to receive(:should_send_to_statsd?).and_return(true)
      end

      it "should send to statsd on success" do
        allow(@ldap).to receive(:bind_as).and_return(true)
        expect(InstStatsd::Statsd).to receive(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_success",
                                      short_stat: "ldap_success",
                                      tags: {account_id: Shard.global_id_for(@aac.account_id), auth_provider_id: @aac.global_id})
        @aac.ldap_bind_result('user', 'pass')
      end

      it "should send to statsd on failure" do
        allow(@ldap).to receive(:bind_as).and_return(false)
        expect(InstStatsd::Statsd).to receive(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_failure",
                                                               short_stat: "ldap_failure",
                                                               tags: {account_id: Shard.global_id_for(@aac.account_id), auth_provider_id: @aac.global_id})
        @aac.ldap_bind_result('user', 'pass')
      end

      it "should send to statsd on timeout" do
        allow(@ldap).to receive(:bind_as).and_raise(Timeout::Error)
        expect(InstStatsd::Statsd).to receive(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_timeout",
                                                               short_stat: "ldap_timeout",
                                                               tags: {account_id: Shard.global_id_for(@aac.account_id), auth_provider_id: @aac.global_id})
        allow(InstStatsd::Statsd).to receive(:increment).with(not_eq("#{@aac.send(:statsd_prefix)}.ldap_timeout"))
        @aac.ldap_bind_result('user', 'pass')
      end

      it "should send to statsd on exception" do
        allow(@ldap).to receive(:bind_as).and_raise(StandardError)
        expect(InstStatsd::Statsd).to receive(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_error",
                                                               short_stat: "ldap_error",
                                                               tags: {account_id: Shard.global_id_for(@aac.account_id), auth_provider_id: @aac.global_id})
        allow(InstStatsd::Statsd).to receive(:increment).with(not_eq("#{@aac.send(:statsd_prefix)}.ldap_error"))
        @aac.ldap_bind_result('user', 'pass')
      end
    end
  end
end
