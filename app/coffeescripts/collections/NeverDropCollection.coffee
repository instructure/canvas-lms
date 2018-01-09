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
  '../util/UniqueDropdownCollection'
], (_, Backbone, UniqueDropdownCollection) ->

  class NeverDropCollection extends UniqueDropdownCollection

    initialize: (records, options={}) ->
      #need to pass in the assignments list
      #and the assignment group id
      {@assignments, @ag_id} = (options or {})
      # set up options for UniqueDropdownCollection
      options.possibleValues = (@assignments?.map (a) -> a.id) or []
      options.propertyName = 'chosen_id'
      options.model = Backbone.Model
      super

    updateAssignments: (assignments)->
      @assignments = assignments

    updateAssignmentGroupId: (id) ->
      @ag_id = id

    #pass the chosen_id to include in the output
    #used to return a list of models to build the select
    #this will retain the assignment order when rendering
    #the <options>
    toAssignments: (include_id) ->
      # map assignments to retain order
      models = @assignments.map (m) =>
        available = @availableValues.find (am) ->
          m.id == am.id
        if available or (m.id == include_id)
          return m.toView()
      # compact results because we're mapping assignments :(
      _.compact(models)

    parse: (resp, opts) ->
      coll = []
      for drop, idx in resp
        if assignment = @findAssignment(drop)
          model_obj =
            id: resp.id or idx
            chosen: assignment.name()
            chosen_id: assignment.get('id')
            label_id: @ag_id or 'new'
          coll.push model_obj
      coll

    findAssignment: (id) ->
      @assignments.find (a) ->
        a.id == id

    #override default UniqueCollection logic for finding the next item
    #returns a model from @availableValues
    findNextAvailable: ->
      # find the first assignment, in order, that has
      # an `id` in @availableValues
      next = @assignments.find (a) =>
        @availableValues.find (av) ->
          a.id == av.id
      @availableValues.get next.id
