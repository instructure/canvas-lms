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
    batch_ids = delayed_message_batch_ids
    dm_id_batches = batch_ids.map do |batch_id|
      dm_ids = delayed_message_ids_for_batch(batch_id)
      @logger.info("Scheduled summary with #{dm_ids.length} messages for communication channel id #{batch_id['communication_channel_id']} and root account id #{batch_id['root_account_id'] || 'null'}")
      dm_ids
    end

    dm_id_batches.in_groups_of(Setting.get('summary_message_consolidator_batch_size', '500').to_i, false) do |batches|
      DelayedMessage.where(:id => batches.flatten).
          update_all(:batched_at => Time.now.utc, :workflow_state => 'sent', :updated_at => Time.now.utc)

      Delayed::Batch.serial_batch do
        batches.each do |dm_ids|
          DelayedMessage.send_later_enqueue_args(:summarize, { :priority => Delayed::LOWER_PRIORITY }, dm_ids)
        end
      end
    end
    dm_id_batches.size
  end

  def delayed_message_batch_ids
    Shackles.activate(:slave) do
      DelayedMessage.connection.select_all(
        DelayedMessage.scoped.select('communication_channel_id').select('root_account_id').uniq.
          where("workflow_state = ? AND send_at <= ?", 'pending', Time.now.to_s(:db)).
          to_sql)
    end
  end

  def delayed_message_ids_for_batch(batch)
    DelayedMessage.
      where("workflow_state = ? AND send_at <= ?", 'pending', Time.now.to_s(:db)).
      where(batch). # hash condition will properly handle the case where root_account_id is null
      all.map(&:id)
  end

end
