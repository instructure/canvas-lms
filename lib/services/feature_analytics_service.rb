# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require "aws-sdk-sqs"

module Services
  class FeatureAnalyticsService
    def self.persist_feature_evaluation(message)
      Canvas.timeout_protection("feature_analytics_queue", raise_on_timeout: false) do
        client.send_message({ queue_url: config["queue_url"], message_body: message.to_json })
      end
    end

    class << self
      private

      def client
        return @client if instance_variable_defined?(:@client)

        client_config = {}
        client_config[:region] = config["region"] if config["region"]
        client_config[:credentials] = Canvas::AwsCredentialProvider.new("feature_analytics", config["vault_credential_path"])

        @client = Aws::SQS::Client.new(client_config)
      end

      def config
        @config ||= DynamicSettings.find("feature_analytics", tree: :private) || {}
      end
    end
  end
end
