define [
  'jquery'
  'compiled/collections/PaginatedCollection'
  'compiled/models/DiscussionTopic'
  'compiled/util/NumberCompare'
], ($, PaginatedCollection, DiscussionTopic, numberCompare) ->

  class DiscussionTopicsCollection extends PaginatedCollection

    model: DiscussionTopic

    comparator: @dateComparator

    @dateComparator: (a, b) ->
      aDate = new Date(a.get('last_reply_at')).getTime()
      bDate = new Date(b.get('last_reply_at')).getTime()

      if aDate < bDate
        1
      else if aDate > bDate
        -1
      else
        @idCompare(a, b)

    @positionComparator: (a, b) ->
      aPosition = a.get('position')
      bPosition = b.get('position')
      c = numberCompare(aPosition, bPosition)
      if c isnt 0 then c else @idCompare(a, b)

    idCompare: (a, b) ->
      numberCompare(parseInt(a.get('id')), parseInt(b.get('id')), descending: true)

    reorderURL: -> @url()+'/reorder'

    reorder: ->
      @each (model, i) ->
        model.set(position: i+1)
      ids = @pluck('id')
      $.post @reorderURL(), order: ids
      @reset @models
