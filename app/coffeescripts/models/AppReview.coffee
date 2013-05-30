define [
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
], ({Model}, DefaultUrlMixin) ->

  class AppReview extends Model
    @mixin DefaultUrlMixin
    urlRoot: -> @_defaultUrl()
