define [
  'jquery'
  'underscore'
  'i18n!discussions'
  'compiled/discussions/MarkAsReadWatcher'
  'compiled/arr/walk'
  'Backbone'
  'compiled/collections/EntryCollection'
  'jst/discussions/_entry_content'
  'jst/discussions/_deleted_entry'
  'jst/discussions/entry_with_replies'
  'jst/discussions/entryStats'
  'compiled/discussions/Reply'
  'compiled/discussions/EntryEditor'
  'str/htmlEscape'
  'vendor/jquery.ba-tinypubsub'
  'compiled/str/convertApiUserContent'
  'jst/_avatar'
  'jst/discussions/_reply_form'
], ($, _, I18n, MarkAsReadWatcher, walk, Backbone, EntryCollection, entryContentPartial, deletedEntriesTemplate, entryWithRepliesTemplate, entryStats, Reply, EntryEditor, htmlEscape, {publish}, convertApiUserContent) ->

  class EntryView extends Backbone.View

    @instances = {}

    @collapseRootEntries = ->
      _.each @instances, (view) ->
        view.collapse() unless view.model.get 'parent'

    @expandRootEntries = ->
      _.each @instances, (view) ->
        view.expand() unless view.model.get 'parent'

    @setAllReadState = (newReadState) ->
      _.each @instances, (view) ->
        view.model.set 'read_state', newReadState

    els:
      '.discussion_entry:first': '$entryContent'
      '.replies:first': '$replies'
      '.headerBadges:first': '$headerBadges'
      '.discussion-read-state-btn:first': '$readStateToggle'

    events:
      'click .loadDescendants': 'loadDescendants'
      'click [data-event]': 'handleDeclarativeEvent'
      'keydown': 'handleKeyDown'

    defaults:
      treeView: null
      descendants: 2
      children: 5
      showMoreDescendants: 2

    template: entryWithRepliesTemplate

    tagName: 'li'

    className: 'entry'

    initialize: ->
      super
      @constructor.instances[@cid] = this
      @$el.attr 'id', "entry-#{@model.get 'id'}"
      @model.on 'change:deleted', @toggleDeleted
      @model.on 'change:read_state', @toggleReadState
      @model.on 'change:editor', @render
      @model.on 'change:editor', (entry) -> entry.trigger('edited')

    toggleRead: (e) ->
      e.preventDefault()
      if @model.get('read_state') is 'read'
        @model.markAsUnread()
      else
        @model.markAsRead()
      EntryView.trigger 'readStateChanged', @model, this

    handleDeclarativeEvent: (event) ->
      $el = $ event.currentTarget
      method = $el.data 'event'
      return if @bypass event
      event.stopPropagation()
      event.preventDefault()
      @[method](event, $el)

    bypass: (event) ->
      target = $ event.target
      return yes if target.data('bypass')?
      clickedAdminLinks = $(event.target).closest('.admin-links').length
      targetHasEvent = $(event.target).data 'event'
      if clickedAdminLinks and !targetHasEvent
        yes
      else
        no

    toJSON: ->
      json = @model.attributes
      json.edited_at = $.datetimeString(json.updated_at)
      if json.editor
        json.editor_name = json.editor.display_name
        json.editor_href = "href=\"#{json.editor.html_url}\""
      else
        json.editor_name = I18n.t 'unknown', 'Unknown'
        json.editor_href = ""
      json

    toggleReadState: (model, read_state) =>
      @setToggleTooltip()
      @$entryContent.toggleClass 'unread', read_state is 'unread'
      @$entryContent.toggleClass 'read', read_state is 'read'

    toggleCollapsed: (event, $el)->
      @addCountsToHeader() unless @addedCountsToHeader
      @$el.toggleClass 'collapsed'

    expand: ->
      @$el.removeClass 'collapsed'

    collapse: ->
      @addCountsToHeader() unless @addedCountsToHeader
      @$el.addClass 'collapsed'

    addCountsToHeader: ->
      stats = @countPosterity()
      html = """
        <div class='new-and-total-badge'>
          <span class="new-items">#{stats.unread}</span>
          <span class="total-items">#{stats.total}</span>
        </div>
        """
      @$headerBadges.append entryStats({stats})
      @addedCountsToHeader = true

    toggleDeleted: (model, deleted) =>
      @$entryContent.toggleClass 'deleted-discussion-entry', deleted
      if deleted
        @model.set('updated_at', (new Date).toISOString())
        @model.set('editor', ENV.current_user)

    setToggleTooltip: ->
      tooltip = if @model.get('read_state') is 'unread'
        I18n.t('mark_as_read', 'Mark as Read')
      else
        I18n.t('mark_as_unread', 'Mark as Unread')

      @$readStateToggle.attr('title', tooltip)


    afterRender: ->
      super
      @collapse() if @options.collapsed
      @setToggleTooltip()
      if @model.get('read_state') is 'unread' and !@model.get('forced_read_state') and !ENV.DISCUSSION.MANUAL_MARK_AS_READ
        @readMarker ?= new MarkAsReadWatcher this
        # this is throttled so calling it here is okay
        MarkAsReadWatcher.checkForVisibleEntries()
      publish 'userContent/change'

    filter: @::afterRender

    renderTree: (opts = {}) =>
      return if @treeView?

      replies = @model.get 'replies'
      descendants = (opts.descendants or @options.descendants) - 1
      children = opts.children or @options.children
      collection = new EntryCollection replies, perPage: children
      boundReplies = collection.map (x) -> x.attributes
      @model.set 'replies', boundReplies

      page = collection.getPageAsCollection 0
      @treeView = new @options.treeView
        el: @$replies[0]
        descendants: descendants
        collection: page
        threaded: @options.threaded
        showMoreDescendants: @options.showMoreDescendants
      @treeView.render()

    renderDescendantsLink: ->
      stats = @countPosterity()
      @descendantsLink = $ '<div/>'
      @descendantsLink.html entryStats({stats, showMore: yes})
      @descendantsLink.addClass 'showMore loadDescendants'
      @$replies.append @descendantsLink

    countPosterity: ->
      stats = unread: 0, total: 0
      return stats unless @model.attributes.replies?
      walk @model.attributes.replies, 'replies', (entry) ->
        stats.unread++ if entry.read_state is 'unread'
        stats.total++
      stats

    loadDescendants: (event) ->
      event.stopPropagation()
      event.preventDefault()
      @renderTree
        children: @options.children
        descendants: @options.showMoreDescendants

    remove: ->
      return unless @model.canModerate()
      if confirm I18n.t('are_your_sure_delete', 'Are you sure you want to delete this entry?')
        @model.set 'deleted', true
        @model.destroy()
        html = deletedEntriesTemplate @toJSON()
        @$('.entry-content:first').html html

    edit: ->
      return unless @model.canModerate()
      @editor ?= new EntryEditor this
      @editor.edit() if not @editor.editing
      # defer for rerender
      @editor.on('display', => setTimeout(@focus, 0))

    focus: =>
      @$('.author').first().focus()

    addReply: (event, $el) ->
      @reply ?= new Reply this, focus: true
      @model.set 'notification', ''
      @reply.edit()
      @reply.on 'save', (entry) =>
        @renderTree()
        @treeView.collection.add entry
        @treeView.collection.fullCollection.add entry
        @model.get('replies').push entry.attributes
        @trigger 'addReply'
        EntryView.trigger 'addReply', entry

    addReplyAttachment: (event, $el) ->
      event.preventDefault()
      @reply.addAttachment($el)

    removeReplyAttachment: (event, $el) ->
      event.preventDefault()
      @reply.removeAttachment($el)

    format: (attr, value) ->
      if attr is 'message'
        value = convertApiUserContent(value)
        @$el.find('.message').removeClass('enhanced')
        publish('userContent/change')
        value
      else if attr is 'notification'
        value
      else
        htmlEscape value

    handleKeyDown: (e) =>
      nodeName = e.target.nodeName.toLowerCase()
      return if nodeName == 'input' || nodeName == 'textarea'
      if e.which == 68 # d
        @remove()
      else if e.which == 69 # e
        @edit()
      else if e.which == 82 # r
        @addReply()
      else return
      e.preventDefault()
      e.stopPropagation()

  _.extend EntryView, Backbone.Events
