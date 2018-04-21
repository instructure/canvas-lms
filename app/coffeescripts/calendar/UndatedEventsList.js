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

import I18n from 'i18n!calendar'
import $ from 'jquery'
import undatedEventsTemplate from 'jst/calendar/undatedEvents'
import ShowEventDetailsDialog from '../calendar/ShowEventDetailsDialog'
import 'jqueryui/draggable'
import 'jquery.disableWhileLoading'
import 'vendor/jquery.ba-tinypubsub'

export default class UndatedEventsList {
  constructor(selector, dataSource, calendar) {
    let toggler
    this.dataSource = dataSource
    this.calendar = calendar
    this.div = $(selector).html(undatedEventsTemplate({unloaded: true}))
    this.hidden = true
    this.visibleContextList = []
    this.previouslyFocusedElement = null

    $.subscribe({
      'CommonEvent/eventDeleting': this.eventDeleting,
      'CommonEvent/eventDeleted': this.eventDeleted,
      'CommonEvent/eventSaving': this.eventSaving,
      'CommonEvent/eventSaved': this.eventSaved,
      'Calendar/visibleContextListChanged': this.visibleContextListChanged
    })

    this.div
      .on('click keyclick', '.undated_event_title', this.clickEvent)
      .on('click', '.undated-events-link', this.show)
    if ((toggler = this.div.prev('.element_toggler'))) {
      toggler.on('click keyclick', this.toggle)
      this.div.find('.undated-events-link').hide()
    }
  }

  load = () => {
    if (this.hidden) return

    const loadingDfd = new $.Deferred()
    this.div.disableWhileLoading(loadingDfd, {
      buttons: ['.undated-events-link'],
      opacity: 1,
      lines: 8,
      length: 2,
      width: 2,
      radius: 3
    })

    const loadingTimer = setTimeout(
      () => $.screenReaderFlashMessage(I18n.t('loading_undated_events', 'Loading undated events')),
      0
    )

    return this.dataSource.getEvents(null, null, this.visibleContextList, events => {
      clearTimeout(loadingTimer)
      loadingDfd.resolve()
      events.forEach(e => {
        e.details_url = e.fullDetailsURL()
        e.icon = e.iconType()
      })
      this.div.html(undatedEventsTemplate({events}))

      events.forEach(e => {
        this.div.find(`.${e.id}`).data('calendarEvent', e)
      })

      this.div.find('.event').draggable({
        revert: 'invalid',
        revertDuration: 0,
        helper: 'clone',
        start: () => {
          this.calendar.closeEventPopups()
          $(this).hide()
        },
        stop(e, ui) {
          // Only show the element after the drag stops if it doesn't have a start date now
          // (meaning it wasn't dropped on the calendar)
          if (!$(this).data('calendarEvent').start) $(this).show()
        }
      })

      this.div.droppable({
        hoverClass: 'droppable-hover',
        accept: '.fc-event',
        drop: (e, ui) => {
          let event
          if (!(event = this.calendar.lastEventDragged)) return
          event.start = null
          event.end = null
          return event.saveDates()
        }
      })

      if (this.previouslyFocusedElement) {
        $(this.previouslyFocusedElement).focus()
      } else {
        this.div.siblings('.element_toggler').focus()
      }
    })
  }

  show = event => {
    event.preventDefault()
    this.hidden = false
    this.load()
  }

  toggle = e => {
    // defer this until after the section toggles
    setTimeout(() => {
      this.hidden = !this.div.is(':visible')
      this.load()
    }, 0)
  }

  clickEvent = jsEvent => {
    jsEvent.preventDefault()
    const eventId = $(jsEvent.target)
      .closest('.event')
      .data('event-id')
    const event = this.dataSource.eventWithId(eventId)
    if (event) {
      return new ShowEventDetailsDialog(event, this.dataSource).show(jsEvent)
    }
  }

  visibleContextListChanged = list => {
    this.visibleContextList = list
    if (!this.hidden) this.load()
  }

  eventSaving = event => {
    this.div.find(`.event.${event.id}`).addClass('event_pending')
    this.previouslyFocusedElement = `.event.${event.id} a`
  }

  eventSaved = () => {
    this.load()
  }

  eventDeleting = event => {
    const $li = this.div.find(`.event.${event.id}`)
    $li.addClass('event_pending')
    const $prev = $li.prev()
    this.previouslyFocusedElement = $prev.length ? `.event.${$prev.data('event-id')} a` : null
  }

  eventDeleted = () => {
    this.load()
  }
}
