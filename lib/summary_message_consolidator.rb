#
# Copyright (C) 2011 Instructure, Inc.
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

class SummaryMessageConsolidator
  def self.process
    SummaryMessageConsolidator.new.process
  end

  def initialize(n=nil)
    @logger = Rails.logger
  end

  def process
    cc_ids = ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) do
      CommunicationChannel.ids_with_pending_delayed_messages
    end
    dm_id_batches = []
    cc_ids.each do |cc_id|
      dm_ids = DelayedMessage.ids_for_messages_with_communication_channel_id(cc_id)
      dm_id_batches << dm_ids
      @logger.info("Scheduled summary with #{dm_ids.length} messages for communication channel id #{cc_id}")
    end

    dm_id_batches.in_groups_of(Setting.get('summary_message_consolidator_batch_size', '500').to_i, false) do |batches|
      DelayedMessage.update_all({ :batched_at => Time.now.utc, :workflow_state => 'sent', :updated_at => Time.now.utc },
                                { :id => batches.flatten })

      Delayed::Batch.serial_batch do
        batches.each do |dm_ids|
          DelayedMessage.send_later_enqueue_args(:summarize, { :priority => Delayed::LOWER_PRIORITY }, dm_ids)
        end
      end
    end
    dm_id_batches.size
  end
end
