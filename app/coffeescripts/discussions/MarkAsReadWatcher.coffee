define [
  'Backbone'
  'i18n!discussions'
  'underscore'
  'jquery'
], (Backbone, I18n, _, $) ->

  # An entry needs to be in the viewport for 2 consecutive secods for it to be marked as read
  # if you are scrolling quickly down the page and it comes in and out of the viewport in less
  # than 2 seconds, it will not count as being read
  MS_UNTIL_READ = 2000
  CHECK_THROTTLE = 1000

  ##
  # Watches an EntryView position to determine whether or not to mark it
  # as read
  class MarkAsReadWatcher

    ##
    # Storage for all unread instances
    @unread: []

    ##
    # @param {EntryView} view
    constructor: (@view) ->
      MarkAsReadWatcher.unread.push this
      @view.model.bind 'change:collapsedView', (model, collapsedView) =>
        @ignore = collapsedView
        if collapsedView
          @clearTimer()

    createTimer: ->
      @timer ||= setTimeout @markAsRead, MS_UNTIL_READ

    clearTimer: ->
      clearTimeout @timer
      delete @timer

    markAsRead: =>
      @view.model.markAsRead()
      MarkAsReadWatcher.unread = _(MarkAsReadWatcher.unread).without(this)
      MarkAsReadWatcher.trigger 'markAsRead', @view.model

    $window = $(window)

    @init: ->
      $window.bind 'scroll resize', @checkForVisibleEntries
      @checkForVisibleEntries()

    @checkForVisibleEntries: _.throttle =>
      topOfViewport = $window.scrollTop()
      bottomOfViewport = topOfViewport + $window.height()
      for entry in @unread
        continue if entry.ignore or entry.view.model.get('forced_read_state')
        topOfElement = entry.view.$el.offset().top
        inView = (topOfElement < bottomOfViewport) &&
                 (topOfElement + entry.view.$el.height() > topOfViewport)
        entry[ if inView then 'createTimer' else 'clearTimer' ]()
      return
    , CHECK_THROTTLE

  _.extend MarkAsReadWatcher, Backbone.Events


