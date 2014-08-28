define [
  'jquery'
  'underscore'
  'compiled/userSettings'
  'jst/calendar/contextList'
  'jst/calendar/undatedEvents'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/EditEventDetailsDialog'
  'compiled/calendar/EventDataSource'
  'compiled/jquery.kylemenu'
  'jquery.instructure_misc_helpers'
  'vendor/jquery.ba-tinypubsub'
], ($, _, userSettings, contextListTemplate, undatedEventsTemplate, commonEventFactory, EditEventDetailsDialog, EventDataSource) ->

  class VisibleContextManager
    constructor: (contexts, selectedContexts, @$holder) ->
      fragmentData = try
               $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
             catch e
               {}

      availableContexts = (c.asset_string for c in contexts)
      @contexts   = fragmentData.show.split(',') if fragmentData.show
      @contexts or= selectedContexts
      @contexts or= userSettings.get('checked_calendar_codes')
      @contexts or= availableContexts

      @contexts = _.intersection(@contexts, availableContexts)
      @contexts = @contexts.slice(0, 10)

      @notify()

      $.subscribe 'Calendar/saveVisibleContextListAndClear', @saveAndClear
      $.subscribe 'Calendar/restoreVisibleContextList', @restoreList

    saveAndClear: () =>
      if !@savedContexts
        @savedContexts = @contexts
        @contexts = []
        @notify()

    restoreList: () =>
      if @savedContexts
        @contexts = @savedContexts
        @savedContexts = null
        @notify()

    toggle: (context) ->
      index = $.inArray context, @contexts
      if index >= 0
        @contexts.splice index, 1
      else
        @contexts.push context
        @contexts.shift() if @contexts.length > 10
      @notify()

    notify: ->
      $.publish 'Calendar/visibleContextListChanged', [@contexts]

      @$holder.find('.context_list_context').each (i, li) =>
        $li = $(li)
        visible = $li.data('context') in @contexts
        $li.toggleClass('checked', visible)
           .toggleClass('not-checked', !visible)
           .find('.context-list-toggle-box')
           .attr('aria-checked', visible)

  return sidebar = (contexts, selectedContexts, dataSource) ->

    $holder   = $('#context-list-holder')
    $skipLink = $('.skip-to-calendar')

    $holder.html contextListTemplate(contexts: contexts)

    visibleContexts = new VisibleContextManager(contexts, selectedContexts, $holder)

    $holder.on 'click keyclick', '.context_list_context', (event) ->
      visibleContexts.toggle $(this).data('context')
      userSettings.set('checked_calendar_codes',
        _.map($(this).parent().children('.checked'), (c) -> $(c).data('context')))

    $skipLink.on 'click', (e) ->
      e.preventDefault()
      $('#content').attr('tabindex', -1).focus()
