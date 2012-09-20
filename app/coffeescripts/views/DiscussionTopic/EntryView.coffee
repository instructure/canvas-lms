define [
  'require'
  'i18n!discussions.entry'
  'Backbone'
  'underscore'
  'compiled/collections/EntryCollection'
  'jst/discussions/_entry_content'
  'jst/discussions/_deleted_entry'
  'jst/discussions/entry_with_replies'
  'compiled/discussions/Reply'
  'compiled/discussions/EntryEditor'
  'compiled/discussions/MarkAsReadWatcher'
  'str/htmlEscape'
  'vendor/jquery.ba-tinypubsub'
  'compiled/jquery.kylemenu'
  'compiled/str/convertApiUserContent'

  # entry_with_replies partials
  'jst/_avatar'
  'jst/discussions/_reply_form'
], (require, I18n, Backbone, _, EntryCollection, entryContentPartial, deletedEntriesTemplate, entryWithRepliesTemplate, Reply, EntryEditor, MarkAsReadWatcher, htmlEscape, {publish}, KyleMenu, convertApiUserContent) ->

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

      # enhance the media_comments in the message
      publish('userContent/change')

      super

    openMenu: (event, $el) ->
      @createMenu($el) unless @menu

    createMenu: ($el) ->
      options =
        appendMenuTo: "body"
        buttonOpts:
          icons:
            primary: null
            secondary: null
      @menu = new KyleMenu $el, options
      @menu.open()

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

    toggleCollapsed: (event, $el) ->
      @model.set 'collapsedView', !@model.get('collapsedView')

    addReply: (event, $el) ->
      @reply ?= new Reply this
      @model.set 'notification', ''
      @reply.edit()

    addReplyAttachment: (event, $el) ->
      @reply.addAttachment($el)

    removeReplyAttachment: (event, $el) ->
      @reply.removeAttachment($el)

    goToReply: (event, $el) ->
      # set the model to focused true or something

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

  # circular dep
  require ['compiled/views/DiscussionTopic/EntryCollectionView'], (EntryCollectionView) ->

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

