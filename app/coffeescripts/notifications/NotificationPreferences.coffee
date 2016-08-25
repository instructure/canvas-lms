# This class creates the Notification Preferences display table and manages the data storage for it.
define [
  'i18n!notification_preferences'
  'jquery'
  'underscore'
  'compiled/userSettings'
  'compiled/notifications/NotificationGroupMappings'
  'jst/profiles/notification_preferences'
  'jsx/notification_preferences/PolicyCell'
  'jquery.disableWhileLoading'
  'jquery.ajaxJSON'
  'compiled/jquery.rails_flash_notifications'
  'jqueryui/tooltip'
], (I18n, $, _, userSettings, NotificationGroupMappings, notificationPreferencesTemplate, PolicyCell) ->

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
          when 'yo' then I18n.t('communication.yo.display', 'Yo')
      # Setup the mappings
      @mappings = new NotificationGroupMappings()
      @$notificationSaveStatus = $('#notifications_save_status')
      @initGrid()

    buildPolicyCellsProps: (category) =>
      cellProps = for channel in @channels
        policy = _.find @policies, (p) ->
          p.communication_channel_id == channel.id and p.category == category.category
        frequency = 'never'
        frequency = policy['frequency'] if policy
        @policyCellProps(category, channel, frequency)

    policyCellProps: (category, channel, selectedValue = 'never') =>
      buttonData = @buttonData
      if channel.type == 'push' || channel.type == 'sms' || channel.type == 'twitter'
        buttonData = @limitedButtonData
      {
        category: category.category
        channelId: channel.id
        selection: selectedValue
        buttonData: buttonData
        onValueChanged: @saveNewPolicyValue
      }

    communicationEventGroups: =>
      # Want return structure to be like this...
      #    {
      #      name: 'Course Activities',
      #      items: [
      #        {
      #          title: 'Due date change'
      #          description: 'When an unfinished course work item has changed when it is due.'
      #          policyCells: @buildPolicyCellsProps(1)
      #        }
      #        {
      #          title: 'Grading policy change'
      #          description: 'Happens when the criteria for a grade is changed.'
      #          policyCells: @buildPolicyCellsProps(2)
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
              policyCells: @buildPolicyCellsProps(category)
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
      eventGroups = @communicationEventGroups()
      $('#notification-preferences').append(notificationPreferencesTemplate(
        channels: @channels,
        eventGroups: eventGroups
        buttonData: @buttonData
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

      this.renderAllPolicyCells(eventGroups)

      # set min-width on row <th /> cells
      $('tbody th[scope=row]').css('min-width', $('h3.group-name').width())

      @setupEventBindings()
      null

    renderAllPolicyCells: (eventGroups) =>
      for group in eventGroups
        for item in group.items
          for cell in item.policyCells
            selector = ".comm-event-option[data-category='#{cell.category}'][data-channelid='#{cell.channelId}']"
            $elt = $(selector)
            PolicyCell.renderAt($elt.find('.comm-event-option-contents')[0], cell)

    # Record the value for the cell.
    saveNewPolicyValue: (category, channelId, newValue) =>
      data =
        category: category
        channel_id: channelId
        frequency: newValue
      @$notificationSaveStatus.disableWhileLoading $.ajaxJSON(@updateUrl, 'PUT', data, null,
        # Error callback
        ((data) =>
          $.flashError(I18n.t('communication.errors.saving_preferences_failed', 'Oops! Something broke.  Please try again'))
        )
      ), @spinOpts

    # Setup event bindings.
    setupEventBindings: =>
      $notificationPrefs = $('#notification-preferences')

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
