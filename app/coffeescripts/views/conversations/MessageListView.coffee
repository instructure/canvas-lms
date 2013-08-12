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
      @collection.each((m) -> m.set('selected', false))

    course: {}
    updateCourse: (course) ->
      @course = course
    render: ->
      super()
      @$('.current-context').text(@course.name || '')
      @$('.current-context-code').text(@course.code || '')
      @$('.list-header')[if @course.name then 'show' else 'hide']()
