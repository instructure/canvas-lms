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
#

define [
  'Backbone'
  '../collections/OutcomeCollection'
  '../collections/PaginatedCollection'
], (Backbone, OutcomeCollection, PaginatedCollection) ->

  class OutcomeGroup extends Backbone.Model
    initialize: (options) ->
      @setUpOutcomesAndGroupsIfNeeded()
      super

    name: ->
      @get 'title'

    # The api returns abbreviated data by default
    # which in most cases means there's no description.
    # Run fetch() to get all the data.
    isAbbreviated: ->
      !@has('description')

    setUrlTo: (action) ->
      @url =
        switch action
          when 'add', 'move' then @get('parent_outcome_group').subgroups_url
          when 'edit', 'delete' then @get 'url'

    setUpOutcomesAndGroupsIfNeeded: ->
      unless @outcomeGroups
        @outcomeGroups = new OutcomeGroupCollection [], parentGroup: this
      unless @outcomes
        @outcomes = new OutcomeCollection []

    getSubtrees: ->
      @outcomeGroups

    getItems: ->
      @outcomes

    expand: (force=false, options={}) ->
      @isExpanded = true
      @trigger 'expanded'
      return $.when() if @expandDfd || force
      @isExpanding = true
      @trigger 'beginexpanding'
      @expandDfd = $.Deferred().done =>
        @isExpanding = false
        @trigger 'endexpanding'

      outcomeGroupDfd = @outcomeGroups?.fetch() unless @get('outcomeGroups_count') is 0
      outcomesDfd = @outcomes?.fetch() if (@get('outcomes_count') isnt 0) and !options.onlyShowSubtrees
      $.when(outcomeGroupDfd, outcomesDfd).done(@expandDfd.resolve)

    collapse: ->
      @isExpanded = false
      @trigger 'collapsed'

    toggle: (options) ->
      if @isExpanded
        @collapse()
      else
        @expand(false, options)

  # OutcomeGroupCollection is redefined inside of this file instead of pointing
  # towards collections/outcomeGroupCollection because RequireJS sucks at
  # figuring out circular dependencies.
  class OutcomeGroupCollection extends PaginatedCollection
    @optionProperty 'parentGroup'
    model: OutcomeGroup

    url: ->
      @parentGroup.attributes.subgroups_url

  return OutcomeGroup
