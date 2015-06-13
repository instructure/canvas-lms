#
# Copyright (C) 2013 Instructure, Inc.
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

describe AccountAuthorizationConfig do

  context "password" do
    it "should decrypt the password to the original value" do
      c = AccountAuthorizationConfig.new
      c.auth_password = "asdf"
      expect(c.auth_decrypted_password).to eql("asdf")
      c.auth_password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(c.auth_decrypted_password).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  it "should enable canvas auth when destroyed" do
    Account.default.settings[:canvas_authentication] = false
    Account.default.save!
    expect(Account.default.canvas_authentication?).to be_truthy
    aac = Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
    expect(Account.default.canvas_authentication?).to be_falsey
    aac.destroy
    expect(Account.default.reload.canvas_authentication?).to be_truthy
    expect(Account.default.settings[:canvas_authentication]).not_to be_falsey
    Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
    # still true
    expect(Account.default.reload.canvas_authentication?).to be_truthy
  end

  it "should disable open registration when created" do
    Account.default.settings[:open_registration] = true
    Account.default.save!
    Account.default.account_authorization_configs.create!(:auth_type => 'cas')
    expect(Account.default.reload.open_registration?).to be_falsey
  end
end
