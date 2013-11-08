define [
  'Backbone'
  'underscore'
  'i18n!publishable'
], (Backbone, _, I18n) ->

  class Publishable extends Backbone.Model

    initialize: (attributes, options)->
      @_root = options['root']
      @set 'unpublishable', true

    publish: =>
      @set 'published', true
      @save()

    unpublish: =>
      @set 'published', false
      @save()

    disabledMessage: ->
      I18n.t('cant_unpublish', "Can't unpublish")

    toJSON: ->
      json = {}
      json[@_root] = _.clone @attributes
      json
