#
# Copyright (C) 2014 Instructure, Inc.
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

class NotificationService
  DEFAULT_CONFIG = {
    notification_service_queue_name: 'notification-service'
  }.freeze

  def self.process(global_id, body, type, to, remote)
    self.notification_queue.send_message({
      'global_id' => global_id,
      'type' => type,
      'delivery' => { 'remote' => remote },
      'message' => body,
      'target' => to
    }.to_json)
  end

  def self.notification_queue
    return @notification_queue if defined?(@notification_queue)
    @config ||= DEFAULT_CONFIG.merge(ConfigFile.load('notification_service').try(:symbolize_keys))
    sqs = AWS::SQS.new(@config)
    @notification_queue = sqs.queues.named(@config[:notification_service_queue_name])
  end
end
