/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import {intersection} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import decodeFromHex from '@canvas/util/decodeFromHex'
import ColorPicker from '@canvas/color-picker'
import userSettings from '@canvas/user-settings'
import contextListTemplate from '../jst/contextList.handlebars'
import forceScreenreaderToReparse from 'force-screenreader-to-reparse'
import 'jquery-kyle-menu'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import 'jquery-tinypubsub'
import AccountCalendarsModal from '../react/AccountCalendarsModal'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('calendar_sidebar')

class VisibleContextManager {
  constructor(contexts, selectedContexts, $holder) {
    this.$holder = $holder
    const fragmentData = (() => {
      try {
        return JSON.parse(decodeFromHex(window.location.hash.substring(1))) || {}
      } catch (e) {
        return {}
      }
    })()

    const availableContexts = contexts.map(c => c.asset_string)

    if (fragmentData.show) {
      this.contexts = fragmentData.show.split(',')
    }
    if (!this.contexts) {
      this.contexts = selectedContexts
    }
    if (!this.contexts) {
      this.contexts = availableContexts
    }

    this.enabledAccounts = contexts.filter(c => c.type === 'account').map(dC => dC.asset_string)

    this.contexts = intersection(this.contexts, availableContexts)
    this.contexts = this.contexts.slice(0, ENV.CALENDAR.VISIBLE_CONTEXTS_LIMIT)

    this.notify()

    $.subscribe('Calendar/saveVisibleContextListAndClear', this.saveAndClear)
    $.subscribe('Calendar/restoreVisibleContextList', this.restoreList)
    $.subscribe('Calendar/ensureCourseVisible', this.ensureCourseVisible)
  }

  saveAndClear = () => {
    if (!this.savedContexts) {
      this.savedContexts = this.contexts
      this.contexts = []
      return this.notifyOnChange()
    }
  }

  restoreList = () => {
    if (this.savedContexts) {
      this.contexts = this.savedContexts
      this.savedContexts = null
      return this.notifyOnChange()
    }
  }

  ensureCourseVisible = context => {
    if ($.inArray(context, this.contexts) < 0) {
      return this.toggle(context)
    }
  }

  toggle(context) {
    const index = $.inArray(context, this.contexts)
    if (index >= 0) {
      this.contexts.splice(index, 1)
    } else {
      this.contexts.push(context)
      if (this.contexts.length > ENV.CALENDAR.VISIBLE_CONTEXTS_LIMIT) {
        this.contexts.shift()
      }
    }
    return this.notifyOnChange()
  }

  notifyOnChange = () => {
    this.notify()

    return $.ajaxJSON('/api/v1/calendar_events/save_selected_contexts', 'POST', {
      selected_contexts: this.contexts.length > 0 ? this.contexts : '[]',
    })
  }

  toggleAccount(context, calendarElement) {
    const wrapper = calendarElement.closest('.editable-list-holder')
    const index = $.inArray(context, this.enabledAccounts)
    if (index >= 0) {
      this.enabledAccounts.splice(index, 1)
      $(calendarElement).remove()
      if (this.contexts.includes(context)) {
        this.toggle(context)
      }
    } else {
      this.enabledAccounts.push(context)
      if (!this.contexts.includes(context)) {
        this.toggle(context)
      }
    }
    return this.saveEnabledAccountContexts(wrapper)
  }

  saveEnabledAccountContexts = wrapper => {
    const enabledAccountIds = this.enabledAccounts.map(a => a.split('_')[1])

    if (enabledAccountIds.length === 0) {
      wrapper[0].appendChild(generateEmptyState())
    }
    return $.ajaxJSON('/api/v1/calendar_events/save_enabled_account_calendars', 'POST', {
      enabled_account_calendars: enabledAccountIds.length > 0 ? enabledAccountIds : '',
    })
  }

  notify = () => {
    $.publish('Calendar/visibleContextListChanged', [this.contexts])

    this.$holder.find('.context_list_context').each((i, li) => {
      let needle
      const $li = $(li)
      const visible = ((needle = $li.data('context')), this.contexts.includes(needle))
      $li
        .toggleClass('checked', visible)
        .toggleClass('not-checked', !visible)
        .find('.context-list-toggle-box')
        .attr('aria-checked', visible)
    })

    return userSettings.set('checked_calendar_codes', this.contexts)
  }

