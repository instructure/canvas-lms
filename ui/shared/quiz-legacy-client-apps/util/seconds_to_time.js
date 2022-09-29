/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('quiz_statistics')

const pad = function (duration) {
  return ('00' + duration).slice(-2)
}

/**
 * @member Util
 *
 * Format a duration given in seconds into a stopwatch-style timer, e.g:
 *
 * - 1 second      => `00:01`
 * - 30 seconds    => `00:30`
 * - 84 seconds    => `01:24`
 * - 7230 seconds  => `02:00:30`
 * - 7530 seconds  => `02:05:30`
 *
 * @param {Number} seconds
 *        The duration in seconds.
 *
 * @return {String}
 */
const secondsToTime = function (seconds) {
  let hh, mm, ss

  if (seconds > 3600) {
    hh = Math.floor(seconds / 3600)
    mm = Math.floor((seconds - hh * 3600) / 60)
    ss = seconds % 60
    return [hh, mm, ss].map(pad).join(':')
  } else {
    return [seconds / 60, seconds % 60].map(Math.floor).map(pad).join(':')
  }
}

/**
 * Instead of rendering a timestamp as the main method does, this method will
 * render a given number of seconds into a human readable sentence. This is
 * the prefered alternative to present to screen-readers if you're using
 * the method above to format a duration.
 *
 * Examples:
 *
 *  - 1     => `1 second`
 *  - 32    => `32 seconds`
 *  - 84    => `1 minute, and 24 seconds`
 *  - 3684  => `1 hour, and 1 minute`
 *
 * Note that the seconds are discarded when the duration is longer than an
 * hour.
 *
 * @param  {Number} seconds
 *         Duration in seconds.
 *
 * @return {String}
 *         A human-readable string representation of the duration.
 */
secondsToTime.toReadableString = function (seconds) {
  let hours, minutes, strHours, strMinutes, strSeconds

  if (seconds < 60) {
    return I18n.t(
      'duration_in_seconds',
      {
        one: '1 second',
        other: '%{count} seconds',
      },
      {count: Math.floor(seconds)}
    )
  } else if (seconds < 3600) {
    minutes = Math.floor(seconds / 60)
    seconds = Math.floor(seconds % 60)

    strMinutes = I18n.t(
      'duration_in_minutes',
      {
        one: '1 minute',
        other: '%{count} minutes',
      },
      {count: minutes}
    )

    strSeconds = I18n.t(
      'duration_in_seconds',
      {
        one: '1 second',
        other: '%{count} seconds',
      },
      {
        count: seconds,
      }
    )

    return I18n.t('duration_in_minutes_and_seconds', '%{minutes} and %{seconds}', {
      minutes: strMinutes,
      seconds: strSeconds,
    })
  } else {
    hours = Math.floor(seconds / 3600)
    minutes = Math.floor((seconds - hours * 3600) / 60)

    strMinutes = I18n.t(
      'duration_in_minutes',
      {
        one: '1 minute',
        other: '%{count} minutes',
      },
      {
        count: minutes,
      }
    )

    strHours = I18n.t(
      'duration_in_hours',
      {
        one: '1 hour',
        other: '%{count} hours',
      },
      {
        count: hours,
      }
    )

    return I18n.t('duration_in_hours_and_minutes', '%{hours} and %{minutes}', {
      minutes: strMinutes,
      hours: strHours,
    })
  }
}

export default secondsToTime
