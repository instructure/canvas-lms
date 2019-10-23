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
import {mockSubmission} from '../../../mocks'
import React from 'react'
import sinon from 'sinon'
import TextEntry from '../TextEntry'

async function makeProps(opts = {}) {
  const mockedSubmission =
    opts.submission ||
    (await mockSubmission({
      Submission: () => ({
        submissionDraft: {body: 'words'}
      })
    }))

  return {
    createSubmissionDraft: jest.fn(),
    editingDraft: opts.editingDraft || false,
    submission: mockedSubmission,
    updateEditingDraft: jest.fn()
  }
}

describe('TextEntry', () => {
  describe('when the submission draft body is null', () => {
    it('renders a Start Entry item', async () => {
      const mockedSubmission = await mockSubmission()
      const props = await makeProps({submission: mockedSubmission})
      const {getByText} = render(<TextEntry {...props} />)

      expect(getByText('Start Entry')).toBeInTheDocument()
    })
  })

  describe('when the submission draft body is not null', () => {
    describe('with the RCE view disabled', () => {
      it('renders the Edit button', async () => {
        const props = await makeProps()
        const {getByTestId, getByText} = render(<TextEntry {...props} />)
        const editButton = getByTestId('edit-text-draft')

        expect(editButton).toContainElement(getByText('Edit'))
      })

      it('renders the Delete button', async () => {
        const props = await makeProps()
        const {getByTestId} = render(<TextEntry {...props} />)

        expect(getByTestId('delete-text-draft')).toBeInTheDocument()
      })

      it('enables the RCE view when the Edit button is clicked', async () => {
        const props = await makeProps()
        const {getByTestId} = render(<TextEntry {...props} />)
        const editButton = getByTestId('edit-text-draft')
        fireEvent.click(editButton)

        expect(props.updateEditingDraft).toHaveBeenCalledWith(true)
      })

      it('deletes the saved draft when the Delete button is clicked', async () => {
        const props = await makeProps()
        const {getByTestId} = render(<TextEntry {...props} />)
        const editButton = getByTestId('delete-text-draft')
        fireEvent.click(editButton)

        expect(props.createSubmissionDraft).toHaveBeenCalledWith({
          variables: {
            id: '1',
            activeSubmissionType: 'online_text_entry',
            attempt: 1,
            body: null
          }
        })
      })
    })

    describe.skip('with the RCE view enabled', () => {
      // TODO: get this to work with latest @testing-library
      it('renders the RCE when the draft body is not null', async () => {
        const props = await makeProps({editingDraft: true})
        const {getByTestId} = render(<TextEntry {...props} />)

        expect(getByTestId('text-editor')).toBeInTheDocument()
      })

      it('renders the Cancel button when the RCE is loaded', async () => {
        const props = await makeProps({editingDraft: true})
        const {getByTestId, getByText} = render(<TextEntry {...props} />)

        const cancelButton = getByTestId('cancel-text-entry')
        expect(cancelButton).toContainElement(getByText('Cancel'))
      })

      it('renders the Save button when the RCE is loaded', async () => {
        const props = await makeProps({editingDraft: true})
        const {getByTestId, getByText} = render(<TextEntry {...props} />)

        const saveButton = getByTestId('save-text-entry')
        expect(saveButton).toContainElement(getByText('Save'))
      })

      it('saves the text draft when the Save button is clicked', async () => {
        const props = await makeProps({editingDraft: true})
        const {getByTestId} = render(<TextEntry {...props} />)

        const saveButton = getByTestId('save-text-entry')
        fireEvent.click(saveButton)

        expect(props.createSubmissionDraft).toHaveBeenCalledWith({
          variables: {
            id: '1',
            attempt: 1,
            body: 'words'
          }
        })
      })

      it.skip('stops displaying the RCE when the Cancel button is clicked', async () => {
        // TODO: get this to work with latest @testing-library
        const props = await makeProps({editingDraft: true})
        const {getByTestId} = render(<TextEntry {...props} />)

        const cancelButton = getByTestId('cancel-text-entry')
        fireEvent.click(cancelButton)

        expect(props.updateEditingDraft).toHaveBeenCalledWith(false)
      })
    })
  })

  it('displays the submitted text body when the text has been submitted', async () => {
    const mockedSubmission = await mockSubmission({
      Submission: () => ({
        body: '<p>thundercougarfalconbird</p>',
        state: 'submitted'
      })
    })
    const props = await makeProps({submission: mockedSubmission})
    const {getByTestId, getByText} = render(<TextEntry {...props} />)

    expect(getByTestId('text-submission')).toBeInTheDocument()
    expect(getByText('thundercougarfalconbird')).toBeInTheDocument()
  })

  it('displays the submitted text body when the submission has been graded', async () => {
    const mockedSubmission = await mockSubmission({
      Submission: () => ({
        body: '<p>thundercougarfalconbird</p>',
        state: 'graded'
      })
    })
    const props = await makeProps({submission: mockedSubmission})
    const {getByTestId, getByText} = render(<TextEntry {...props} />)

    expect(getByTestId('text-submission')).toBeInTheDocument()
    expect(getByText('thundercougarfalconbird')).toBeInTheDocument()
  })

  it('sets up beforeunload handler', async () => {
    sinon.spy(window, 'addEventListener')

    const props = await makeProps()
    render(<TextEntry {...props} />)

    expect(window.addEventListener.lastCall.args).toContain('beforeunload')
  })
})
