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

import React from 'react'
import {render, screen} from '@testing-library/react'
import {ContentUnsupported} from '../ContentUnsupported'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('ContentUnsupported', () => {
  const mockData = {
    errors: {
      discussions: [
        {
          id: 1,
          name: 'Discussion 1',
          link: '/discussion1',
          errors: {
            discussion_type: {
              attribute: 'type',
              type: 'unsupported',
              message: 'Discussion type not supported',
            },
          },
        },
      ],
      collaborations: [
        {
          id: 1,
          name: 'Collab 1',
          link: '/collab1',
          errors: {
            peer_reviews: {
              attribute: 'peer_reviews',
              type: 'unsupported',
              message: 'Peer reviews not supported',
            },
          },
        },
      ],
      outcomes: [
        {
          id: 1,
          name: 'Outcome 1',
          link: '/outcome1',
          errors: {
            rubric: {
              attribute: 'rubric',
              type: 'unsupported',
              message: 'Rubric not supported',
            },
          },
        },
      ],
      groups: [
        {
          id: 1,
          name: 'Group 1',
          link: '/group1',
          errors: {
            group_category: {
              attribute: 'category',
              type: 'unsupported',
              message: 'Group category not supported',
            },
          },
        },
      ],
    },
  }

  it('includes all content type sections', () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <ContentUnsupported />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Discussions (1 item)')).toBeInTheDocument()
    expect(screen.getByText('Collaborations (1 item)')).toBeInTheDocument()
    expect(screen.getByText('Outcomes (1 item)')).toBeInTheDocument()
    expect(screen.getByText('Groups (1 item)')).toBeInTheDocument()
  })

  it('inlcudes only Discussions when there are no other errors', () => {
    render(
      <HorizonToggleContext.Provider
        value={{
          errors: {
            discussions: [
              {
                id: 1,
                name: 'Discussion 1',
                link: '/discussion1',
                errors: {
                  discussion_type: {
                    attribute: 'type',
                    type: 'unsupported',
                    message: 'Discussion type not supported',
                  },
                },
              },
            ],
          },
        }}
      >
        <ContentUnsupported />
      </HorizonToggleContext.Provider>,
    )

    expect(screen.getByText('Discussions (1 item)')).toBeInTheDocument()
    expect(screen.queryByText('Collaborations')).not.toBeInTheDocument()
    expect(screen.queryByText('Outcomes')).not.toBeInTheDocument()
    expect(screen.queryByText('Groups')).not.toBeInTheDocument()
  })
})
