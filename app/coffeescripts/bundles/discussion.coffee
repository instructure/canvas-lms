require [
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
], (DiscussionFilterState, DiscussionToolbarView, DiscussionFilterResultsView, MarkAsReadWatcher, $, Backbone, Entry, MaterializedDiscussionTopic, SideCommentDiscussionTopic, EntryCollection, TopicView, EntriesView) ->

  perPage     = 10
  descendants = 3
  children    = 3

  ##
  # create the objects ...
  router        = new Backbone.Router

  @data         = if ENV.DISCUSSION.THREADED
                    new MaterializedDiscussionTopic
                  else
                    new SideCommentDiscussionTopic

  entries       = new EntryCollection null, {perPage}

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

  ##
  # connect them ...
  data.on 'change', ->
    entries.reset data.get 'entries'

  entriesView.on 'scrollAwayFromEntry', ->
    $window = $ window
    # prevent scroll to top for non-pushstate browsers when hash changes
    top = $window.scrollTop()
    router.navigate '',
      trigger: false
      replace: true
    $window.scrollTo top

  filterView.on 'clickEntry', (entry) ->
    router.navigate "entry-#{entry.get 'id'}", yes

  ##
  # routes
  router.route '*catchall', 'catchall', -> router.navigate '', yes
  router.route 'entry-:id', 'id', entriesView.goToEntry
  router.route 'page-:page', 'page', (page) ->
    entriesView.render page
    # TODO: can get a little bouncy when the page isn't as tall as the previous
    $(window).scrollTo '#discussion_subentries'
  router.route '', 'root', entriesView.render
  initEntries = ->
    data.fetch success: ->
      Backbone.history.start
        pushState: yes
        root: ENV.DISCUSSION.APP_URL + '/'
    topicView.on 'addReply', (entry) ->
      entries.add entry
      router.navigate "entry-#{entry.get 'id'}", yes
    MarkAsReadWatcher.init()

  topicView.render()
  toolbarView.render()

  ##
  # Get the party started
  if ENV.DISCUSSION.INITIAL_POST_REQUIRED
    once = ->
      initEntries()
      topicView.off 'addReply', once
    topicView.on 'addReply', once
  else
    initEntries()


