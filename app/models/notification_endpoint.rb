#
# Copyright (C) 2015 Instructure, Inc.
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

class NotificationEndpoint < ActiveRecord::Base
  attr_accessible :token, :arn

  belongs_to :access_token

  validates_presence_of :token, :access_token

  before_create :create_platform_endpoint
  after_destroy :delete_platform_endpoint

  def push_json(json)
    begin
      response = DeveloperKey.sns.client.publish(target_arn: self.arn, message: json, message_structure: 'json')
      response.successful?
    rescue AWS::SNS::Errors::EndpointDisabled
      false
    end
  end

  private
  def create_platform_endpoint
    response = DeveloperKey.sns.client.create_platform_endpoint(
      platform_application_arn: self.access_token.developer_key.sns_arn,
      token: self.token,
      custom_user_data: self.access_token.global_id.to_s
    )
    raise "error creating platform endpoint: #{response.error.message}" unless response.successful?
    self.arn = response.data[:endpoint_arn]
  end

  def delete_platform_endpoint
    response = DeveloperKey.sns.client.delete_endpoint(endpoint_arn: self.arn)
  end
end
