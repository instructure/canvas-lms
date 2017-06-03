#
# Copyright (C) 2014 - present Instructure, Inc.
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

class ClearRailsCache < ActiveRecord::Migration[4.2]
  tag :predeploy

  # note that if you have any environments that are "split" somehow -
  # sharing a database, or created from a snapshot of a database,
  # or have non-connected cache servers - you'll need to manually
  # clear the cache in each of them.
  def up
    Rails.cache.clear if Shard.current.default?
  end

  def down
  end
end
