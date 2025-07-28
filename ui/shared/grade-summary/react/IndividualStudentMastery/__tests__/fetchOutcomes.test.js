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
import fetchOutcomes, {fetchUrl} from '../fetchOutcomes'
import NaiveFetchDispatch from '../NaiveFetchDispatch'

describe('fetchOutcomes', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  const defaultResponses = () => ({
    groupsResponse: [
      {
        id: 1,
        title: 'Group 1',
      },
      {
        id: 2,
        title: 'Group 2',
      },
    ],
    linksResponse: [
      {
        outcome_group: {id: 1},
        outcome: {
          id: 1,
          title: 'Outcome 1',
        },
      },
      {
        outcome_group: {id: 2},
        outcome: {
          id: 2,
          title: 'Outcome 2',
        },
      },
    ],
    rollupsResponse: {
      rollups: [
        {
          scores: [
            {score: 3.0, links: {outcome: 1}},
            {score: 1.0, links: {outcome: 2}},
          ],
        },
      ],
    },
    resultsResponses: {
      1: {
        outcome_results: [
          {id: 1, score: 3.0, links: {assignment: 'assignment_1', learning_outcome: '1'}},
          {id: 2, score: 2.0, links: {assignment: 'assignment_2', learning_outcome: '1'}},
          {
            id: 3,
            score: 2.0,
            links: {alignment: 'live_assessments/assessment_1', learning_outcome: '1'},
          },
        ],
        linked: {
          assignments: [
            {id: 'assignment_1', name: 'Assignment 1'},
            {id: 'assignment_2', name: 'Assignment 2'},
            {id: 'live_assessments/assessment_1', name: 'Test'},
          ],
        },
      },
      2: {
        outcome_results: [
          {id: 3, score: 3.0, links: {assignment: 'assignment_1', learning_outcome: '2'}},
        ],
        linked: {
          assignments: [{id: 'assignment_1', name: 'Assignment 1'}],
        },
      },
      12: {
        outcome_results: [
          {id: 12, score: 3.0, links: {assignment: 'assignment_1', learning_outcome: '12'}},
        ],
        linked: {
          assignments: [{id: 'assignment_1', name: 'Assignment 1'}],
        },
      },
    },
    alignmentsResponse: {
      1: [
        {
          assignment_id: 1,
          learning_outcome_id: 1,
          submission_types: 'online_text_entry',
          title: 'Assignment 1',
          url: 'http://example.com',
        },
        {
          assignment_id: 2,
          learning_outcome_id: 1,
          submission_types: 'online_text_entry',
          title: 'Assignment 2',
          url: 'http://example2.com',
        },
      ],
      2: [
        {
          assignment_id: 1,
          learning_outcome_id: 2,
          submission_types: 'online_text_entry',
          title: 'Assignment 1',
          url: 'http://example.com',
        },
      ],
    },
    assignmentsResponse: [
      {
        id: 1,
        course_id: 1,
        rubric: [
          {
            points: 5,
            ratings: [
              {
                points: 5,
                description: "Full Marks"
              },
              {
                points: 0,
                description: "No Marks"
              }
            ]
          },
          {
            points: 5,
            description: "Outcome 1",
            ratings: [
              {
                points: 5,
                description: "Exceeds Expectations"
              },
              {
                points: 3,
                description: "Meets Expectations"
              },
              {
                points: 0,
                description: "Does Not Meet Expectations"
              }
            ],
            outcome_id: 1
          }
        ]
      }
    ]
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
          assignment: {id: 'assignment_1', name: 'Assignment 1'},
          score: 3,
        },
        {
          assignment: {id: 'assignment_2', name: 'Assignment 2'},
          score: 2,
        },
        {
          assignment: {id: 'live_assessments/assessment_1', name: 'Test'},
          score: 2,
        },
      ],
    },
    {
      groupId: 2,
      id: 2,
      title: 'Outcome 2',
      score: 1,
      mastered: false,
      results: [
        {
          assignment: {id: 'assignment_1', name: 'Assignment 1'},
          score: 3,
        },
      ],
    },
  ]

  const mockAll = ({
    groupsResponse,
    linksResponse,
    rollupsResponse,
    resultsResponses,
    alignmentsResponse,
    assignmentsResponse,
    fullResponse = false,
  }) => {
    fetchMock.mock('/api/v1/courses/1/outcome_groups?per_page=100', groupsResponse)
    fetchMock.mock(
      '/api/v1/courses/1/outcome_group_links?outcome_style=full&per_page=100',
      linksResponse,
    )
    fetchMock.mock('/api/v1/courses/1/outcome_rollups?user_ids[]=2&per_page=100', rollupsResponse)
    fetchMock.mock('/api/v1/courses/1/outcome_alignments?student_id=2', alignmentsResponse)
    fetchMock.mock('begin:/api/v1/courses/1/outcome_results', url => {
      const outcomeIdPattern = /outcome_ids\[\]=(\d+)/g
      const ids = []
      let match
      while ((match = outcomeIdPattern.exec(url))) {
        ids.push(match[1])
      }
      const results = {outcome_results: [], linked: {assignments: []}}
      if (fullResponse) {
        Object.values(resultsResponses).forEach(result => {
          results.outcome_results.push(...result.outcome_results)
          results.linked.assignments.push(...result.linked.assignments)
        })
      } else {
        ids.forEach(id => {
          const response = resultsResponses[id] || {outcome_results: [], linked: {assignments: []}}
          results.outcome_results.push(...response.outcome_results)
          results.linked.assignments.push(...response.linked.assignments)
        })
      }
      return results
    })
    fetchMock.mock('/api/v1/courses/1/assignments?per_page=100&page=1', assignmentsResponse)
  }

  it('throws error if http throws error', async () => {
    fetchMock.mock('*', 500)
    await expect(fetchOutcomes(1, 1)).rejects.toThrow()
  })

  it('handles complete request', async () => {
    const responses = defaultResponses()
    mockAll(responses)
    const {outcomeGroups, outcomes} = await fetchOutcomes(1, 2)
    expect(outcomeGroups).toMatchObject(responses.groupsResponse)
    expect(outcomes).toMatchObject(expectedOutcomes)
    const testResults = outcomes.map(outcome => outcome.results[0])
    expect(testResults[0].outcomeRatingsFromRubric)
      .toMatchObject(responses.assignmentsResponse[0].rubric[1].ratings)
    expect(testResults[1].outcomeRatingsFromRubric).toBeUndefined()
  })

  it('removes hidden results', async () => {
    const responses = defaultResponses()
    responses.resultsResponses['1'].outcome_results[1].hidden = true
    mockAll(responses)
    const {outcomes} = await fetchOutcomes(1, 2)
    expect(outcomes[0].results).toHaveLength(2)
  })

  it('removes empty outcome groups', async () => {
    const responses = defaultResponses()
    responses.linksResponse = responses.linksResponse.slice(0, 1)
    mockAll(responses)
    const {outcomeGroups} = await fetchOutcomes(1, 2)
    expect(outcomeGroups).toHaveLength(1)
  })

  it('handles multiple results requests', async () => {
    const responses = defaultResponses()
    for (let i = 3; i <= 20; i++) {
      responses.linksResponse.push({
        outcome_group: {id: i},
        outcome: {
          id: i,
          title: `Outcome ${i}`,
        },
      })
    }
    mockAll(responses)
    const {outcomes} = await fetchOutcomes(1, 2)
    expect(outcomes).toHaveLength(20)
    expect(outcomes.find(outcome => outcome.id === 12).results).toHaveLength(1)
  })
  it('handles an unexpected outcome result', async () => {
    /* the idea here is to simulate an outcome_results response
       with elements not currently in the 'outcomeResultsByOutcomeId' variable
       so that the array adds the inexisting index before pushing the data */
    const responses = {...defaultResponses(), fullResponse: true}
    for (let i = 3; i <= 10; i++) {
      responses.linksResponse.push({
        outcome_group: {id: i},
        outcome: {
          id: i,
          title: `Outcome ${i}`,
        },
      })
    }
    mockAll(responses)
    const {outcomes} = await fetchOutcomes(1, 2)
    expect(outcomes).toHaveLength(10)
  })
  describe('fetchUrl', () => {
    let dispatch

    beforeEach(() => {
      dispatch = new NaiveFetchDispatch({activeRequestLimit: 2})
    })

    const mockRequests = (first, second, third) => {
      fetchMock.mock('/first', {
        body: first,
        headers: {
          link: '</current>; rel="current",</second>; rel="next",</first>; rel="first",</last>; rel="last"',
        },
      })
      fetchMock.mock('/second', {
        body: second,
        headers: !third
          ? null
          : {
              link: '</current>; rel="current",</third>; rel="next",</first>; rel="first",</last>; rel="last"',
            },
      })
      if (third) {
        fetchMock.mock('/third', {
          body: third,
          headers: {
            link: '</current>; rel="current",</first>; rel="first",</last>; rel="last"',
          },
        })
      }
    }

    it('combines result arrays', async () => {
      mockRequests([1, 'hello world', {foo: 'bar'}], [2, 'goodbye', {baz: 'bat'}])
      const resp = await fetchUrl('/first', dispatch)
      expect(resp).toEqual([1, 'hello world', {foo: 'bar'}, 2, 'goodbye', {baz: 'bat'}])
    })

    it('combines result objects', async () => {
      mockRequests({a: 'b', c: ['d', 'e', 'f']}, {g: 'h', c: ['i', 'j', 'k']})
      const resp = await fetchUrl('/first', dispatch)
      expect(resp).toEqual({a: 'b', c: ['d', 'e', 'f', 'i', 'j', 'k'], g: 'h'})
    })

    it('handles three requests', async () => {
      mockRequests({a: 'b', c: ['d', 'e', 'f']}, {g: 'h', c: ['i', 'j', 'k']}, {a: 'x'})
      const resp = await fetchUrl('/first', dispatch)
      expect(resp).toEqual({a: 'x', c: ['d', 'e', 'f', 'i', 'j', 'k'], g: 'h'})
    })

    it('handles deeply nested objects', async () => {
      mockRequests(
        {a: {b: {c: {d: ['e', 'f'], g: ['h', 'i'], j: 'k'}}}},
        {a: {b: {c: {d: ['e2', 'f2'], g: ['h2', 'i2'], j: 'k2'}}}},
      )
      const resp = await fetchUrl('/first', dispatch)
      expect(resp).toEqual({
        a: {b: {c: {d: ['e', 'f', 'e2', 'f2'], g: ['h', 'i', 'h2', 'i2'], j: 'k2'}}},
      })
    })
  })
})
