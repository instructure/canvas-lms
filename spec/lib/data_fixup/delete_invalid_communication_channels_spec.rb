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
#

require "spec_helper"

describe DataFixup::DeleteInvalidCommunicationChannels do
  before :once do
    user_model
    @channel = @user.communication_channels.create!(
      path: "valid@example.com",
      path_type: CommunicationChannel::TYPE_EMAIL
    )
  end

  it "deletes email address with no @ sign" do
    CommunicationChannel.where(id: @channel.id).update_all(path: "invalid.com")
    DataFixup::DeleteInvalidCommunicationChannels.run
    expect(CommunicationChannel.where(id: @channel.id).exists?).to be_falsey
  end

  it "keeps a valid email address" do
    DataFixup::DeleteInvalidCommunicationChannels.run
    expect(CommunicationChannel.where(id: @channel.id).exists?).to be_truthy
  end

  it "doesn't touch non-email channels" do
    CommunicationChannel.where(id: @channel.id).update_all(
      path_type: CommunicationChannel::TYPE_SMS
    )
    DataFixup::DeleteInvalidCommunicationChannels.run
    expect(CommunicationChannel.where(id: @channel.id).exists?).to be_truthy
  end

  it "fixes valid email with whitespace" do
    CommunicationChannel.where(id: @channel.id).update_all(path: " valid@example.com")
    DataFixup::DeleteInvalidCommunicationChannels.run
    expect(CommunicationChannel.where(id: @channel.id).pluck(:path)).to eq(["valid@example.com"])
  end

  it "deletes valid duplicate email with whitespace" do
    CommunicationChannel.where(id: @channel.id).update_all(path: " valid@example.com")
    @channel2 = @user.communication_channels.create!(
      path: "valid@example.com",
      path_type: CommunicationChannel::TYPE_EMAIL
    )
    DataFixup::DeleteInvalidCommunicationChannels.run
    expect(CommunicationChannel.where(id: @channel.id).exists?).to be_falsey
  end

  it "deletes valid duplicate email with whitespace and mixed case" do
    CommunicationChannel.where(id: @channel.id).update_all(path: " Valid@Example.com")
    @channel2 = @user.communication_channels.create!(
      path: "valid@example.com",
      path_type: CommunicationChannel::TYPE_EMAIL
    )
    DataFixup::DeleteInvalidCommunicationChannels.run
    expect(CommunicationChannel.where(id: @channel.id).exists?).to be_falsey
  end
end
