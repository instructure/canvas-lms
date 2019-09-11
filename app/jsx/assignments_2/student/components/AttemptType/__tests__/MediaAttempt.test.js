/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import MediaAttempt from '../MediaAttempt'
import {mockAssignment} from '../../../mocks'
import {render} from '@testing-library/react'
import React from 'react'

describe('MediaAttempt', () => {
  it('renders the upload tab by default', async () => {
    const assignment = await mockAssignment()
    const {getByText} = render(<MediaAttempt assignment={assignment} />)
    expect(getByText('Record/Upload')).toBeInTheDocument()
    expect(getByText('Add Media')).toBeInTheDocument()
  })

  // This will crash given the media modal requires browser specifics
  // fwiw get a real browser or test with selenium
  // it('opens media modal when button is clicked', async () => {
  // const assignment = await mockAssignment()
  // const {getByText, getByTestId} = render(<MediaAttempt assignment={assignment} />)
  // const editButton = getByTestId('media-modal-launch-button')
  // fireEvent.click(editButton)
  // expect(
  // await waitForElement(() => getByText('drag and drop or clik to browse'))
  // ).toBeInTheDocument()
  // })
})
