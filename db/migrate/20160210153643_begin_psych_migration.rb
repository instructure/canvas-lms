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

class BeginPsychMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def runnable?
    Shard.current.default?
  end

  def up
    if User.exists? # don't raise for a fresh install
      raise "WARNING:\n
        This migration needs to be run with the release/2016-04-23 version of canvas-lms to
        change all yaml columns in the database to a Psych compatible format.\n"
    end
  end

  def down
  end
end
