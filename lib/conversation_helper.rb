# frozen_string_literal: true

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

module ConversationHelper
  def set_root_account_ids
    write_attribute(:root_account_ids, conversation&.root_account_ids&.sort&.join(","))
  end

  # NOTE: all ids are relative to the birth shard, if you are going to consume these you should do
  # `Shard.birth.activate do`
  def root_account_ids
    (read_attribute(:root_account_ids) || "").split(",").map(&:to_i).sort
  end

  def root_account_ids=(ids)
    # handle case when ids is a comma separated list
    if ids.is_a? String
      ids = ids.split(",").map(&:to_i)
    end
    # ids must be sorted for the scope to work
    write_attribute(:root_account_ids, ids&.sort&.join(","))
  end

  def global_root_account_ids
    root_account_ids&.map do |id|
      Shard.global_id_for(id, Shard.birth)
    end
  end
end
