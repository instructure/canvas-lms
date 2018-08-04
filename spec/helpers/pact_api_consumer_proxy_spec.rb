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
require_relative '../spec_helper'
require_relative '../contracts/service_consumers/api/proxy_app'

describe PactApiConsumerProxy do

  context 'Authorization header' do

    subject(:proxy) { PactApiConsumerProxy.new }

    before :each do
      # This happens when our Pact tests run -- we need to make it happen
      # here, too.
      ActiveRecord::Base.connection.tables.each do |t|
        ActiveRecord::Base.connection.reset_pk_sequence!(t)
      end

      @student1 = User.create!(name: 'Student1')
      @student2 = User.create!(name: 'Student2')

      student1_token = double(full_token: '1_TOKEN')
      student1_tokens = double(create!: student1_token)
      allow_any_instantiation_of(@student1).to receive(:access_tokens).and_return(student1_tokens)

      student2_token = double(full_token: '2_TOKEN')
      student2_tokens = double(create!: student2_token)
      allow_any_instantiation_of(@student2).to receive(:access_tokens).and_return(student2_tokens)
    end

    it 'sets header for the specified user' do
      expected_env = {
        'HTTP_AUTHORIZATION' => 'Bearer 2_TOKEN'
      }
      expect(CanvasRails::Application).to receive(:call).with(expected_env)

      proxy_env = {
        'HTTP_AUTHORIZATION' => 'some_token',
        'HTTP_AUTH_USER' => 'Student2'
      }
      proxy.call(proxy_env)
    end

    it 'sets header for the first user if one is not specified' do
      expected_env = {
        'HTTP_AUTHORIZATION' => 'Bearer 1_TOKEN'
      }
      expect(CanvasRails::Application).to receive(:call).with(expected_env)

      proxy_env = {
        'HTTP_AUTHORIZATION' => 'some_token',
      }
      proxy.call(proxy_env)
    end

    it 'does not add Authorization header if it is not sent to proxy' do
      expect(CanvasRails::Application)
        .to receive(:call).with(hash_excluding('HTTP_AUTHORIZATION')).twice

      user_but_no_auth_header = {
        'HTTP_AUTH_USER' => 'Some User'
      }
      proxy.call(user_but_no_auth_header)
      proxy.call({})
    end

    it 'removes the HTTP_AUTH_USER header' do
      expect(CanvasRails::Application).to receive(:call).with(hash_excluding('HTTP_AUTH_USER')).twice

      env_with_auth = {
        'HTTP_AUTHORIZATION' => 'some_token',
        'HTTP_AUTH_USER' => 'Student1'
      }
      env_without_auth = {
        'HTTP_AUTH_USER' => 'Student1'
      }
      proxy.call(env_with_auth)
      proxy.call(env_without_auth)
    end

    it 'throws an error if the specified user does not exist' do
      proxy_env = {
        'HTTP_AUTHORIZATION' => 'some_token',
        'HTTP_AUTH_USER' => 'NotAStudent'
      }

      expect { proxy.call(proxy_env) }.to raise_error('There is no user with name NotAStudent.')
    end

    it 'creates a pseudonym for the requested user' do
      allow(CanvasRails::Application).to receive(:call).and_return nil

      proxy_env = {
        'HTTP_AUTHORIZATION' => 'some_token',
        'HTTP_AUTH_USER' => 'Student1'
      }
      proxy.call(proxy_env)
      pseudonym = Pseudonym.last
      expect(pseudonym.unique_id).to eq('Student1@instructure.com')
    end
  end
end
