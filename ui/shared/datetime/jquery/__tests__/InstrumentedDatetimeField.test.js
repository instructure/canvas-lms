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

import InstrumentedDatetimeField from '../InstrumentedDatetimeField'
import {configure} from '@canvas/datetime-natural-parsing-instrument'
import $ from 'jquery'

describe('@canvas/datetime/InstrumentedDatetimeField', () => {
  let previousState
  let events

  beforeEach(() => {
    events = []
    previousState = configure({events})
  })

  afterEach(() => {
    configure(previousState)
  })

  describe('typing', () => {
    it('tracks it on blur', () => {
      const node = document.createElement('input')
      new InstrumentedDatetimeField($(node))
      const inputEvent = new Event('input')

      inputEvent.inputType = 'insertText'

      node.value = '2021-08-24 18:00:00'
      node.dispatchEvent(inputEvent)

      expect(events.length).toEqual(0)

      node.dispatchEvent(new Event('blur'))

      expect(events.length).toEqual(1)
      expect(events[0]).toMatchObject({
        method: 'type',
        value: '2021-08-24 18:00:00',
      })
    })
  })

  describe('picking', () => {
    it('works', () => {
      const node = document.createElement('input')
      const datetimeField = new InstrumentedDatetimeField($(node))
      const field = datetimeField.$field
      const picker = field.data('datepicker')

      picker.selectedYear = 2021
      picker.selectedMonth = 7 // August
      picker.selectedDay = '24'
      field.data('timeHour', '18')
      field.data('timeMinute', '30')

      datetimeField.$field.data('datepicker').settings.onSelect(node.value, picker)
      datetimeField.$field.data('datepicker').settings.onClose(node.value)

      expect(events.length).toEqual(1)
      expect(events[0]).toMatchObject({
        method: 'pick',
        value: 'Aug 24, 2021, 6:30 PM',
      })
    })
  })

  describe('pasting', () => {
    it('works', () => {
      const node = document.createElement('input')
      new InstrumentedDatetimeField($(node))

      node.value = '2021-08-24 18:00:00'
      node.dispatchEvent(new Event('paste'))
      node.dispatchEvent(new Event('change'))

      expect(events.length).toEqual(1)
      expect(events[0]).toMatchObject({
        method: 'paste',
        value: '2021-08-24 18:00:00',
      })
    })
  })
})
