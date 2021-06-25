/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {PeerReview} from '../PeerReview'
import React from 'react'
import {render} from '@testing-library/react'

describe('PeerReview', () => {
  it('displays the correct message when the review is assigned', () => {
    const props = {
      dueAtDisplayText: 'Jan 26 11:49pm',
      revieweeName: 'Morty Smith',
      reviewLinkUrl: '#',
      workflowState: 'assigned'
    }
    const {getByText} = render(<PeerReview {...props} />)

    expect(getByText('Peer review for Morty Smith Due: Jan 26 11:49pm')).toBeTruthy()
  })

  it('omits the due date when there is not one', () => {
    const props = {
      revieweeName: 'Morty Smith',
      reviewLinkUrl: '#',
      workflowState: 'assigned'
    }
    const {getByText} = render(<PeerReview {...props} />)

    expect(getByText('Peer review for Morty Smith')).toBeTruthy()
  })

  it('displays the correct message when the review is completed', () => {
    const props = {
      revieweeName: 'Rick Sanchez',
      workflowState: 'completed'
    }
    const {getByText} = render(<PeerReview {...props} />)

    expect(getByText('You have completed a peer review for Rick Sanchez')).toBeTruthy()
  })
})
