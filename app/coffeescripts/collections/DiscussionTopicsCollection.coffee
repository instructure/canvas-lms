define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/DiscussionTopic'
], (PaginatedCollection, DiscussionTopic) ->

  class DiscussionTopicsCollection extends PaginatedCollection

    model: DiscussionTopic