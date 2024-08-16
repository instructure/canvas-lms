/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import GridEvent from '../GridEvent'

describe('GradebookGrid GridEvent', () => {
  let spyValues
  let supportEvent

  beforeEach(() => {
    supportEvent = new GridEvent()
    spyValues = []
  })

  describe('#trigger()', () => {
    it('executes all subscribed handlers in order of subscription', () => {
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(1)
      })
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(2)
      })
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(3)
      })
      supportEvent.trigger()
      expect(spyValues).toEqual([1, 2, 3])
    })

    it('includes the given event with each trigger', () => {
      const exampleEvent = new Event('example')
      supportEvent.subscribe((event, _datum) => {
        spyValues.push(event)
      })
      supportEvent.subscribe((event, _datum) => {
        spyValues.push(event)
      })
      supportEvent.subscribe((event, _datum) => {
        spyValues.push(event)
      })
      supportEvent.trigger(exampleEvent)
      expect(spyValues).toEqual([exampleEvent, exampleEvent, exampleEvent])
    })

    it('includes optional data with each trigger', () => {
      supportEvent.subscribe((_event, datum) => {
        spyValues.push(datum)
      })
      supportEvent.subscribe((_event, datum) => {
        spyValues.push(datum)
      })
      supportEvent.subscribe((_event, datum) => {
        spyValues.push(datum)
      })
      supportEvent.trigger(null, 'example datum')
      expect(spyValues).toEqual(['example datum', 'example datum', 'example datum'])
    })

    it('does not call subsequent handlers after any one returns false', () => {
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(1)
      })
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(2)
        return false
      })
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(3)
      })
      supportEvent.trigger()
      expect(spyValues).toEqual([1, 2])
    })

    it('does not call unsubscribed handlers', () => {
      const handler = (_event, _datum) => {
        spyValues.push(2)
      }
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(1)
      })
      supportEvent.subscribe(handler)
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(3)
      })
      supportEvent.unsubscribe(handler)
      supportEvent.trigger()
      expect(spyValues).toEqual([1, 3])
    })

    it('does not subscribe the same handler multiple times', () => {
      const handler = (_event, _datum) => {
        spyValues.push(2)
      }
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(1)
      })
      supportEvent.subscribe(handler)
      supportEvent.subscribe((_event, _datum) => {
        spyValues.push(3)
      })
      supportEvent.subscribe(handler)
      supportEvent.trigger()
      expect(spyValues).toEqual([1, 2, 3])
    })
  })
})
