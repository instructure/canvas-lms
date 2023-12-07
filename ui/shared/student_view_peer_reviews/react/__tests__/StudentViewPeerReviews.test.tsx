/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {StudentViewPeerReviews, type StudentViewPeerReviewsProps} from '../StudentViewPeerReviews'

describe('StudentViewPeerReviews Component Tests', () => {
  it('renders the StudentViewPeerReviews component with anonymous peer reviewers', async () => {
    const defaultProps: StudentViewPeerReviewsProps = {
      assignment: {
        id: '1',
        anonymous_peer_reviews: true,
        course_id: '1',
        name: 'Assignment 1',
        assessment_requests: [
          {
            anonymous_id: 'anonymous1',
            user_id: 'user1',
            user_name: 'username1',
            available: true,
          },
          {
            anonymous_id: 'anonymous2',
            user_id: 'user2',
            user_name: 'username2',
            available: true,
          },
        ],
      },
    }

    const {container, queryByText, queryAllByText} = render(
      <StudentViewPeerReviews {...defaultProps} />
    )
    expect(container.querySelectorAll('li')).toHaveLength(2)
    expect(queryAllByText('Anonymous Student')).toHaveLength(2)
    expect(queryByText('username1')).not.toBeInTheDocument()
    expect(queryByText('username2')).not.toBeInTheDocument()

    const firstLink = container.querySelectorAll('a.item_link')[0]
    const secondLink = container.querySelectorAll('a.item_link')[1]
    expect(firstLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?anonymous_asset_id=anonymous1'
    )
    expect(secondLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?anonymous_asset_id=anonymous2'
    )
  })

  it('renders the StudentViewPeerReviews component with non anonymous peer reviewers', () => {
    const defaultProps: StudentViewPeerReviewsProps = {
      assignment: {
        id: '1',
        anonymous_peer_reviews: false,
        course_id: '1',
        name: 'Assignment 1',
        assessment_requests: [
          {
            anonymous_id: 'anonymous1',
            user_id: 'user1',
            user_name: 'username1',
            available: true,
          },
          {
            anonymous_id: 'anonymous2',
            user_id: 'user2',
            user_name: 'username2',
            available: true,
          },
          {
            anonymous_id: 'anonymous3',
            user_id: 'user3',
            user_name: 'username3',
            available: true,
          },
        ],
      },
    }

    const {container, queryByText} = render(<StudentViewPeerReviews {...defaultProps} />)
    expect(container.querySelectorAll('li')).toHaveLength(3)
    expect(queryByText('Anonymous Student')).not.toBeInTheDocument()
    expect(queryByText('username1')).toBeInTheDocument()
    expect(queryByText('username2')).toBeInTheDocument()
    expect(queryByText('username3')).toBeInTheDocument()

    const firstLink = container.querySelectorAll('a.item_link')[0]
    const secondLink = container.querySelectorAll('a.item_link')[1]
    const thirdLink = container.querySelectorAll('a.item_link')[2]
    expect(firstLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?reviewee_id=user1'
    )
    expect(secondLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?reviewee_id=user2'
    )
    expect(thirdLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?reviewee_id=user3'
    )
  })

  it('renders the StudentViewPeerReviews with mix of unavailable reviews', () => {
    const defaultProps: StudentViewPeerReviewsProps = {
      assignment: {
        id: '1',
        name: 'Assignment 1',
        anonymous_peer_reviews: false,
        course_id: '1',
        assessment_requests: [
          {
            anonymous_id: 'anonymous1',
            user_id: 'user1',
            user_name: 'username1',
            available: true,
          },
          {
            anonymous_id: 'anonymous2',
            user_id: 'user2',
            user_name: 'username2',
            available: false,
          },
        ],
      },
    }
    const {container, queryByText} = render(<StudentViewPeerReviews {...defaultProps} />)
    expect(container.querySelectorAll('li')).toHaveLength(2)
    expect(queryByText('Anonymous Student')).not.toBeInTheDocument()
    expect(queryByText('username1')).toBeInTheDocument()
    expect(queryByText('Not Available')).toBeInTheDocument()

    const firstLink = container.querySelectorAll('a.item_link')[0]
    const secondLink = container.querySelectorAll('a.item_link')[1]
    expect(firstLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?reviewee_id=user1'
    )
    expect(secondLink.attributes.getNamedItem('href')?.value).toEqual(
      '/courses/1/assignments/1?reviewee_id=user2'
    )
  })

  it('renders the StudentViewPeerReviews with correct peer review icon based on workflow_state', () => {
    const defaultProps: StudentViewPeerReviewsProps = {
      assignment: {
        id: '1',
        name: 'Assignment 1',
        anonymous_peer_reviews: false,
        course_id: '1',
        assessment_requests: [
          {
            anonymous_id: 'anonymous1',
            user_id: 'user1',
            user_name: 'username1',
            available: true,
            workflow_state: 'completed',
          },
          {
            anonymous_id: 'anonymous2',
            user_id: 'user2',
            user_name: 'username2',
            available: false,
            workflow_state: '',
          },
        ],
      },
    }
    const {container} = render(<StudentViewPeerReviews {...defaultProps} />)
    expect(container.querySelector('svg[name="IconPeerGraded"]')).toBeInTheDocument()
    expect(container.querySelector('svg[name="IconPeerReview"]')).toBeInTheDocument()
  })

  it('renders screen reader text for peer review link', () => {
    const defaultProps: StudentViewPeerReviewsProps = {
      assignment: {
        id: '1',
        name: 'Assignment 1',
        anonymous_peer_reviews: false,
        course_id: '1',
        assessment_requests: [
          {
            anonymous_id: 'anonymous1',
            user_id: 'user1',
            user_name: 'username1',
            available: true,
            workflow_state: 'completed',
          },
        ],
      },
    }
    const {container} = render(<StudentViewPeerReviews {...defaultProps} />)
    expect(
      container.querySelector('a[aria-label="Required Peer Review 1 for Assignment 1"]')
    ).toBeInTheDocument()
  })
})
