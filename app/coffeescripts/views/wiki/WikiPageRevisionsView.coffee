define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/views/wiki/WikiPageRevisionView'
  'jst/wiki/WikiPageRevisions'
  'compiled/jquery/floatingSticky'
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
        newSelection.view.$el.focus()

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
