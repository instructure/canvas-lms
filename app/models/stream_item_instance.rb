# frozen_string_literal: true

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

class StreamItemInstance < ActiveRecord::Base
  include Workflow

  belongs_to :user
  belongs_to :stream_item
  belongs_to :context, polymorphic: %i[course account group assignment_override]

  validates :stream_item_id, :user_id, :context_id, :context_type, presence: true

  before_save :set_context_code
  def set_context_code
    self.context_type ||= stream_item.context_type
    self.context_id ||= stream_item.context_id
  end

  class << self
    # Don't use update_all() because there is an observer
    # on StreamItemInstance to invalidate some cache keys.
    # Use update_all_with_invalidation() instead.
    def update_all(*)
      raise "Using update_all will break things, use update_all_with_invalidation instead."
    end

    # Runs update_all() and also invalidates cache keys for the array of contexts (a context
    # is an array of [context_type, context_id])
    def update_all_with_invalidation(contexts, updates)
      contexts.each { |context| StreamItemCache.invalidate_context_stream_item_key(context.first, context.last) }
      in_batches(of: 10_000).update_all(updates)
    end
  end

  workflow do
    state :read
    state :unread
  end
end
