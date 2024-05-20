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

import $ from 'jquery'

export default function getTextWidth(text: string) {
  let $textMeasure = $('#text-measure')
  if (!$textMeasure.length) {
    $textMeasure = $('<span id="text-measure" style="padding: 10px; display: none;" />').appendTo(
      '#content'
    )
  }
  // convert to integer to maintain backwards compatibility
  return Math.floor($textMeasure?.text(text).outerWidth() ?? 0)
}
