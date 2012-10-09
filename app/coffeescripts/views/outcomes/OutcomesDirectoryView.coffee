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
  'jquery.disableWhileLoading'
  'jqueryui/droppable'
  'compiled/jquery.rails_flash_notifications'
], (I18n, $, _, PaginatedView, OutcomeGroup, OutcomeCollection, OutcomeGroupCollection, OutcomeGroupIconView, OutcomeIconView) ->

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

    initDroppable: ->
      @$el.droppable
        scope: 'outcomes'
        drop: (e, ui) =>
          # don't re-add to group
          return if ui.draggable.parent().get(0) == e.target
          model = ui.draggable.data('view').model
          @moveModelHere model

    # use this promise to know when both groups and outcomes have been loaded
    promise: ->
      @loadDfd.promise()

    # move a model from some dir to this
    moveModelHere: (model) ->
      model.collection.remove model
      if model instanceof OutcomeGroup
        @groups.add model
      else
        @outcomes.add model
      model.trigger 'select'
      @changeLink model, @outcomeGroup.toJSON(), model.outcomeGroup

    # change the outcome link from oldGroup to the newGroup
    changeLink: (model, newGroup, oldGroup) ->
      disablingDfd = new $.Deferred()

      model.outcomeGroup = oldGroup
      model.setUrlTo 'delete'
      unlinkUrl = model.url
      onFail = (m, r) ->
        disablingDfd.reject()
        $.flashError I18n.t 'flash.error', "An error occurred. Please try again later."

      # create new link
      model.outcomeGroup = newGroup
      model.setUrlTo 'add'
      $.ajaxJSON(model.url, 'POST', outcome_id: model.get 'id')
        .done( (modelData) ->
          # reset model urls etc.
          model.set model.parse(modelData)
          # new link created, now remove old link
          $.ajaxJSON(unlinkUrl, 'DELETE')
            .done( ->
              # old link removed
              $.flashMessage I18n.t 'flash.updateSuccess', 'Update successful'
              disablingDfd.resolve())
            .fail onFail)
        .fail onFail
      @$el.disableWhileLoading disablingDfd
      disablingDfd

    focusFirstOutcome: =>
      $li = @$el.find('[tabindex=0]')
      if $li.length > 0
        $li.focus()
      else
        @$el.prev().find('[tabindex=0]').focus()

    # Overriding
    paginationLoaderTemplate: ->
      "<li><a href='#' class='loading-more'>
        #{I18n.t("loading_more_results", "Loading more results")}</a></li>"

    # Overriding to insert into the ul.
    showPaginationLoader: ->
      @$el.append(@$paginationLoader ?= $(@paginationLoaderTemplate()))

    # Fetch outcomes after all the groups have been fetched.
    fetchOutcomes: ->
      @collection = @outcomes
      @bindPaginationEvents()
      @outcomes.fetch(success: => @loadDfd.resolve(this))
      @showPaginationLoader()

    triggerSelect: (sv) =>
      @clearSelection()
      @selectedView = sv
      sv.select()
      @trigger 'select', this, sv.model

    selectedModel: ->
      @selectedView?.model

    prevSelectedModel: ->
      @prevSelectedView?.model

    # Cache the backbone views for outcomes and groups.
    # Groups are shown first.
    views: ->
      return @_views if @_views and not _.isEmpty @_views

      @_views = @_viewsFor(@groups.models, OutcomeGroupIconView)
        .concat @_viewsFor(@outcomes.models, OutcomeIconView)
      for v in @_views
        v.on 'select', @triggerSelect
      @_views

    reset: =>
      @_clearViews()
      @render()

    removeGroup: (group) ->
      @_clearSelectedView()
      @clearSelection()
      @trigger 'select', this, null
      @reset()

    remove: ->
      @_clearSelectedView()
      @_clearViews()
      super arguments...

    clearSelection: (e) ->
      e?.preventDefault()
      @_clearSelectedView()
      _.each @views(), (v) -> v.unSelect()

    clearOutcomeSelection: ->
      if @selectedView instanceof OutcomeIconView
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

    _clearSelectedView: ->
      @prevSelectedView = @selectedView
      @selectedView = null
