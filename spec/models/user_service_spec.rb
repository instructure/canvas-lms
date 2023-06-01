# frozen_string_literal: true

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

describe UserService do
  before :once do
    user_service_model
  end

  it "has a useful workflow" do
    expect(@user_service.state).to be(:active)
    @user_service.failed_request
    expect(@user_service.state).to be(:failed)
  end

  it "has a named scope for type" do
    @user_service.type = "BookmarkService"
    @user_service.save!
    expect(UserService.of_type("BookmarkService").first.id).to eql(@user_service.id)
  end

  it "has a named scope for service" do
    expect(UserService.for_service(@user_service)).to eq [@user_service]
    expect(UserService.for_service(@user_service.service)).to eq [@user_service]
  end

  it "has a service_name" do
    expect(@user_service.service_name).to eql("Value For Service")
  end

  it "is able to crypt a password" do
    expect(@user_service.crypted_password).to be_nil
    @user_service.password = "password"
    expect(@user_service.crypted_password).not_to be_nil
    expect(@user_service.decrypted_password).to eql("password")
  end

  context "registration" do
    specs_require_sharding

    it "is able to register a UserService, defaulting to a GoogleDocs service" do
      @registration = UserService.register(
        user: user_model,
        token: "some token",
        secret: "some secret",
        service_user_id: @user.id,
        service_user_name: @user.name,
        service_user_url: "some url",
        password: "password"
      )
      expect(@registration.token).to eql("some token")
      expect(@registration.secret).to eql("some secret")
      expect(@registration.service_user_id.to_i).to eql(@user.id)
      expect(@registration.service_user_name).to eql(@user.name)
      expect(@registration.service_user_url).to eql("some url")
      expect(@registration.decrypted_password).to eql("password")
      expect(@registration.type).to eql("DocumentService")
    end

    it "is able to register a diigo service" do
      params = {}
      params[:service] = "diigo"
      params[:user_name] = "some username"
      params[:password] = "password"

      us = UserService.register_from_params(user_model, params)

      expect(us.service_domain).to eql("diigo.com")
      expect(us.protocol).to eql("http-auth")
      expect(us.service_user_id).to eql("some username")
      expect(us.service_user_name).to eql("some username")
      expect(us.decrypted_password).to eql("password")
    end

    it "allows user services to be setup cross shard" do
      user = User.new
      @shard1.activate { user.save! }
      @shard2.activate do
        @registration = UserService.register(
          user:,
          token: "some token",
          secret: "some secret",
          service_user_id: user.id,
          service_user_name: user.name,
          service_user_url: "some url",
          password: "password"
        )

        expect(@registration.token).to eql("some token")
        expect(@registration.secret).to eql("some secret")
        expect(@registration.service_user_id.to_i).to eql(user.id)
        expect(@registration.service_user_name).to eql(user.name)
        expect(@registration.service_user_url).to eql("some url")
        expect(@registration.decrypted_password).to eql("password")
        expect(@registration.type).to eql("DocumentService")
      end
    end

    it "is not able to register an unknown service type" do
      params = {}
      params[:service] = "some crazy service"
      params[:user_name] = "some username"
      params[:password] = "password"

      expect { UserService.register_from_params(user_model, params) }.to raise_error("Unknown Service Type")
    end
  end

  context "service type disambiguation" do
    it "knows that google_drive means 'DocumentService" do
      expect(UserService.service_type("google_drive")).to eql("DocumentService")
    end

    it "knows that diigo means BookmarkService" do
      expect(UserService.service_type("diigo")).to eql("BookmarkService")
    end

    it "uses other things as a generic UserService" do
      expect(UserService.service_type("anything else")).to eql("UserService")
    end
  end

  context "password" do
    it "decrypts the password to the original value" do
      s = UserService.new
      s.password = "asdf"
      expect(s.decrypted_password).to eql("asdf")
      s.password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(s.decrypted_password).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  describe "valid?" do
    it "validates character length maximum (255) for user input fields" do
      lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
      exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure
      dolor in reprehenderit."
      params = {}
      params[:service] = "diigo"
      params[:user_name] = lorem_ipsum
      params[:password] = "password"
      expect { UserService.register_from_params(user_model, params) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Service user is too long (maximum is 255 characters), Service user name is too long (maximum is 255 characters)"
        )
    end
  end
end
