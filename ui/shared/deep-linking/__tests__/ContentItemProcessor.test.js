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

import $ from 'jquery'
import ContentItemProcessor from '../ContentItemProcessor'

const oldEnv = window.ENV
const env = {
  DEEP_LINKING_LOGGING: 'true'
}

beforeEach(() => {
  window.ENV = env
})

afterEach(() => {
  window.ENV = oldEnv
})

describe('message claims', () => {
  const oldFlashError = $.flashError
  const oldFlashMessage = $.flashMessage

  const flashErrorMock = jest.fn()
  const flashMessageMock = jest.fn()

  const messages = {
    msg: 'Message',
    errormsg: 'Error message'
  }

  beforeEach(() => {
    $.flashError = flashErrorMock
    $.flashMessage = flashMessageMock
    new ContentItemProcessor([], messages, {})
  })

  afterEach(() => {
    $.flashError = oldFlashError
    $.flashMessage = oldFlashMessage
  })

  it('shows the message', () => {
    expect(flashMessageMock).toHaveBeenCalledWith(messages.msg)
  })

  it('shows the error message', () => {
    expect(flashErrorMock).toHaveBeenCalledWith(messages.errormsg)
  })
})

describe('log claims', () => {
  const oldLog = console.log
  const oldError = console.error

  const logMock = jest.fn()
  const errorMock = jest.fn()

  const logs = {
    log: 'Log',
    errorlog: 'Error log'
  }

  beforeEach(() => {
    console.log = logMock
    console.error = errorMock
    new ContentItemProcessor([], {}, logs)
  })

  afterEach(() => {
    console.log = oldLog
    console.error = oldError
  })

  it('shows the log', () => {
    expect(logMock).toHaveBeenCalledWith(logs.log)
  })

  it('shows the error log', () => {
    expect(errorMock).toHaveBeenCalledWith(logs.errorlog)
  })
})
