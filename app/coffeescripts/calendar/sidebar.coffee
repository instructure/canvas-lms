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
], ($, {map}, userSettings, contextListTemplate, undatedEventsTemplate, commonEventFactory, EditEventDetailsDialog, EventDataSource) ->

  class VisibleContextManager
    constructor: (contexts, selectedContexts, @$holder) ->
      fragmentData = try
               $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
             catch e
               {}

      @contexts   = fragmentData.show.split(',') if fragmentData.show
      @contexts or= selectedContexts
      @contexts or= userSettings.get('checked_calendar_codes')
      @contexts or= (c.asset_string for c in contexts[0...10])

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
        @contexts.shift if @contexts.length > 10
      @notify()

    notify: ->
      $.publish 'Calendar/visibleContextListChanged', [@contexts]

      @$holder.find('.context_list_context').each (i, li) =>
        $li = $(li)
        visible = $li.data('context') in @contexts
        $li.toggleClass('checked', visible).toggleClass('not-checked', !visible)

  return sidebar = (contexts, selectedContexts, dataSource) ->

    $holder = $('#context-list-holder')

    $holder.html contextListTemplate(contexts: contexts)

    visibleContexts = new VisibleContextManager(contexts, selectedContexts, $holder)

    $holder.delegate '.context_list_context', 'click', (event) ->
      # dont toggle if thy were clicking the .settings button
      unless $(event.target).closest('[data-add-event]').length
        visibleContexts.toggle $(this).data('context')
        userSettings.set('checked_calendar_codes',
          map($(this).parent().children('.checked'), (c) -> $(c).data('context')))

    $holder.delegate '[data-add-event]', 'click', ->
      context = $(this).parents('li[data-context]').data('context')
      event = commonEventFactory(null, contexts)
      new EditEventDetailsDialog(event).show()
      # TODO, codesmell: we should get rid of this next line and let EditEventDetailsDialog
      # take care of that behaviour
      $('select[class="context_id"]').val(context).triggerHandler('change')
