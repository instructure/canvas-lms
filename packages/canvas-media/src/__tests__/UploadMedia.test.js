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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import UploadMedia from '../index'

const uploadMediaTranslations = {
  UploadMediaStrings: {
    CLEAR_FILE_TEXT: 'Clear selected file',
    CLOSE_TEXT: 'Close',
    COMPUTER_PANEL_TITLE: 'Computer',
    DRAG_DROP_CLICK_TO_BROWSE: 'Drop and drop, or click to browse your computer',
    DRAG_FILE_TEXT: 'Drag a file here',
    EMBED_PANEL_TITLE: 'Embed',
    EMBED_VIDEO_CODE_TEXT: 'Embed Code',
    INVALID_FILE_TEXT: 'Invalid File',
    LOADING_MEDIA: 'Loading...',
    RECORD_PANEL_TITLE: 'Record',
    SUBMIT_TEXT: 'Submit',
    UPLOADING_ERROR: 'Upload Error',
    UPLOAD_MEDIA_LABEL: 'Upload Media',
    MEDIA_RECORD_NOT_AVAILABLE: 'Record not available'
  }
}

function renderComponent(overrideProps = {}) {
  return render(
    <UploadMedia
      contextType="course"
      contextId="17"
      open
      liveRegion={() => null}
      onStartUpload={() => {}}
      onComplete={() => {}}
      onDismiss={() => {}}
      tabs={{embed: false, record: false, upload: true}}
      uploadMediaTranslations={uploadMediaTranslations}
      {...overrideProps}
    />
  )
}

describe('Upload Media', () => {
  describe('renders the selected tabs', () => {
    it('renders Computer', () => {
      const {getByText} = renderComponent({tabs: {embed: false, record: false, upload: true}})
      expect(getByText('Computer')).toBeInTheDocument()
    })

    it('renders Computer and Embed', () => {
      const {getByText} = renderComponent({tabs: {embed: true, record: false, upload: true}})
      expect(getByText('Computer')).toBeInTheDocument()
      expect(getByText('Embed')).toBeInTheDocument()
    })

    it('renders Computer, Record, and Embed', () => {
      const {getByText} = renderComponent({tabs: {embed: true, record: true, upload: true}})
      expect(getByText('Computer')).toBeInTheDocument()
      expect(getByText('Record')).toBeInTheDocument()
      expect(getByText('Embed')).toBeInTheDocument()
    })
  })

  describe('on submitting results', () => {
    it('calls onStartUpload', () => {
      const onStartUpload = jest.fn()
      const {getByText} = renderComponent({onStartUpload})

      fireEvent.click(getByText('Submit'))
      expect(onStartUpload).toHaveBeenCalled()
    })

    // the rest is tested via saveMediaRecording.test.js
  })
})
