require [
  'compiled/views/DiscussionTopic/EntryView'
  'compiled/models/DiscussionFilterState'
  'compiled/views/DiscussionTopic/DiscussionToolbarView'
  'compiled/views/DiscussionTopic/DiscussionFilterResultsView'
  'compiled/discussions/MarkAsReadWatcher'
  'jquery'
  'Backbone'
  'compiled/models/Entry'
  'compiled/models/Topic'
  'compiled/models/SideCommentDiscussionTopic'
  'compiled/collections/EntryCollection'
  'compiled/views/DiscussionTopic/TopicView'
  'compiled/views/DiscussionTopic/EntriesView'
  'compiled/jquery/sticky'
], (EntryView, DiscussionFilterState, DiscussionToolbarView, DiscussionFilterResultsView, MarkAsReadWatcher, $, Backbone, Entry, MaterializedDiscussionTopic, SideCommentDiscussionTopic, EntryCollection, TopicView, EntriesView) ->

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

  topicView     = new TopicView
                    el: '#main'
                    model: new Backbone.Model
                    filterModel: filterModel

  entriesView   = new EntriesView
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

  entriesView.on 'scrollAwayFromEntry', ->
    # prevent scroll to top for non-pushstate browsers when hash changes
    top = $container.scrollTop()
    router.navigate '',
      trigger: false
      replace: true
    $container.scrollTo top

  filterView.on 'clickEntry', (entry) ->
    router.navigate "entry-#{entry.get 'id'}", yes

  toolbarView.on 'expandAll', ->
    EntryView.expandRootEntries()
    scrollToTop()

  toolbarView.on 'collapseAll', ->
    EntryView.collapseRootEntries()
    scrollToTop()

  filterView.on 'render', ->
    scrollToTop()

  filterView.on 'hide', ->
    scrollToTop()

  filterModel.on 'reset', -> EntryView.expandRootEntries()


  ##
  # routes
  router.route 'entry-:id', 'id', entriesView.goToEntry
  router.route 'page-:page', 'page', (page) ->
    entriesView.render page
    # TODO: can get a little bouncy when the page isn't as tall as the previous
    scrollToTop()
  initEntries = (initial_entry) ->
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

  topicView.render()
  toolbarView.render()

  ##
  # Get the party started
  if ENV.DISCUSSION.INITIAL_POST_REQUIRED
    once = (entry) ->
      initEntries(entry)
      topicView.off 'addReply', once
    topicView.on 'addReply', once
  else
    initEntries()


