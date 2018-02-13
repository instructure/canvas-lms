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
  'underscore'
  'Backbone'
  'compiled/collections/NeverDropCollection'
], (_, Backbone, NeverDropCollection) ->

  class AssignmentStub extends Backbone.Model
    name: -> @get('name')
    toView: =>
      name: @get('name')
      id: @id

  class Assignments extends Backbone.Collection
    model: AssignmentStub

  QUnit.module "NeverDropCollection",
    setup: ->
      list = [1..5]
      @assignments = new Assignments []
      @assignments.comparator = 'position'
      @assignments.reset((id: val, position:list.length-i, name: "Assignment #{val}") for val, i in list)
      @never_drops = new NeverDropCollection [],
        assignments: @assignments
        ag_id: 1

  test "#initialize", ->
    deepEqual @never_drops.assignments, @assignments
    strictEqual @never_drops.ag_id, 1

  test "#toAssignments", ->
    @never_drops.add {}
    @never_drops.add {}
    @never_drops.add {}
    @never_drops.add {}
    output = @never_drops.toAssignments @never_drops.at(3).get('chosen_id')
    expected = @assignments.slice(3).map (m) -> m.toView()
    deepEqual output, expected

  test "#findNextAvailable", ->
    @never_drops.add {}
    deepEqual @never_drops.findNextAvailable(), @never_drops.availableValues.get(@assignments.at(1).id), "finds the available item that has the id of the second assignment"
