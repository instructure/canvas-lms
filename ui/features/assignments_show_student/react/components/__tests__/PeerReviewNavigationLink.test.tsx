/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'

import PeerReviewNavigationLink from '../PeerReviewNavigationLink'

describe('PeerReviewNavigationLink', () => {
  const props = {
    assignedAssessments: [
      {
        assetId: '1',
        anonymizedUser: {_id: '1', displayName: 'Jim'},
        anonymousId: null,
        workflowState: 'completed',
        assetSubmissionType: 'online_text_entry',
      },
      {
        assetId: '2',
        anonymizedUser: {_id: '2', displayName: 'Bob'},
        anonymousId: null,
        workflowState: 'assigned',
        assetSubmissionType: null,
      },
      {
        assetId: '3',
        anonymizedUser: {_id: '3', displayName: 'Jill'},
        anonymousId: null,
        workflowState: 'assigned',
        assetSubmissionType: 'online_text_entry',
      },
    ],
    currentAssessmentIndex: 1,
  }

  it('displays the labels for peer review states', () => {
    const {getByTestId, getByText} = render(<PeerReviewNavigationLink {...props} />)
    fireEvent.click(getByTestId('header-peer-review-link'))
    expect(getByText('Ready to Review')).toBeInTheDocument()
    expect(getByText('Not Yet Submitted')).toBeInTheDocument()
    expect(getByText('Completed Peer Reviews')).toBeInTheDocument()
  })

  // LF-1022
  it.skip('displays a gray highlight on the current peer review', () => {
    const {getByTestId} = render(<PeerReviewNavigationLink {...props} />)
    fireEvent.click(getByTestId('header-peer-review-link'))
    const completedMenuItem = getByTestId('peer-review-completed-1')
    expect(completedMenuItem.firstChild?.firstChild).toHaveStyle('color: white')
    expect(completedMenuItem).toHaveStyle('background: #6B7780')
  })

  describe('required peer review link when the anonymous peer review option is disabled', () => {
    it('displays a ready peer review in the Ready to Review section', () => {
      const {getByTestId} = render(<PeerReviewNavigationLink {...props} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-ready-3')).toHaveTextContent('Jill')
    })

    it('displays a ready peer review in the Not Yet Submitted section', () => {
      const {getByTestId} = render(<PeerReviewNavigationLink {...props} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-not-submitted-2')).toHaveTextContent('Bob')
    })

    it('displays a ready peer review in the Completed Peer Reviews section', () => {
      const {getByTestId} = render(<PeerReviewNavigationLink {...props} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-completed-1')).toHaveTextContent('Jim')
    })

    it('contains the correct url for the item is clicked on', () => {
      ENV.COURSE_ID = '1'
      ENV.ASSIGNMENT_ID = '1'
      const {getByTestId} = render(<PeerReviewNavigationLink {...props} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-completed-1')).toHaveAttribute(
        'href',
        '/courses/1/assignments/1?reviewee_id=1'
      )
    })
  })

  describe('required peer review link when the anonymous peer review option is enabled', () => {
    const props_ = {
      assignedAssessments: [
        {
          assetId: '1',
          anonymizedUser: null,
          anonymousId: 'anon_1',
          workflowState: 'completed',
          assetSubmissionType: 'online_text_entry',
        },
        {
          assetId: '2',
          anonymizedUser: null,
          anonymousId: 'anon_2',
          workflowState: 'assigned',
          assetSubmissionType: null,
        },
        {
          assetId: '3',
          anonymizedUser: null,
          anonymousId: 'anon_3',
          workflowState: 'assigned',
          assetSubmissionType: 'online_text_entry',
        },
      ],
      currentAssessmentIndex: 1,
    }

    it('displays a ready peer review in the Ready to Review section', () => {
      const {getByTestId} = render(<PeerReviewNavigationLink {...props_} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-ready-3')).toHaveTextContent('Anonymous 3')
    })

    it('displays a ready peer review in the Not Yet Submitted section', () => {
      const {getByTestId} = render(<PeerReviewNavigationLink {...props_} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-not-submitted-2')).toHaveTextContent('Anonymous 2')
    })

    it('displays a ready peer review in the Completed Peer Reviews section', () => {
      const {getByTestId} = render(<PeerReviewNavigationLink {...props_} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-completed-1')).toHaveTextContent('Anonymous 1')
    })

    it('contains the correct url for the item is clicked on', () => {
      ENV.COURSE_ID = '1'
      ENV.ASSIGNMENT_ID = '1'
      const {getByTestId} = render(<PeerReviewNavigationLink {...props_} />)
      fireEvent.click(getByTestId('header-peer-review-link'))
      expect(getByTestId('peer-review-completed-1')).toHaveAttribute(
        'href',
        '/courses/1/assignments/1?anonymous_asset_id=anon_1'
      )
    })
  })
})
