#
# Copyright (C) 2011 - present Instructure, Inc.
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

class MessageDispatcher < Delayed::PerformableMethod
  def self.dispatch(message)
    Delayed::Job.enqueue(self.new(message.for_queue, :deliver),
                         run_at: message.dispatch_at,
                         priority: 25,
                         max_attempts: 15)
  end

  def self.batch_dispatch(messages)
    return if messages.empty?

    if messages.size == 1
      self.dispatch(messages.first)
      return
    end

    Delayed::Job.enqueue(self.new(self, :deliver_batch, [messages.map(&:for_queue)]),
                         run_at: messages.first.dispatch_at,
                         priority: 25,
                         max_attempts: 15)
  end

  # Called by delayed_job when a job fails to reschedule it.
  def reschedule_at(now, num_attempts)
    object.dispatch_at
  end

  protected

  def self.deliver_batch(messages)
    if messages.first.is_a?(Message::Queued)
      queued = messages.sort_by(&:created_at)
      message_ids = []
      messages = []
      start_time = nil
      previous_time = nil
      current_partition = nil
      queued.each_with_index do |m, i|
        start_time ||= m.created_at
        previous_time ||= m.created_at
        partition = Message.infer_partition_table_name('created_at' => m.created_at)
        current_partition ||= partition

        if partition != current_partition || i == queued.length - 1
          # catch the last item in the list, since there will be no lookback
          if i == queued.length - 1
            message_ids << m.id
            previous_time = m.created_at
          end
          range_for_partition = start_time..previous_time
          messages.concat(Message.in_partition('created_at' => start_time).where(id: message_ids, created_at: range_for_partition).to_a)
          message_ids = []
          start_time = m.created_at
          current_partition = partition
        end

        message_ids << m.id
        previous_time = m.created_at
      end
      raise ActiveRecord::RecordNotFound unless messages.length == queued.length
    end
    messages.each do |message|
      begin
        message.deliver
      rescue Exception, Timeout::Error => e
        # this delivery failed, we'll have to make an individual job to retry
        self.dispatch(message)
      end
    end
  end

end
