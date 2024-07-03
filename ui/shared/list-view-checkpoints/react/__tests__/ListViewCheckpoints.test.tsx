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

import React from 'react'
import {render} from '@testing-library/react'
import {ListViewCheckpoints} from '../ListViewCheckpoints'
import {
  checkpointedAssignmentNoDueDates,
  checkpointedAssignmentWithDueDates,
  checkpointedAssignmentWithOverrides,
} from './mocks'

describe('ListViewCheckpoints', () => {
  it('renders the ListViewCheckpoints component with the correct checkpoint titles', async () => {
    const {container, getByTestId} = render(
      <ListViewCheckpoints {...checkpointedAssignmentNoDueDates} />
    )
    expect(container.querySelectorAll('li')).toHaveLength(2)

    expect(getByTestId('1_reply_to_topic_title').textContent).toEqual('Reply To Topic')
    expect(getByTestId('1_reply_to_entry_title').textContent).toEqual('Required Replies (4)')
  })

  describe('due date', () => {
    it('renders the ListViewCheckpoints components with No Due Date if the checkpoint as no due date', () => {
      const {getByTestId} = render(<ListViewCheckpoints {...checkpointedAssignmentNoDueDates} />)

      expect(getByTestId('1_reply_to_topic_due_date').textContent).toEqual('No Due Date')
      expect(getByTestId('1_reply_to_entry_due_date').textContent).toEqual('No Due Date')
    })

    it('renders the ListViewCheckpoints components with the formatted due dates if the checkpoint due_at field is populated', () => {
      const {getByTestId} = render(<ListViewCheckpoints {...checkpointedAssignmentWithDueDates} />)

      expect(getByTestId('1_reply_to_topic_due_date').textContent).toEqual('Jun 2')
      expect(getByTestId('1_reply_to_entry_due_date').textContent).toEqual('Jun 4')
    })

    // Once VICE-4350 is completed, modify this test to reflect the new changes for finding the due date from the checkpoint overrides
    it('renders the ListViewCheckpoints components with the formatted due dates if the checkpoint has overrides', () => {
      ENV.current_user_id = '1'

      const {getByTestId} = render(<ListViewCheckpoints {...checkpointedAssignmentWithOverrides} />)

      expect(getByTestId('1_reply_to_topic_due_date').textContent).toEqual('Jun 2')
      expect(getByTestId('1_reply_to_entry_due_date').textContent).toEqual('Jun 4')
    })
  })
})
