# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::AddHeapFieldsToCommons do
  describe ".run" do
    let(:lti) do
      ContextExternalTool.create!(
        {
          name: "Canvas Commons",
          tool_id: nil,
          context: Account.default,
          shared_secret: "a",
          consumer_key: "b",
          url: "http://example.com/launch"
        }
      )
    end

    context "when custom_fields is nil" do
      before do
        lti.update(custom_fields: nil)
      end

      it "adds the the correct fields" do
        DataFixup::AddHeapFieldsToCommons.run
        expect(lti.reload.custom_fields).to eq({
                                                 "canvas_root_account_uuid" => "$vnd.Canvas.root_account.uuid",
                                                 "usage_metrics_enabled" => "$com.instructure.Account.usage_metrics_enabled",
                                                 "canvas_user_uuid" => "$vnd.instructure.User.uuid"
                                               })
      end
    end

    context "when custom_fields is an empty hash" do
      before do
        lti.update(custom_fields: {})
      end

      it "adds the the correct fields" do
        DataFixup::AddHeapFieldsToCommons.run
        expect(lti.reload.custom_fields).to eq({
                                                 "canvas_root_account_uuid" => "$vnd.Canvas.root_account.uuid",
                                                 "usage_metrics_enabled" => "$com.instructure.Account.usage_metrics_enabled",
                                                 "canvas_user_uuid" => "$vnd.instructure.User.uuid"
                                               })
      end
    end

    context "when custom_fields is not empty" do
      before do
        lti.update(custom_fields: { "key" => "value" })
      end

      it "adds the the correct fields" do
        DataFixup::AddHeapFieldsToCommons.run
        expect(lti.reload.custom_fields).to include({ "canvas_root_account_uuid" => "$vnd.Canvas.root_account.uuid" })
        expect(lti.reload.custom_fields).to include({ "usage_metrics_enabled" => "$com.instructure.Account.usage_metrics_enabled" })
        expect(lti.reload.custom_fields).to include({ "canvas_user_uuid" => "$vnd.instructure.User.uuid" })
      end

      it "keeps the other existing custom fields" do
        DataFixup::AddHeapFieldsToCommons.run
        expect(lti.reload.custom_fields).to include({ "key" => "value" })
      end
    end

    context "when the custom fields are already present" do
      before do
        lti.update(custom_fields: {
                     "key" => "value",
                     "canvas_root_account_uuid" => "already set",
                     "usage_metrics_enabled" => "already set",
                     "canvas_user_uuid" => "already set",
                   })
      end

      it "does not set the custom fields" do
        DataFixup::AddHeapFieldsToCommons.run
        expect(lti.reload.custom_fields["canvas_root_account_uuid"]).to eq("already set")
        expect(lti.reload.custom_fields["usage_metrics_enabled"]).to eq("already set")
        expect(lti.reload.custom_fields["canvas_user_uuid"]).to eq("already set")
      end
    end
  end
end
