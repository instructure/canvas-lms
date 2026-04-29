/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
//
// Copyright (C) 2013 - present Instructure, Inc.
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
//

import {reduce, each} from 'es-toolkit/compat'
import Backbone from '@canvas/backbone'
import template from '../../jst/Syllabus.handlebars'
import {fudgeDateForProfileTimezone} from '@instructure/moment-utils'
import {render} from '@canvas/react'
import {Tooltip} from '@instructure/ui-tooltip'
import {datetimeString} from '@canvas/datetime/date-functions'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import type {SyllabusEventApi} from '../types'

const I18n = createI18nScope('syllabus')

interface TooltipRoot {
  unmount: () => void
}

interface SyllabusViewOverride {
  title?: string
}

export interface SyllabusViewEvent {
  date?: Date | null
  due_at?: Date
  end_at?: Date
  eventCount?: number
  html_url?: string
  json: SyllabusEventApi
  last: boolean
  orig_date: number | null
  override: SyllabusViewOverride | null
  passed?: boolean
  related_id: string
  same_day: boolean
  same_time: boolean
  start_at?: Date
  subtype?: string
  title: string
  todo_at?: Date
  type?: string
  workflow_state?: string
}

export interface SyllabusViewDate {
  date: Date | null
  events: SyllabusViewEvent[]
  orig_date: number | null
  passed: boolean
}

export interface SyllabusViewJson {
  dates: SyllabusViewDate[]
  overrides_present: boolean
}

interface SyllabusViewInit {
  can_read: boolean
  is_valid_user: boolean
}

function assignmentSubType(json: SyllabusEventApi) {
  const submissionTypes = json.submission_types ?? ''
  if (/discussion/.test(submissionTypes)) return 'discussion_topic'
  if (/quiz/.test(submissionTypes)) return 'quiz'
  return undefined
}

// Declaration merging: expose render() inherited from Backbone.View (untyped JS base)
// eslint-disable-next-line @typescript-eslint/no-unsafe-declaration-merging
interface SyllabusView {
  render(): this
}

// eslint-disable-next-line @typescript-eslint/no-unsafe-declaration-merging
class SyllabusView extends Backbone.View {
  declare can_participate?: boolean
  declare can_read: boolean
  declare is_public_course?: boolean
  declare is_valid_user: boolean
  declare template: (json: SyllabusViewJson) => string
  declare tooltipRoots: TooltipRoot[]
  declare $: (element: Element | string) => JQuery<HTMLElement>
  declare $el: JQuery<HTMLElement>

  constructor(options?: Record<string, unknown>) {
    super(options)
  }

  static initClass() {
    this.prototype.template = template
  }

  initialize({can_read, is_valid_user}: SyllabusViewInit) {
    this.can_read = can_read
    this.is_valid_user = is_valid_user
    this.tooltipRoots = []
    return super.initialize(...arguments)
  }

