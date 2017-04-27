#
# Copyright (C) 2015 - present Instructure, Inc.
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
  module FixFolderNames
    def self.run
      wildcards = []
      [" ", "\t", "\r", "\n"].each do |ws|
        wildcards += ["#{ws}%", "%#{ws}"]
      end

      Folder.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        Folder.active.where(:id => min_id..max_id).where((["(name LIKE ?)"] * wildcards.count).join(" OR "), *wildcards).each do |f|
          f.name = f.name.strip
          f.save
        end
      end
    end
  end
end
