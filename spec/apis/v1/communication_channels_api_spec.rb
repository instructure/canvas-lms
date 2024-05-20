# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe "CommunicationChannels API", type: :request do
  describe "index" do
    before :once do
      @someone = user_with_pseudonym
      @admin   = user_with_pseudonym

      Account.site_admin.account_users.create!(user: @admin)

      @path = "/api/v1/users/#{@someone.id}/communication_channels"
      @path_options = { controller: "communication_channels",
                        action: "index",
                        format: "json",
                        user_id: @someone.id.to_param }
    end

    context "an authorized user" do
      it "lists all channels without bounce information for a user that is not a site admin" do
        json = api_call_as_user(@someone, :get, @path, @path_options)

        cc = @someone.communication_channel
        expect(json).to eql [{
          "id" => cc.id,
          "created_at" => cc.created_at.iso8601,
          "address" => cc.path,
          "type" => cc.path_type,
          "position" => cc.position,
          "workflow_state" => "unconfirmed",
          "user_id" => cc.user_id
        }]
      end

      it "lists all channels with bounce information for a user that is a site admin" do
        json = api_call_as_user(@admin, :get, @path, @path_options)

        cc = @someone.communication_channel
        expect(json).to eql [{
          "id" => cc.id,
          "created_at" => cc.created_at.iso8601,
          "address" => cc.path,
          "type" => cc.path_type,
          "position" => cc.position,
          "workflow_state" => "unconfirmed",
          "user_id" => cc.user_id,
          "bounce_count" => 0,
          "last_bounce_at" => nil,
          "last_bounce_summary" => nil,
          "last_suppression_bounce_at" => nil,
          "last_transient_bounce_at" => nil,
          "last_transient_bounce_summary" => nil
        }]
      end
    end

    context "an unauthorized user" do
      it "returns 401" do
        user_with_pseudonym
        raw_api_call(:get, @path, @path_options)
        expect(response).to have_http_status :unauthorized
      end

      it "does not list channels for a teacher's students" do
        course_with_teacher
        @course.enroll_student(@someone)
        @user = @teacher

        raw_api_call(:get, @path, @path_options)
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "create" do
    before :once do
      @someone    = user_with_pseudonym
      @admin      = user_with_pseudonym
      @site_admin = user_with_pseudonym

      Account.site_admin.account_users.create!(user: @site_admin)
      Account.default.account_users.create!(user: @admin)

      @path = "/api/v1/users/#{@someone.id}/communication_channels"
      @path_options = { controller: "communication_channels",
                        action: "create",
                        format: "json",
                        user_id: @someone.id.to_param, }
      @post_params = { communication_channel: {
        address: "new+api@example.com", type: "email"
      } }
    end

    it "registers user if skip_confirmation is truthy" do
      allow(InstStatsd::Statsd).to receive(:increment)
      json = api_call(:post, @path, @path_options, @post_params)
      channel = CommunicationChannel.find(json["id"])
      channel.update(workflow_state: "retired")
      api_call(:post, @path, @path_options, @post_params.merge({ skip_confirmation: 1 }))
      expect(InstStatsd::Statsd).to have_received(:increment).once.with("communication_channels.create.skip_confirmation")

      expect(channel.reload.workflow_state).to eq "active"
      expect(@someone.reload.registered?).to be_truthy
    end

    it "does not create a login on restore of login that was set to build login" do
      json = api_call(:post, @path, @path_options, @post_params.merge({ skip_confirmation: 1 }))
      channel = CommunicationChannel.find(json["id"])
      channel.update(workflow_state: "retired", build_pseudonym_on_confirm: true)
      api_call(:post, @path, @path_options, @post_params.merge({ skip_confirmation: 1 }))
      expect(channel.reload.workflow_state).to eq "active"
      expect(channel.pseudonym).to be_nil
    end

    it "shoulds casing communication channel restores" do
      json = api_call(:post, @path, @path_options, @post_params.merge({ skip_confirmation: 1 }))
      channel = CommunicationChannel.find(json["id"])
      channel.update(workflow_state: "retired", build_pseudonym_on_confirm: true)
      api_call(:post, @path, @path_options, @post_params.merge({
                                                                 skip_confirmation: 1,
                                                                 communication_channel: {
                                                                   address: "NEW+api@example.com",
                                                                   type: "email"
                                                                 }
                                                               }))
      expect(channel.reload.workflow_state).to eq "active"
      expect(channel.path).to eq "NEW+api@example.com"
    end

    it "is able to create new channels" do
      json = api_call(:post, @path, @path_options, @post_params.merge({
                                                                        skip_confirmation: 1
                                                                      }))

      @channel = CommunicationChannel.find(json["id"])

      expect(json).to eq({
                           "id" => @channel.id,
                           "created_at" => @channel.created_at.iso8601,
                           "address" => "new+api@example.com",
                           "type" => "email",
                           "workflow_state" => "active",
                           "user_id" => @someone.id,
                           "position" => 2,
                           "bounce_count" => 0,
                           "last_bounce_at" => nil,
                           "last_bounce_summary" => nil,
                           "last_suppression_bounce_at" => nil,
                           "last_transient_bounce_at" => nil,
                           "last_transient_bounce_summary" => nil
                         })
    end

    it "doesn't error if the user already has a login with the same e-mail address" do
      @someone.pseudonyms.create!(unique_id: "new+api@example.com")
      api_call(:post, @path, @path_options, @post_params.merge(skip_confirmation: 1))
      expect(response).to be_successful
    end

    context "a site admin" do
      before { @user = @site_admin }

      it "is able to auto-validate new channels" do
        json = api_call(:post, @path, @path_options, @post_params.merge({
                                                                          skip_confirmation: 1
                                                                        }))

        @channel = CommunicationChannel.find(json["id"])
        expect(@channel).to be_active
      end
    end

    context "an account admin" do
      before { @user = @admin }

      it "is able to create new channels for other users" do
        json = api_call(:post, @path, @path_options, @post_params)

        @channel = CommunicationChannel.find(json["id"])

        expect(json).to eq({
                             "id" => @channel.id,
                             "created_at" => @channel.created_at.iso8601,
                             "address" => "new+api@example.com",
                             "type" => "email",
                             "workflow_state" => "unconfirmed",
                             "user_id" => @someone.id,
                             "position" => 2
                           })
      end

      it "is able to create new channels for other users and auto confirm" do
        json = api_call(:post, @path, @path_options, @post_params.merge({ skip_confirmation: 1 }))

        @channel = CommunicationChannel.find(json["id"])

        expect(json).to eq({
                             "id" => @channel.id,
                             "created_at" => @channel.created_at.iso8601,
                             "address" => "new+api@example.com",
                             "type" => "email",
                             "workflow_state" => "active",
                             "user_id" => @someone.id,
                             "position" => 2
                           })
      end
    end

    context "a user" do
      before { @user = @someone }

      it "is able to create its own channels" do
        expect do
          api_call(:post, @path, @path_options, @post_params)
        end.to change(CommunicationChannel, :count).by(1)
      end

      it "is not able to create channels for others" do
        raw_api_call(:post,
                     "/api/v1/users/#{@admin.id}/communication_channels",
                     @path_options.merge(user_id: @admin.to_param),
                     @post_params)

        expect(response).to have_http_status :unauthorized
      end

      context "not configured push" do
        let(:dk) { DeveloperKey.default }

        before do
          dk.update!(sns_arn: nil)
          allow(DeveloperKey).to receive(:default).and_return(dk)
        end

        it "complains about sns not being configured" do
          @post_params[:communication_channel] = { token: "registration_token", type: "push" }
          raw_api_call(:post, @path, @path_options, @post_params)

          expect(response).to have_http_status :bad_request
        end
      end

      context "push" do
        before { @post_params.merge!(communication_channel: { token: +"registration_token", type: "push" }) }

        let(:client) { double }
        let(:dk) { DeveloperKey.default }

        it "works" do
          allow(DeveloperKey).to receive(:sns).and_return(client)
          $spec_api_tokens[@user] = @user.access_tokens.create!(developer_key: dk).full_token
          expect(client).to receive(:create_platform_endpoint).once.and_return(endpoint_arn: "endpointarn")

          json = api_call(:post, @path, @path_options, @post_params)
          expect(json["type"]).to eq "push"
          expect(json["workflow_state"]).to eq "active"
          expect(@user.notification_endpoints.first.arn).to eq "endpointarn"
        end

        it "does not create two push channels regardless of case" do
          allow(DeveloperKey).to receive(:sns).and_return(client)
          $spec_api_tokens[@user] = @user.access_tokens.create!(developer_key: dk).full_token
          expect(client).to receive(:create_platform_endpoint).once.and_return(endpoint_arn: "endpointarn")
          @post_params[:communication_channel][:token].upcase!
          api_call(:post, @path, @path_options, @post_params)
          @post_params[:communication_channel][:token].downcase!
          api_call(:post, @path, @path_options, @post_params)
          expect(@user.notification_endpoints.count).to eq 1
        end

        context "shards" do
          specs_require_sharding

          it "does not have unique constraint error for push channel" do
            allow(DeveloperKey).to receive(:sns).and_return(client)
            $spec_api_tokens[@user] = @user.access_tokens.create!(developer_key: dk).full_token
            expect(client).to receive(:create_platform_endpoint).once.and_return(endpoint_arn: "endpointarn")
            api_call(:post, @path, @path_options, @post_params)
            @shard1.activate { @new_user = User.create!(name: "shard one") }
            # this is faster than a user_merge
            @new_user.associate_with_shard(Shard.current)
            @user.access_tokens.update_all(user_id: @new_user.id)
            $spec_api_tokens[@new_user] = $spec_api_tokens[@user]
            @user = @new_user
            @path_options[:user_id] = @user.id
            api_call(:post, "/api/v1/users/#{@user.id}/communication_channels", @path_options, @post_params)
            expect(response).to be_successful
          end
        end
      end
    end
  end

  describe "destroy" do
    let_once(:someone) { user_with_pseudonym }
    let_once(:admin) do
      user = user_with_pseudonym
      Account.default.account_users.create!(user:)
      user
    end
    let_once(:channel) { someone.communication_channel }
    let(:path) { "/api/v1/users/#{someone.id}/communication_channels/#{channel.id}" }
    let(:path_options) do
      { controller: "communication_channels",
        action: "destroy",
        user_id: someone.to_param,
        format: "json",
        id: channel.to_param }
    end

    context "an admin" do
      before { @user = admin }

      it "is able to delete others' channels" do
        json = api_call(:delete, path, path_options)

        expect(json).to eq({
                             "position" => 1,
                             "address" => channel.path,
                             "id" => channel.id,
                             "workflow_state" => "retired",
                             "user_id" => someone.id,
                             "type" => "email",
                             "created_at" => channel.created_at.iso8601
                           })
      end
    end

    context "a user" do
      before { @user = someone }

      it "is able to delete its own channels" do
        json = api_call(:delete, path, path_options)

        expect(json).to eq({
                             "position" => 1,
                             "address" => channel.path,
                             "id" => channel.id,
                             "workflow_state" => "retired",
                             "user_id" => someone.id,
                             "type" => "email",
                             "created_at" => channel.created_at.iso8601
                           })
      end

      it "404s if already deleted" do
        api_call(:delete, path, path_options)
        raw_api_call(:delete, path, path_options)
        expect(response).to have_http_status :not_found
      end

      it "is not able to delete others' channels" do
        admin_channel = admin.communication_channel
        raw_api_call(:delete,
                     "/api/v1/users/#{admin.id}/communication_channels/#{admin_channel.id}",
                     path_options.merge(user_id: admin.to_param, id: admin_channel.to_param))

        expect(response).to have_http_status :unauthorized
      end

      it "is able to delete by path, instead of id" do
        api_call(:delete,
                 "/api/v1/users/#{someone.id}/communication_channels/#{channel.path_type}/#{URI::DEFAULT_PARSER.escape(channel.path)}",
                 controller: "communication_channels",
                 action: "destroy",
                 user_id: someone.to_param,
                 format: "json",
                 type: channel.path_type,
                 address: channel.path)
        expect(CommunicationChannel.find(channel.id)).to be_retired # for some reason, .reload on a let() bound model returns nil
      end

      it "404s if already deleted by path" do
        api_call(:delete,
                 "/api/v1/users/#{someone.id}/communication_channels/#{channel.path_type}/#{URI::DEFAULT_PARSER.escape(channel.path)}",
                 controller: "communication_channels",
                 action: "destroy",
                 user_id: someone.to_param,
                 format: "json",
                 type: channel.path_type,
                 address: channel.path)
        raw_api_call(:delete,
                     "/api/v1/users/#{someone.id}/communication_channels/#{channel.path_type}/#{URI::DEFAULT_PARSER.escape(channel.path)}",
                     controller: "communication_channels",
                     action: "destroy",
                     user_id: someone.to_param,
                     format: "json",
                     type: channel.path_type,
                     address: channel.path)
        expect(response).to have_http_status :not_found
      end
    end
  end
end
