define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/DiscussionTopic'
  'compiled/util/NumberCompare'
], (PaginatedCollection, DiscussionTopic, numberCompare) ->

  class DiscussionTopicsCollection extends PaginatedCollection

    model: DiscussionTopic

    comparator: @dateComparator

    @dateComparator: (a, b) ->
      aDate = new Date(a.get('last_reply_at')).getTime()
      bDate = new Date(b.get('last_reply_at')).getTime()

      if aDate < bDate
        1
      else if aDate is bDate
        0
      else
        -1

    @positionComparator: (a, b) ->
      aPosition = a.get('position')
      bPosition = b.get('position')
      numberCompare(aPosition, bPosition)