  overrideEnabledAccounts = newEnabledAccounts => {
    this.enabledAccounts = newEnabledAccounts
  }
}

function generateEmptyState() {
  const emptyStateContainer = document.createElement('div')
  emptyStateContainer.classList.add('accounts-empty-state')
  emptyStateContainer.innerHTML = I18n.t('Click the "+" icon to add a calendar')
  return emptyStateContainer
}

function setupCalendarFeedsWithSpecialAccessibilityConsiderationsForNVDA() {
  const $calendarFeedModalContent = $('#calendar_feed_box')
  const $calendarFeedModalOpener = $('.dialog_opener[aria-controls="calendar_feed_box"]')
  // We need to get the modal initialized early rather than wait for
  // .dialog_opener to open it so we can attach the event to it the first
  // time.  We extend so that we still get all the magic that .dialog_opener
  // should give us.
  $calendarFeedModalContent.dialog(
    $.extend(
      {
        autoOpen: false,
        modal: true,
        zIndex: 1000,
        create: (e, _ui) => {
          e.target.parentElement.setAttribute(
            'aria-labelledby',
            e.target.parentElement.querySelector('.ui-dialog-title').id
          )
        },
      },
      $calendarFeedModalOpener.data('dialogOpts')
    )
  )

  $calendarFeedModalContent.on('dialogclose', () => {
    forceScreenreaderToReparse($('#application')[0])
    $('#calendar-feed .dialog_opener').focus()
  })
}

function setupAccountCalendarDialog(getSelectedOtherCalendars, onOtherCalendarsChange) {
  ReactDOM.unmountComponentAtNode($(`#manage-accounts-btn`)[0])

  ReactDOM.render(
    <AccountCalendarsModal
      getSelectedOtherCalendars={getSelectedOtherCalendars}
      onSave={onOtherCalendarsChange}
      calendarsPerRequest={100}
      featureSeen={ENV.CALENDAR.ACCOUNT_CALENDAR_EVENTS_SEEN}
    />,
    $(`#manage-accounts-btn`)[0]
  )
}

function refreshOtherCalendarsSection($holder, otherCalendars, notify) {
  otherCalendars.sort((a, b) => {
    return a.name.localeCompare(b.name)
  })
  $holder.html(
    contextListTemplate({
      contexts: otherCalendars,
      type: 'other-calendars',
      includeRemoveOption: 'calendars',
    })
  )
  notify()
}

function convertAccountCalendars(accountCalendars) {
  return accountCalendars.map(oC => ({
    id: oC.id,
    name: oC.name,
    asset_string: oC.asset_string,
    type: oC.type,
    auto_subscribe: oC.auto_subscribe,
    viewed_auto_subscribed_account_calendars: oC.viewed_auto_subscribed_account_calendars,
  }))
}

