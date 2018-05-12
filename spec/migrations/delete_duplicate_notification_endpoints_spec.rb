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

require_relative "../spec_helper"

describe DataFixup::DeleteDuplicateNotificationEndpoints do
  it "removes duplciate notification endpoints based on arn" do
      sns_client = double()
      allow(sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: 'arn')
      allow(DeveloperKey).to receive(:sns).and_return(sns_client)
      at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
      ne1 = at.notification_endpoints.create!(token: 'token')
      ne2 = at.notification_endpoints.create!(token: 'TOKEN')

      DataFixup::DeleteDuplicateNotificationEndpoints.run

      expect(NotificationEndpoint.where(arn: 'arn').count).to eq 1
  end
end
