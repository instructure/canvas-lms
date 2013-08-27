define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class SandboxList extends Backbone.Collection

    initialize: (@userId) -> super

    fetch: (options) ->
      @trigger 'request'
      Backbone.Collection.prototype.fetch.call(this, options)

    url: -> "/sfu/api/v1/user/#{@userId}/sandbox"
