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

  let(:account){ Account.default }

  context "password" do
    it "should decrypt the password to the original value" do
      c = AccountAuthorizationConfig.new
      c.auth_password = "asdf"
      expect(c.auth_decrypted_password).to eql("asdf")
      c.auth_password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(c.auth_decrypted_password).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  describe "enable_canvas_authentication" do

    before do
      account.authentication_providers.destroy_all
      account.settings[:canvas_authentication] = false
      account.save!
      account.authentication_providers.create!(auth_type: 'ldap')
      account.authentication_providers.create!(auth_type: 'cas')
    end

    it "leaves settings as they are after deleting one of many aacs" do
      account.authentication_providers.first.destroy
      expect(account.reload.settings[:canvas_authentication]).to be_falsey
    end

    it "enables canvas_authentication if deleting the last aac" do
      account.authentication_providers.destroy_all
      expect(account.reload.settings[:canvas_authentication]).to be_truthy
    end

  end

  it "should disable open registration when created" do
    account.settings[:open_registration] = true
    account.save!
    account.authentication_providers.create!(auth_type: 'cas')
    expect(account.reload.open_registration?).to be_falsey
  end

  describe "FindByType module" do
    let!(:aac){ account.authentication_providers.create!(auth_type: 'facebook') }

    it "still reloads ok" do
      expect { aac.reload }.to_not raise_error
    end

    it "works through associations that use the provided module" do
      found = account.authentication_providers.find('facebook')
      expect(found).to eq(aac)
    end
  end

  describe "#auth_provider_filter" do
    it "includes nil for legacy auth types" do
      aac = AccountAuthorizationConfig.new(auth_type: "cas")
      expect(aac.auth_provider_filter).to eq([nil, aac])
    end

    it "is just the AAC for oauth types" do
      aac = AccountAuthorizationConfig.new(auth_type: "facebook")
      expect(aac.auth_provider_filter).to eq(aac)
    end
  end

  describe '#destroy' do
    let!(:aac){ account.authentication_providers.create!(auth_type: 'cas') }
    it "retains the database row" do
      aac.destroy
      found = AccountAuthorizationConfig.find(aac.id)
      expect(found).to_not be_nil
    end

    it "sets workflow_state upon destroy" do
      aac.destroy
      aac.reload
      expect(aac.workflow_state).to eq('deleted')
    end

    it "is aliased with #destroy!" do
      aac.destroy!
      found = AccountAuthorizationConfig.find(aac.id)
      expect(found).to_not be_nil
    end

    it "soft-deletes associated pseudonyms" do
      user = user_model
      pseudonym = user.pseudonyms.create!(unique_id: "user@facebook.com")
      pseudonym.authentication_provider = aac
      pseudonym.save!
      aac.destroy
      expect(pseudonym.reload.workflow_state).to eq("deleted")
    end
  end

  describe ".active" do
    let!(:aac){ account.authentication_providers.create!(auth_type: 'cas') }
    it "finds an aac that isn't deleted" do
      expect(AccountAuthorizationConfig.active).to include(aac)
    end

    it "ignores aacs which have been deleted" do
      aac.destroy
      expect(AccountAuthorizationConfig.active).to_not include(aac)
    end
  end

  describe "list-i-ness" do
    let!(:aac1){ account.authentication_providers.create!(auth_type: 'facebook') }
    let!(:aac2){ account.authentication_providers.create!(auth_type: 'github') }

    it "manages positions automatically within an account" do
      expect(aac1.reload.position).to eq(1)
      expect(aac2.reload.position).to eq(2)
    end

    it "respects deletions for position management" do
      aac3 = account.authentication_providers.create!(auth_type: 'twitter')
      expect(aac2.reload.position).to eq(2)
      aac2.destroy
      expect(aac1.reload.position).to eq(1)
      expect(aac3.reload.position).to eq(2)
    end
  end

end
