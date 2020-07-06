/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {ltiMessageHandler} from '../messages'
import $ from 'jquery'

describe('ltiMessageHander', () => {
  /* eslint-disable no-console */
  const oldLog = console.log
  const oldError = console.error

  const logMock = jest.fn()
  const errorMock = jest.fn()

  beforeEach(() => {
    console.log = logMock
    console.error = errorMock
  })

  afterEach(() => {
    console.log = oldLog
    console.error = oldError
    jest.restoreAllMocks()
  })
  /* eslint-enable no-console */

  it('does not log unparseable messages from window.postMessage', () => {
    ltiMessageHandler({data: 'abcdef'})
    expect(logMock).not.toHaveBeenCalled()
    expect(errorMock).not.toHaveBeenCalled()
  })

  it('does not log ignored messages from window.postMessage', () => {
    ltiMessageHandler({data: JSON.stringify({a: 'b', c: 'd'})})
    ltiMessageHandler({data: {abc: 'def'}})
    expect(logMock).not.toHaveBeenCalled()
    expect(errorMock).not.toHaveBeenCalled()
  })

  it('handles parseable messages from window.postMessage', () => {
    const flashMessage = jest.spyOn($, 'screenReaderFlashMessageExclusive')
    ltiMessageHandler({data: JSON.stringify({subject: 'lti.screenReaderAlert', body: 'Hi'})})
    expect(flashMessage).toHaveBeenCalledWith('Hi')
  })
})
