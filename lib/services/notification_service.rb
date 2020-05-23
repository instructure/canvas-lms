#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'aws-sdk-sqs'

module Services
  class NotificationService
    def self.process(global_id, body, type, to, priority=false)
      queue_url = choose_queue_url(priority)
      return unless queue_url.present?

      notification_sqs.send_message(message_body: {
          global_id: global_id,
          type: type,
          message: body,
          target: to,
          request_id: RequestContextGenerator.request_id
        }.to_json,
        queue_url: queue_url)
    end

    class << self
      private

      QUEUE_NAME_KEYS = {
        priority: 'notification_service_priority_queue_name',
        default: 'notification_service_queue_name'
      }.freeze

      def notification_sqs
        return nil if config.blank?

        @notification_sqs ||= begin
          conf = Canvas::AWS.validate_v2_config(config, 'notification_service.yml')
          sqs = Aws::SQS::Client.new(conf.except(*QUEUE_NAME_KEYS.values))
          @queue_urls = {}
          QUEUE_NAME_KEYS.each do |key, queue_name_key|
            queue_name = conf[queue_name_key]
            next unless queue_name.present?
            @queue_urls[key] = sqs.get_queue_url(queue_name: queue_name).queue_url
          end
          sqs
        end
      end

      def choose_queue_url(priority)
        return nil unless notification_sqs.present?
        url = @queue_urls[:priority] if priority
        url || @queue_urls[:default]
      end

      def config
        ConfigFile.load('notification_service').dup || {}
      end
    end
  end
end
