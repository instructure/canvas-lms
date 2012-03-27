define [
  'compiled/backbone-ext/Backbone'
  'compiled/discussions/EntryView'
], (Backbone, EntryView) ->

  ##
  # View for a collection of entries
  class EntryCollectionView extends Backbone.View

    initialize: (@$el, @entries, args...) ->
      super args...
      @entries.bind 'reset', @addAll
      @entries.bind 'add', @add
      @render()

    render: ->
      @$el.html '<ul class=discussion-entries></ul>'
      @cacheElements()

    cacheElements: ->
      @list = @$el.children '.discussion-entries'

    add: (entry) =>
      view = new EntryView model: entry
      @list.append view.el

    addAll: =>
      @entries.each @add


