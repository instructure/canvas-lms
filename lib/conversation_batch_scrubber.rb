#
# Copyright (C) 2017 - present Instructure, Inc.
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

# Public: Delete old (> 90 days) records from conversation_batches table.
class ConversationBatchScrubber < MessageScrubber

  protected

  def filter_attribute
    'updated_at'
  end

  def klass
    ConversationBatch.where(workflow_state: 'sent')
  end

  def limit_setting
    'conversation_batch_scrubber_limit'
  end

  def limit_size
    90
  end
end
