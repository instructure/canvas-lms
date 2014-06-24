define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class SandboxList extends Backbone.Collection

    initialize: (@userId) -> super

    url: -> "/sfu/api/v1/user/#{@userId}/sandbox"
