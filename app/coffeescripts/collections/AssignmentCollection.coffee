#
# Copyright (C) 2013 - present Instructure, Inc.
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

define [
  'Backbone'
  'compiled/models/Assignment'
], (Backbone, Assignment) ->

  class AssignmentCollection extends Backbone.Collection

    model: Assignment

    comparator: 'position'

    # Inserts the model in at the position specified in the model.  Anything
    # that has a position equal to or greater than to the newModel's position
    # will have its position incremented, to maintain order and uniqueness of
    # position.  IF position is not set, inserts at the beginning (assumes
    # positons are 1-indexed)
    insertModel: (newModel) =>
      newPos = newModel.get('position') || 1
      @models.forEach((oldModel) =>
        oldPos = oldModel.get('position')
        # If an entry somehow doesn't have a position, just don't move it.
        # This assumes positions are always at least 1.
        if oldPos && oldPos >= newPos
          oldModel.set('position', oldPos + 1)
      )
      @add(newModel)
