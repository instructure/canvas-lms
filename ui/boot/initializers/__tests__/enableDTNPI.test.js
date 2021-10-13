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

import { up as enableDTNPI, down as disableDTNPI } from '../enableDTNPI'
import { log } from '@canvas/datetime-natural-parsing-instrument'

describe('enableDTNPI', () => {
  let consoleLog

  beforeEach(() => {
    consoleLog = jest.spyOn(console, 'log').mockImplementation(() => {})
  })

  afterEach(async () => {
    consoleLog.mockReset()

    await disableDTNPI()
  })

  it('sets up the persistent event container', async () => {
    await enableDTNPI({ throttle: 1 })
    log({ id: 'foo' })
    await new Promise(resolve => setTimeout(resolve, 1))
    const events = JSON.parse(localStorage.getItem('dtnpi'))
    expect(events.length).toEqual(1)
    expect(events[0]).toMatchObject({ id: 'foo' })
  })

  it('truncates long values', async () => {
    await enableDTNPI({ throttle: 1 })
    log({ value: Array(65).join('*') })
    await new Promise(resolve => setTimeout(resolve, 1))
    const events = JSON.parse(localStorage.getItem('dtnpi'))
    expect(events.length).toEqual(1)
    expect(events[0].value).toEqual(Array(33).join('*'))
  })

  it('does not track too many events', async () => {
    await enableDTNPI({ throttle: 1, size: 3 })
    log({ id: '1' })
    log({ id: '2' })
    log({ id: '3' })
    log({ id: '4' })
    await new Promise(resolve => setTimeout(resolve, 1))
    const events = JSON.parse(localStorage.getItem('dtnpi'))
    expect(events.length).toEqual(3)
    expect(events.map(x => x.id)).toEqual(['2','3','4'])
  })

  it('submits tracked events to the backend', async () => {
    localStorage.setItem('dtnpi', JSON.stringify([{
      locale: 'en',
      method: 'paste',
      parsed: '2021-08-18T06:00:00.000Z',
      value: 'wed aug 18',
    }]))

    await enableDTNPI()

    const logEntry = consoleLog.mock.calls.find(x => x.join().startsWith('[dtnpi]'))

    expect(logEntry).toBeTruthy()
    expect(logEntry.join('')).toMatch('[dtnpi] submitting 1 events')
  })
})