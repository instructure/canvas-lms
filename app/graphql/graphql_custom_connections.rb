# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class PatchedArrayConnection < GraphQL::Relay::ArrayConnection
  # The default ArrayConnection uses `find_index(item)` which uses `==` to get
  # the index. Unfortunately submission histories are saved through versionable
  # which returns an array of submission histories that all share the same id,
  # and active record overrides the `==` method to check for equality based on
  # said id. When dealing with submissions, change the comparator to look at the
  # submitted_at time (what submission#submission_history is doing) instead of
  # by id so cursors don't break.
  def cursor_from_submission_node(submission)
    submission_idx = sliced_nodes.find_index { |i| i.submitted_at.to_i == submission.submitted_at.to_i }
    idx = (after ? index_from_cursor(after) : 0) + submission_idx + 1
    encode(idx.to_s)
  end

  def cursor_from_node(item)
    return cursor_from_submission_node(item) if item.class.name == 'Submission'
    super
  end
end

GraphQL::Relay::BaseConnection.register_connection_implementation(Array, PatchedArrayConnection)
