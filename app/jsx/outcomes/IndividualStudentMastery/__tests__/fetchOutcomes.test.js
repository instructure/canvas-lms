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
import fetchOutcomes from '../fetchOutcomes'

describe('fetchOutcomes', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  const groups = [
    {
      id: 1,
      title: 'Group 1'
    },
    {
      id: 2,
      title: 'Group 2'
    }
  ]

  const links = [
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
  ]

  const rollups = {
    rollups: [
      {
        scores: [
          { score: 3.0, links: { outcome: 1 } },
          { score: 1.0, links: { outcome: 2 } },
        ]
      }
    ]
  }

  const results1 = {
    outcome_results: [
      { id: 1, score: 3.0, links: { alignment: 'assignment_1' } },
      { id: 2, score: 2.0, links: { alignment: 'assignment_2' } }
    ],
    linked: {
      alignments: [
        { id: 'assignment_1', name: 'Assignment 1' },
        { id: 'assignment_2', name: 'Assignment 2' }
      ]
    }
  }

  const results2 = {
    outcome_results: [
      { id: 3, score: 3.0, links: { alignment: 'assignment_1' } },
    ],
    linked: {
      alignments: [
        { id: 'assignment_1', name: 'Assignment 1' }
      ]
    }
  }


  const expectedOutcomes = [
    {
      groupId: 1,
      id: 1,
      title: 'Outcome 1',
      score: 3,
      mastered: false,
      results: [
        {
          alignment: { id: 'assignment_1', name: 'Assignment 1' },
          score: 3
        },
        {
          alignment: { id: 'assignment_2', name: 'Assignment 2' },
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
          alignment: { id: 'assignment_1', name: 'Assignment 1' },
          score: 3
        }
      ]
    }
  ]

  const mockAll = () => {
    fetchMock.mock('/api/v1/courses/1/outcome_groups', groups)
    fetchMock.mock('/api/v1/courses/1/outcome_group_links?outcome_style=full', links)
    fetchMock.mock('/api/v1/courses/1/outcome_rollups?user_ids[]=2', rollups)
    fetchMock.mock('/api/v1/courses/1/outcome_results?user_ids[]=2&outcome_ids[]=1&include[]=alignments&per_page=100', results1)
    fetchMock.mock('/api/v1/courses/1/outcome_results?user_ids[]=2&outcome_ids[]=2&include[]=alignments&per_page=100', results2)
  }

  it('throws error if http throws error', (done) => {
    fetchMock.mock('*', 500)
    fetchOutcomes(1, 1)
      .then(() => done.fail())
      .catch(() => done())
  })

  it('handles complete request', (done) => {
    mockAll()
    fetchOutcomes(1, 2)
      .then(({ outcomeGroups, outcomes }) => {
        expect(outcomeGroups).toMatchObject(groups)
        expect(outcomes).toMatchObject(expectedOutcomes)
        done()
      })
  })
})
