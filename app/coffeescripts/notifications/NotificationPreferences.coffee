# This class creates the Notification Preferences display table and manages the data storage for it.
define [
  'i18n!notification_preferences'
  'jquery'
  'underscore'
  'compiled/userSettings'
  'compiled/notifications/NotificationGroupMappings'
  'jst/profiles/notification_preferences'
  'jst/profiles/notifications/_policy_cell'
  'jquery.disableWhileLoading'
  'jquery.ajaxJSON'
  'compiled/jquery.rails_flash_notifications'
  'jqueryui/tooltip'
], (I18n, $, _, userSettings, NotificationGroupMappings, notificationPreferencesTemplate, policyCellTemplate) ->

  class NotificationPreferences

    constructor: (@options) ->
      # Define the buttons for display. The 'code' must match up to the Notification::FREQ_* constants.
      @buttonData = [
        code: 'immediately'
        icon: 'icon-check'
        text: I18n.t('frequencies.immediately', 'ASAP')
        title: I18n.t('frequencies.title.right_away', 'Notify me right away')
      ,
        code: 'daily'
        icon: 'icon-clock'
        text: I18n.t('frequencies.daily', 'Daily')
        title: I18n.t('frequencies.title.daily', 'Send daily summary')
      ,
        code: 'weekly'
        icon: 'icon-calendar-month'
        text: I18n.t('frequencies.weekly', 'Weekly')
        title: I18n.t('frequencies.title.weekly', 'Send weekly summary')
      ,
        code: 'never'
        icon: 'icon-x'
        text: I18n.t('frequencies.never', 'Never')
        title: I18n.t('frequencies.title.never', 'Do not send me anything')
      ]

      @limitedButtonData = [_.first(@buttonData), _.last(@buttonData)]

      @updateUrl  = @options.update_url
      @channels   = @options.channels || []
      @categories = @options.categories || []
      @policies   = @options.policies || []

      # Give each channel a 'name'
      for c in @channels
        c.name = switch c.type
          when 'email' then I18n.t('communication.email.display', 'Email Address')
          when 'sms' then I18n.t('communication.sms.display', 'Cell Number')
          when 'push' then I18n.t('communication.push.display', 'Push Notification')
          when 'twitter' then I18n.t('communication.twitter.display', 'Twitter')
          when 'facebook' then I18n.t('communication.facebook.display', 'Facebook')
          when 'yo' then I18n.t('communication.yo.display', 'Yo')
      # Setup the mappings
      @mappings = new NotificationGroupMappings()
      @$notificationSaveStatus = $('#notifications_save_status')
      @initGrid()

    # Display the frequency selection buttons. Optionally set the focus to the control if desired.
    cellButtonsShow: ($cell, setFocus=true) ->
      $cell.addClass('show-buttons')
      $selection = $cell.find('.event-option-selection')
      $buttons   = $cell.find('.event-option-buttons')
      #
      $selection.hide()
      $buttons.removeClass('screenreader-only')
      if setFocus
        $radio = $cell.find('.frequency:checked')
        $labelToFocus = $cell.find("label[for=#{$radio.attr('id')}]")
        $labelToFocus.focus() if $labelToFocus

    # Hide the frequency selection buttons. Optionally set the focus to the selected status link if desired.
    cellButtonsHide: ($cell, setFocus=true) =>
      $cell.removeClass('show-buttons')
      $selection = $cell.find('.event-option-selection')
      $buttons   = $cell.find('.event-option-buttons')
      #
      $buttons.addClass('screenreader-only')
      $selection.show()
      $selection.find('a:first').focus() if setFocus

    # Build the option cell HTML as an array for all channels and for the given category
    buildPolicyCellsHtml: (category) =>
      fragments = for c in @channels
        policy = _.find @policies, (p) ->
          p.communication_channel_id is c.id and p.category is category.category
        frequency = 'never'
        frequency = policy['frequency'] if policy
        @policyCellHtml(category, c, frequency)
      fragments.join ''

    hideButtonsExceptCell: ($notCell) =>
      # Hide any and all option buttons. May remain from another selection that wasn't changed.
      for cellElem in $("#notification-preferences td.comm-event-option.show-buttons")
        $cell = $(cellElem)
        if $cell != $notCell
          @cellButtonsHide($cell, false) if $cell.find(':focus').length == 0

    communicationEventGroups: =>
      # Want return structure to be like this...
      #    {
      #      name: 'Course Activities',
      #      items: [
      #        {
      #          title: 'Due date change'
      #          description: 'When an unfinished course work item has changed when it is due.'
      #          policyCells: @buildPolicyCellsHtml(1)
      #        }
      #        {
      #          title: 'Grading policy change'
      #          description: 'Happens when the criteria for a grade is changed.'
      #          policyCells: @buildPolicyCellsHtml(2)
      #        }
      #      ]
      #    }

      # Container to hold the data for the groups as an ordered list
      groupsData = []
      # Loop through the groups. Add all the items to the items list.
      for groupName, items of @mappings.groups
        groupItems = []
        for categoryName in items
          # Find the event and add it if found
          category = _.find(@categories, (e) -> e.category == categoryName)
          if category
            item =
              title: category.display_name
              description: category.category_description
              policyCells: @buildPolicyCellsHtml(category)
            if category.option
              item['checkName'] = category.option.name
              item['checkedState'] = category.option.value
              item['checkLabel'] = category.option.label
              item['checkID'] = category.option.id
            groupItems.push(item)
        # If any items found for the group, add the group and the items.
        if groupItems.length > 0
          groupsData.push(name: @mappings.getGroupDisplayName(groupName), items: groupItems)

      # Return the group data list.
      groupsData

    # Find and return the button data for the given code.
    findButtonDataForCode: (buttonCode) =>
      _.find(@buttonData, (b) -> b['code'] == buttonCode )

    # Build the HTML notifications table.
    buildTable: =>
      $('#notification-preferences').append(notificationPreferencesTemplate(
        touch: INST.browser.touch,
        channels: @channels,
        eventGroups: @communicationEventGroups()
        ))
      # Display Bootstrap-like popover tooltip on category names. Allow entire cell to trigger popup.
      $('#notification-preferences .category-name.show-popover').tooltip(
          position:
            my: "left center"
            at: "right+20 center"
            collision: 'none none'
          ,
          tooltipClass: 'popover left middle horizontal'
      )
      # set min-width on row <th /> cells
      $('tbody th[scope=row]').css('min-width', $('h3.group-name').width())

      @setupEventBindings()
      null

    # Generate and return the HTML for an option cell with the with the sepecified value set/reflected.
    policyCellHtml: (category, channel, selectedValue = 'never') =>
      # Reset all buttons to not be active by default. Set their ID to be unique to the data combination.
      _.each(@buttonData, (b) ->
        b['active'] = false
        b['coordinate'] = "cat_#{category.id}_ch_#{channel.id}"
        b['id'] = "#{b['coordinate']}_#{b['code']}"
      )
      selected = @findButtonDataForCode(selectedValue)
      selected['active'] = true

      cellButtonData = if channel.type == 'push' then @limitedButtonData else @buttonData

      policyCellTemplate
        touch:      INST.browser.touch
        category:   category.category
        channelId:  channel.id
        selected:   selected
        allButtons: cellButtonData

    # Record and display the value for the cell.
    saveNewCellValue: ($cell, value) =>
      # Find the button data for display and showing selection.
      btnData = @findButtonDataForCode(value)
      # Setup display
      $cell.attr('data-selection', value)
      $cell.find('a.change-selection i').attr('class', btnData['icon'])
      $cell.find('a.change-selection span.img-text').text(btnData['text'])
      # Get category and channel values
      category = $cell.attr('data-category')
      channelId = $cell.attr('data-channelId')
      # Send value to server
      data = {category: category, channel_id: channelId, frequency: value}
      @$notificationSaveStatus.disableWhileLoading $.ajaxJSON(@updateUrl, 'PUT', data, null,
        # Error callback
        ((data) =>
          $.flashError(I18n.t('communication.errors.saving_preferences_failed', 'Oops! Something broke.  Please try again'))
        )
      ), @spinOpts

    # Setup event bindings.
    setupEventBindings: =>

      $notificationPrefs = $('#notification-preferences')

      # Setup the buttons as a buttonset
      $notificationPrefs.find('.event-option-buttons').buttonset()

      unless INST.browser.touch
        # Catch mouse over and auto-toggle for faster interactions.
        $notificationPrefs.find('.notification-prefs-table').on
          mouseenter: (e) =>
            @cellButtonsShow($(e.currentTarget), false)
          mouseleave: (e) =>
            @cellButtonsHide($(e.currentTarget), false)
          , '.comm-event-option'

        # Setup current selection click event to display selection changing buttons
        $notificationPrefs.find('.notification-prefs-table a.change-selection').on 'click', (e) =>
          # Hide any/all other showing buttons
          e.preventDefault()
          cell = $(e.currentTarget).closest('td')
          @hideButtonsExceptCell(cell)
          @cellButtonsShow(cell, true)

      # When selection button is clicked, the hidden radio button is changed. React to that change. Hide the control and focus the selection
      $notificationPrefs.find('.frequency').on 'change', (e) =>
        radio = $(e.currentTarget)
        cell = radio.closest('td')
        # Record the selected value in data attribute and update image class to reflect new state
        val = radio.attr('data-value')
        @saveNewCellValue(cell, val)

      # When selection option is changed. (Used for mobile users)
      $notificationPrefs.find('.mobile-select').on 'change', (e) =>
        select = $(e.currentTarget)
        cell = $(e.currentTarget).closest('td')
        # Record the selected value in data attribute and update image class to reflect new state
        val = select.find('option:selected').val()
        @saveNewCellValue(cell, val)

      # Catch the change for a user preference and record it at the server.
      $notificationPrefs.find('.user-pref-check').on 'change', (e)=>
        check = $(e.currentTarget)
        checkStatus = (check.attr('checked') == 'checked')
        # Send user prefernce value to server
        data = {user: {}}
        data['user'][check.attr('name')] = checkStatus
        @$notificationSaveStatus.disableWhileLoading $.ajaxJSON(@updateUrl, 'PUT', data, null,
          # Error callback
          ((data) =>
            $.flashError(I18n.t('communication.errors.saving_preferences_failed', 'Oops! Something broke.  Please try again'))
          )
        ), @spinOpts
      null

    # Options for the save spinner
    spinOpts: length: 4, radius: 5, width: 3

    # Initialize the grid.
    initGrid: =>
      @buildTable()
      null
