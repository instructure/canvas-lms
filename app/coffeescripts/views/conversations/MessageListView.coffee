define [
  'i18n!messages'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/conversations/MessageView'
  'jst/conversations/messageList'
], (I18n, PaginatedCollectionView, MessageView, template) ->

  class MessageListView extends PaginatedCollectionView

    tagName: 'div'

    itemView: MessageView

    template: template

    course: {}

    selectedMessages: []

    autoFetch: true

    events:
      'click': 'onClick'

    constructor: ->
      super
      @attachEvents()

    attachEvents: ->
      @collection.on('change:selected', @trackSelectedMessages)

    trackSelectedMessages: (model) =>
      if model.get('selected')
        @selectedMessages.push(model)
      else
        @selectedMessages.splice(@selectedMessages.indexOf(model), 1)

    onClick: (e) ->
      return unless e.target is @el
      @collection.each((m) -> m.set('selected', false))

    updateCourse: (course) ->
      @course = course

    selectedMessage: ->
      @selectedMessages[0]

    updateMessage: (message, thread) =>
      selectedThread = @collection.where(selected: true)[0]
      updatedThread = @collection.get(thread.id)
      updatedThread.set
        last_message:  thread.last_message
        last_authored_message_at: new Date().toString()
        message_count: I18n.n(updatedThread.get('messages').length)
      @collection.sort()
      @render()
      selectedThread?.view.select()

    afterRender: ->
      super
      @$('.current-context').text(@course.name)
      @$('.list-header')[if @course.name then 'show' else 'hide']()

    selectAll: ->
      @collection.each (x) -> x.set('selected', true)
