/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {fetchAccessibilityIssueSummary} from '../accessibility_issue_summary'

const server = setupServer()
const accountId = '123'
const endpoint = `/api/v1/accounts/${accountId}/accessibility_issue_summary`

describe('fetchAccessibilityIssueSummary', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('returns active and resolved counts from the response', async () => {
    server.use(http.get(endpoint, () => HttpResponse.json({active: 12, resolved: 5})))

    const result = await fetchAccessibilityIssueSummary({accountId})

    expect(result.active).toBe(12)
    expect(result.resolved).toBe(5)
  })

  it('returns zeros as fallback when response body is empty', async () => {
    server.use(http.get(endpoint, () => HttpResponse.json(null)))

    const result = await fetchAccessibilityIssueSummary({accountId})

    expect(result.active).toBe(0)
    expect(result.resolved).toBe(0)
  })

  it('omits enrollment_term_id param when not provided', async () => {
    let params: URLSearchParams | undefined

    server.use(
      http.get(endpoint, ({request}) => {
        params = new URL(request.url).searchParams
        return HttpResponse.json({active: 0, resolved: 0})
      }),
    )

    await fetchAccessibilityIssueSummary({accountId})

    expect(params?.has('enrollment_term_id')).toBe(false)
  })

  it('sends enrollment_term_id param when provided', async () => {
    let params: URLSearchParams | undefined

    server.use(
      http.get(endpoint, ({request}) => {
        params = new URL(request.url).searchParams
        return HttpResponse.json({active: 4, resolved: 2})
      }),
    )

    await fetchAccessibilityIssueSummary({accountId, enrollmentTermId: '42'})

    expect(params?.get('enrollment_term_id')).toBe('42')
  })

  it('omits enrollment_term_id param when empty string is provided', async () => {
    let params: URLSearchParams | undefined

    server.use(
      http.get(endpoint, ({request}) => {
        params = new URL(request.url).searchParams
        return HttpResponse.json({active: 0, resolved: 0})
      }),
    )

    await fetchAccessibilityIssueSummary({accountId, enrollmentTermId: ''})

    expect(params?.has('enrollment_term_id')).toBe(false)
  })

  it('re-throws errors from the API', async () => {
    server.use(
      http.get(endpoint, () =>
        HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500}),
      ),
    )

    await expect(fetchAccessibilityIssueSummary({accountId})).rejects.toThrow()
  })
})
