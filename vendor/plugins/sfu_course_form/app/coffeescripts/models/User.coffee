define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class User extends Backbone.Model

    initialize: (@userId) ->
      @hasLoaded = false
      @on 'change', ->
        @hasLoaded = true
        $(document).trigger 'userloaded'
      super

    url: ->
      "/sfu/api/v1/amaint/user/#{@userId}"
