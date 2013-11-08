define [
  'compiled/views/PaginatedCollectionView'
  'compiled/views/conversations/MessageView'
  'jst/conversations/messageList'
], (PaginatedCollectionView, MessageView, template) ->

  class MessageListView extends PaginatedCollectionView

    tagName: 'div'

    itemView: MessageView

    template: template

    course: {}

    events:
      'click': 'onClick'

    onClick: (e) ->
      return unless e.target is @el
      @collection.each((m) -> m.set('selected', false))

    updateCourse: (course) ->
      @course = course

    updateMessage: (message, thread) =>
      selectedThread = @collection.where(selected: true)[0]
      updatedThread = @collection.get(thread.id)
      updatedThread.set
        last_message:  thread.last_message
        last_authored_message_at: new Date().toString()
        message_count: updatedThread.get('messages').length
      @collection.sort()
      @render()
      selectedThread?.view.select()

    afterRender: ->
      super
      @$('.current-context').text(@course.name)
      @$('.list-header')[if @course.name then 'show' else 'hide']()
