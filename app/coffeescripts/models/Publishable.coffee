define [
  'Backbone'
  'underscore'
  'i18n!publishable'
], (Backbone, _, I18n) ->

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

    disabledMessage: ->
      I18n.t('cant_unpublish', "Can't unpublish")

    url: ->
      @_url

    toJSON: ->
      json = {}
      json[@_root] = _.clone @attributes
      json
