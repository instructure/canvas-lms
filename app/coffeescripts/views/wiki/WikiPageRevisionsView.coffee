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
  'jquery'
  'underscore'
  'Backbone'
  '../CollectionView'
  './WikiPageRevisionView'
  'jst/wiki/WikiPageRevisions'
  '../../jquery/floatingSticky'
], ($, _, Backbone, CollectionView, WikiPageRevisionView, template) ->

  class WikiPageRevisionsView extends CollectionView
    className: 'show-revisions'
    template: template
    itemView: WikiPageRevisionView

    @mixin
      events:
        'click .prev-button': 'prevPage'
        'click .next-button': 'nextPage'
        'click .close-button': 'close'
      els:
        '#ticker': '$ticker'
        'aside': '$aside'
        '.revisions-list': '$revisionsList'

    @optionProperty 'pages_path'

    initialize: (options) ->
      super
      @selectedRevision = null

      # handle selection changes
      @on 'selectionChanged', (newSelection, oldSelection) =>
        oldSelection.model?.set('selected', false)
        newSelection.model?.set('selected', true)

      # reposition after rendering
      @on 'render renderItem', => @reposition()

    afterRender: ->
      super
      $.publish('userContent/change')
      @trigger('render')

      @floatingSticky = @$aside.floatingSticky('#main', {top: '#content'})

    remove: ->
      if @floatingSticky
        _.each @floatingSticky, (sticky) -> sticky.remove()
        @floatingSticky = null

      super

    renderItem: ->
      super
      @trigger('renderItem')

    attachItemView: (model, view) ->
      if !!@selectedRevision && @selectedRevision.get('revision_id') == model.get('revision_id')
        model.set(@selectedRevision.attributes)
        model.set('selected', true)
        @setSelectedModelAndView(model, view)
      else
        model.set('selected', false)

      selectModel = =>
        @setSelectedModelAndView(model, view)
      selectModel() unless @selectedModel

      view.pages_path = @pages_path
      view.$el.on 'click', selectModel
      view.$el.on 'keypress', (e) =>
        if (e.keyCode == 13 || e.keyCode == 27)
          e.preventDefault()
          selectModel()

    setSelectedModelAndView: (model, view) ->
      oldSelectedModel = @selectedModel
      oldSelectedView = @selectedView
      @selectedModel = model
      @selectedView = view
      @selectedRevision = model
      @trigger 'selectionChanged', {model: model, view: view}, {model: oldSelectedModel, view: oldSelectedView}

    reposition: ->
      if @floatingSticky
        _.each @floatingSticky, (sticky) -> sticky.reposition()

    prevPage: (ev) ->
      ev?.preventDefault()
      @$el.disableWhileLoading @collection.fetch page: 'prev', reset: true

    nextPage: (ev) ->
      ev?.preventDefault()
      @$el.disableWhileLoading @collection.fetch page: 'next', reset: true

    close: (ev) ->
      ev?.preventDefault()
      window.location.href = @collection.parentModel.get('html_url')

    toJSON: ->
      json = super
      json.CAN =
        FETCH_PREV: @collection.canFetch('prev')
        FETCH_NEXT: @collection.canFetch('next')
      json
