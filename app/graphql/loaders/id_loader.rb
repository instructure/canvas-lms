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

class Loaders::IDLoader < GraphQL::Batch::Loader
  def initialize(scope)
    @scope = scope
  end

  def load(key)
    # since we might load an id that is a number or a string, we need to coerce
    # here to keep things consistent
    super(key.to_s)
  end

  def perform(ids)
    @scope.where(id: ids).each { |o| fulfill(o.id.to_s, o) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
