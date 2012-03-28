define [
  'require'
  'i18n!discussions.entry'
  'compiled/backbone-ext/Backbone'
  'compiled/discussions/EntryCollection'
  'jst/discussions/_entry_content'
  'jst/discussions/_deleted_entry'
  'jst/discussions/entry_with_replies'
  'compiled/discussions/Reply'
  'compiled/discussions/EntryEditor'
  'compiled/discussions/MarkAsReadWatcher'
  'str/htmlEscape'
  'compiled/jquery.kylemenu'

  # entry_with_replies partials
  'jst/_avatar'
  'jst/discussions/_reply_form'
], (require, I18n, Backbone, EntryCollection, entryContentPartial, deletedEntriesTemplate, entryWithRepliesTemplate, Reply, EntryEditor, MarkAsReadWatcher, htmlEscape) ->

  # save memory
  noop = ->

  ##
  # View for a single entry
  class EntryView extends Backbone.View

    # So we can delegate from EntriesView, instead of attaching
    # handlers for every EntryView
    @instances = []

    tagName: 'li'

    className: 'entry'

    initialize: ->
      super

      # store the instance so we can delegate from EntriesView
      id = @model.get 'id'
      EntryView.instances[id] = this

      # for event handler delegated from EntriesView
      @model.bind 'change:id', (model, id) => @$el.attr 'data-id', id
      @model.bind 'change:collapsedView', @onCollapsedView
      @model.bind 'change:read_state', @onReadState

      #TODO: style this based on focus state
      #@model.bind 'change:focused', ->

      @render()

      @model.bind 'change:deleted', (model, deleted) =>
        @$('.discussion_entry:first').toggleClass 'deleted-discussion-entry', deleted

      @$('.discussion_entry:first').addClass('deleted-discussion-entry') if @model.get('deleted')
      @toggleCollapsedClass()
      @createReplies()

    onCollapsedView: (model, collapsedView) =>
      @toggleCollapsedClass()
      if @model.get 'hideRepliesOnCollapse'
        els = @$('.replies, .add-side-comment-wrap')
        if collapsedView
          els.hide()
        else
          els.show()

    onReadState: (model, read_state) =>
      if read_state is 'unread'
        @markAsReadWatcher ?= new MarkAsReadWatcher this
      @$('article:first').toggleClass('unread', read_state is 'unread')

    fetchFullEntry: ->
      @model.set 'message', I18n.t('loading', 'loading...')
      @model.fetch()

    toggleCollapsedClass: ->
      collapsedView = @model.get 'collapsedView'
      @$el.children('.discussion_entry')
        .toggleClass('collapsed', !!collapsedView)
        .toggleClass('expanded', !collapsedView)

    render: ->
      @$el.html entryWithRepliesTemplate @model.toJSON()
      @$el.attr 'data-id', @model.get 'id'
      @$el.attr 'id', @model.cid
      super

    openMenu: (event, $el) ->
      @createMenu($el) unless @$menu
      # open it up on first click
      @$menu.popup 'open'
      # stop propagation (EntriesView::handleEntryEvent)
      false

    createMenu: ($el) ->
      $el.kyleMenu
        appendMenuTo: "body"
        buttonOpts:
          icons:
            primary: null
            secondary: null

      @$menu = $el.data 'kyleMenu'

      # EntriesView::handleEntryEvent won't capture clicks on this
      # since its appended to the body, so we have to replicate the
      # event handling here
      @$menu.delegate '[data-event]', 'click', (event) =>
        event.preventDefault()
        $el = $(event.currentTarget)
        action = $el.data('event')
        @[action](event, $el)

    # circular dep, defined at end of file
    createReplies: ->

    # events delegated from EntriesView
    remove: ->
      @model.set 'collapsedView', true
      html = deletedEntriesTemplate @model.toJSON()
      @$('.entry_content:first').html html
      @model.destroy()

    edit: ->
      @editor ?= new EntryEditor this
      @editor.edit()
      false

    toggleCollapsed: (event, $el) ->
      @model.set 'collapsedView', !@model.get('collapsedView')

    addReply: (event, $el) ->
      event.preventDefault()
      @reply ?= new Reply this
      @model.set 'notification', ''
      @reply.edit()

    addReplyAttachment: (event, $el) ->
      event.preventDefault()
      @reply.addAttachment($el)

    removeReplyAttachment: (event, $el) ->
      event.preventDefault()
      @reply.removeAttachment($el)

    goToReply: (event, $el) ->
      # set the model to focused true or something

  # circular dep
  require ['compiled/discussions/EntryCollectionView'], (EntryCollectionView) ->

    EntryView::createReplies = ->
      el = @$el.find '.replies'
      @collection = new EntryCollection

      @view = new EntryCollectionView
        $el: el
        collection: @collection

      replies = @model.get 'replies'
      _.each replies, (reply) =>
        reply.parent_cid = @model.cid
      @collection.reset @model.get('replies')

  EntryView

