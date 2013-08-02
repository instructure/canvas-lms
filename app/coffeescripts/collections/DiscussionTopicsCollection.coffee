define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/DiscussionTopic'
], (PaginatedCollection, DiscussionTopic) ->

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

      if aPosition < bPosition
        -1
      else if aPosition is bPosition
        0
      else
        1
