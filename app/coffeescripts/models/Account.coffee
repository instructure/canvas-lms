define [
  'underscore'
  'Backbone'
], (_, Backbone) ->

  class Account extends Backbone.Model
    urlRoot: '/api/v1/accounts'

    present: ->
      _.clone @attributes

    toJSON: ->
      id: @get('id')
      account: _.omit(@attributes, 'id')
