require [
  'i18n!discussions'
  'compiled/views/DiscussionTopic/EntryView'
  'compiled/models/DiscussionFilterState'
  'compiled/views/DiscussionTopic/DiscussionToolbarView'
  'compiled/views/DiscussionTopic/DiscussionFilterResultsView'
  'compiled/discussions/MarkAsReadWatcher'
  'jquery'
  'underscore'
  'Backbone'
  'react'
  'react-dom'
  'jsx/discussion_topics/DiscussionTopicKeyboardShortcutModal'
  'compiled/models/Entry'
  'compiled/models/Topic'
  'compiled/models/SideCommentDiscussionTopic'
  'compiled/collections/EntryCollection'
  'compiled/views/DiscussionTopic/DiscussionTopicToolbarView'
  'compiled/views/DiscussionTopic/TopicView'
  'compiled/views/DiscussionTopic/EntriesView'
  'jsx/conditional_release_stats/index'
  'rubricEditBinding'     # sets up event listener for 'rubricEditDataReady'
  'compiled/jquery/sticky'
  'compiled/jquery/ModuleSequenceFooter'
  'jsx/context_cards/StudentContextCardTrigger'
], (I18n, EntryView, DiscussionFilterState, DiscussionToolbarView, DiscussionFilterResultsView, MarkAsReadWatcher, $, _, Backbone, React, ReactDOM, DiscussionTopicKeyboardShortcutModal, Entry, MaterializedDiscussionTopic, SideCommentDiscussionTopic, EntryCollection, DiscussionTopicToolbarView, TopicView, EntriesView, CyoeStats) ->

  descendants = 5
  children    = 10

  ##
  # create the objects ...
  router        = new Backbone.Router

  @data         = if ENV.DISCUSSION.THREADED
                    new MaterializedDiscussionTopic root_url: ENV.DISCUSSION.ROOT_URL
                  else
                    new SideCommentDiscussionTopic root_url: ENV.DISCUSSION.ROOT_URL

  entries       = new EntryCollection null

  filterModel   = new DiscussionFilterState

  discussionTopicToolbarView = new DiscussionTopicToolbarView(el: '#discussion-managebar')

  ReactDOM.render(
    React.createElement(DiscussionTopicKeyboardShortcutModal),
    document.getElementById('keyboard-shortcut-modal')
  )

  topicView     = new TopicView
                    el: '#main'
                    model: new Backbone.Model
                    filterModel: filterModel

  @entriesView   = new EntriesView
                    el: '#discussion_subentries'
                    collection: entries
                    descendants: descendants
                    children: children
                    threaded: ENV.DISCUSSION.THREADED
                    model: filterModel

  toolbarView   = new DiscussionToolbarView
                    el: '#discussion-toolbar'
                    model: filterModel

  filterView    = new DiscussionFilterResultsView
                    el: '#filterResults'
                    allData: data
                    model: filterModel

  $container = $ window
  $subentries = $ '#discussion_subentries'

  scrollToTop = ->
    $container.scrollTo $subentries, offset: -49

  ##
  # connect them ...
  data.on 'change', ->
    entryData = data.get 'entries'
    entries.options.per_page = entryData.length
    entries.reset entryData

  ##
  # define function that syncs a discussion entry's
  # read state back to the materialized view data.
  updateMaterializedViewReadState = (id, read_state) ->
    e = data.flattened[id]
    e.read_state = read_state if e

  ##
  # propagate mark all read/unread changes to all views
  setAllReadStateAllViews = (newReadState) ->
    entries.setAllReadState(newReadState)
    EntryView.setAllReadState(newReadState)
    filterView.setAllReadState(newReadState)

  entriesView.on 'scrollAwayFromEntry', ->
    # prevent scroll to top for non-pushstate browsers when hash changes
    top = $container.scrollTop()
    router.navigate '',
      trigger: false
      replace: true
    $container.scrollTop(top)

  ##
  # catch when an EntryView changes the read_state
  # of a discussion entry and update the materialized view.
  EntryView.on 'readStateChanged', (entry, view)->
    updateMaterializedViewReadState(entry.get('id'), entry.get('read_state'))

  ##
  # catch when auto-mark-as-read watcher changes an entry
  # and update the materialized view to match.
  MarkAsReadWatcher.on 'markAsRead', (entry)->
    updateMaterializedViewReadState(entry.get('id'), entry.get('read_state'))

  ##
  # detect when read_state changes on filtered model.
  # sync the change to full view collections.
  filterView.on 'readStateChanged', (id, read_state) ->
    # update on materialized view
    updateMaterializedViewReadState(id, read_state)

  filterView.on 'clickEntry', (entry) ->
    router.navigate "entry-#{entry.get 'id'}", yes

  toolbarView.on 'showDeleted', (show) ->
    entriesView.showDeleted(show)

  toolbarView.on 'expandAll', ->
    EntryView.expandRootEntries()
    scrollToTop()

  toolbarView.on 'collapseAll', ->
    EntryView.collapseRootEntries()
    scrollToTop()

  topicView.on 'markAllAsRead', ->
    data.markAllAsRead()
    setAllReadStateAllViews('read')

  topicView.on 'markAllAsUnread', ->
    data.markAllAsUnread()
    setAllReadStateAllViews('unread')

  filterView.on 'render', ->
    scrollToTop()

  filterView.on 'hide', ->
    scrollToTop()

  filterModel.on 'reset', -> EntryView.expandRootEntries()

  canReadReplies = ->
    ENV.DISCUSSION.PERMISSIONS.CAN_READ_REPLIES

  ##
  # routes
  router.route 'topic', 'topic', ->
    $container.scrollTop $('#discussion_topic')
    setTimeout ->
      $('#discussion_topic .author').focus()
      $container.one "scroll", -> router.navigate('')
    , 10
  router.route 'entry-:id', 'id', entriesView.goToEntry
  router.route 'page-:page', 'page', (page) ->
    entriesView.render page
    # TODO: can get a little bouncy when the page isn't as tall as the previous
    scrollToTop()
  initEntries = (initial_entry) ->
    if canReadReplies()
      data.fetch success: ->
        entriesView.render()
        Backbone.history.start
          pushState: yes
          root: ENV.DISCUSSION.APP_URL + '/'
        if initial_entry
          fetched_model = entries.get(initial_entry.id)
          entries.remove(fetched_model) if fetched_model
          entries.add(initial_entry)
          entriesView.render()
          router.navigate "entry-#{initial_entry.get 'id'}", yes
      topicView.on 'addReply', (entry) ->
        entries.add entry
        router.navigate "entry-#{entry.get 'id'}", yes
      MarkAsReadWatcher.init() unless ENV.DISCUSSION.MANUAL_MARK_AS_READ
    else
      $('#discussion_subentries span').text(I18n.t("You must log in to view replies"))

  topicView.render()
  toolbarView.render()

  ##
  # Add module sequence footer
  if ENV.DISCUSSION.SEQUENCE?
    $('#module_sequence_footer').moduleSequenceFooter(
      assetType: ENV.DISCUSSION.SEQUENCE.ASSET_TYPE
      assetID: ENV.DISCUSSION.SEQUENCE.ASSET_ID
      courseID: ENV.DISCUSSION.SEQUENCE.COURSE_ID
      )

  ##
  # Get the party started
  if ENV.DISCUSSION.INITIAL_POST_REQUIRED
    once = (entry) ->
      initEntries(entry)
      topicView.off 'addReply', once
    topicView.on 'addReply', once
  else
    initEntries()

  graphsRoot = document.getElementById('crs-graphs')
  detailsParent = document.getElementById('not_right_side')
  CyoeStats.init(graphsRoot, detailsParent)
