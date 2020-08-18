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

require 'spec_helper'

describe DataFixup::CleanupCrossShardDeveloperKeys do
  specs_require_sharding

  before :once do
    @shard1.activate do
      @account1 = account_model
    end
    @dk = DeveloperKey.create!(account: @account1, user: user_model)
  end

  it 'should delete developer keys that have no associated access tokens' do
    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect{@dk.reload}.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should delete developer keys that have associated access tokens with deleted users' do
    user_model.update_attributes(workflow_state: 'deleted')
    AccessToken.create!(user: @user, developer_key: @dk)

    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect{@dk.reload}.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should delete developer keys that have associated access tokens with cross-shard (shadow) users only' do
    @shard1.activate do
      @user1 = user_model
    end
    user_model.update_attributes(id: @user1.global_id)
    AccessToken.create!(user: @user, developer_key: @dk)

    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect{@dk.reload}.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should delete all of the developer key's associated objects" do
    user_model.update_attributes(workflow_state: 'deleted')
    at = AccessToken.create!(user: @user, developer_key: @dk)
    dkab = DeveloperKeyAccountBinding.create!(developer_key: @dk, account: account_model)
    cet = ContextExternalTool.create!(developer_key: @dk, account: Account.default, name: 'hi',
      consumer_key: 'do', shared_secret: 'you', url: 'https://knowwherethebathroomis.com')
    cetp = ContextExternalToolPlacement.create!(context_external_tool: cet, placement_type: 'course_navigation')

    DataFixup::CleanupCrossShardDeveloperKeys.run
    expect{@dk.reload}.to raise_error(ActiveRecord::RecordNotFound)
    expect{at.reload}.to raise_error(ActiveRecord::RecordNotFound)
    expect{dkab.reload}.to raise_error(ActiveRecord::RecordNotFound)
    expect{cet.reload}.to raise_error(ActiveRecord::RecordNotFound)
    expect{cetp.reload}.to raise_error(ActiveRecord::RecordNotFound)
  end
end
