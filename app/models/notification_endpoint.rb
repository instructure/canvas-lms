# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "aws-sdk-sns"

class NotificationEndpoint < ActiveRecord::Base
  class FailedSnsInteraction < StandardError; end

  include Canvas::SoftDeletable

  belongs_to :access_token

  validates :token, :access_token, presence: true

  before_create :create_platform_endpoint
  after_destroy :delete_platform_endpoint

  def push_json(json)
    return false unless endpoint_exists? && own_endpoint? && endpoint_enabled? && !token_changed?

    sns_client.publish(target_arn: arn, message: json, message_structure: "json")
  end

  private

  DIFFERENT_ATTRIBUTES_ERROR_REGEX = /^Invalid parameter: Token Reason: Endpoint (.*) already exists with the same Token, but different attributes.$/

  def region
    Aws::ARNParser.parse(access_token.developer_key.sns_arn).region
  end

  def sns_client
    DeveloperKey.sns(region:)
  end

  def endpoint_attributes
    @endpoint_attributes ||= sns_client.get_endpoint_attributes(endpoint_arn: arn).attributes
  end

  def endpoint_exists?
    endpoint_attributes
    true
  rescue Aws::SNS::Errors::NotFound
    false
  end

  def own_endpoint?
    endpoint_attributes["CustomUserData"] == access_token.global_id.to_s
  end

  def endpoint_enabled?
    endpoint_attributes["Enabled"] == "true"
  end

  def token_changed?
    token != endpoint_attributes["Token"]
  end

  def create_platform_endpoint
    # try to create new or find existing with our access_token
    retried = false
    begin
      response = sns_client.create_platform_endpoint(
        platform_application_arn: access_token.developer_key.sns_arn,
        token:,
        custom_user_data: access_token.global_id.to_s
      )
      self.arn = response[:endpoint_arn]
    rescue Aws::SNS::Errors::InvalidParameter => e
      # parse already existing with different access_token from the response message
      Canvas::Errors.capture_exception(:push_notifications, e, :info)
      raise unless DIFFERENT_ATTRIBUTES_ERROR_REGEX.match(e.message)

      self.arn = $1
      # steal the endpoint by setting the access token
      endpoint_updated = false
      begin
        sns_client.set_endpoint_attributes(
          endpoint_arn: arn,
          attributes: { "CustomUserData" => access_token.global_id.to_s }
        )
        endpoint_updated = true
      rescue Aws::SNS::Errors::NotFound => ex
        # there's a race condition if the endpoint we JUST found
        # and are trying to update gets deleted by a different
        # request in the same moment.  In this case we should
        # try to create again, since the blocking endpoint is gone,
        # but only once since if it's cyclical something strange
        # is happening.
        endpoint_updated = false
        if retried
          raise FailedSnsInteraction, "Unable to create or reassign SNS endpoint for access_token #{access_token.global_id}"
        end

        retried = true
        Canvas::Errors.capture_exception(:push_notifications, ex, :info)
      end
      retry unless endpoint_updated
    end
  end

  def delete_platform_endpoint
    return unless endpoint_exists? && own_endpoint?

    sns_client.delete_endpoint(endpoint_arn: arn)
  end
end