  // Normalizes the JSON for all of the aggregated event types
  // into something simpler for the template to consume
  //
  // Example output:
  // {
  //    // Array of the date objects
  //    "dates": [ ... ]
  // }
  //
  // Example date object:
  // {
  //   // Date object for the date at midnight (null for undated events)
  //   "date": new Date(),
  //
  //   // Indicates whether the date is in the past
  //   "passed": true,
  //
  //   // Array of event objects that start on this day
  //   "events": [ ... ]
  // }
  //
  // Example event object:
  // {
  //    // Identifier to associate related events
  //    "related_id": "assignment_1",
  //
  //    // Assignment or other type of event
  //    "type": "assignment|sub_assignment|event",
  //
  //    // Title of the event
  //    "title": "Event title",
  //
  //    // URL for the user to access details on the assignment/sub_assignment/event
  //    "html_url": "http://...",
  //
  //    // Date the event begins (this is the due_at date for assignments and sub_assignments)
  //    "start_at": "2012-01-01T23:59:00-07:00",
  //
  //    // Date the event ends (this is the due_at date for assignments and sub_assignments)
  //    "end_at": "2012-01-01T23:59:00-07:00",
  //
  //    // Date the event is due (null for non-assignment events)
  //    "due_at": "2012-01-01T23:59:00-07:00",
  //
  //    // Indicates that the start and end times are on the same day
  //    "same_day": true,
  //
  //    // Indicates that the start and end times are the same time
  //    "same_time": true,
  //
  //    // Indicates that this event is the last on the same day
  //    "last": false,
  //
  //    // Override information associated with this event (null for non-overwritten)
  //    "override": {
  //        // Title for the override
  //        "title": "Overridden for James"
  //    }
  //
  //    // The original JSON from the model
  //    "json": { ... }
  // }
  toJSON(): SyllabusViewJson {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const html_url_for_assignment = this.can_read
    const html_url_for_event = this.can_read && this.is_valid_user // since the calendar page doesn't support anonymous access yet

    const relatedEvents: Record<string, SyllabusViewEvent[]> = {}
    let lastDate: SyllabusViewDate | null = null
    let lastEvent: SyllabusViewEvent | null = null
    const dateCollator = (memo: SyllabusViewDate[], json: SyllabusEventApi) => {
      let due_at: Date | undefined
      let end_at: Date | undefined
      let html_url: string | undefined
      let start_at: Date | undefined
      let todo_at: Date | undefined

      const related_id = String(json.related_id ?? json.id)
      if (json.type === 'assignment' || json.type === 'sub_assignment') {
        if (html_url_for_assignment) {
          html_url = json.html_url
        }
      } else if (html_url_for_event) {
        html_url = json.html_url
      }

      const title = json.title ?? ''

      if (json.start_at) {
        start_at = fudgeDateForProfileTimezone(json.start_at) ?? undefined
      }
      if (json.end_at) {
        end_at = fudgeDateForProfileTimezone(json.end_at) ?? undefined
      }
      if (json.type === 'assignment' || json.type === 'sub_assignment') {
        due_at = start_at
      } else if ((json.type === 'wiki_page' || json.type === 'discussion_topic') && json.todo_at) {
        todo_at = fudgeDateForProfileTimezone(json.todo_at) ?? undefined
      }

      let override: SyllabusViewOverride | null = null
      let overrides = json.assignment_overrides
      if (json.type === 'sub_assignment') {
        overrides = json.sub_assignment_overrides
      }

      each(overrides ?? [], ov => {
        if (override == null) {
          override = {}
        }
        override.title = ov.title
      })

      let start_date: Date | null = null
      let orig_start_date: number | null = null
      if (start_at && json.start_at) {
        start_date = new Date(start_at.getFullYear(), start_at.getMonth(), start_at.getDate())
        orig_start_date = Date.parse(json.start_at)
      }

      let end_date: Date | null = null
      if (end_at) {
        end_date = new Date(end_at.getFullYear(), end_at.getMonth(), end_at.getDate())
      }

      if (
        !lastDate ||
        (lastDate.date != null ? lastDate.date.getTime() : undefined) !==
          (start_date != null ? start_date.getTime() : undefined)
      ) {
        lastDate = {
          date: start_date,
          orig_date: orig_start_date,
          passed: Boolean(start_date && start_date < today),
          events: [],
        }

        memo.push(lastDate)
        lastEvent = null
      } else if (lastEvent) {
        lastEvent.last = false
      }

      lastEvent = {
        related_id,
        type: json.type,
        subtype: assignmentSubType(json),
        title,
        html_url,
        start_at,
        end_at,
        due_at,
        orig_date: orig_start_date,
        todo_at,
        same_day:
          (start_date != null ? start_date.getTime() : undefined) ===
          (end_date != null ? end_date.getTime() : undefined),
        same_time:
          (start_at != null ? start_at.getTime() : undefined) ===
          (end_at != null ? end_at.getTime() : undefined),
        last: true,
        override,
        json,
        workflow_state: json.workflow_state,
      }

      lastDate.events.push(lastEvent)

      lastDate.events.forEach(event => {
        event.eventCount = lastDate?.events.length
        event.date = lastDate?.date
        event.passed = lastDate?.passed
      })

      if (!(related_id in relatedEvents)) {
        relatedEvents[related_id] = []
      }
      relatedEvents[related_id].push(lastEvent)

      return memo
    }

    // Get the dates and events
    const dates = reduce(
      super.toJSON(...arguments) as SyllabusEventApi[],
      dateCollator,
      [] as SyllabusViewDate[],
    )

    // Remove extraneous override information for single events
    let overrides_present = false
    for (const id in relatedEvents) {
      const events = relatedEvents[id]
      if (events.length === 1) {
        events[0].override = null
      } else {
        for (const event of events) {
          overrides_present = overrides_present || event.override !== null
        }
      }
    }

    // Return the dates and events in a handlebars friendly way
    return {
      dates,
      overrides_present,
    }
  }

  afterRender() {
    this.mountTimezoneTooltips()
  }

  mountTimezoneTooltips() {
    this.$el.find('.tooltip-time-mount').each((_, mountPoint) => {
      const $mountPoint = this.$(mountPoint)
      const datetime = $mountPoint.data('datetime') as string | undefined
      const timeText = ($mountPoint.data('time-text') as string | undefined) ?? ''
      const label = $mountPoint.data('label') as string | undefined
      if (!datetime) return

      const tooltipContent = this.generateTooltipContent(datetime)
      const displayText = label ? `${label} ${timeText}` : timeText

      const root = render(
        <Tooltip renderTip={tooltipContent}>
          <button type="button" style={{all: 'unset', cursor: 'pointer'}}>
            {displayText}
          </button>
        </Tooltip>,
        mountPoint,
      )
      this.tooltipRoots.push(root as TooltipRoot)
    })
  }

  generateTooltipContent(datetime: string) {
    const localDatetime = datetimeString(datetime)

    if (ENV.CONTEXT_TIMEZONE && ENV.TIMEZONE !== ENV.CONTEXT_TIMEZONE) {
      const courseDatetime = datetimeString(datetime, {timezone: ENV.CONTEXT_TIMEZONE})
      if (localDatetime !== courseDatetime) {
        return (
          <>
            {I18n.t('Local')}: {localDatetime}
            <br />
            {I18n.t('Course')}: {courseDatetime}
          </>
        )
      }
    }
    return localDatetime
  }

  remove() {
    this.tooltipRoots.forEach(root => root.unmount())
    this.tooltipRoots = []
    return super.remove(...arguments)
  }
}
SyllabusView.initClass()
export default SyllabusView
