define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class AmaintTermList extends Backbone.Collection

    initialize: (@userId) -> super

    url: -> "/sfu/api/v1/amaint/user/#{@userId}/term"
