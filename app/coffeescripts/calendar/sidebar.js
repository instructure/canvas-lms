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
import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import ColorPicker from 'jsx/shared/ColorPicker'
import userSettings from '../userSettings'
import contextListTemplate from 'jst/calendar/contextList'
import forceScreenreaderToReparse from 'jsx/shared/helpers/forceScreenreaderToReparse'
import '../jquery.kylemenu'
import 'jquery.instructure_misc_helpers'
import 'vendor/jquery.ba-tinypubsub'

class VisibleContextManager {
  constructor(contexts, selectedContexts, $holder) {
    this.$holder = $holder
    const fragmentData = (() => {
      try {
        return $.parseJSON($.decodeFromHex(window.location.hash.substring(1))) || {}
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

    this.contexts = _.intersection(this.contexts, availableContexts)
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
      selected_contexts: this.contexts
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
        modal: true
      },
      $calendarFeedModalOpener.data('dialogOpts')
    )
  )

  $calendarFeedModalContent.on('dialogclose', () => {
    forceScreenreaderToReparse($('#application')[0])
    $('#calendar-feed .dialog_opener').focus()
  })
}

export default function sidebar(contexts, selectedContexts, dataSource) {
  const $holder = $('#context-list-holder')
  const $skipLink = $('.skip-to-calendar')
  const $colorPickerBtn = $('.ContextList__MoreBtn')

  setupCalendarFeedsWithSpecialAccessibilityConsiderationsForNVDA()

  $holder.html(contextListTemplate({contexts}))

  const visibleContexts = new VisibleContextManager(contexts, selectedContexts, $holder)

  $holder.on('click keyclick', '.context-list-toggle-box', function(event) {
    const parent = $(this).closest('.context_list_context')
    visibleContexts.toggle($(parent).data('context'))
  })

  $holder.on('click keyclick', '.ContextList__MoreBtn', function(event) {
    const positions = {
      top: $(this).offset().top - $(window).scrollTop(),
      left: $(this).offset().left - $(window).scrollLeft()
    }

    const assetString = $(this)
      .closest('li')
      .data('context')

    // ensures previously picked color clears
    ReactDOM.unmountComponentAtNode($('#color_picker_holder')[0])

    ReactDOM.render(
      <ColorPicker
        isOpen
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
      $('#color_picker_holder')[0]
    )
  })

  $skipLink.on('click', e => {
    e.preventDefault()
    $('#content')
      .attr('tabindex', -1)
      .focus()
  })
}
