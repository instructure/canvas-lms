# frozen_string_literal: true

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

module DataFixup
  module FixOverwrittenFileModuleItems
    def self.run
      replacement_ids = []
      Attachment.find_ids_in_ranges(:batch_size => 10_000) do |min_id, max_id|
        replacement_ids += Attachment.where(:id => min_id..max_id, :file_state => 'deleted', :could_be_locked => true).
          where.not(:replacement_attachment_id => nil).pluck(:replacement_attachment_id)
      end
      replacement_ids.uniq.sort.each_slice(1000) do |sliced_ids|
        Attachment.where(:id => sliced_ids).where("could_be_locked IS NULL OR could_be_locked = ?", false).update_all(:could_be_locked => true)
      end
    end
  end
end
