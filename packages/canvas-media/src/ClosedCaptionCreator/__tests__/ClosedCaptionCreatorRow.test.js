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
import React from 'react'

import ClosedCaptionCreatorRow from '../ClosedCaptionCreatorRow'

function makeProps() {
  return {
    languages: [{id: 'en', label: 'English'}, {id: 'fr', label: 'French'}],
    liveRegion: () => document.getElementById('flash_screenreader_holder'),
    uploadMediaTranslations: {
      UploadMediaStrings: {
        CLOSED_CAPTIONS_LANGUAGE_HEADER: 'Language',
        CLOSED_CAPTIONS_FILE_NAME_HEADER: 'File Name',
        CLOSED_CAPTIONS_ACTIONS_HEADER: 'Actions',
        CLOSED_CAPTIONS_ADD_SUBTITLE: 'Subtitle',
        CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER: 'Add Subtitle',
        CLOSED_CAPTIONS_CHOOSE_FILE: 'Choose File',
        CLOSED_CAPTIONS_SELECT_LANGUAGE: 'Select Language'
      }
    },
    onOptionSelected: () => {},
    onFileSelected: () => {},
    fileSelected: false,
    selectedFileName: '',
    renderTrashButton: false,
    trashButtonOnClick: () => {}
  }
}

describe('ClosedCaptionCreatorRow', () => {
  const selectFile = (element, file) => {
    fireEvent.change(element, {
      target: {
        file
      }
    })
  }

  beforeAll(() => {
    const node = document.createElement('div')
    node.setAttribute('role', 'alert')
    node.setAttribute('id', 'flash_screenreader_holder')
    document.body.appendChild(node)
  })

  it('renders normally', () => {
    const {getByText} = render(<ClosedCaptionCreatorRow {...makeProps()} />)
    expect(getByText('Select Language')).toBeInTheDocument()
    expect(getByText('Choose File')).toBeInTheDocument()
  })

  it('renders trash can when renderTrashButton is present', () => {
    const callback = jest.fn()
    const props = makeProps()
    props.renderTrashButton = true
    props.trashButtonOnClick = callback
    const {getByText} = render(<ClosedCaptionCreatorRow {...props} />)
    const deleteRowButton = getByText('Delete Row').closest('button')
    fireEvent.click(deleteRowButton)
    expect(getByText('Delete Row')).toBeInTheDocument()
    expect(callback).toHaveBeenCalledTimes(1)
  })

  it('renders selectedFileName if fileSelected', () => {
    const props = makeProps()
    props.selectedFileName = 'thebestfilename.webvtt'
    props.fileSelected = true
    const {getByText} = render(<ClosedCaptionCreatorRow {...props} />)
    expect(getByText(props.selectedFileName)).toBeInTheDocument()
  })

  it('calls onFileSelected when file is selected', () => {
    const props = makeProps()
    const callback = jest.fn()
    props.onFileSelected = callback
    const {container} = render(<ClosedCaptionCreatorRow {...props} />)
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.vtt', {type: 'application/vtt'})
    selectFile(fileInput, [file])
    // We can validate the event object here but the parent is the one grabbing the file
    // from the input
    expect(callback).toHaveBeenCalledTimes(1)
  })
})
