#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path('../../../spec_helper', File.dirname(__FILE__))
require_dependency "canvas/oauth/provider"

module Canvas::Oauth
  describe Provider do
    let(:provider) { Provider.new('123') }

    def stub_dev_key(key)
      allow(DeveloperKey).to receive(:where).and_return(double(first: key))
    end

    describe 'initialization' do
      it 'retains the client_id' do
        expect(provider.client_id).to eq '123'
      end

      it 'defaults the redirect_uri to a blank string' do
        expect(provider.redirect_uri).to eq ''
      end

      it 'can override the default redirect_uri' do
        expect(Provider.new('123','456').redirect_uri).to eq '456'
      end

    end

    describe '#has_valid_key?' do

      it 'is true when there is a key and the key is active' do
        stub_dev_key(double(active?: true))
        expect(provider.has_valid_key?).to be_truthy
      end

      it 'is false when there is a key that is not active' do
        stub_dev_key(double(active?: false))
        expect(provider.has_valid_key?).to be_falsey
      end

      it 'is false when there is no key' do
        stub_dev_key(nil)
        expect(provider.has_valid_key?).to be_falsey
      end
    end

    describe '#client_id_is_valid?' do
      it 'is false for a nil id' do
        expect(Provider.new(nil, '456').client_id_is_valid?).to be_falsey
      end

      it 'is false for a non-integer' do
        expect(Provider.new('XXXXX', '456').client_id_is_valid?).to be_falsey
      end

      it 'is true for an integer' do
        expect(Provider.new('123', '456').client_id_is_valid?).to be_truthy
      end
    end

    describe '#has_valid_redirect?' do
      it 'is true when the redirect url is the OOB uri' do
        provider = Provider.new('123', Provider::OAUTH2_OOB_URI)
        expect(provider.has_valid_redirect?).to be_truthy
      end

      it 'is true when the redirect url is kosher for the developerKey' do
        stub_dev_key(double(:redirect_domain_matches? => true))
        expect(provider.has_valid_redirect?).to be_truthy
      end

      it 'is false otherwise' do
        stub_dev_key(double(:redirect_domain_matches? => false))
        expect(provider.has_valid_redirect?).to be_falsey
      end
    end

    describe '#icon_url' do
      it 'delegates to the key' do
        stub_dev_key(double(:icon_url => 'unique_url'))
        expect(provider.icon_url).to eq 'unique_url'
      end
    end

    describe '#key' do
      it 'is nil if there is no client id' do
        expect(Provider.new(nil).key).to be_nil
      end

      it 'delegates to the class level finder on DeveloperKey' do
        key = double
        stub_dev_key(key)
        expect(provider.key).to eq key
      end
    end

    describe 'authorized_token?' do
      let(:developer_key) {DeveloperKey.create!}
      let(:user) {User.create!}

      it 'finds a pre existing token with the same scope' do
        user.access_tokens.create!(:developer_key => developer_key, :scopes => ["#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"], :remember_access => true)
        expect(Provider.new(developer_key.id, "", ['userinfo']).authorized_token?(user)).to eq true
      end

      it 'ignores tokens unless access is remembered' do
        user.access_tokens.create!(:developer_key => developer_key, :scopes => ["#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"])
        expect(Provider.new(developer_key.id, "", ['userinfo']).authorized_token?(user)).to eq false
      end

      it 'ignores tokens for out of band requests ' do
        user.access_tokens.create!(:developer_key => developer_key, :scopes => ["#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"], :remember_access => true)
        expect(Provider.new(developer_key.id, Canvas::Oauth::Provider::OAUTH2_OOB_URI, ['userinfo']).authorized_token?(user)).to eq false
      end
    end

    describe '#app_name' do
      let(:key_attrs) { {:name => 'some app', :user_name => 'some user', :email => 'some email'} }
      let(:key) { double(key_attrs) }

      it 'prefers the key name' do
        stub_dev_key(key)
        expect(provider.app_name).to eq 'some app'
      end

      it 'falls back to the user name' do
        key_attrs[:name] = nil
        stub_dev_key(key)
        expect(provider.app_name).to eq 'some user'
      end

      it 'falls back to the email if there is nothing else' do
        key_attrs[:name] = nil
        key_attrs[:user_name] = nil
        stub_dev_key(key)
        expect(provider.app_name).to eq 'some email'
      end

      it 'goes to the default app name if there are no pieces of data in the key' do
        key_attrs[:name] = nil
        key_attrs[:user_name] = nil
        key_attrs[:email] = nil
        stub_dev_key(key)
        expect(provider.app_name).to eq 'Third-Party Application'
      end
    end

    describe '#session_hash' do

      before { stub_dev_key(double(:id => 123)) }

      it 'uses the key id for a client id' do
        expect(provider.session_hash[:client_id]).to eq 123
      end

      it 'passes the redirect_uri through' do
        provider = Provider.new('123', 'some uri')
        expect(provider.session_hash[:redirect_uri]).to eq 'some uri'
      end

      it 'passes the scope through' do
        provider = Provider.new('123', 'some uri', 'userinfo,full_access')
        expect(provider.session_hash[:scopes]).to eq 'userinfo,full_access'
      end
    end
  end
end
