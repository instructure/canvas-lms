define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/Message'
], (PaginatedCollection, Message) ->

  class MessageCollection extends PaginatedCollection

    model: Message

    url: '/api/v1/conversations'
