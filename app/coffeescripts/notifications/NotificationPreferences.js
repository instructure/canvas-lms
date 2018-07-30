//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// This class creates the Notification Preferences display table and manages the data storage for it.
import I18n from 'i18n!notification_preferences'
import $ from 'jquery'
import _ from 'underscore'
import NotificationGroupMappings from '../notifications/NotificationGroupMappings'
import notificationPreferencesTemplate from 'jst/profiles/notification_preferences'
import PolicyCell from 'jsx/notification_preferences/PolicyCell'
import 'jquery.disableWhileLoading'
import 'jquery.ajaxJSON'
import '../jquery.rails_flash_notifications'
import 'jqueryui/tooltip'

export default class NotificationPreferences {

  constructor (options) {
    this.buildPolicyCellsProps = this.buildPolicyCellsProps.bind(this)
    this.policyCellProps = this.policyCellProps.bind(this)
    this.communicationEventGroups = this.communicationEventGroups.bind(this)
    this.findButtonDataForCode = this.findButtonDataForCode.bind(this)
    this.buildTable = this.buildTable.bind(this)
    this.renderAllPolicyCells = this.renderAllPolicyCells.bind(this)
    this.saveNewPolicyValue = this.saveNewPolicyValue.bind(this)
    this.setupEventBindings = this.setupEventBindings.bind(this)
    this.initGrid = this.initGrid.bind(this)
    this.options = options
    // Define the buttons for display. The 'code' must match up to the Notification::FREQ_* constants.
    this.buttonData = [{
      code: 'immediately',
      icon: 'icon-check',
      text: I18n.t('frequencies.immediately', 'ASAP'),
      title: I18n.t('frequencies.title.right_away', 'Notify me right away'),
    }, {
      code: 'daily',
      icon: 'icon-clock',
      text: I18n.t('frequencies.daily', 'Daily'),
      title: I18n.t('frequencies.title.daily', 'Send daily summary'),
    }, {
      code: 'weekly',
      icon: 'icon-calendar-month',
      text: I18n.t('frequencies.weekly', 'Weekly'),
      title: I18n.t('frequencies.title.weekly', 'Send weekly summary'),
    }, {
      code: 'never',
      icon: 'icon-x',
      text: I18n.t('frequencies.never', 'Never'),
      title: I18n.t('frequencies.title.never', 'Do not send me anything'),
    }]

    this.limitedButtonData = [_.first(this.buttonData), _.last(this.buttonData)]

    this.updateUrl = this.options.update_url
    this.channels = this.options.channels || []
    this.categories = this.options.categories || []
    this.policies = this.options.policies || []
    this.showObservedNames = this.options.show_observed_names

    // Give each channel a 'name'
    this.channels.forEach((c) => {
      c.name = {
        email: I18n.t('communication.email.display', 'Email Address'),
        sms: I18n.t('communication.sms.display', 'Cell Number'),
        push: I18n.t('communication.push.display', 'Push Notification'),
        twitter: I18n.t('communication.twitter.display', 'Twitter')
      }[c.type]
    })
    // Setup the mappings
    this.mappings = new NotificationGroupMappings()
    this.$notificationSaveStatus = $('#notifications_save_status')
    this.initGrid()
  }

  buildPolicyCellsProps = category =>
    this.channels.map((channel) => {
      const policy = _.find(this.policies, p => p.communication_channel_id === channel.id && p.category === category.category)
      const frequency = policy ? policy.frequency : 'never'
      return this.policyCellProps(category, channel, frequency)
    })

  policyCellProps = (category, channel, selectedValue = 'never') => {
    let {buttonData} = this
    if (channel.type === 'push' || channel.type === 'sms' || channel.type === 'twitter') {
      buttonData = this.limitedButtonData
    }
    return {
      category: category.category,
      channelId: channel.id,
      selection: selectedValue,
      buttonData,
      onValueChanged: this.saveNewPolicyValue
    }
  }

