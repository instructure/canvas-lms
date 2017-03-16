define [
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'react-modal'
  'jsx/shared/ColorPicker'
  'compiled/userSettings'
  'jst/calendar/contextList'
  'jst/calendar/undatedEvents'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/EditEventDetailsDialog'
  'compiled/calendar/EventDataSource'
  'jsx/shared/helpers/forceScreenreaderToReparse'
  'compiled/jquery.kylemenu'
  'jquery.instructure_misc_helpers'
  'vendor/jquery.ba-tinypubsub'
], ($, _, React, ReactDOM, ReactModal, ColorPickerComponent, userSettings, contextListTemplate, undatedEventsTemplate, commonEventFactory, EditEventDetailsDialog, EventDataSource, forceScreenreaderToReparse) ->
  ColorPicker = React.createFactory(ColorPickerComponent)

  class VisibleContextManager
    constructor: (contexts, selectedContexts, @$holder) ->
      fragmentData = try
               $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
             catch e
               {}

      availableContexts = (c.asset_string for c in contexts)
      @contexts   = fragmentData.show.split(',') if fragmentData.show
      @contexts or= selectedContexts
      @contexts or= availableContexts

      @contexts = _.intersection(@contexts, availableContexts)
      @contexts = @contexts.slice(0, ENV.CALENDAR.VISIBLE_CONTEXTS_LIMIT)

      @notify()

      $.subscribe 'Calendar/saveVisibleContextListAndClear', @saveAndClear
      $.subscribe 'Calendar/restoreVisibleContextList', @restoreList
      $.subscribe 'Calendar/ensureCourseVisible', @ensureCourseVisible

    saveAndClear: () =>
      if !@savedContexts
        @savedContexts = @contexts
        @contexts = []
        @notifyOnChange()

    restoreList: () =>
      if @savedContexts
        @contexts = @savedContexts
        @savedContexts = null
        @notifyOnChange()

    ensureCourseVisible: (context) =>
      if $.inArray(context, @contexts) < 0
        @toggle(context)

    toggle: (context) ->
      index = $.inArray context, @contexts
      if index >= 0
        @contexts.splice index, 1
      else
        @contexts.push context
        @contexts.shift() if @contexts.length > ENV.CALENDAR.VISIBLE_CONTEXTS_LIMIT
      @notifyOnChange()

    notifyOnChange: =>
      @notify()

      $.ajaxJSON '/api/v1/calendar_events/save_selected_contexts', 'POST',
        selected_contexts: @contexts

    notify: =>
      $.publish 'Calendar/visibleContextListChanged', [@contexts]

      @$holder.find('.context_list_context').each (i, li) =>
        $li = $(li)
        visible = $li.data('context') in @contexts
        $li.toggleClass('checked', visible)
           .toggleClass('not-checked', !visible)
           .find('.context-list-toggle-box')
           .attr('aria-checked', visible)

      userSettings.set('checked_calendar_codes', @contexts)

  setupCalendarFeedsWithSpecialAccessibilityConsiderationsForNVDA = ->
    $calendarFeedModalContent = $('#calendar_feed_box')
    $calendarFeedModalOpener = $('.dialog_opener[aria-controls="calendar_feed_box"]')
    # We need to get the modal initialized early rather than wait for
    # .dialog_opener to open it so we can attach the event to it the first
    # time.  We extend so that we still get all the magic that .dialog_opener
    # should give us.
    $calendarFeedModalContent.dialog($.extend({
      autoOpen: false,
      modal: true
    }, $calendarFeedModalOpener.data('dialogOpts')))

    $calendarFeedModalContent.on('dialogclose', ->
      forceScreenreaderToReparse($('#application')[0])
      $('#calendar-feed .dialog_opener').focus()
    )


  return sidebar = (contexts, selectedContexts, dataSource) ->
    $holder   = $('#context-list-holder')
    $skipLink = $('.skip-to-calendar')
    $colorPickerBtn = $('.ContextList__MoreBtn')

    setupCalendarFeedsWithSpecialAccessibilityConsiderationsForNVDA()

    $holder.html contextListTemplate(contexts: contexts)

    visibleContexts = new VisibleContextManager(contexts, selectedContexts, $holder)

    $holder.on 'click keyclick', '.context-list-toggle-box', (event) ->
      parent = $(this).closest('.context_list_context')
      visibleContexts.toggle $(parent).data('context')

    $holder.on 'click keyclick', '.ContextList__MoreBtn', (event) ->
      positions =
        top: $(this).offset().top - $(window).scrollTop()
        left: $(this).offset().left - $(window).scrollLeft()

      assetString = $(this).closest('li').data('context')

      # ensures previously picked color clears
      ReactDOM.unmountComponentAtNode($('#color_picker_holder')[0])

      ReactDOM.render(ColorPicker({
        isOpen: true
        positions: positions
        assetString: assetString,
        afterClose: () ->
          forceScreenreaderToReparse($('#application')[0])
        afterUpdateColor: (color) =>
          color = '#' + color
          $existingStyles = $('#calendar_color_style_overrides')
          $newStyles = $('<style>')
          $newStyles.text ".group_#{assetString},.group_#{assetString}:hover,.group_#{assetString}:focus{color: #{color}; border-color: #{color}; background-color: #{color};}"
          $existingStyles.append($newStyles)
      }), $('#color_picker_holder')[0])

    $skipLink.on 'click', (e) ->
      e.preventDefault()
      $('#content').attr('tabindex', -1).focus()
