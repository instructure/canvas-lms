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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {TempEnrollModal} from '../TempEnrollModal'

const props = {
  user: {id: '1', name: 'student1'},
  canReadSIS: true,
  accountId: '1',
}

describe('TempEnrollModal', () => {
  it('shows modal when opened', () => {
    const {getByText, queryByText} = render(
      <TempEnrollModal {...props}>
        <p>child_element</p>
      </TempEnrollModal>
    )
    const noHeading = queryByText('Create a Temporary Enrollment for student1')
    expect(noHeading).toBeNull()

    const c = getByText('child_element')
    fireEvent.click(c)

    expect(getByText('Create a Temporary Enrollment for student1')).toBeInTheDocument()
  })

  it('hides modal when exited', async () => {
    const {getByText, queryByText} = render(
      <TempEnrollModal {...props}>
        <p>child_element</p>
      </TempEnrollModal>
    )
    const c = getByText('child_element')
    fireEvent.click(c)

    const cancel = getByText('Cancel')
    fireEvent.click(cancel)

    await waitFor(() => expect(queryByText('Cancel')).toBeNull())
    const header = queryByText('Create a Temporary Enrollment for student1')
    expect(header).toBeNull()
  })
})
