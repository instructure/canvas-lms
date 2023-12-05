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

import moment from 'moment-timezone'
import RruleHelper, {
  type RRuleHelperSpec,
  RruleValidationError,
  icalDateToISODate,
} from './RRuleHelper'
import type {RRULEDayValue, SelectedDaysArray} from './types'
import {useScope} from '@canvas/i18n'

const I18n = useScope('calendar_custom_recurring_event_natural_language')

const ORDINALS: readonly string[] = Object.freeze([
  '',
  I18n.t('first'),
  I18n.t('second'),
  I18n.t('third'),
  I18n.t('fourth'),
  I18n.t('fifth'),
])

// I know these dates map to their respective days of the week
const match_day_of_week = (rrule_day: RRULEDayValue, timezone: string): Date => {
  switch (rrule_day) {
    case 'SU':
      return moment.tz('2023-07-02', timezone).toDate()
    case 'MO':
      return moment.tz('2023-07-03', timezone).toDate()
    case 'TU':
      return moment.tz('2023-07-04', timezone).toDate()
    case 'WE':
      return moment.tz('2023-07-05', timezone).toDate()
    case 'TH':
      return moment.tz('2023-07-06', timezone).toDate()
    case 'FR':
      return moment.tz('2023-07-07', timezone).toDate()
    case 'SA':
      return moment.tz('2023-07-08', timezone).toDate()
  }
}

function ordinalize(n: number): string {
  if (n < 0) return I18n.t('last')
  return ORDINALS[n]
}

