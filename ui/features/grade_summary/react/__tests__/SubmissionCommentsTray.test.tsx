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
import SubmissionCommentsTray from '../SubmissionCommentsTray'
import * as useState from '../stores'
import {render, fireEvent} from '@testing-library/react'
import type {SubmissionAttemptsComments} from '../../../../api.d'

// EVAL-3907 - remove or rewrite to remove spies on imports
describe.skip('SubmissionCommentsTray', () => {
  const attempts: SubmissionAttemptsComments = {
    attempts: {
      1: [
        // @ts-ignore
        {
          id: '1',
          comment: 'this is a comment',
          display_updated_at: 'Sat Nov 1st',
          updated_at: '',
          author: {
            display_name: 'user123',
            id: '1',
            avatar_image_url: '',
            html_url: '',
          },
          created_at: Date(),
          edited_at: Date(),
        },
      ],
    },
  }

  it('renders the tray when open is set to true', () => {
    jest.spyOn(useState, 'default').mockReturnValueOnce(attempts).mockReturnValueOnce(true)
    const {getByTestId, queryByText} = render(<SubmissionCommentsTray />)
    expect(getByTestId('submission-tray-details')).toBeInTheDocument()
    expect(getByTestId('submission-tray-dismiss')).toBeInTheDocument()
    expect(queryByText('Feedback')).toBeInTheDocument()
    expect(queryByText('this is a comment')).toBeInTheDocument()
  })
  it('does not render the tray when open is set to false', () => {
    jest.spyOn(useState, 'default').mockReturnValueOnce(attempts).mockReturnValueOnce(false)
    const {queryByText, queryByTestId} = render(<SubmissionCommentsTray />)
    expect(queryByTestId('submission-tray-details')).not.toBeInTheDocument()
    expect(queryByTestId('submission-tray-dismiss')).not.toBeInTheDocument()
    expect(queryByText('Feedback')).not.toBeInTheDocument()
    expect(queryByText('this is a comment')).not.toBeInTheDocument()
  })
  it('sets state to closed when CloseButton is clicked', () => {
    jest.spyOn(useState, 'default').mockReturnValueOnce(attempts).mockReturnValueOnce(true)
    jest.spyOn(useState, 'updateState')
    const {getByTestId} = render(<SubmissionCommentsTray />)
    fireEvent.click(getByTestId('submission-tray-dismiss').childNodes[0])
    expect(useState.updateState).toHaveBeenLastCalledWith({submissionTrayOpen: false})
  })
})
