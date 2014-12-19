#
# Copyright (C) 2012 Instructure, Inc.
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
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/views/PaginatedView'
  'compiled/models/OutcomeGroup'
  'compiled/collections/OutcomeCollection'
  'compiled/collections/OutcomeGroupCollection'
  'compiled/views/outcomes/OutcomeGroupIconView'
  'compiled/views/outcomes/OutcomeIconView'
  'str/htmlEscape'
  'jquery.disableWhileLoading'
  'jqueryui/droppable'
  'compiled/jquery.rails_flash_notifications'
], (I18n, $, _, PaginatedView, OutcomeGroup, OutcomeCollection, OutcomeGroupCollection, OutcomeGroupIconView, OutcomeIconView, htmlEscape) ->

  # The outcome group "directory" browser.
  class OutcomesDirectoryView extends PaginatedView

    tagName: 'ul'
    className: 'outcome-level'

    # if opts includes 'outcomeGroup', an instance of OutcomeGroup,
    # then the groups and the outcomes for the outcomeGroup will be fetched.
    initialize: (opts) ->
      @readOnly = opts.readOnly
      @parent = opts.parent

      if @outcomeGroup = opts.outcomeGroup
        unless @groups
          @groups = new OutcomeGroupCollection
          @groups.url = @outcomeGroup.get('subgroups_url')
        @groups.on 'add reset', @reset, this # TODO: make add more efficient
        @groups.on 'remove', @removeGroup, this
        @groups.on 'fetched:last', @fetchOutcomes, this

        unless @outcomes
          @outcomes = new OutcomeCollection
          @outcomes.url = @outcomeGroup.get('outcomes_url')
        @outcomes.on 'add remove reset', @reset, this

      # for PaginatedView
      # @collection starts as @groups but can later change to @outcomes
      @collection = @groups
      @paginationScrollContainer = @$el
      super opts

      @loadDfd = $.Deferred()

      if @outcomeGroup
        @$el.disableWhileLoading(dfd = @groups.fetch())
        dfd.done(@focusFirstOutcome)

      @loadDfd.done(@selectFirstOutcome) if opts.selectFirstItem

    initDroppable: ->
      @$el.droppable
        scope: 'outcomes'
        hoverClass: 'outcome-level-hover'
        drop: (e, ui) =>
          # don't re-add to this group
          return if ui.draggable.parent().get(0) == e.target
          model = ui.draggable.data('view').model
          @moveModelHere model

    # use this promise to know when both groups and outcomes have been loaded
    promise: ->
      @loadDfd.promise()

    # Public: move a model from some dir to this
    moveModelHere: (model) =>
      model.collection.remove model
      if model instanceof OutcomeGroup
        @groups.add model
        dfd = @moveGroup model, @outcomeGroup.toJSON()
      else
        @outcomes.add model
        dfd = @changeLink model, @outcomeGroup.toJSON()
      dfd.done -> model.trigger 'select'

    # Internal: change the outcome link to the newGroup
    changeLink: (outcome, newGroup) ->
      disablingDfd = new $.Deferred()
      @$el.disableWhileLoading disablingDfd

      onFail = (m, r) ->
        disablingDfd.reject()
        $.flashError I18n.t 'flash.error', "An error occurred. Please refresh the page and try again."

      # create new link
      outcome.setUrlTo 'delete'
      unlinkUrl = outcome.url
      outcome.outcomeGroup = newGroup
      outcome.setUrlTo 'add'
      $.ajaxJSON(outcome.url, 'POST', outcome_id: outcome.get 'id')
        .done( (modelData) ->
          # reset urls etc.
          outcome.set outcome.parse(modelData)
          # new link created, now remove old link
          $.ajaxJSON(unlinkUrl, 'DELETE')
            .done( ->
              # old link removed
              $.flashMessage I18n.t 'flash.updateSuccess', 'Update successful'
              disablingDfd.resolve())
            .fail onFail)
        .fail onFail

      disablingDfd

    # Internal: change the group's parent to the newGroup
    moveGroup: (group, newGroup) ->
      disablingDfd = new $.Deferred()

      onFail = (m, r) ->
        disablingDfd.reject()
        $.flashError I18n.t 'flash.error', "An error occurred. Please refresh the page and try again."

      group.setUrlTo 'edit'
      $.ajaxJSON(group.url, 'PUT', parent_outcome_group_id: newGroup.id)
        .done( (modelData) ->
          # reset urls etc.
          group.set group.parse(modelData)
          $.flashMessage I18n.t 'flash.updateSuccess', 'Update successful'
          disablingDfd.resolve())
        .fail onFail

      @$el.disableWhileLoading disablingDfd
      disablingDfd

    focusFirstOutcome: =>
      $li = @$el.find('[tabindex=0]')
      if $li.length > 0
        $li.focus()
      else
        @$el.prev().find('[tabindex=0]').focus()

    selectFirstOutcome: =>
      $('ul.outcome-level li:first').click()

    # Overriding
    paginationLoaderTemplate: ->
      "<li><a href='#' class='loading-more'>
        #{htmlEscape I18n.t("loading_more_results", "Loading more results")}</a></li>"

    # Overriding to insert into the ul.
    showPaginationLoader: ->
      @$paginationLoader ?= $(@paginationLoaderTemplate())
      @$el.append(@$paginationLoader)

    # Fetch outcomes after all the groups have been fetched.
    fetchOutcomes: ->
      @collection = @outcomes
      @bindPaginationEvents()
      @outcomes.fetch(success: => @loadDfd.resolve(this))
      @startPaginationListener()
      @showPaginationLoader()

    triggerSelect: (sv) =>
      @clearSelection()
      @selectedModel = sv.model
      sv.select()
      @trigger 'select', this, sv.model

    # Cache the backbone views for outcomes and groups.
    # Groups are shown first.
    views: ->
      return @_views if @_views and not _.isEmpty @_views

      @_views = @_viewsFor(@groups.models, OutcomeGroupIconView)
        .concat @_viewsFor(@outcomes.models, OutcomeIconView)
      for v in @_views
        v.on 'select', @triggerSelect
        v.select() if v.model is @selectedModel
      @_views

    reset: =>
      @_clearViews()
      @render()

    removeGroup: (group) ->
      @reset()
      if group is _.last(@sidebar.directories)?.outcomeGroup
        @trigger 'select', this, null

    remove: ->
      @_clearViews()
      @selectedModel = null
      super arguments...

    clearSelection: (e) ->
      e?.preventDefault()
      @prevSelectedModel = @selectedModel
      @selectedModel = null
      _.each @views(), (v) -> v.unSelect()

    clearOutcomeSelection: ->
      if @selectedModel instanceof Outcome
        @clearSelection()

    render: =>
      @$el.empty()
      _.each @views(), (v) => @$el.append v.render().el
      @initDroppable() unless @readOnly
      # Make the first <li /> tabbable for accessibility purposes.
      @$('li:first').attr('tabindex', 0)
      @$el.data 'view', this
      this

    # private
    _viewsFor: (models, viewClass) ->
      _.map models, (model) => new viewClass {model: model, readOnly: @readOnly, dir: this}

    # private
    _clearViews: ->
      _.each @_views, (v) -> v.remove()
      @_views = null
