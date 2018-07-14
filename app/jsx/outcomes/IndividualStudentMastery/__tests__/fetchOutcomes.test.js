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

import fetchMock from 'fetch-mock'
import fetchOutcomes, { fetchUrl } from '../fetchOutcomes'

describe('fetchOutcomes', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  const defaultResponses = () => ({
    groupsResponse: [
      {
        id: 1,
        title: 'Group 1'
      },
      {
        id: 2,
        title: 'Group 2'
      }
    ],
    linksResponse: [
      {
        outcome_group: { id: 1 },
        outcome: {
          id: 1,
          title: 'Outcome 1'
        }
      },
      {
        outcome_group: { id: 2 },
        outcome: {
          id: 2,
          title: 'Outcome 2'
        }
      }
    ],
    rollupsResponse: {
      rollups: [
        {
          scores: [
            { score: 3.0, links: { outcome: 1 } },
            { score: 1.0, links: { outcome: 2 } },
          ]
        }
      ]
    },
    resultsResponses: {
      1: {
        outcome_results: [
          { id: 1, score: 3.0, links: { assignment: 'assignment_1' } },
          { id: 2, score: 2.0, links: { assignment: 'assignment_2' } }
        ],
        linked: {
          assignments: [
            { id: 'assignment_1', name: 'Assignment 1' },
            { id: 'assignment_2', name: 'Assignment 2' }
          ]
        }
      },
      2: {
        outcome_results: [
          { id: 3, score: 3.0, links: { assignment: 'assignment_1' } },
        ],
        linked: {
          assignments: [
            { id: 'assignment_1', name: 'Assignment 1' }
          ]
        }
      }
    }
  })

  const expectedOutcomes = [
    {
      groupId: 1,
      id: 1,
      title: 'Outcome 1',
      score: 3,
      mastered: false,
      results: [
        {
          assignment: { id: 'assignment_1', name: 'Assignment 1' },
          score: 3
        },
        {
          assignment: { id: 'assignment_2', name: 'Assignment 2' },
          score: 2
        }
      ]
    },
    {
      groupId: 2,
      id: 2,
      title: 'Outcome 2',
      score: 1,
      mastered: false,
      results: [
        {
          assignment: { id: 'assignment_1', name: 'Assignment 1' },
          score: 3
        }
      ]
    }
  ]

  const mockAll = ({ groupsResponse, linksResponse, rollupsResponse, resultsResponses }) => {
    fetchMock.mock('/api/v1/courses/1/outcome_groups?per_page=100', groupsResponse)
    fetchMock.mock('/api/v1/courses/1/outcome_group_links?outcome_style=full&per_page=100', linksResponse)
    fetchMock.mock('/api/v1/courses/1/outcome_rollups?user_ids[]=2&per_page=100', rollupsResponse)
    Object.keys(resultsResponses).forEach((id) => {
      fetchMock.mock(
        `/api/v1/courses/1/outcome_results?user_ids[]=2&outcome_ids[]=${id}&include[]=assignments&per_page=100`,
        resultsResponses[id]
      )
    })
  }

  it('throws error if http throws error', (done) => {
    fetchMock.mock('*', 500)
    fetchOutcomes(1, 1)
      .then(() => done.fail())
      .catch(() => done())
  })

  it('handles complete request', (done) => {
    const responses = defaultResponses()
    mockAll(responses)
    fetchOutcomes(1, 2)
      .then(({ outcomeGroups, outcomes }) => {
        expect(outcomeGroups).toMatchObject(responses.groupsResponse)
        expect(outcomes).toMatchObject(expectedOutcomes)
        done()
      })
  })

  it('removes hidden results', (done) => {
    const responses = defaultResponses()
    responses.resultsResponses['1'].outcome_results[1].hidden = true
    mockAll(responses)
    fetchOutcomes(1, 2)
      .then(({ outcomes }) => {
        expect(outcomes[0].results).toHaveLength(1)
        done()
      })
  })

  it('removes empty outcome groups', (done) => {
    const responses = defaultResponses()
    responses.linksResponse = responses.linksResponse.slice(0, 1)
    mockAll(responses)
    fetchOutcomes(1, 2)
      .then(({ outcomeGroups }) => {
        expect(outcomeGroups).toHaveLength(1)
        done()
      })
  })

  describe('fetchUrl', () => {
    const mockRequests = (first, second, third) => {
      fetchMock.mock('/first', {
        body: first,
        headers: {
          link: '</current>; rel="current",</second>; rel="next",</first>; rel="first",</last>; rel="last"'
        }
      })
      fetchMock.mock('/second', {
        body: second,
        headers: !third ? null : {
          link: '</current>; rel="current",</third>; rel="next",</first>; rel="first",</last>; rel="last"'
        }
      })
      if (third) {
        fetchMock.mock('/third', {
          body: third,
          headers: {
            link: '</current>; rel="current",</first>; rel="first",</last>; rel="last"'
          }
        })
      }
    }

    it('combines result arrays', (done) => {
      mockRequests(
        [1, 'hello world', { foo: 'bar' }],
        [2, 'goodbye', { baz: 'bat' }]
      )
      fetchUrl('/first').then((resp) => {
        expect(resp).toEqual(
          [1, 'hello world', { foo: 'bar' }, 2, 'goodbye', { baz: 'bat' }]
        )
        done()
      })
    })

    it('combines result objects', (done) => {
      mockRequests(
        { a: 'b', c: ['d', 'e', 'f'] },
        { g: 'h', c: ['i', 'j', 'k'] }
      )
      fetchUrl('/first').then((resp) => {
        expect(resp).toEqual(
          { a: 'b', c: ['d', 'e', 'f', 'i', 'j', 'k'], g: 'h' }
        )
        done()
      })
    })

    it('handles three requests', (done) => {
      mockRequests(
        { a: 'b', c: ['d', 'e', 'f'] },
        { g: 'h', c: ['i', 'j', 'k'] },
        { a: 'x' }
      )
      fetchUrl('/first').then((resp) => {
        expect(resp).toEqual(
          { a: 'x', c: ['d', 'e', 'f', 'i', 'j', 'k'], g: 'h' }
        )
        done()
      })
    })

    it('handles deeply nested objects', (done) => {
      mockRequests(
        { a: { b: { c: { d: ['e', 'f'], g: ['h', 'i'], j: 'k' } } } },
        { a: { b: { c: { d: ['e2', 'f2'], g: ['h2', 'i2'], j: 'k2' } } } }
      )
      fetchUrl('/first').then((resp) => {
        expect(resp).toEqual(
          { a: { b: { c: { d: ['e', 'f', 'e2', 'f2'], g: ['h', 'i', 'h2', 'i2'], j: 'k2' } } } },
        )
        done()
      })
    })
  })
})
