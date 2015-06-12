define [
  'compiled/views/CollectionView'
  'compiled/views/conversations/ContextMessageView'
], (CollectionView, ContextMessageView) ->

  class ContextMessagesView extends CollectionView
    itemView: ContextMessageView

    initialize: (options) ->
      super
      @collection.each (model) =>
        model.bind("removeView", @handleChildViewRemoval)

    handleChildViewRemoval: (e) ->
      el = e.view.$el
      index = el.index()
      hasSiblings = el.siblings().length > 0
      prev = el.prev().find('.delete-btn')
      next = el.next().find('.delete-btn')
      e.view.remove()

      if (index > 0)
        prev.focus()
      else
        if (hasSiblings)
          next.focus()
        else
          $('#add-message-attachment-button').focus()
