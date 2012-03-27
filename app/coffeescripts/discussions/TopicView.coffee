define [
  'i18n!discussions'
  'compiled/backbone-ext/Backbone'
  'compiled/discussions/Topic'
  'compiled/discussions/EntriesView'
  'compiled/discussions/EntryView'
  'jst/discussions/_reply_form'
  'compiled/discussions/Reply'
  'compiled/widget/assignmentRubricDialog'
  'compiled/util/wikiSidebarWithMultipleEditors'
  'jquery.instructure_misc_helpers' #scrollSidebar

], (I18n, Backbone, Topic, EntriesView, EntryView, replyTemplate, Reply, assignmentRubricDialog) ->

  ##
  # View that considers the enter ERB template, not just the JS
  # generated html
  #
  # TODO have a Topic model and move it here instead of having Discussion
  # control all the topic's information (like unread stuff)
  class TopicView extends Backbone.View

    events:

      ##
      # Only catch events for the top level "add reply" form,
      # EntriesView handles the clicks for the other replies
      'click #discussion_topic .discussion-reply-form [data-event]': 'handleEvent'

      ##
      # TODO: add view switcher feature
      #'change .view_switcher': 'switchView' # for v2, see comments at initViewSwitcher

    initialize: ->
      @$el = $ '#main'
      @model.set 'id', ENV.DISCUSSION.TOPIC.ID

      # overwrite cid so Reply::getModelAttributes gets the right "go to parent" link
      @model.cid = 'main'

      @model.set 'canAttach', ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH

      @render()
      @initEntries() unless ENV.DISCUSSION.INITIAL_POST_REQUIRED

      # @initViewSwitcher()

      $.scrollSidebar() if $(document.body).is('.with-right-side')
      assignmentRubricDialog.initTriggers()
      @disableNextUnread()

    ##
    # Creates the Entries
    #
    # @api private
    initEntries: =>
      return false if @discussion

      @discussion = new EntriesView model: new Topic

      # shares the collection with EntriesView so that addReply works
      # (Reply::onPostReplySuccess uses @view.collection.add)
      # TODO: here is where the roles of TopicView and EntriesView blurs
      # need to spend a little time getting the two roles more defined
      @collection = @discussion.collection
      @discussion.model.bind 'change:unread_entries', @onUnreadChange

      # sets the intial href for next unread button when everthing is ready
      @discussion.model.bind 'fetchSuccess', =>
        unread_entries = @discussion.model.get 'unread_entries'
        @setNextUnread unread_entries

      # TODO get rid of this global, used
      window.DISCUSSION = @discussion
      true

    ##
    # Updates the unread count on the top of the page
    #
    # @api private
    onUnreadChange: (model, unread_entries) =>
      @model.set 'unreadCount', unread_entries.length
      @model.set 'unreadText', I18n.t 'unread_count_tooltip',
        zero: 'No unread replies'
        one: '1 unread reply'
        other: '%{count} unread replies'
      ,
        count: unread_entries.length
      @setNextUnread unread_entries

    ##
    # When the "next unread" button is clicked, this updates the href
    #
    # @param {Array} unread_entries - ids of unread entries
    # @api private
    setNextUnread: (unread_entries) ->
      if unread_entries.length is 0
        @disableNextUnread()
        return
      # using the DOM to find the next unread, sort of a cop out but seems
      # like the simplest solution, we don't reallyhave a nice way to access
      # the entry data in a threaded way.
      # also, start with the discussion view as the root for the search
      unread = @discussion.$('.can_be_marked_as_read.unread:first')
      parent = unread.parent()
      id = parent.attr('id')
      @$('#jump_to_next_unread').removeClass('disabled').attr('href', "##{id}")

    ##
    # Disables the next unread button
    #
    # @api private
    disableNextUnread: ->
      @$('#jump_to_next_unread').addClass('disabled').removeAttr('href')

    ##
    # Adds a root level reply to the main topic
    #
    # @api private
    addReply: (event) ->
      event.preventDefault()
      @reply ?= new Reply this, topLevel: true, added: @initEntries
      @model.set 'notification', ''
      @reply.edit()

    addReplyAttachment: EntryView::addReplyAttachment

    removeReplyAttachment: EntryView::removeReplyAttachment

    ##
    # Handles events for declarative HTML. Right now only catches the reply
    # form allowing EntriesView to handle its own events
    handleEvent: (event) ->
      # get the element and the method to call
      el = $ event.currentTarget
      method = el.data 'event'
      @[method]? event, el

    render: ->
      # erb renders most of this, we just want to re-use the
      # reply template
      if ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
        html = replyTemplate @model.toJSON()
        @$('.entry_content:first').append html
      super

    # TODO: v2 implement this, commented out discussion_topics/show.html.erb
    ###
    initViewSwitcher: ->
      @$('.view_switcher').show().selectmenu
        icons: [
          {find: '.collapsed-view'}
          {find: '.unread-view'}
          {find: '.expanded-view'}
        ]

    switchView: (event) ->
      $select = $ event.currentTarget
      view = $select.val()
      @[view + 'View']()

    collapsedView: ->
      view.model.set('collapsedView', true) for view in EntryView.instances

    expandedView: ->
      view.model.set('collapsedView', false) for view in EntryView.instances

    unreadView: ->
      console.log 'unread'
    ###

