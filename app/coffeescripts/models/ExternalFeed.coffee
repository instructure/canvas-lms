define [
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
], (Backbone, DefaultUrlMixin) ->

  class ExternalFeed  extends Backbone.Model
    @mixin DefaultUrlMixin
    resourceName: 'external_feeds'
    urlRoot: -> @_defaultUrl()
