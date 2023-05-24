# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe MediaObjectsController, type: :request do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "POST '/api/v1/media_objects'" do
    let(:user) { @student }

    before do
      user_session(user)
    end

    it "matches the create_media_object api route" do
      assert_recognizes({ :controller => "media_objects", :action => "create_media_object", "format" => "json" }, { path: "api/v1/media_objects", method: :post })
    end

    it "creates the object if it doesn't already exist" do
      @original_count = @user.media_objects.count
      allow_any_instance_of(MediaObject).to receive(:media_sources).and_return("stub")

      json = api_call(:post,
                      "/api/v1/media_objects",
                      { controller: "media_objects",
                        action: "create_media_object",
                        format: "json",
                        context_code: "user_#{@user.id}",
                        id: "new_object",
                        type: "audio",
                        title: "title" })
      @user.reload
      expect(@user.media_objects.count).to eq @original_count + 1
      @media_object = @user.media_objects.last

      expect(@media_object.media_id).to eq "new_object"
      expect(@media_object.media_type).to eq "audio"
      expect(@media_object.title).to eq "title"
      expect(json["media_object"]["id"]).to eq @media_object.id
      expect(json["media_object"]["title"]).to eq @media_object.title
      expect(json["media_object"]["media_type"]).to eq @media_object.media_type
    end

    context "when the context is a cross-shard user" do
      specs_require_sharding

      let(:user_shard) { @shard2 }
      let(:default_shard) { Account.default.shard }
      let(:user_root_account) { account_model }

      let(:user) do
        u = nil

        user_shard.activate do
          u = user_model
          u.user_account_associations.create!(account: user_root_account)
          u
        end
      end

      let(:media_object_request) do
        api_call(
          :post,
          "/api/v1/media_objects",
          {
            controller: "media_objects",
            action: "create_media_object",
            format: "json",
            context_code: "user_#{user.id}",
            id: "new_object",
            type: "video",
            title: "title"
          }
        )
      end

      it "sets the MediaObject root account to the domain root account" do
        new_object = default_shard.activate { MediaObject.find(media_object_request.dig("media_object", "id")) }
        expect(new_object.root_account).to eq Account.default
      end

      it "creates the MediaObject on the domain root account's shard" do
        new_object = default_shard.activate { MediaObject.find(media_object_request.dig("media_object", "id")) }
        expect(new_object.shard).to eq Account.default.shard
      end
    end
  end
end
