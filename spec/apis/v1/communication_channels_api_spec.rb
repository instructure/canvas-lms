#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe 'CommunicationChannels API', type: :request do
  describe 'index' do
    before :once do
      @someone = user_with_pseudonym
      @admin   = user_with_pseudonym

      Account.site_admin.account_users.create!(user: @admin)

      @path = "/api/v1/users/#{@someone.id}/communication_channels"
      @path_options = { :controller => 'communication_channels',
        :action => 'index', :format => 'json', :user_id => @someone.id.to_param }
    end

    context 'an authorized user' do
      it 'should list all channels' do
        json = api_call(:get, @path, @path_options)

        cc = @someone.communication_channel
        expect(json).to eql [{
          'id'       => cc.id,
          'address'  => cc.path,
          'type'     => cc.path_type,
          'position' => cc.position,
          'workflow_state' => 'unconfirmed',
          'user_id'  => cc.user_id }]
      end
    end

    context 'an unauthorized user' do
      it 'should return 401' do
        user_with_pseudonym
        raw_api_call(:get, @path, @path_options)
        expect(response.code).to eql '401'
      end

      it "should not list channels for a teacher's students" do
        course_with_teacher
        @course.enroll_student(@someone)
        @user = @teacher

        raw_api_call(:get, @path, @path_options)
        expect(response.code).to eql '401'
      end
    end
  end

  describe 'create' do
    before :once do
      @someone    = user_with_pseudonym
      @admin      = user_with_pseudonym
      @site_admin = user_with_pseudonym

      Account.site_admin.account_users.create!(user: @site_admin)
      Account.default.account_users.create!(user: @admin)

      @path = "/api/v1/users/#{@someone.id}/communication_channels"
      @path_options = { :controller => 'communication_channels',
        :action => 'create', :format => 'json',
        :user_id => @someone.id.to_param, }
      @post_params = { :communication_channel => {
        :address => 'new+api@example.com', :type => 'email' }}
    end

    it 'should be able to create new channels' do
      json = api_call(:post, @path, @path_options, @post_params.merge({
        :skip_confirmation => 1 }))

      @channel = CommunicationChannel.find(json['id'])

      expect(json).to eq({
        'id' => @channel.id,
        'address' => 'new+api@example.com',
        'type' => 'email',
        'workflow_state' => 'active',
        'user_id' => @someone.id,
        'position' => 2
      })
    end

    context 'a site admin' do
      before { @user = @site_admin }

      it 'should be able to auto-validate new channels' do
        json = api_call(:post, @path, @path_options, @post_params.merge({
          :skip_confirmation => 1 }))

        @channel = CommunicationChannel.find(json['id'])
        expect(@channel).to be_active
      end
    end

    context 'an account admin' do
      before { @user = @admin }

      it 'should be able to create new channels for other users' do
        json = api_call(:post, @path, @path_options, @post_params)

        @channel = CommunicationChannel.find(json['id'])

        expect(json).to eq({
          'id' => @channel.id,
          'address' => 'new+api@example.com',
          'type' => 'email',
          'workflow_state' => 'unconfirmed',
          'user_id' => @someone.id,
          'position' => 2
        })
      end

      it 'should be able to create new channels for other users and auto confirm' do
        json = api_call(:post, @path, @path_options, @post_params.merge({:skip_confirmation => 1}))

        @channel = CommunicationChannel.find(json['id'])

        expect(json).to eq({
          'id' => @channel.id,
          'address' => 'new+api@example.com',
          'type' => 'email',
          'workflow_state' => 'active',
          'user_id' => @someone.id,
          'position' => 2
        })
      end

    end

    context 'a user' do
      before { @user = @someone }

      it 'should be able to create its own channels' do
        expect {
          api_call(:post, @path, @path_options, @post_params)
        }.to change(CommunicationChannel, :count).by(1)
      end

      it 'should not be able to create channels for others' do
        raw_api_call(:post, "/api/v1/users/#{@admin.id}/communication_channels",
          @path_options.merge(:user_id => @admin.to_param), @post_params)

        expect(response.code).to eql '401'
      end

      context 'push' do
        before { @post_params.merge!(communication_channel: {token: 'registration_token', type: 'push'}) }

        it 'should complain about sns not being configured' do
          raw_api_call(:post, @path, @path_options, @post_params)

          expect(response.code).to eql '400'
        end

        it "should work" do
          client = mock()
          sns = mock()
          sns.stubs(:client).returns(client)
          DeveloperKey.stubs(:sns).returns(sns)
          dk = DeveloperKey.default
          dk.sns_arn = 'apparn'
          dk.save!
          $spec_api_tokens[@user] = @user.access_tokens.create!(developer_key: dk).full_token
          client.expects(:create_platform_endpoint).once.returns(endpoint_arn: 'endpointarn')

          json = api_call(:post, @path, @path_options, @post_params)
          expect(json['type']).to eq 'push'
          expect(json['workflow_state']).to eq 'active'
          expect(@user.notification_endpoints.first.arn).to eq 'endpointarn'
        end
      end
    end
  end

  describe 'destroy' do
    let_once(:someone) { user_with_pseudonym }
    let_once(:admin) do
      user = user_with_pseudonym
      Account.default.account_users.create!(user: user)
      user
    end
    let_once(:channel) { someone.communication_channel }
    let(:path) {"/api/v1/users/#{someone.id}/communication_channels/#{channel.id}"}
    let(:path_options) do
      { :controller => 'communication_channels',
        :action => 'destroy', :user_id => someone.to_param, :format => 'json',
        :id => channel.to_param }
    end

    context 'an admin' do
      before(:each) { @user = admin }

      it "should be able to delete others' channels" do
        json = api_call(:delete, path, path_options)

        expect(json).to eq({
          'position' => 1,
          'address' => channel.path,
          'id' => channel.id,
          'workflow_state' => 'retired',
          'user_id' => someone.id,
          'type' => 'email'
        })
      end
    end

    context 'a user' do
      before(:each) { @user = someone }

      it 'should be able to delete its own channels' do
        json = api_call(:delete, path, path_options)

        expect(json).to eq({
          'position' => 1,
          'address' => channel.path,
          'id' => channel.id,
          'workflow_state' => 'retired',
          'user_id' => someone.id,
          'type' => 'email'
        })
      end

      it "should 404 if already deleted" do
        api_call(:delete, path, path_options)
        raw_api_call(:delete, path, path_options)
        expect(response.code).to eq '404'
      end

      it "should not be able to delete others' channels" do
        admin_channel = admin.communication_channel
        raw_api_call(:delete, "/api/v1/users/#{admin.id}/communication_channels/#{admin_channel.id}",
                     path_options.merge(:user_id => admin.to_param, :id => admin_channel.to_param))

        expect(response.code).to eql '401'
      end

      it "should be able to delete by path, instead of id" do
        api_call(:delete, "/api/v1/users/#{someone.id}/communication_channels/#{channel.path_type}/#{URI.escape(channel.path)}",
                 :controller => 'communication_channels',
                 :action => 'destroy', :user_id => someone.to_param, :format => 'json',
                 :type => channel.path_type, :address => channel.path)
        expect(CommunicationChannel.find(channel.id)).to be_retired # for some reason, .reload on a let() bound model returns nil
      end

      it "should 404 if already deleted by path" do
        api_call(:delete, "/api/v1/users/#{someone.id}/communication_channels/#{channel.path_type}/#{URI.escape(channel.path)}",
                 :controller => 'communication_channels',
                 :action => 'destroy', :user_id => someone.to_param, :format => 'json',
                 :type => channel.path_type, :address => channel.path)
        raw_api_call(:delete, "/api/v1/users/#{someone.id}/communication_channels/#{channel.path_type}/#{URI.escape(channel.path)}",
                     :controller => 'communication_channels',
                     :action => 'destroy', :user_id => someone.to_param, :format => 'json',
                     :type => channel.path_type, :address => channel.path)
        expect(response.code).to eq '404'
      end
    end
  end
end
