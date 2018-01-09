#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'underscore'
  '../backbone-ext/DefaultUrlMixin'
  '../collections/AssignmentCollection'
], (Backbone, _, DefaultUrlMixin, AssignmentCollection) ->

  isAdmin = ->
    _.contains(ENV.current_user_roles, 'admin')

  class AssignmentGroup extends Backbone.Model
    @mixin DefaultUrlMixin
    resourceName: 'assignment_groups'

    urlRoot: -> @_defaultUrl()

    initialize: ->
      if (assignments = @get('assignments'))?
        @set 'assignments', new AssignmentCollection(assignments)

    name: (newName) ->
      return @get 'name' unless arguments.length > 0
      @set 'name', newName

    position: (newPosition) ->
      return @get('position') || 0 unless arguments.length > 0
      @set 'position', newPosition

    groupWeight: (newWeight) ->
      return @get('group_weight') || 0 unless arguments.length > 0
      @set 'group_weight', newWeight

    rules: (newRules) ->
      return @get 'rules' unless arguments.length > 0
      @set 'rules', newRules

    removeNeverDrops: ->
      rules = @rules()
      if rules.never_drop
        delete rules.never_drop

    hasRules: ->
      @countRules() > 0

    countRules: ->
      rules = @rules() or {}
      aids = @assignmentIds()
      count = 0
      for k,v of rules
        if k == "never_drop"
          count += _.intersection(aids, v).length
        else
          count++
      count

    assignmentIds: ->
      assignments = @get('assignments')
      return [] unless assignments?
      assignments.pluck('id')

    canDelete: ->
      return true if isAdmin()
      not @anyAssignmentInClosedGradingPeriod() and not @hasFrozenAssignments()

    hasFrozenAssignments: ->
      @get('assignments').any (m) ->
        m.get('frozen')

    anyAssignmentInClosedGradingPeriod: ->
      @get('any_assignment_in_closed_grading_period')

    hasIntegrationData: ->
      !_.isEmpty(@get('integration_data')) || !_.isEmpty(@get('sis_source_id'))
