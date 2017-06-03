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
end
