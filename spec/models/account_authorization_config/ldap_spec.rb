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

describe AccountAuthorizationConfig::LDAP do
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
      aac = AccountAuthorizationConfig::LDAP.new
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
      @aac = AccountAuthorizationConfig::LDAP.new(account: @account)
      @aac.auth_type = 'ldap'
      @aac.ldap_filter = 'bob'
      @aac.save!
    end

    it "should not attempt to bind with a blank password" do
      aac = AccountAuthorizationConfig::LDAP.new
      aac.auth_type = 'ldap'
      aac.ldap_filter = 'bob'
      aac.expects(:ldap_connection).never
      aac.ldap_bind_result('test', '')
    end

    context "statsd" do
      before do
        @ldap = mock()
        @ldap.stubs(:base)
        @aac.expects(:ldap_connection).returns(@ldap)
        @aac.expects(:ldap_filter).returns(nil)
      end

      it "should send to statsd on success" do
        @ldap.stubs(:bind_as).returns(true)
        CanvasStatsd::Statsd.expects(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_success")
        @aac.ldap_bind_result('user', 'pass')
      end

      it "should send to statsd on failure" do
        @ldap.stubs(:bind_as).returns(false)
        CanvasStatsd::Statsd.expects(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_failure")
        @aac.ldap_bind_result('user', 'pass')
      end

      it "should send to statsd on timeout" do
        @ldap.stubs(:bind_as).raises(Timeout::Error)
        CanvasStatsd::Statsd.expects(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_timeout")
        CanvasStatsd::Statsd.stubs(:increment).with(Not(equals("#{@aac.send(:statsd_prefix)}.ldap_timeout")))
        @aac.ldap_bind_result('user', 'pass')
      end

      it "should send to statsd on exception" do
        @ldap.stubs(:bind_as).raises(StandardError)
        CanvasStatsd::Statsd.expects(:increment).with("#{@aac.send(:statsd_prefix)}.ldap_error")
        CanvasStatsd::Statsd.stubs(:increment).with(Not(equals("#{@aac.send(:statsd_prefix)}.ldap_error")))
        @aac.ldap_bind_result('user', 'pass')
      end
    end
  end
end
