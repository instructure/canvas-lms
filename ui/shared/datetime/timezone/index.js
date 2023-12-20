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

import {
  parse,
  format,
  adjustFormat,
  shift,
  hasMeridiem as hasMeridian, // TODO: rename instances of 'meridian' to 'meridiem'
} from 'datetime'

import {
  changeToTheSecondBeforeMidnight,
  isMidnight,
  mergeTimeAndDate,
  setToEndOfMinute,
} from '../index'

// TODO: remove this module and redirect callers to @canvas/datetime
export default {
  adjustFormat,
  changeToTheSecondBeforeMidnight,
  format,
  hasMeridian,
  isMidnight,
  mergeTimeAndDate,
  parse,
  setToEndOfMinute,
  shift,
}
