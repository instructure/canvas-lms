# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::SetDefaultRceFavorites do
  before do
    @root_account = Account.default
    @subaccount = @root_account.sub_accounts.create!
    @subsubaccount = @subaccount.sub_accounts.create!
  end

  it "does not do anything if Setting is empty" do
    Setting.set("rce_always_on_developer_key_ids", "")
    expect { DataFixup::SetDefaultRceFavorites.run }.not_to change { @root_account.reload.settings[:rce_favorite_tool_ids] }
  end

  context "with some on_by_default tools" do
    # on_by_default tools are created in the root accounts only (inherited by subaccounts)
    let(:tool1) do
      ContextExternalTool.create!(
        context: @root_account,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key: dev_key_model,
        lti_version: "1.3",
        workflow_state: "public"
      )
    end
    let(:tool2) do
      ContextExternalTool.create!(
        context: @root_account,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key: dev_key_model,
        lti_version: "1.3",
        workflow_state: "public"
      )
    end
    let(:sentry_scope) { double("scope") }

    it "adds the toolids to the root account favorites, but does not modify subaccount settings if they are nil" do
      Setting.set("rce_always_on_developer_key_ids", "#{tool1.developer_key_id},#{tool2.developer_key_id}")
      @subsubaccount.settings[:rce_favorite_tool_ids] = { value: [42, Shard.global_id_for(tool1.id)] }
      @subsubaccount.save!

      DataFixup::SetDefaultRceFavorites.run

      expect(@root_account.reload.settings[:rce_favorite_tool_ids][:value]).to match_array([Shard.global_id_for(tool1.id), Shard.global_id_for(tool2.id)])
      expect(@subaccount.reload.settings[:rce_favorite_tool_ids]).to be_nil
      expect(@subsubaccount.reload.settings[:rce_favorite_tool_ids][:value]).to match_array([42, Shard.global_id_for(tool1.id), Shard.global_id_for(tool2.id)])
    end

    it "caches the tool_ids of the root account" do
      Setting.set("rce_always_on_developer_key_ids", tool1.developer_key_id.to_s)
      @subsubaccount.settings[:rce_favorite_tool_ids] = { value: [42, Shard.global_id_for(tool1.id)] }
      @subsubaccount.save!

      # We have 2 root_accounts and 1 subaccount with non-nil settings, so we expect the cache to be called twice (2 miss, 1 hit)
      expect(ContextExternalTool).to receive(:active).twice.and_call_original

      DataFixup::SetDefaultRceFavorites.run
    end

    it "reports errors to Sentry" do
      Setting.set("rce_always_on_developer_key_ids", tool1.developer_key_id.to_s)
      allow_any_instance_of(Account).to receive(:save!).and_raise(StandardError.new("test error"))

      expect(Sentry).to receive(:with_scope).and_yield(sentry_scope)
      expect(sentry_scope).to receive(:set_tags).with(account_id: @root_account.global_id)
      expect(sentry_scope).to receive(:set_context).with("exception", { name: "StandardError", message: "test error" })
      expect(Sentry).to receive(:capture_message).with("DataFixup#set_default_rce_favorites", { level: :warning })

      DataFixup::SetDefaultRceFavorites.run
    end
  end
end
