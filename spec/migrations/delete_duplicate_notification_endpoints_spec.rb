require_relative "../spec_helper"

describe DataFixup::DeleteDuplicateNotificationEndpoints do
  it "removes duplciate notification endpoints based on arn" do
      at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
      ne1 = at.notification_endpoints.build(token: 'token', arn: 'arn')
      ne2 = at.notification_endpoints.build(token: 'TOKEN', arn: 'arn')
      ne1.save_without_callbacks
      ne2.save_without_callbacks

      DataFixup::DeleteDuplicateNotificationEndpoints.run

      expect(NotificationEndpoint.where(arn: 'arn').count).to eq 1
  end
end