export default function sidebar(contexts, selectedContexts, dataSource, onContextsChange) {
  const $skipLink = $('.skip-to-calendar')
  const $calendarHolder = $('#calendar-list-holder')
  const $otherCalendarsHolder = $('#other-calendars-list-holder')
  const $combineHolder = $($calendarHolder).add($otherCalendarsHolder)
  const calendars = contexts.filter(c => c.type !== 'account')
  let otherCalendars = contexts.filter(c => c.type === 'account')

  $skipLink.focus(() => {
    $skipLink.removeClass('screenreader-only')
  })

  $skipLink.focusout(() => {
    $skipLink.addClass('screenreader-only')
  })

  setupCalendarFeedsWithSpecialAccessibilityConsiderationsForNVDA()

  $calendarHolder.html(
    contextListTemplate({contexts: calendars, type: 'calendars', includeRemoveOption: 'calendars'})
  )
  const visibleContexts = new VisibleContextManager(contexts, selectedContexts, $combineHolder)

  if ($otherCalendarsHolder.length) {
    const syncOtherCalendars = (newCalendars, notify) =>
      refreshOtherCalendarsSection($otherCalendarsHolder, newCalendars, notify)
    if (otherCalendars.length > 0) {
      syncOtherCalendars(otherCalendars, visibleContexts.notify)
    } else {
      $otherCalendarsHolder[0].appendChild(generateEmptyState())
    }

    const onOtherCalendarsChange = newOtherCalendars => {
      const newAddedCalendars = newOtherCalendars.filter(newAC => {
        return !otherCalendars.some(oldAC => newAC.id === oldAC.id)
      })
      const removedCalendars = otherCalendars.filter(oldAC => {
        return !newOtherCalendars.some(newAC => oldAC.id === newAC.id)
      })

      // make sure the removed contexts aren't active before syncing the calendar
      removedCalendars.forEach(removedCalendar => {
        if (visibleContexts.contexts.includes(removedCalendar.asset_string)) {
          visibleContexts.toggle(removedCalendar.asset_string)
        }
      })
      otherCalendars = newOtherCalendars
      const contextAccountCodes = otherCalendars.map(nOC => nOC.asset_string)
      syncOtherCalendars(otherCalendars, visibleContexts.notify)
      visibleContexts.overrideEnabledAccounts(contextAccountCodes)
      onContextsChange(otherCalendars)
      // make sure the calendar is synced and ready to enable the new contexts
      newAddedCalendars.forEach(newCalendar => {
        if (!visibleContexts.contexts.includes(newCalendar.asset_string)) {
          visibleContexts.toggle(newCalendar.asset_string)
        }
      })
      if (otherCalendars.length === 0) $otherCalendarsHolder[0].appendChild(generateEmptyState())
    }

    const getSelectedOtherCalendars = () => {
      const currentSelection = otherCalendars.filter(oC =>
        visibleContexts.enabledAccounts.includes(oC.asset_string)
      )
      return convertAccountCalendars(currentSelection)
    }
    setupAccountCalendarDialog(getSelectedOtherCalendars, onOtherCalendarsChange)
  }

  $combineHolder.on('click keyclick', '.context-list-toggle-box', function (_event) {
    const parent = $(this).closest('.context_list_context')
    visibleContexts.toggle($(parent).data('context'))
  })

  $otherCalendarsHolder.on('click keyclick', '.ContextList__DeleteBtn', async function (_event) {
    const parent = $(this).closest('.context_list_context')
    const toRemove = $(parent).data('context')
    const calendarToRemoveIndex = otherCalendars.findIndex(oC => oC.asset_string === toRemove)
    otherCalendars.splice(calendarToRemoveIndex, 1)
    try {
      const response = await visibleContexts.toggleAccount(toRemove, parent)
      if (response.status === 'ok') {
        showFlashAlert({
          type: 'success',
          message: I18n.t('Calendar removed'),
        })
      }
    } catch (err) {
      showFlashAlert({
        err,
        message: I18n.t('An error occurred while removing the calendar'),
      })
    }
  })

  $combineHolder.on('click keyclick', '.ContextList__MoreBtn', function (_event) {
    const positions = {
      top: $(this).offset().top - $(window).scrollTop(),
      left: $(this).offset().left - $(window).scrollLeft(),
    }

    const assetString = $(this).closest('li').data('context')

    // ensures previously picked color clears
    ReactDOM.unmountComponentAtNode($(`#calendars_color_picker_holder`)[0])

    ReactDOM.render(
      <ColorPicker
        isOpen={true}
        positions={positions}
        assetString={assetString}
        afterClose={() => forceScreenreaderToReparse($('#application')[0])}
        afterUpdateColor={color => {
          color = `#${color}`
          const $existingStyles = $('#calendar_color_style_overrides')
          const $newStyles = $('<style>')
          $newStyles.text(
            `.group_${assetString},
            .group_${assetString}:hover,
            .group_${assetString}:focus{
              color: ${color};
              border-color: ${color};
              background-color: ${color};
            }`
          )
          $existingStyles.append($newStyles)
        }}
      />,
      $(`#calendars_color_picker_holder`)[0]
    )
  })

  $skipLink.on('click', e => {
    e.preventDefault()
    $('#content').attr('tabindex', -1).focus()
  })
}
