#
# Copyright (C) 2016 - present Instructure, Inc.
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

class CleanseTheSyckness < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    if CANVAS_RAILS4_2
      DataFixup::SycknessCleanser.columns_hash.each do |model, columns|
        DataFixup::SycknessCleanser.send_later_if_production_enqueue_args(:run,
          {:strand => "syckness_cleanse_#{Shard.current.database_server.id}", :priority => Delayed::MAX_PRIORITY}, model, columns)
      end
    else
      if User.exists? # don't raise for a fresh install
        raise "WARNING:\n
          This migration needs to be run under Rails 4.2.\n"
      end
    end
  end

  def down
  end
end
