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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20111121175219_disable_open_registration_for_delegated_auth.rb'

describe 'DisableOpenRegistrationForDelegatedAuth' do
  describe "up" do
    it "should work" do
      @cas_account = Account.create!
      @saml_account = Account.create!
      @ldap_account = Account.create!
      @normal_account = Account.create!
      @all_accounts = [@cas_account, @saml_account, @ldap_account, @normal_account]
      @cas_account.account_authorization_configs.create!(:auth_type => 'cas')
      @saml_account.account_authorization_configs.create!(:auth_type => 'saml')
      @ldap_account.account_authorization_configs.create!(:auth_type => 'ldap')
      @all_accounts.each do |account|
        # have to bypass the settings= logic for weeding these out since they don't
        # apply
        account.write_attribute(:settings, { :open_registration => true })
        account.save!
        expect(account.open_registration?).to be_truthy
      end

      DisableOpenRegistrationForDelegatedAuth.up

      @all_accounts.each(&:reload)
      expect(@cas_account.open_registration?).to be_falsey
      expect(@saml_account.open_registration?).to be_falsey
      expect(@ldap_account.open_registration?).to be_truthy
      expect(@normal_account.open_registration?).to be_truthy
    end
  end
end