export default function RRuleToNaturalLanguage(rrule: string, locale: string, timezone: string) {
  // Mon, Tue, ...
  const weekday_formatter = new Intl.DateTimeFormat(locale, {weekday: 'short', timeZone: timezone})
    .format
  // Jan 5, 2023, Feb 5, 2023, ...
  const date_formatter = new Intl.DateTimeFormat(locale, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    timeZone: timezone,
  }).format
  // Jan, Feb, ...
  const month_formatter = new Intl.DateTimeFormat(locale, {month: 'short', timeZone: timezone})
    .format
  // Jan 5, Feb 5, ...
  const monthday_formatter = new Intl.DateTimeFormat(locale, {
    month: 'short',
    day: 'numeric',
    timeZone: timezone,
  }).format

  const spec: RRuleHelperSpec = RruleHelper.parseString(rrule)
  rrule_validate_common_opts(spec)

  switch (spec.freq) {
    case 'DAILY':
      return parse_daily(spec)
    case 'WEEKLY':
      return parse_weekly(spec)
    case 'MONTHLY':
      return parse_monthly(spec)
    case 'YEARLY':
      return parse_yearly(spec)
    default:
      throw new RruleValidationError(I18n.t("Invalid FREQ '%{freq}'", {freq: spec.freq}))
  }

  function format_date(date_str: string): string {
    const m = moment(icalDateToISODate(date_str)).tz(timezone)
    return date_formatter(m.toDate())
  }

  function format_month(rr_month: number): string {
    return month_formatter(new Date(0, rr_month - 1))
  }

  function format_weekday(weekdays: SelectedDaysArray): string {
    return weekdays
      .map((d: RRULEDayValue) => weekday_formatter(match_day_of_week(d, timezone)))
      .join(', ')
  }

  function format_month_day(month: number, monthdate: number): string {
    // 2024 is a leap year and can handle formatting 2/29
    const m = moment({y: 2024, M: month - 1, d: monthdate}).tz(timezone)
    return monthday_formatter(m.toDate())
  }

  function rrule_validate_common_opts(rropts: RRuleHelperSpec): void | never {
    new RruleHelper(rropts).isValid()
  }

  function parse_daily(rropts: RRuleHelperSpec): string {
    const interval = rropts.interval
    const times = rropts.count
    const until_date = rropts.until

    if (times) {
      return I18n.t(
        {
          one: 'Daily, %{times} times',
          other: 'Every %{count} days, %{times} times',
        },
        {
          count: interval,
          times,
        }
      )
    } else if (until_date) {
      return I18n.t(
        {
          one: 'Daily until %{until}',
          other: 'Every %{count} days until %{until}',
        },
        {
          count: interval,
          until: format_date(until_date),
        }
      )
    }
    return ''
  }

  // const DAYS_IN_MONTH = [null, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  function rruledays_to_daynames(weekdays: SelectedDaysArray): string {
    return format_weekday(weekdays)
  }

  function parse_weekly(rropts: RRuleHelperSpec): string {
    if (rropts.weekdays) {
      return parse_weekly_byday(rropts)
    }

    const interval = rropts.interval
    const times = rropts.count
    const until_date = rropts.until

    if (times) {
      I18n.t(
        {
          one: 'Weekly, %{times} times',
          other: 'Every %{count} weeks, %{times} times',
        },
        {
          count: interval,
          times,
        }
      )
    } else if (until_date) {
      I18n.t(
        {
          one: 'Weekly until %{until}',
          other: 'Every %{count} weeks until %{until}',
        },
        {
          count: interval,
          until: format_date(until_date),
        }
      )
    }
    return ''
  }

  function parse_weekly_byday(rropts: RRuleHelperSpec): string {
    const interval = rropts.interval
    const times = rropts.count
    const until_date = rropts.until
    if (!Array.isArray(rropts.weekdays)) throw new Error("can't get here")

    const by_day: string = rruledays_to_daynames(rropts.weekdays)

    if (times) {
      return I18n.t(
        {
          one: 'Weekly on %{byday}, %{times} times',
          other: 'Every %{count} weeks on %{byday}, %{times} times',
        },
        {
          count: interval,
          byday: by_day,
          times,
        }
      )
    } else if (until_date) {
      return I18n.t(
        {
          one: 'Weekly on %{byday} until %{until}',
          other: 'Every %{count} weeks on %{byday} until %{until}',
        },
        {
          count: interval,
          byday: by_day,
          until: format_date(until_date),
        }
      )
    }
    return ''
  }

  function parse_monthly(rropts: RRuleHelperSpec): string {
    if (rropts.weekdays) {
      return parse_monthly_byday(rropts)
    } else if (rropts.monthdate) {
      return parse_monthly_bymonthday(rropts)
    } else {
      // return parse_generic_monthly(rropts)
      return ''
    }
  }

  function parse_monthly_byday(rropts: RRuleHelperSpec): string {
    const interval = rropts.interval
    const times = rropts.count
    const until_date = rropts.until
    const days_of_week: string = rropts.weekdays ? rruledays_to_daynames(rropts.weekdays) : ''
    const pos = rropts.pos

    if (times) {
      if (pos !== undefined) {
        return I18n.t(
          {
            one: 'Monthly on the %{ord} %{days}, %{times} times',
            other: 'Every %{count} months on the %{ord} %{days}, %{times} times',
          },
          {
            count: interval,
            ord: ordinalize(pos),
            days: days_of_week,
            times,
          }
        )
      }
    } else if (until_date) {
      if (pos !== undefined) {
        return I18n.t(
          {
            one: 'Monthly on the %{ord} %{days} until %{until}',
            other: 'Every %{count} months on the %{ord} %{days} until %{until}',
          },
          {
            count: interval,
            ord: ordinalize(pos),
            days: days_of_week,
            until: format_date(until_date),
          }
        )
      }
    }
    return ''
  }

  function parse_monthly_bymonthday(rropts: RRuleHelperSpec): string {
    const interval = rropts.interval
    const times = rropts.count
    const until_date = rropts.until
    const days_of_month = rropts.monthdate

    if (times) {
      return I18n.t(
        {
          one: 'Monthly on day %{days}, %{times} times',
          other: 'Every %{count} months on day %{days}, %{times} times',
        },
        {
          count: interval,
          days: days_of_month,
          times,
        }
      )
    } else if (until_date) {
      return I18n.t(
        {
          one: 'Monthly on day %{days} until %{until}',
          other: 'Every %{count} months on day %{days} until %{until}',
        },
        {
          count: interval,
          days: days_of_month,
          until: format_date(until_date),
        }
      )
    } else {
      return ''
    }
  }

  function parse_yearly(rropts: RRuleHelperSpec): string {
    if (rropts.weekdays) {
      return parse_yearly_byday(rropts)
    } else if (rropts.monthdate) {
      return parse_yearly_bymonthday(rropts)
    }
    throw new RruleValidationError(I18n.t('A yearly RRULE must include BYDAY or BYMONTHDAY'))
  }

  function parse_yearly_byday(rropts: RRuleHelperSpec): string {
    if (rropts.weekdays === undefined || rropts.month === undefined || rropts.pos === undefined) {
      throw new RruleValidationError(I18n.t('Should not have gotten here'))
    }
    const times = rropts.count
    const interval = rropts.interval
    const until_date = rropts.until
    const month = format_month(rropts.month)
    const days_of_week = rropts.weekdays ? rruledays_to_daynames(rropts.weekdays) : ''
    const pos = rropts.pos

    if (times) {
      if (pos !== undefined) {
        return I18n.t(
          {
            one: 'Annually on the %{ord} %{days} of %{month}, %{times} times',
            other: 'Every %{count} years on the %{ord} %{days} of %{month}, %{times} times',
          },
          {
            count: interval,
            ord: ordinalize(pos),
            days: days_of_week,
            month,
            times,
          }
        )
      }
    } else if (until_date) {
      return I18n.t(
        {
          one: 'Annually on the %{ord} %{days} of %{month} until %{until}',
          other: 'Every %{count} years on the %{ord} %{days} of %{month} until %{until}',
        },
        {
          count: interval,
          ord: ordinalize(pos),
          days: days_of_week,
          month,
          until: format_date(until_date),
        }
      )
    }
    return ''
  }

  function parse_yearly_bymonthday(rropts: RRuleHelperSpec): string {
    if (rropts.monthdate === undefined || rropts.month === undefined) {
      throw new RruleValidationError(I18n.t('Never should have made it here'))
    }
    const times = rropts.count
    const interval = rropts.interval
    const until_date = rropts.until
    const month = rropts.month
    const day = rropts.monthdate
    const date = format_month_day(month, day)

    if (times) {
      return I18n.t(
        {
          one: 'Annually on %{date}, %{times} times',
          other: 'Every %{count} years on %{date}, %{times} times',
        },
        {
          count: interval,
          date,
          times,
        }
      )
    } else if (until_date) {
      return I18n.t(
        {
          one: 'Annually on %{date} until %{until}',
          other: 'Every %{count} years on %{date} until %{until}',
        },
        {
          count: interval,
          date,
          until: format_date(until_date),
        }
      )
    } else {
      return ''
    }
  }
}
