define [
  'underscore'
  'compiled/collections/PaginatedCollection'
  'compiled/models/Message'
], (_, PaginatedCollection, Message) ->

  class MessageCollection extends PaginatedCollection

    model: Message

    url: '/api/v1/conversations'

    params:
      scope: 'inbox'

    comparator: (a, b) ->
      dates = _.map [a, b], (message) ->
        message.timestamp().getTime()
      return -1 if dates[0] > dates[1]
      return  1 if dates[1] > dates[0]
      return 0

    selectRange: (model) ->
      newPos = @indexOf(model)
      lastSelected = _.last(@view.selectedMessages)
      @.each (x) -> x.set('selected', false)
      lastPos = @indexOf(lastSelected)
      range = @slice(Math.min(newPos, lastPos), Math.max(newPos, lastPos)+1)
      # the anchor needs to stay at the end
      range.reverse() if newPos > lastPos
      _.each range, (x) -> x.set('selected', true)
