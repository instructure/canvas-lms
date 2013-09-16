define [
  'underscore'
  'Backbone'
], (_, {Model}) ->

  class ConversationSearchResult extends Model
    parse: (data) ->
      _.extend(data, isContext: data.type == 'context')
