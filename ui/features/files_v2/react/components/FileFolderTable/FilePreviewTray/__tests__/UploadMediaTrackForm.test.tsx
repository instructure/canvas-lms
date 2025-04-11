/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {UploadMediaTrackForm, UploadMediaTrackFormProps} from '../UploadMediaTrackForm'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const defaultProps: UploadMediaTrackFormProps = {
  attachmentId: '1',
  closeForm: jest.fn(),
}

const renderComponent = (props?: Partial<UploadMediaTrackFormProps>) => {
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <UploadMediaTrackForm {...defaultProps} {...props} />
    </MockedQueryClientProvider>,
  )
}

describe('UploadMediaTrackForm', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    fetchMock.post(/.*\/media_tracks/, {uploadResult: 'ok'}, {overwriteRoutes: true})
  })

  afterEach(() => {
    destroyContainer()
  })

  it('displays language error message when no language is selected', async () => {
    renderComponent()
    const fileInput = screen.getByTestId('file-input')
    const file = new File(['dummy content'], 'test.srt', {type: 'text/plain'})
    await userEvent.upload(fileInput, file)

    const saveButton = screen.getByRole('button', {name: /save/i})
    await userEvent.click(saveButton)
    const errorText = screen.getByText('Please choose a language for the caption.')
    expect(errorText).toBeInTheDocument()

    const languageInput = screen.getByRole('combobox', {name: /choose a language \*/i})
    expect(languageInput).toHaveFocus()
  })

  it('displays file error message when no file is selected', async () => {
    renderComponent()
    const languageInput = screen.getByRole('combobox', {name: /choose a language \*/i})
    await userEvent.type(languageInput, 'English')
    const option = screen.getByRole('option', {name: /english \(australia\)/i})
    await userEvent.click(option)

    const saveButton = screen.getByRole('button', {name: /save/i})
    await userEvent.click(saveButton)
    const errorText = screen.getByText('Please upload a file.')
    expect(errorText).toBeInTheDocument()

    const fileButton = screen.getByRole('button', {name: /choose file/i})
    expect(fileButton).toHaveFocus()
  })

  it('displays both errors when both language and file are missing', async () => {
    renderComponent()
    const saveButton = screen.getByRole('button', {name: /save/i})
    await userEvent.click(saveButton)
    const languageErrorText = screen.getByText('Please choose a language for the caption.')
    const fileErrorText = screen.getByText('Please upload a file.')
    expect(languageErrorText).toBeInTheDocument()
    expect(fileErrorText).toBeInTheDocument()

    const languageInput = screen.getByRole('combobox', {name: /choose a language \*/i})
    expect(languageInput).toHaveFocus()
  })

  it('submits form with language and file', async () => {
    renderComponent()
    const langaugeInput = screen.getByRole('combobox', {name: /choose a language \*/i})
    await userEvent.type(langaugeInput, 'English')
    const option = screen.getByRole('option', {name: /english \(australia\)/i})
    await userEvent.click(option)

    const fileInput = screen.getByTestId('file-input')
    const file = new File(['dummy content'], 'test.srt', {type: 'text/plain'})

    await userEvent.upload(fileInput, file)

    const saveButton = screen.getByRole('button', {name: /save/i})
    await userEvent.click(saveButton)

    const formData = fetchMock.lastCall()?.[1]?.body as FormData
    expect(formData.get('locale')).toEqual('en-AU')
    expect(defaultProps.closeForm).toHaveBeenCalled()
  })

  it('closes on cancel', async () => {
    renderComponent()
    const cancelButton = screen.getByRole('button', {name: /cancel/i})
    await userEvent.click(cancelButton)
    expect(defaultProps.closeForm).toHaveBeenCalled()
  })

  it('flashes error on upload failure', async () => {
    fetchMock.post(/.*\/media_tracks/, {status: 500}, {overwriteRoutes: true})
    renderComponent()
    const langaugeInput = screen.getByRole('combobox', {name: /choose a language \*/i})
    await userEvent.type(langaugeInput, 'English')
    const option = screen.getByRole('option', {name: /english \(australia\)/i})
    await userEvent.click(option)

    const fileInput = screen.getByTestId('file-input')
    const file = new File(['dummy content'], 'test.srt', {type: 'text/plain'})

    await userEvent.upload(fileInput, file)

    const saveButton = screen.getByRole('button', {name: /save/i})
    await userEvent.click(saveButton)

    const errorText = screen.getAllByText(
      'There was an error uploading your caption. Please try again.',
    )
    // visible text and screenreader
    expect(errorText).toHaveLength(2)
  })
})
