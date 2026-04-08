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
import qs from 'qs'
import {duplicateRubric} from '../ViewRubricQueries'

vi.mock('@instructure/get-cookie', () => ({
  default: () => 'test-csrf-token',
}))

const server = setupServer()

beforeAll(() => server.listen())
afterAll(() => server.close())
afterEach(() => server.resetHandlers())

const baseCriteria = [
  {
    id: 'c1',
    description: 'Criterion 1',
    longDescription: 'Long desc 1',
    points: 10,
    learningOutcomeId: undefined,
    criterionUseRange: false,
    ignoreForScoring: true,
    masteryPoints: 0,
    ratings: [
      {id: 'r1', description: 'Full', longDescription: 'Full marks', points: 10},
      {id: 'r2', description: 'None', longDescription: 'No marks', points: 0},
    ],
  },
  {
    id: 'c2',
    description: 'Criterion 2',
    longDescription: 'Long desc 2',
    points: 5,
    learningOutcomeId: undefined,
    criterionUseRange: true,
    ignoreForScoring: false,
    masteryPoints: 0,
    ratings: [{id: 'r3', description: 'Pass', longDescription: '', points: 5}],
  },
]

describe('duplicateRubric', () => {
  let capturedBody: Record<string, any> = {}

  beforeEach(() => {
    capturedBody = {}
    server.use(
      http.post('/accounts/:accountId/rubrics/', async ({request}) => {
        const text = await request.text()
        capturedBody = qs.parse(text, {allowDots: true}) as Record<string, any>
        return HttpResponse.json({rubric: {id: '99', title: 'Test Copy'}})
      }),
    )
  })

  it('includes ignore_for_scoring for each criterion', async () => {
    await duplicateRubric({
      title: 'Test',
      pointsPossible: 15,
      accountId: '1',
      criteria: baseCriteria,
    })

    const criteria = capturedBody.rubric?.criteria
    expect(criteria).toBeDefined()
    expect(criteria['0'].ignore_for_scoring).toBe('true')
    expect(criteria['1'].ignore_for_scoring).toBe('false')
  })

  it('appends " Copy" to the rubric title', async () => {
    await duplicateRubric({
      title: 'My Rubric',
      pointsPossible: 10,
      accountId: '1',
      criteria: baseCriteria,
    })

    expect(capturedBody.rubric?.title).toBe('My Rubric Copy')
  })

  it('sets is_duplicate to true', async () => {
    await duplicateRubric({
      title: 'Test',
      pointsPossible: 10,
      accountId: '1',
      criteria: baseCriteria,
    })

    expect(capturedBody.rubric?.is_duplicate).toBe('true')
  })

  it('maps criterion fields to snake_case', async () => {
    await duplicateRubric({
      title: 'Test',
      pointsPossible: 10,
      accountId: '1',
      criteria: baseCriteria,
    })

    const c0 = capturedBody.rubric?.criteria?.['0']
    expect(c0.description).toBe('Criterion 1')
    expect(c0.long_description).toBe('Long desc 1')
    expect(c0.points).toBe('10')
    expect(c0.criterion_use_range).toBe('false')
  })

  it('uses course URL when courseId is provided', async () => {
    server.use(
      http.post('/courses/:courseId/rubrics/', async ({request}) => {
        const text = await request.text()
        capturedBody = qs.parse(text, {allowDots: true}) as Record<string, any>
        return HttpResponse.json({rubric: {id: '99', title: 'Test Copy'}})
      }),
    )

    await duplicateRubric({
      title: 'Test',
      pointsPossible: 10,
      courseId: '5',
      criteria: baseCriteria,
    })

    expect(capturedBody.rubric_association?.association_type).toBe('Course')
  })

  it('throws on non-ok response', async () => {
    server.use(
      http.post(
        '/accounts/:accountId/rubrics/',
        () => new HttpResponse(null, {status: 422, statusText: 'Unprocessable Entity'}),
      ),
    )

    await expect(
      duplicateRubric({title: 'Test', pointsPossible: 10, accountId: '1'}),
    ).rejects.toThrow('Failed to duplicate rubric')
  })

  it('sets rubric_association purpose to bookmark', async () => {
    await duplicateRubric({
      title: 'Test',
      pointsPossible: 10,
      accountId: '1',
      criteria: baseCriteria,
    })

    expect(capturedBody.rubric_association?.purpose).toBe('bookmark')
  })

  it('throws when response contains an error field', async () => {
    server.use(
      http.post('/accounts/:accountId/rubrics/', () =>
        HttpResponse.json({error: 'something went wrong'}),
      ),
    )

    await expect(
      duplicateRubric({title: 'Test', pointsPossible: 10, accountId: '1'}),
    ).rejects.toThrow('Failed to duplicate rubric')
  })
})
