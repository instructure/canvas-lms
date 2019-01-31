#
# Copyright (C) 2018 - present Instructure, Inc.
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

##
# This is just like Loaders::IDLoader, but you can specify a foreign key
# (IDLoader will always load by the 'id' column)
#
# Example:
#
#   Loaders::ForeignKeyLoader.for(course.enrollments, :user_id).
#     load(1).
#     then do |user|
#       # user ~ course.enrollments.find_by(user_id: 1)
#     end
class Loaders::ForeignKeyLoader < GraphQL::Batch::Loader

  # +scope+ is any active record scope
  #
  # +fk+ is the column you want to load by
  def initialize(scope, fk)
    @scope = scope
    @column = fk
  end

  # :nodoc:
  # Shard-safety
  def load(id)
    super(Shard.global_id_for(id))
  end

  # :nodoc:
  def perform(ids)
    Shard.partition_by_shard(ids) { |sharded_ids|
      @scope.where(@column => sharded_ids).
        group_by { |o| o.send(@column).to_s }.
        each { |id, os|
          fulfill(Shard.global_id_for(id), os)
        }
    }
    ids.each { |id|
      fulfill(id, nil) unless fulfilled?(id)
    }
  end
end
