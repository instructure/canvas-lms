/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import NaiveRequestDispatch from '@canvas/network/NaiveRequestDispatch/index'
import api from '../enrollmentTermsApi'
import fakeENV from '@canvas/test-utils/fakeENV'

interface DeserializedTerm {
  id: string
  name: string | null
  startAt: Date | null
  endAt: Date | null
  createdAt: Date | null
  gradingPeriodGroupId: string | null
}

interface SerializedTerm {
  id: number
  name: string | null
  start_at: string | null
  end_at: string | null
  created_at: string | null
  grading_period_group_id: number | null
}

interface SerializedTermGroup {
  enrollment_terms: SerializedTerm[]
}

const deserializedTerms: DeserializedTerm[] = [
  {
    id: '1',
    name: 'Fall 2013 - Art',
    startAt: new Date('2013-06-03T02:57:42Z'),
    endAt: new Date('2013-12-03T02:57:53Z'),
    createdAt: new Date('2015-10-27T16:51:41Z'),
    gradingPeriodGroupId: '2',
  },
  {
    id: '3',
    name: null,
    startAt: new Date('2014-01-03T02:58:36Z'),
    endAt: new Date('2014-03-03T02:58:42Z'),
    createdAt: new Date('2013-06-02T17:29:19Z'),
    gradingPeriodGroupId: '2',
  },
  {
    id: '4',
    name: null,
    startAt: null,
    endAt: null,
    createdAt: new Date('2014-05-02T17:29:19Z'),
    gradingPeriodGroupId: '1',
  },
]

const serializedTerms: SerializedTermGroup = {
  enrollment_terms: [
    {
      id: 1,
      name: 'Fall 2013 - Art',
      start_at: '2013-06-03T02:57:42Z',
      end_at: '2013-12-03T02:57:53Z',
      created_at: '2015-10-27T16:51:41Z',
      grading_period_group_id: 2,
    },
    {
      id: 3,
      name: null,
      start_at: '2014-01-03T02:58:36Z',
      end_at: '2014-03-03T02:58:42Z',
      created_at: '2013-06-02T17:29:19Z',
      grading_period_group_id: 2,
    },
    {
      id: 4,
      name: null,
      start_at: null,
      end_at: null,
      created_at: '2014-05-02T17:29:19Z',
      grading_period_group_id: 1,
    },
  ],
}

vi.mock('@canvas/network/NaiveRequestDispatch/index', () => ({
  default: vi.fn(),
}))

describe('enrollmentTermsApi', () => {
  let mockDeferred: JQuery.Deferred<SerializedTermGroup[]>

  beforeEach(() => {
    fakeENV.setup({
      ENROLLMENT_TERMS_URL: 'api/enrollment_terms',
    })
    mockDeferred = $.Deferred<SerializedTermGroup[]>()
    const mockDispatch = {
      getDepaginated: vi.fn().mockReturnValue(mockDeferred),
    }
    ;(NaiveRequestDispatch as any).mockImplementation(
      () => mockDispatch as unknown as NaiveRequestDispatch,
    )
  })

  afterEach(() => {
    fakeENV.teardown()
    vi.resetAllMocks()
  })

  describe('list', () => {
    it('calls the endpoint with correct URL', () => {
      const dispatch = new NaiveRequestDispatch()
      api.list()
      expect(dispatch.getDepaginated).toHaveBeenCalledWith('api/enrollment_terms')
    })

    it('deserializes returned enrollment terms', async () => {
      mockDeferred.resolve([serializedTerms])
      const terms = await api.list()
      expect(terms).toEqual(deserializedTerms)
    })

    it('rejects the promise upon errors', async () => {
      const error = new Error('FAIL')
      mockDeferred.reject(error)
      await expect(api.list()).rejects.toThrow('FAIL')
    })
  })
})
