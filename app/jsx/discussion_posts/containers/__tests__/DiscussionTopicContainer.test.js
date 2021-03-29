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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import DiscussionTopicContainer from '../DiscussionTopicContainer'

describe('DiscussionTopicContainer', () => {
  const setup = props => {
    return render(<DiscussionTopicContainer {...props} />)
  }
  it('renders without optional props', async () => {
    const container = setup()
    expect(await container.queryByText('24 replies, 4 unread')).toBeTruthy()
    expect(await container.queryByTestId('graded-discussion-info')).toBeNull()
    expect(await container.queryByTestId('discussion-topic-reply')).toBeNull()
  })

  it('renders Graded info when isGraded', async () => {
    const container = setup({isGraded: true})
    const gradedDiscussionInfo = await container.findByTestId('graded-discussion-info')
    expect(gradedDiscussionInfo).toHaveTextContent(
      'Section 2This is a graded discussion: 5 points possibleDue: Jan 26 11:49pm'
    )
  })

  it('renders teacher components when hasTeacherPermissions', async () => {
    const container = setup({isGraded: true, hasTeacherPermissions: true})
    const manageButton = await container.getByText('Manage Discussion').closest('button')
    fireEvent.click(manageButton)
    expect(await container.getByText('Edit')).toBeTruthy()
    expect(await container.getByText('Delete')).toBeTruthy()
    expect(await container.getByText('Close for Comments')).toBeTruthy()
    expect(await container.getByText('Send To...')).toBeTruthy()
    expect(await container.getByText('Copy To...')).toBeTruthy()
  })
})
