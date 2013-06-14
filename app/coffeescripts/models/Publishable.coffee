define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  class Publishable extends Backbone.Model

    initialize: (attributes, options)->
      @_url = options['url']
      @_root = options['root']
      @set 'publishable', true

    publish: =>
      @set 'published', true
      @save()

    unpublish: =>
      @set 'published', false
      @save()

    url: ->
      @_url

    toJSON: ->
      json = {}
      json[@_root] = _.clone @attributes
      json
