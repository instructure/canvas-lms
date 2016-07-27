define [
  'jquery'
  'underscore'
  'react'
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
], ($, _, React, ReactModal, ColorPickerComponent, userSettings, contextListTemplate, undatedEventsTemplate, commonEventFactory, EditEventDetailsDialog, EventDataSource, forceScreenreaderToReparse) ->
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
      @contexts = @contexts.slice(0, 10)

      @notify()

      $.subscribe 'Calendar/saveVisibleContextListAndClear', @saveAndClear
      $.subscribe 'Calendar/restoreVisibleContextList', @restoreList

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

    toggle: (context) ->
      index = $.inArray context, @contexts
      if index >= 0
        @contexts.splice index, 1
      else
        @contexts.push context
        @contexts.shift() if @contexts.length > 10
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

  return sidebar = (contexts, selectedContexts, dataSource) ->
    $holder   = $('#context-list-holder')
    $skipLink = $('.skip-to-calendar')
    $colorPickerBtn = $('.ContextList__MoreBtn')

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
      React.unmountComponentAtNode($('#color_picker_holder')[0]);

      React.render(ColorPicker({
        isOpen: true
        positions: positions
        assetString: assetString,
        afterClose: () ->
          forceScreenreaderToReparse($('#application')[0])
        afterUpdateColor: (color) =>
          color = '#' + color
          $existingStyles = $('#calendar_color_style_overrides');
          $newStyles = $('<style>')
          $newStyles.text ".group_#{assetString},.group_#{assetString}:hover,.group_#{assetString}:focus{color: #{color}; border-color: #{color}; background-color: #{color};}"
          $existingStyles.append($newStyles)
      }), $('#color_picker_holder')[0]);

    $skipLink.on 'click', (e) ->
      e.preventDefault()
      $('#content').attr('tabindex', -1).focus()
