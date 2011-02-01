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
    @logger = RAILS_DEFAULT_LOGGER
  end
  
  def process
    cc_ids = CommunicationChannel.ids_with_pending_delayed_messages
    cc_ids.each do |cc_id|
      dm_ids = DelayedMessage.ids_for_messages_with_communication_channel_id(cc_id)
      DelayedMessage.update_all({ :batched_at => Time.now, :workflow_state => 'sent', :updated_at => Time.now },
                                { :id => dm_ids })
      DelayedMessage.send_later(:summarize, dm_ids)
      
      @logger.info("Scheduled summary with #{dm_ids.length} messages for communication channel id #{cc_id}")
    end
  end
end
