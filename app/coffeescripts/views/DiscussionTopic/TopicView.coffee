define [
  'i18n!discussions'
  'jquery'
  'Backbone'
  'underscore'
  'compiled/models/DiscussionTopic'
  'compiled/views/DiscussionTopic/EntriesView'
  'compiled/views/DiscussionTopic/EntryView'
  'compiled/views/PublishButtonView',
  'jst/discussions/_reply_form'
  'compiled/discussions/Reply'
  'compiled/widget/assignmentRubricDialog'
  'compiled/util/wikiSidebarWithMultipleEditors'
  'jquery.instructure_misc_helpers' #scrollSidebar
  'str/htmlEscape'
], (I18n, $, Backbone, _, DiscussionTopic, EntriesView, EntryView, PublishButtonView, replyTemplate, Reply, assignmentRubricDialog, htmlEscape) ->

  class TopicView extends Backbone.View

    events:
      ##
      # Only catch events for the top level "add reply" form,
      # EntriesView handles the clicks for the other replies
      'click #discussion_topic .discussion-reply-action[data-event]': 'handleEvent'
      'click .add_root_reply': 'addRootReply'
      'click .discussion_locked_toggler': 'toggleLocked'
      'click .toggle_due_dates': 'toggleDueDates'
      'click .rte_switch_views_link': 'toggleEditorMode'
      'click .topic-subscribe-button': 'subscribeTopic'
      'click .topic-unsubscribe-button': 'unsubscribeTopic'
      'click .mark_all_as_read': 'markAllAsRead'
      'click .mark_all_as_unread': 'markAllAsUnread'

    els:
      '.add_root_reply': '$addRootReply'
      '.topic .discussion-entry-reply-area': '$replyLink'
      '.due_date_wrapper': '$dueDates'
      '.reply-textarea:first': '$textarea'
      '#discussion-toolbar': '$discussionToolbar'
      '.topic-subscribe-button': '$subscribeButton'
      '.topic-unsubscribe-button': '$unsubscribeButton'
      '.announcement_cog': '$announcementCog'

    initialize: ->
      super
      @model.set 'id', ENV.DISCUSSION.TOPIC.ID
      # overwrite cid so Reply::getModelAttributes gets the right "go to parent" link
      @model.cid = 'main'
      @model.set 'canAttach', ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH
      @filterModel = @options.filterModel
      @filterModel.on 'change', @hideIfFiltering
      @topic = new DiscussionTopic(id: ENV.DISCUSSION.TOPIC.ID)
      # get rid of the /view on /api/vl/courses/x/discusison_topics/x/view
      @topic.url = ENV.DISCUSSION.ROOT_URL.replace /\/view/m, ''
      # set initial subscribed state
      @topic.set 'subscribed', ENV.DISCUSSION.TOPIC.IS_SUBSCRIBED

      # catch when non-root replies are added so we can twiddle the subscribed button
      EntryView.on('addReply', => @setSubscribed(true))
      $(window).on('keydown', @handleKeyDown)

    hideIfFiltering: =>
      if @filterModel.hasFilter()
        @$replyLink.addClass 'hidden'
      else
        @$replyLink.removeClass 'hidden'

    afterRender: ->
      super
      $.scrollSidebar() if $(document.body).is('.with-right-side')
      assignmentRubricDialog.initTriggers()
      @$el.toggleClass 'side_comment_discussion', !ENV.DISCUSSION.THREADED
      @subscriptionStatusChanged()
      if $el = @$('#topic_publish_button')
        @topic.set(unpublishable: ENV.DISCUSSION.TOPIC.CAN_UNPUBLISH, published: ENV.DISCUSSION.TOPIC.IS_PUBLISHED)
        new PublishButtonView(model: @topic, el: $el).render()

    filter: @::afterRender

    toggleLocked: (event) ->
      # this is weird but Topic.coffee was not set up to talk to the API for CRUD
      locked = $(event.currentTarget).data('mark-locked')
      @topic.save({locked: locked}).done -> window.location.reload()

    toggleDueDates: (event) ->
      event.preventDefault()
      @$dueDates.toggleClass('hidden')
      $(event.currentTarget).text if @$dueDates.hasClass('hidden')
        I18n.t('show_due_dates', 'Show Due Dates')
      else
        I18n.t('hide_due_dates', 'Hide Due Dates')

    toggleEditorMode: (event) ->
      event.preventDefault()
      event.stopPropagation()
      @$textarea.editorBox('toggle')
      # hide the clicked link, and show the other toggle link.
      # todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(event.currentTarget).siblings('.rte_switch_views_link').andSelf().toggle()

    subscribeTopic: (event) ->
      event.preventDefault()
      @topic.topicSubscribe()
      @subscriptionStatusChanged()
      # focus the toggled button if the toggled button was focused
      if @$subscribeButton.is(':focus')
        @$unsubscribeButton.focus()

    unsubscribeTopic: (event) ->
      event.preventDefault()
      @topic.topicUnsubscribe()
      @subscriptionStatusChanged()
      # focus the toggled button if the toggled button was focused
      if @$unsubscribeButton.is(':focus')
        @$subscribeButton.focus()

    subscriptionStatusChanged: =>
      subscribed = @topic.get 'subscribed'
      @$discussionToolbar.removeClass 'subscribed'
      @$discussionToolbar.removeClass 'unsubscribed'
      if ENV.DISCUSSION.CAN_SUBSCRIBE
        if subscribed
          @$discussionToolbar.addClass 'subscribed'
        else
          @$discussionToolbar.addClass 'unsubscribed'

    ##
    # Adds a root level reply to the main topic
    #
    # @api private
    addReply: (event) ->
      event?.preventDefault()
      unless @reply?
        @reply = new Reply this, topLevel: true, focus: true
        @reply.on 'edit', => @$addRootReply?.hide()
        @reply.on 'hide', => @$addRootReply?.show()
        @reply.on 'save', (entry) =>
          ENV.DISCUSSION.CAN_SUBSCRIBE = true
          @topic.set('subscription_hold', false)
          @setSubscribed(true)
          @trigger 'addReply', entry
      @model.set 'notification', ''
      @reply.edit()

    # Update subscribed state without posted. Done when replies are posted and
    # user is auto-subscribed.
    setSubscribed: (newValue) ->
      @topic.set('subscribed', true)
      @subscriptionStatusChanged()

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
      # erb renders most of this
      if ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
        modelData = @model.toJSON()
        modelData.showBoxReplyLink = true
        modelData.root = true
        modelData.isForMainDiscussion = true
        html = replyTemplate modelData
        @$('#discussion_topic').append html
      super
    format: (attr, value) ->
      if attr is 'notification'
        value
      else
        htmlEscape value

    addRootReply: (event) ->
      target = $('#discussion_topic .discussion-reply-form')
      @addReply event
      $('html, body').animate scrollTop: target.offset().top - 100

    markAllAsRead: (event) ->
      event.preventDefault()
      @trigger 'markAllAsRead'
      @$announcementCog.focus()

    markAllAsUnread: (event) ->
      event.preventDefault()
      @trigger 'markAllAsUnread'
      @$announcementCog.focus()

    handleKeyDown: (e) =>
      nodeName = e.target.nodeName.toLowerCase()
      return if nodeName == 'input' || nodeName == 'textarea'
      return if e.which != 78 # n
      @addRootReply(e)
      e.preventDefault()
      e.stopPropagation()