  communicationEventGroups () {
    // Want return structure to be like this...
    //    {
    //      name: 'Course Activities',
    //      items: [
    //        {
    //          title: 'Due date change'
    //          description: 'When an unfinished course work item has changed when it is due.'
    //          policyCells: @buildPolicyCellsProps(1)
    //        }
    //        {
    //          title: 'Grading policy change'
    //          description: 'Happens when the criteria for a grade is changed.'
    //          policyCells: @buildPolicyCellsProps(2)
    //        }
    //      ]
    //    }

    // Container to hold the data for the groups as an ordered list
    // TODO NEED TO FIX THIS FILE
    const groupsData = []
    // Loop through the groups. Add all the items to the items list.
    for (const groupName in this.mappings.groups) {
      const items = this.mappings.groups[groupName]
      const groupItems = []
      items.forEach((categoryName) => {
        // Find the event and add it if found
        const category = _.find(this.categories, e => e.category === categoryName)
        if (category) {
          const item = {
            title: category.display_name,
            description: category.category_description,
            policyCells: this.buildPolicyCellsProps(category),
          }
          if (category.option) {
            item.checkName = category.option.name
            item.checkedState = category.option.value
            item.checkLabel = category.option.label
            item.checkID = category.option.id
          }
          groupItems.push(item)
        }
      })

      // If any items found for the group, add the group and the items.
      if (groupItems.length > 0) {
        groupsData.push({name: this.mappings.getGroupDisplayName(groupName), items: groupItems})
      }
    }

    // Return the group data list.
    return groupsData
  }

  // Find and return the button data for the given code.
  findButtonDataForCode (buttonCode) {
    return _.find(this.buttonData, b => b.code === buttonCode)
  }

  // Build the HTML notifications table.
  buildTable () {
    const eventGroups = this.communicationEventGroups()
    $('#notification-preferences').append(notificationPreferencesTemplate({
      channels: this.channels,
      eventGroups,
      buttonData: this.buttonData,
      showObservedNames: {
        available: this.showObservedNames != null,
        name: 'send_observed_names_in_notifications',
        on: this.showObservedNames,
        label: I18n.t('Show name of observed students in notifications.'),
      }
    }))

    // Display Bootstrap-like popover tooltip on category names. Allow entire cell to trigger popup.
    $('#notification-preferences .category-name.show-popover').tooltip({
      position: {
        my: 'left center',
        at: 'right+20 center',
        collision: 'none none',
      },
      tooltipClass: 'popover left middle horizontal',
    })

    this.renderAllPolicyCells(eventGroups)

    // set min-width on row <th /> cells
    $('tbody th[scope=row]').css('min-width', $('h3.group-name').width())

    this.setupEventBindings()
    return null
  }

  // Record the value for the cell.
  renderAllPolicyCells (eventGroups) {
    eventGroups.forEach((group) => {
      group.items.forEach((item) => {
        item.policyCells.forEach((cell) => {
          const selector = `.comm-event-option[data-category='${cell.category}'][data-channelid='${cell.channelId}']`
          const $elt = $(selector)
          PolicyCell.renderAt($elt.find('.comm-event-option-contents')[0], cell)
        })
      })
    })
  }

  // Record the value for the cell.
  saveNewPolicyValue (category, channelId, newValue) {
    const data = {
      category,
      channel_id: channelId,
      frequency: newValue,
    }
    this.$notificationSaveStatus.disableWhileLoading($.ajaxJSON(this.updateUrl, 'PUT', data, null, () =>
      $.flashError(I18n.t('communication.errors.saving_preferences_failed', 'Oops! Something broke.  Please try again'))
    ), this.spinOpts)
  }

  // Setup event bindings.
  setupEventBindings () {
    const $notificationPrefs = $('#notification-preferences')

    // Catch the change for a user preference and record it at the server.
    $notificationPrefs.find('.user-pref-check').on('change', (e) => {
      const check = $(e.currentTarget)
      const checkStatus = check.attr('checked') === 'checked'
      // Send user preference value to server
      const data = {user: {}}
      data.user[check.attr('name')] = checkStatus
      this.$notificationSaveStatus.disableWhileLoading($.ajaxJSON(this.updateUrl, 'PUT', data, null, () =>
        $.flashError(I18n.t('communication.errors.saving_preferences_failed', 'Oops! Something broke.  Please try again'))
      ), this.spinOpts)
    })
  }

  // Options for the save spinner
  spinOpts = {length: 4, radius: 5, width: 3}

  // Initialize the grid.
  initGrid () {
    this.buildTable()
  }
}
