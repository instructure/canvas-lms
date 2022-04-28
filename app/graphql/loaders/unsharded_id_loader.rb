# frozen_string_literal: true

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
# Batch-loads records from a scope by their id; does not partition by shard (unlike IDLoader).
#
# Example:
#
#    Loaders::UnshardedIDLoader.for(Setting).load(1).then do |setting|
#      # setting is Setting.find_by(id: 1)
#    end
class Loaders::UnshardedIDLoader < GraphQL::Batch::Loader
  # +scope+ is any ActiveRecord scope
  def initialize(scope)
    super()
    @scope = scope
  end

  # :nodoc:
  def load(id)
    super(id.to_i)
  end

  # :nodoc:
  def perform(ids)
    @scope.where(id: ids).each do |o|
      fulfill(o.id, o)
    end
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
