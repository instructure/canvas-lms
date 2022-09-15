/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const {floor} = Math

const padToTwoDigits = duration => {
  const padding = duration >= 0 && duration < 10 ? '0' : ''
  return padding + duration.toFixed()
}

// Format a duration given in seconds into a stopwatch-style timer, e.g:
//
//   1 second      => 00:01
//   30 seconds    => 00:30
//   84 seconds    => 01:24
//   7230 seconds  => 02:00:30
//   7530 seconds  => 02:05:30
export const secondsToStopwatchTime = inputSeconds => {
  if (inputSeconds > 3600) {
    const hours = floor(inputSeconds / 3600)
    const minutes = floor((inputSeconds - hours * 3600) / 60)
    const seconds = inputSeconds % 60
    return `${padToTwoDigits(hours)}:${padToTwoDigits(minutes)}:${padToTwoDigits(seconds)}`
  } else {
    return `${padToTwoDigits(floor(inputSeconds / 60))}:${padToTwoDigits(floor(inputSeconds % 60))}`
  }
}

export const responsiveQuerySizes = ({mobile = false, tablet = false, desktop = false} = {}) => {
  const querySizes = {}
  if (mobile) {
    querySizes.mobile = {maxWidth: '767px'}
  }
  if (tablet) {
    querySizes.tablet = {maxWidth: '1023px'}
  }
  if (desktop) {
    querySizes.desktop = {minWidth: tablet ? '1024px' : '768px'}
  }
  return querySizes
}
