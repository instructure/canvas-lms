# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe CommMessagesApiController, type: :request do
  describe "index" do
    context "a site admin" do
      context "with permission" do
        before :once do
          @test_user = user_factory(active_all: true)
          site_admin_user
        end

        it "is able to see all messages" do
          Message.create!(user: @test_user, body: "site admin message", root_account_id: Account.site_admin.id)
          Message.create!(user: @test_user, body: "account message", root_account_id: Account.default.id)
          json = api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}", {
                            controller: "comm_messages_api",
                            action: "index",
                            format: "json",
                            user_id: @test_user.to_param
                          })
          expect(json.size).to be 2
          expect(EmailAddressValidator.valid?(json.first["from"])).to be_truthy
          expect(json.first["from_name"]).to eq "Instructure Canvas"
          expect(json.pluck("body").sort).to eql ["account message", "site admin message"]
        end

        it "requires a valid user_id parameter" do
          raw_api_call(:get, "/api/v1/comm_messages", {
                         controller: "comm_messages_api", action: "index", format: "json"
                       })
          expect(response).to have_http_status :not_found

          raw_api_call(:get, "/api/v1/comm_messages?user_id=0", {
                         controller: "comm_messages_api",
                         action: "index",
                         format: "json",
                         user_id: "0"
                       })
          expect(response).to have_http_status :not_found
        end

        it "uses start_time and end_time parameters to limit results" do
          m = Message.new(user: @test_user, body: "account message", root_account_id: Account.default.id)
          m.write_attribute(:created_at, 1.day.from_now)
          m.save!
          m2 = Message.create!(user: @test_user, body: "account message", root_account_id: Account.default.id)

          start_time = 1.hour.ago.iso8601
          end_time = 1.hour.from_now.iso8601
          json = api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}&start_time=#{start_time}&end_time=#{end_time}", {
                            controller: "comm_messages_api",
                            action: "index",
                            format: "json",
                            user_id: @test_user.to_param,
                            start_time:,
                            end_time:
                          })
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq m2.id
        end

        it "paginates results" do
          5.times do |v|
            Message.create!(user: @test_user, body: "body #{v}", root_account_id: Account.default.id)
          end
          json = api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}&per_page=2", {
                            controller: "comm_messages_api",
                            action: "index",
                            format: "json",
                            user_id: @test_user.to_param,
                            per_page: "2"
                          })
          expect(json.size).to be 2

          json = api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}&per_page=2&page=2", {
                            controller: "comm_messages_api",
                            action: "index",
                            format: "json",
                            user_id: @test_user.to_param,
                            per_page: "2",
                            page: "2"
                          })
          expect(json.size).to be 2

          json = api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}&per_page=2&page=3", {
                            controller: "comm_messages_api",
                            action: "index",
                            format: "json",
                            user_id: @test_user.to_param,
                            per_page: "2",
                            page: "3"
                          })
          expect(json.size).to be 1
        end
      end

      context "without permission" do
        before do
          @test_user = user_factory(active_all: true)
          account_admin_user_with_role_changes(account: Account.site_admin,
                                               role_changes: { read_messages: false })
        end

        it "receives unauthorized" do
          raw_api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}", {
                         controller: "comm_messages_api",
                         action: "index",
                         format: "json",
                         user_id: @test_user.to_param
                       })
          expect(response).to have_http_status :unauthorized
        end
      end
    end

    context "an account admin" do
      context "with permission" do
        before :once do
          @test_user = user_factory(active_all: true)
          account_admin_user_with_role_changes(account: Account.default,
                                               role_changes: { view_notifications: true })
        end

        it "receives unauthorized if account setting disabled" do
          Account.default.settings[:admins_can_view_notifications] = false
          Account.default.save!
          raw_api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}", {
                         controller: "comm_messages_api",
                         action: "index",
                         format: "json",
                         user_id: @test_user.to_param
                       })
          expect(response).to have_http_status :unauthorized
        end

        it "is only able to see associated account's messages" do
          Account.default.settings[:admins_can_view_notifications] = true
          Account.default.save!
          Message.create!(user: @test_user, body: "site admin message", root_account_id: Account.site_admin.id)
          Message.create!(user: @test_user, body: "account message", root_account_id: Account.default.id)
          json = api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}", {
                            controller: "comm_messages_api",
                            action: "index",
                            format: "json",
                            user_id: @test_user.to_param
                          })
          expect(json.size).to be 1
          expect(json.pluck("body").sort).to eql ["account message"]
        end
      end

      context "without permission" do
        before do
          @test_user = user_factory(active_all: true)
          account_admin_user_with_role_changes(account: Account.default,
                                               role_changes: { view_notifications: false })
        end

        it "receives unauthorized" do
          raw_api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}", {
                         controller: "comm_messages_api",
                         action: "index",
                         format: "json",
                         user_id: @test_user.to_param
                       })
          expect(response).to have_http_status :unauthorized
        end
      end
    end

    context "an unauthorized user" do
      before do
        @test_user = user_factory(active_all: true)
        @user = user_factory(active_all: true)
      end

      it "receives unauthorized" do
        raw_api_call(:get, "/api/v1/comm_messages?user_id=#{@test_user.id}", {
                       controller: "comm_messages_api",
                       action: "index",
                       format: "json",
                       user_id: @test_user.to_param
                     })
        expect(response).to have_http_status :unauthorized
      end
    end
  end
end
