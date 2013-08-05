define [
  'compiled/views/PaginatedCollectionView'
  'compiled/views/conversations/MessageView'
  'jst/conversations/messageList'
], (PaginatedCollectionView, MessageView, template) ->

  class MessageListView extends PaginatedCollectionView

    scrollContainer: '.message-list'

    tagName: 'div'

    itemView: MessageView

    template: template

    events:
      'click': 'onClick'

    onClick: (e) ->
      return unless e.target is @el
      @collection.find((m) -> m.get('selected')).set('selected', false)
