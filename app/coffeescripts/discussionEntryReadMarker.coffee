define [
  'i18n!discussions'
  'use!underscore'
  'jquery'
  'jquery.ajaxJSON'
], (I18n, _, $) ->

  # an entry needs to be in the viewport for 2 consecutive secods for it to be marked as read
  # if you are scrolling quickly down the page and it comes in and out of the viewport in less
  # than 2 seconds, it will not count as being read
  MILLISECONDS_ENTRY_NEEDS_TO_BE_VIEWABLE_TO_MARK_AS_READ = 2000
  CHECK_THROTTLE = 100

  class UnreadEntry
    constructor: (element) ->
      @$element = $(element)

    createTimer: ->
      @timer ||= setTimeout @markAsRead, MILLISECONDS_ENTRY_NEEDS_TO_BE_VIEWABLE_TO_MARK_AS_READ

    clearTimer: ->
      clearTimeout @timer
      delete @timer

    markAsRead: =>
      @$element.removeClass('unread').addClass('just_read')
      UnreadEntry.unreadEntries = _(UnreadEntry.unreadEntries).without(this)
      UnreadEntry.updateUnreadCount()
      $.ajaxJSON @$element.data('markReadUrl'), 'PUT'

    $window = $(window)

    @init: ->
      @unreadEntries = _.map $('.can_be_marked_as_read.unread'), (el) ->
        new UnreadEntry(el)
      @$topic = $('.topic')
      @$topicUnreadEntriesCount = @$topic.find('.topic_unread_entries_count')
      @$topicUnreadEntriesTooltip = @$topic.find('.topic_unread_entries_tooltip')
      $window.bind 'scroll resize', @checkForVisibleEntries
      @checkForVisibleEntries()

    @checkForVisibleEntries: _.throttle =>
      topOfViewport = $window.scrollTop()
      bottomOfViewport = topOfViewport + $window.height()
      for entry in @unreadEntries
        topOfElement    = entry.$element.offset().top
        inView = (topOfElement < bottomOfViewport) &&
                 (topOfElement + entry.$element.height() > topOfViewport)
        entry[ if inView then 'createTimer' else 'clearTimer' ]()
      return
    , CHECK_THROTTLE

    @updateUnreadCount: ->
      unreadEntriesLength = @unreadEntries.length
      @$topic.toggleClass('has_unread_entries', !!unreadEntriesLength)
      @$topicUnreadEntriesCount.text(unreadEntriesLength || '')
      tip = I18n.t('reply_count', { zero: 'No unread entries', one: '1 unread entry', other: '%{count} unread entries' }, count: unreadEntriesLength)
      @$topicUnreadEntriesTooltip.text(tip)
