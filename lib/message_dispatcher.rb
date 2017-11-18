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
    Delayed::Job.enqueue(self.new(message, :deliver),
                         run_at: message.dispatch_at,
                         max_attempts: 15)
  end

  def self.batch_dispatch(messages)
    return if messages.empty?

    if messages.size == 1
      self.dispatch(messages.first)
      return
    end

    Delayed::Job.enqueue(self.new(self, :deliver_batch, [messages]),
                         run_at: messages.first.dispatch_at,
                         max_attempts: 15)
  end

  # Called by delayed_job when a job fails to reschedule it.
  def reschedule_at(now, num_attempts)
    object.dispatch_at
  end

  protected

  def self.deliver_batch(messages)
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
