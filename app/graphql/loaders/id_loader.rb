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
# Batch-loads records from a scope by their id.
#
# Example:
#
#    Loaders::IDLoader.for(Course).load(1).then do |course|
#      # course is Course.find_by(id: 1)
#    end
#
# Example:
#    Loaders::IDLoader.for(user.enrollments).load(3).then do |enrollment|
#      # enrollment equiv to user.enrollments.find_by(id: 3)
#    end
class Loaders::IDLoader < GraphQL::Batch::Loader
  # +scope+ is any ActiveRecord scope
  def initialize(scope)
    @scope = scope
  end

  # :nodoc:
  # here we globalize ids so that we don't run into cross-shard issues
  def load(id)
    super(Shard.global_id_for(id))
  end

  # :nodoc:
  def perform(ids)
    Shard.partition_by_shard(ids) { |sharded_ids|
      @scope.where(id: sharded_ids).each { |o|
        fulfill(o.global_id, o)
      }
    }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
