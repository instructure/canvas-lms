define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/collections/KollectionCollection'
  'jst/Kollections/IndexView'
], (Backbone, _, preventDefault, KollectionCollection, template) ->

  class IndexView extends Backbone.View

    template: template

    initialize: ->
      @collection.on 'reset', @render
      @collection.fetch()
