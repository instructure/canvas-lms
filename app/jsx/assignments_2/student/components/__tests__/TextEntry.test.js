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

import {fireEvent, render} from '@testing-library/react'
import {mockSubmission} from '../../mocks'
import React from 'react'
import TextEntry from '../TextEntry'

describe('TextEntry', () => {
  describe('when the submission draft body is null', () => {
    it('renders a Start Entry item', async () => {
      const submission = await mockSubmission()
      const {getByText} = render(<TextEntry submission={submission} />)

      expect(getByText('Start Entry')).toBeInTheDocument()
    })
  })

  describe('when the submission draft body is not null', () => {
    it('renders the RCE when the draft body is not null', async () => {
      const submission = await mockSubmission({
        Submission: () => ({
          submissionDraft: {body: 'words'}
        })
      })
      const {getByTestId} = render(<TextEntry submission={submission} />)

      expect(getByTestId('text-editor')).toBeInTheDocument()
    })

    it('renders the Cancel button when the RCE is loaded', async () => {
      const submission = await mockSubmission({
        Submission: () => ({
          submissionDraft: {body: 'words'}
        })
      })
      const {getByTestId, getByText} = render(<TextEntry submission={submission} />)
      const cancelButton = getByTestId('cancel-text-entry')

      expect(cancelButton).toContainElement(getByText('Cancel'))
    })

    it('renders the Save button when the RCE is loaded', async () => {
      const submission = await mockSubmission({
        Submission: () => ({
          submissionDraft: {body: 'words'}
        })
      })
      const {getByTestId, getByText} = render(<TextEntry submission={submission} />)
      const saveButton = getByTestId('save-text-entry')

      expect(saveButton).toContainElement(getByText('Save'))
    })

    it('saves the text draft when the Save button is clicked', async () => {
      const createSubmissionDraft = jest.fn()
      const submission = await mockSubmission({
        Submission: () => ({
          submissionDraft: {body: 'words'}
        })
      })
      const {getByTestId} = render(
        <TextEntry createSubmissionDraft={createSubmissionDraft} submission={submission} />
      )
      const saveButton = getByTestId('save-text-entry')
      fireEvent.click(saveButton)

      expect(createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          attempt: 1,
          body: 'words'
        }
      })
    })

    it('clears the text draft when the Cancel button is clicked', async () => {
      const createSubmissionDraft = jest.fn()
      const submission = await mockSubmission({
        Submission: () => ({
          submissionDraft: {body: 'words'}
        })
      })
      const {getByTestId} = render(
        <TextEntry createSubmissionDraft={createSubmissionDraft} submission={submission} />
      )
      const cancelButton = getByTestId('cancel-text-entry')
      fireEvent.click(cancelButton)

      expect(createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          attempt: 1,
          body: null
        }
      })
    })
  })
})
