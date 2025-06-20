/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import subject from '../reports'
import Dispatcher from '../../dispatcher'
import config from '../../config'

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
afterEach(async () => {
  server.resetHandlers()
  // __reset__() will clear all callbacks
  subject.__reset__()
  // Give a moment for any pending async operations to settle
  await sleep(10)
})
afterAll(() => server.close())

beforeEach(() => {
  config.ajax = $.ajax
  config.quizReportsUrl = 'http://localhost/reports'
  // Ensure we start with a clean state
  subject.__reset__()
})

describe('quizReports:generate', function () {
  it('should reject if the report is already generated', async () => {
    subject.populate({
      quiz_reports: [
        {
          id: '1',
          report_type: 'student_analysis',
          file: {
            url: '/attachments/1',
          },
        },
      ],
    })

    // The dispatcher returns a promise, so we can check if it rejects
    try {
      await new Promise((resolve, reject) => {
        Dispatcher.dispatch('quizReports:generate', 'student_analysis').then(resolve).catch(reject)
      })
      // If we get here, the test should fail
      expect(true).toBe(false)
    } catch (error) {
      expect(error.message).toContain('report is already generated')
    }
  })
})
