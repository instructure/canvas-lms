define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/DiscussionTopic'
], (PaginatedCollection, DiscussionTopic) ->

  class DiscussionTopicsCollection extends PaginatedCollection

    model: DiscussionTopic

    comparator: (a, b) ->
      aDate = new Date(a.get('last_reply_at')).getTime()
      bDate = new Date(b.get('last_reply_at')).getTime()

      if aDate < bDate
        1
      else if aDate is bDate
        0
      else
        -1
