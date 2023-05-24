# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe DataFixup::CleanupCrossShardDeveloperKeys do
  specs_require_sharding

  before :once do
    @shard1.activate do
      @account1 = account_model
    end
    @dk = DeveloperKey.create!(account: @account1, user: user_model)
  end

  it "deletes developer keys that have no associated access tokens" do
    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect { @dk.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes developer keys that have associated access tokens with deleted users" do
    user_model.update(workflow_state: "deleted")
    AccessToken.create!(user: @user, developer_key: @dk)

    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect { @dk.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes developer keys that have associated access tokens with cross-shard (shadow) users only" do
    @shard1.activate do
      @user1 = user_model
    end
    user_model.update(id: @user1.global_id)
    AccessToken.create!(user: @user, developer_key: @dk)

    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect { @dk.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes all of the developer key's associated objects" do
    user_model.update(workflow_state: "deleted")
    at = AccessToken.create!(user: @user, developer_key: @dk)
    dkab = DeveloperKeyAccountBinding.create!(developer_key: @dk, account: account_model)
    cet = ContextExternalTool.create!(developer_key: @dk,
                                      account: Account.default,
                                      name: "hi",
                                      consumer_key: "do",
                                      shared_secret: "you",
                                      url: "https://knowwherethebathroomis.com")
    cetp = ContextExternalToolPlacement.create!(context_external_tool: cet, placement_type: "course_navigation")

    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect { @dk.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { at.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { dkab.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { cet.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { cetp.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "with site admin keys" do
    let(:user) { @shard1.activate { user_model } }

    let(:site_admin_key) do
      Account.site_admin.shard.activate do
        DeveloperKey.create!
      end
    end

    let(:site_admin_access_token) do
      user.shard.activate do
        AccessToken.create!(developer_key: site_admin_key, user: user)
      end
    end

    before do
      site_admin_access_token.shard.activate { DataFixup::CleanupCrossShardDeveloperKeys.run }
      site_admin_key.shard.activate { DataFixup::CleanupCrossShardDeveloperKeys.run }
    end

    it "does not delete site admin keys" do
      expect(site_admin_key.reload).to be_active
    end

    it "does not delete site admin access tokens" do
      expect(site_admin_access_token.reload).to be_active
    end
  end

  context "with local keys" do
    let!(:local_access_token) { AccessToken.create!(developer_key: local_key, user: user) }
    let!(:local_key) { DeveloperKey.create!(account: root_account) }

    let(:root_account) { Account.root_accounts.first }
    let(:user) { user_model }

    before { DataFixup::CleanupCrossShardDeveloperKeys.run }

    it "does not delete local keys" do
      expect(local_key.reload).to be_active
    end

    it "does not delete local access tokens" do
      expect(local_access_token.reload).to be_active
    end
  end
end
