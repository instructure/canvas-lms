/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

// A utility for creating and parsing RRULEs
// 1. Given the parameters of a recurring event and an RRuleHelperSpec,
//    create an RRuleHelper object which can then be used to generate
//    an RRULE string.
// 2. Parse an RRULE string into an RRuleHelperSpec.

import moment from 'moment-timezone'
import {FrequencyValue, MonthlyModeValue, SelectedDaysArray, UnknownSubset} from './types'

export const DEFAULT_COUNT = 5
export const MAX_COUNT = 400 // keep in sync with RECURRING_EVENT_LIMIT in app/helpers/rrule_helper.rb

export type RRuleHelperSpec = {
  freq: FrequencyValue
  interval: number
  weekdays?: SelectedDaysArray
  month?: number
  monthdate?: number
  pos?: number
  until?: string
  count?: number
}

// Given an iCalendar formatted date-time string, return
// an ISO 8601 formatted string.
export const icalDateToISODate = (icalDate: string): string => {
  return moment(icalDate).utc().format()
}

// Given an ISO 8601 formatted date-time string, return
// an iCalendar formatted string.
export const ISODateToIcalDate = (isoDate: string): string => {
  return moment(isoDate).utc().format('YYYYMMDDTHHmmss[Z]')
}

const makeEmptySpec = (more: UnknownSubset<RRuleHelperSpec> = {}): RRuleHelperSpec => ({
  freq: 'DAILY',
  interval: 1,
  ...more,
})

export default class RRuleHelper {
  // the parameters describing the recurrence
  spec: RRuleHelperSpec

  // Create an RRuleHelper object from an RRuleHelperSpec
  constructor(spec: RRuleHelperSpec) {
    this.spec = spec
  }

  // Parse an RRULE string into an RRuleHelperSpec
  static parseString(rrule_str: string = ''): RRuleHelperSpec {
    if (rrule_str.length === 0) {
      // guarantee what return is valid
      return makeEmptySpec({count: DEFAULT_COUNT})
    }

    const keys = [
      'FREQ',
      'INTERVAL',
      'BYDAY',
      'BYMONTH',
      'BYMONTHDAY',
      'BYSETPOS',
      'UNTIL',
      'UNTIL;TZID',
      'COUNT',
    ]
    const restr = keys.map(k => `(${k}=[^;]+)`).join('|')
    const re = new RegExp(restr, 'g')
    const matches = [...rrule_str.matchAll(re)]
    const spec: RRuleHelperSpec = makeEmptySpec()
    for (const value of matches) {
      const [key, val] = value[0].split('=')
      switch (key) {
        case 'FREQ':
          spec.freq = val as FrequencyValue
          break
        case 'INTERVAL':
          spec.interval = parseInt(val, 10)
          break
        case 'BYDAY':
          spec.weekdays = val.split(',') as SelectedDaysArray
          break
        case 'BYMONTH':
          spec.month = parseInt(val, 10)
          break
        case 'BYMONTHDAY':
          spec.monthdate = parseInt(val, 10)
          break
        case 'BYSETPOS':
          spec.pos = parseInt(val, 10)
          break
        case 'UNTIL':
          spec.until = icalDateToISODate(val)
          break
        case 'COUNT':
          spec.count = parseInt(val, 10)
          break
        default:
          throw new Error(`Unknown key: ${key}`)
      }
    }
    return spec
  }

  // Generate an RRULE string from an RRuleHelper
  toString(): string {
    if (!this.isValid()) throw new Error('Invalid RRULE spec')
    switch (this.spec.freq) {
      case 'DAILY':
        return this.daily()
      case 'WEEKLY':
        return this.weekly()
      case 'MONTHLY':
        return this.monthly()
      case 'YEARLY':
        return this.yearly()
      default:
        throw new Error(`Unknown frequency: ${this.spec.freq}`)
    }
  }

  hasValidEnd(): boolean {
    return (
      (typeof this.spec.count === 'number' && this.spec.count > 0) ||
      (typeof this.spec.until === 'string' && moment(this.spec.until).isValid())
    )
  }

  hasValidInterval(): boolean {
    return typeof this.spec.interval === 'number' && this.spec.interval > 0
  }

  hasValidWeekdays(): boolean {
    return Array.isArray(this.spec.weekdays) && this.spec.weekdays.length > 0
  }

  hasValidPos(): boolean {
    return typeof this.spec.pos === 'number' && this.spec.pos > 0
  }

  isValid(): boolean {
    if (!this.hasValidEnd()) return false
    if (!this.hasValidInterval()) return false

    switch (this.spec.freq) {
      case 'DAILY':
        return typeof this.spec.interval === 'number' && this.spec.interval > 0
      case 'WEEKLY':
        return this.hasValidWeekdays()
      case 'MONTHLY':
        return this.spec.monthdate !== undefined || this.spec.pos !== undefined
      case 'YEARLY':
        return (
          (this.spec.monthdate !== undefined && this.spec.month !== undefined) ||
          (this.spec.month !== undefined && this.hasValidWeekdays() && this.hasValidPos())
        )
      default:
        return false
    }
  }

  monthlyMode(): MonthlyModeValue | undefined {
    if (this.spec.freq !== 'MONTHLY') {
      return undefined
    }
    if (this.spec.monthdate !== undefined) {
      return 'BYMONTHDATE'
    } else if (
      Array.isArray(this.spec.weekdays) &&
      this.spec.weekdays.length > 0 &&
      typeof this.spec.pos === 'number'
    ) {
      return 'BYMONTHDAY'
    } else {
      return undefined
    }
  }

  untilOrCount(until: string | undefined, count: number | undefined): string {
    if (until !== undefined) {
      return `;UNTIL=${ISODateToIcalDate(until)}`
    } else if (count !== undefined) {
      return `;COUNT=${count}`
    } else {
      return ''
    }
  }

  daily() {
    const {interval, until, count} = this.spec
    const endoptions = this.untilOrCount(until, count)
    return `FREQ=DAILY;INTERVAL=${interval}${endoptions}`
  }

  weekly() {
    const {interval, weekdays, until, count} = this.spec
    if (weekdays === undefined) {
      throw new Error("Weekly recurrence doesn't have weekdays")
    }
    const endoptions = this.untilOrCount(until, count)
    return `FREQ=WEEKLY;INTERVAL=${interval};BYDAY=${weekdays.join(',')}${endoptions}`
  }

  monthly() {
    const {interval, monthdate, weekdays, pos, until, count} = this.spec
    const endoptions = this.untilOrCount(until, count)
    if (pos === undefined) {
      return `FREQ=MONTHLY;INTERVAL=${interval};BYMONTHDAY=${monthdate}${endoptions}`
    } else if (monthdate === undefined && Array.isArray(weekdays)) {
      return `FREQ=MONTHLY;INTERVAL=${interval};BYDAY=${weekdays.join(
        ','
      )};BYSETPOS=${pos}${endoptions}`
    } else {
      throw new Error('Invalid monthly recurrence')
    }
  }

  yearly() {
    const {interval, month, monthdate, weekdays, pos, until, count} = this.spec
    const endoptions = this.untilOrCount(until, count)
    if (pos === undefined) {
      return `FREQ=YEARLY;INTERVAL=${interval};BYMONTH=${month};BYMONTHDAY=${monthdate}${endoptions}`
    } else if (monthdate === undefined) {
      return `FREQ=YEARLY;INTERVAL=${interval};BYDAY=${weekdays};BYMONTH=${month};BYSETPOS=${pos}${endoptions}`
    } else {
      throw new Error('Invalid yearly recurrence')
    }
  }
}
