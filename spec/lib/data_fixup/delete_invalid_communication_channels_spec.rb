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
