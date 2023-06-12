# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class ExternalToolTestController
  include Api::V1::ExternalTools
end

describe Api::V1::ExternalTools do
  let(:controller) { ExternalToolTestController.new }

  describe "#external_tool_json" do
    before do
      course_with_student
    end

    let(:tool) do
      params = { name: "a",
                 url: "www.google.com/tool_launch",
                 domain: "google.com",
                 consumer_key: "12345",
                 shared_secret: "secret",
                 privacy_level: "public" }
      tool = @course.context_external_tools.new(params)
      tool.settings = { selection_width: 1234, selection_height: 99, icon_url: "www.google.com/icon" }
      tool.save
      tool
    end

    it "generates json" do
      json = controller.external_tool_json(tool, @course, @student, nil)
      expect(json["id"]).to eq tool.id
      expect(json["name"]).to eq tool.name
      expect(json["description"]).to eq tool.description
      expect(json["url"]).to eq tool.url
      expect(json["domain"]).to eq tool.domain
      expect(json["consumer_key"]).to eq tool.consumer_key
      expect(json["created_at"]).to eq tool.created_at
      expect(json["updated_at"]).to eq tool.updated_at
      expect(json["privacy_level"]).to eq tool.privacy_level
      expect(json["custom_fields"]).to eq tool.custom_fields
      expect(json["version"]).to eq "1.1"
    end

    it "generates json with 1.3 version" do
      tool.use_1_3 = true
      tool.developer_key_id = 1
      tool.save!
      json = controller.external_tool_json(tool, @course, @student, nil)
      expect(json["version"]).to eq "1.3"
      expect(json["developer_key_id"]).to eq 1
    end

    it "gets default extension settings" do
      json = controller.external_tool_json(tool, @course, @student, nil)
      expect(json["selection_width"]).to eq tool.settings[:selection_width]
      expect(json["selection_height"]).to eq tool.settings[:selection_height]
      expect(json["icon_url"]).to eq tool.settings[:icon_url]
    end

    it "gets extension labels" do
      tool.homework_submission = { label: { "en" => "Hi" } }
      tool.save
      @student.locale = "en"
      @student.save
      json = controller.external_tool_json(tool, @course, @student, nil)
      json["homework_submission"]["label"] = "Hi"
    end

    describe "is_rce_favorite" do
      let(:root_account_tool) do
        tool.context = @course.root_account
        tool.save!
        tool
      end

      it "includes is_rce_favorite when can_be_rce_favorite?" do
        root_account_tool.editor_button = { url: "http://example.com" }
        root_account_tool.is_rce_favorite = true
        root_account_tool.save!
        json = controller.external_tool_json(tool, @course.root_account, account_admin_user, nil)
        expect(json[:is_rce_favorite]).to be true
      end

      it "excludes is_rce_favorite when not can_be_rce_favorite?" do
        root_account_tool.is_rce_favorite = true
        root_account_tool.save!
        json = controller.external_tool_json(tool, @course.root_account, account_admin_user, nil)
        expect(json).not_to have_key(:is_rce_favorite)
      end
    end
  end
end
