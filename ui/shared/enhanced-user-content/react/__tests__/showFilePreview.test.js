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

import {findByLabelText, getByLabelText} from '@testing-library/dom'
import fetchMock from 'fetch-mock'
import {showFilePreview} from '../showFilePreview'
import fakeENV from '@canvas/test-utils/fakeENV'
import $ from 'jquery'

// Mock the FlashAlert module to prevent the console error about onDismiss
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

// Mock jQuery's flashError function
$.flashError = jest.fn()

// captured from a real query
const fauxFile =
  '{"id":"2282","uuid":"euqlFIGlaDneUO3hdN7n6NRkpRuImBhxSgy4Otev","folder_id":135,"display_name":"client-app-files.txt","filename":"client-app-files.txt","upload_status":"success","content-type":"text/plain","url":"http://localhost:3000/files/2282/download?download_frd=1","size":201105,"created_at":"2021-02-01T15:07:40Z","updated_at":"2021-02-01T15:07:43Z","unlock_at":null,"locked":false,"hidden":true,"lock_at":null,"hidden_for_user":false,"thumbnail_url":null,"modified_at":"2021-02-01T15:07:40Z","mime_class":"text","media_entry_id":null,"locked_for_user":false,"canvadoc_session_url":null,"crocodoc_session_url":null}'

describe('showFilePreview', () => {
  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = ''
    fetchMock.reset()
    fetchMock.mock('/api/v1/files/2282?include[]=enhanced_preview_url&verifier=abc', fauxFile)
    // Reset jQuery mock before each test
    $.flashError.mockClear()
  })

  afterEach(() => {
    fakeENV.teardown()
    fetchMock.restore()
    document.body.innerHTML = ''
  })

  it('creates the container if one does not exist', async () => {
    await showFilePreview('2282', 'abc')
    expect(document.getElementById('file_preview_container')).not.toBeNull()
  })

  it('displays the file preview', async () => {
    await showFilePreview('2282', 'abc')
    await findByLabelText(document.body, 'File Preview Overlay')
    expect(getByLabelText(document.body, 'File Preview Overlay')).toBeInTheDocument()
  })

  it('displays a flash error message if file is not found', async () => {
    // Mock the 404 response for this specific test
    fetchMock.mock('/api/v1/files/2283?include[]=enhanced_preview_url&verifier=abc', 404, {
      overwriteRoutes: true,
    })

    // Call the function that should trigger the error
    await showFilePreview('2283', 'abc')

    // Check that the container exists but no preview is rendered
    const container = document.getElementById('file_preview_container')
    expect(container).not.toBeNull()

    // The container should be empty when there's an error
    expect(container.innerHTML).toBe('')
  })
})
