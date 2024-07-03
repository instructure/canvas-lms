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

import {useScope as useI18nScope} from '@canvas/i18n'
import datePickerFormat from '@instructure/moment-utils/datePickerFormat'

const I18n = useI18nScope('calendar')

describe('Date Picker Format Spec', () => {
  test('formats medium with weekday correctly', () => {
    const format = datePickerFormat(I18n.t('#date.formats.medium_with_weekday'))
    expect(format).toBe("D M d',' yy")
  })

  test('formats medium correctly', () => {
    const format = datePickerFormat(I18n.t('#date.formats.medium'))
    expect(format).toBe("M d',' yy")
  })

  test('escapes literal strings with single quotes', () => {
    const format1 = datePickerFormat('%d de %b de %Y')
    expect(format1).toBe("d 'de' M 'de' yy")
    const format2 = datePickerFormat('%-d de %b de %Y')
    expect(format2).toBe("d 'de' M 'de' yy")
    const format3 = datePickerFormat('%d de %b de')
    expect(format3).toBe("d 'de' M 'de'")
  })
})
