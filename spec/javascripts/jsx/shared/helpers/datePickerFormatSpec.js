/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'

QUnit.module('Date Picker Format Spec')

test('formats medium with weekday correcly', () => {
  const format = datePickerFormat(I18n.t('#date.formats.medium_with_weekday'))
  equal(format, 'D M d, yy')
})

test('formats medium correctly', () => {
  const format = datePickerFormat(I18n.t('#date.formats.medium'))
  equal(format, 'M d, yy')
})
