#
# Copyright (C) 2014-2016 Instructure, Inc.
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

module Services
  class NotificationService
    def self.process(global_id, body, type, to)
      return unless notification_queue.present?

      notification_queue.send_message(message_body: {
          global_id: global_id,
          type: type,
          message: body,
          target: to,
          request_id: RequestContextGenerator.request_id
        }.to_json,
        queue_url: @queue_url)
    end

    class << self
      private

      def notification_queue
        return nil if config.blank?

        @notification_queue ||= begin
          conf = Canvas::AWS.validate_v2_config(config, 'notification_service.yml')
          queue_name = conf['notification_service_queue_name']
          sqs = Aws::SQS::Client.new(conf.except('notification_service_queue_name'))
          @queue_url = sqs.get_queue_url(queue_name: queue_name).queue_url
          sqs
        end
      end

      def config
        ConfigFile.load('notification_service') || {}
      end
    end
  end
end
