//
// Copyright (C) 2014 - present Instructure, Inc.
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

const {floor} = Math

const pad = function (duration) {
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
export default function (seconds) {
  if (seconds > 3600) {
    const hh = floor(seconds / 3600)
    const mm = floor((seconds - hh * 3600) / 60)
    const ss = seconds % 60
    return `${pad(hh)}:${pad(mm)}:${pad(ss)}`
  } else {
    return `${pad(floor(seconds / 60))}:${pad(floor(seconds % 60))}`
  }
}
