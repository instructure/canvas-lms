define [
  'Backbone'
  'compiled/views/DiscussionTopic/EntryView'
  'jst/discussions/EntryCollectionView'
], (Backbone, EntryView, entryCollectionViewTemplate) ->

  ##
  # View for a collection of entries
  class EntryCollectionView extends Backbone.View

    initialize: (options) ->
      #TODO: backbone supposedly does the next couple lines for us but didn't
      @$el = options.$el
      @collection = options.collection

      @collection.bind 'reset', @addAll
      @collection.bind 'add', @add
      @render()

    render: ->
      html = entryCollectionViewTemplate @options
      @$el.html html
      @cacheElements()

    cacheElements: ->
      @list = @$el.children '.discussion-entries'

    add: (entry) =>
      view = new EntryView model: entry
      @list.append view.el

    addAll: =>
      @collection.each @add

