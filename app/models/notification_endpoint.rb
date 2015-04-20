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

require 'aws-sdk'

class NotificationEndpoint < ActiveRecord::Base
  attr_accessible :token, :arn

  belongs_to :access_token

  validates_presence_of :token, :access_token

  before_create :create_platform_endpoint
  after_destroy :delete_platform_endpoint

  def push_json(json)
    return false unless endpoint_exists? && own_endpoint? && endpoint_enabled?
    sns_client.publish(target_arn: self.arn, message: json, message_structure: 'json')
  end

  private

  DIFFERENT_ATTRIBUTES_ERROR_REGEX = %r{^Invalid parameter: Token Reason: Endpoint (.*) already exists with the same Token, but different attributes.$}

  def sns_client
    DeveloperKey.sns.client
  end

  def endpoint_attributes
    @endpoint_attributes ||= begin
      response = sns_client.get_endpoint_attributes(endpoint_arn: self.arn)
      response[:attributes]
    end
  end

  def endpoint_exists?
    begin
      endpoint_attributes
      true
    rescue AWS::SNS::Errors::NotFound
      false
    end
  end

  def own_endpoint?
    endpoint_attributes['CustomUserData'] == access_token.global_id.to_s
  end

  def endpoint_enabled?
    endpoint_attributes['Enabled'] == 'true'
  end

  def create_platform_endpoint
    # try to create new or find existing with our access_token
    begin
      response = sns_client.create_platform_endpoint(
        platform_application_arn: access_token.developer_key.sns_arn,
        token: self.token,
        custom_user_data: access_token.global_id.to_s
      )
      self.arn = response[:endpoint_arn]
    rescue AWS::SNS::Errors::InvalidParameter => e
      # parse already existing with different access_token from the response message
      raise unless DIFFERENT_ATTRIBUTES_ERROR_REGEX.match(e.message)
      self.arn = $1
      # steal the endpoint by setting the access token
      sns_client.set_endpoint_attributes(
        endpoint_arn: self.arn,
        attributes: {'CustomUserData' => access_token.global_id.to_s}
      )
    end
  end

  def delete_platform_endpoint
    return unless endpoint_exists? && own_endpoint?
    sns_client.delete_endpoint(endpoint_arn: self.arn)
  end
end
