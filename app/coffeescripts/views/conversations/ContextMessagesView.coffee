define [
  'compiled/views/CollectionView'
  'compiled/views/conversations/ContextMessageView'
], (CollectionView, ContextMessageView) ->

  class ContextMessagesView extends CollectionView
    itemView: ContextMessageView
