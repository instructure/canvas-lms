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

import ClosedCaptionCreator from '../ClosedCaptionCreator'

function makeProps(options = {}) {
  return {
    languages: [
      {id: 'en', label: 'English'},
      {id: 'fr', label: 'French'}
    ],
    liveRegion: () => document.getElementById('flash_screenreader_holder'),
    uploadMediaTranslations: {
      UploadMediaStrings: {
        ADDED_CAPTION: 'added caption',
        ADD_NEW_CAPTION_OR_SUBTITLE: 'add new caption',
        REMOVE_FILE: 'Remove {lang} closed captions',
        NO_FILE_CHOSEN: 'no file chosen',
        SUPPORTED_FILE_TYPES: 'supported file types',
        CLOSED_CAPTIONS_CHOOSE_FILE: 'Choose File',
        CLOSED_CAPTIONS_SELECT_LANGUAGE: 'select language',
        DELETED_CAPTION: 'deleted caption'
      },
      SelectStrings: {
        USE_ARROWS: 'Use arrows',
        LIST_COLLAPSED: 'List collapsed.',
        LIST_EXPANDED: 'List expanded.',
        OPTION_SELECTED: '{option} selected.'
      }
    },
    updateSubtitles: () => {},
    ...options
  }
}

describe('ClosedCaptionPanel', () => {
  const selectFile = (element, file) => {
    fireEvent.change(element, {
      target: {
        files: file
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
    const {getByTestId} = render(<ClosedCaptionCreator {...makeProps()} />)
    expect(getByTestId('CC-CreatorRow-choosing')).toBeInTheDocument()
  })

  it('selects a file', () => {
    const updateSubtitles = jest.fn()
    const {container, getByText, getByPlaceholderText, getByTestId} = render(
      <ClosedCaptionCreator {...makeProps({updateSubtitles})} />
    )
    const selectLang = getByPlaceholderText('select language')
    fireEvent.click(selectLang)
    const frOpt = getByText('French')
    fireEvent.click(frOpt)

    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.srt', {type: 'application/srt'})
    selectFile(fileInput, [file])

    expect(getByTestId('CC-CreatorRow-chosen')).toBeInTheDocument()
    expect(getByText('add new caption')).toBeInTheDocument()
    expect(updateSubtitles).toHaveBeenCalledWith(
      expect.arrayContaining([expect.objectContaining({locale: 'fr'})])
    )
  })

  it('adds a new row when + is clicked', () => {
    const {container, getByText, getByPlaceholderText, getAllByTestId} = render(
      <ClosedCaptionCreator {...makeProps()} />
    )
    expect(getAllByTestId('CC-CreatorRow-choosing').length).toBe(1)

    // create the first row
    const selectLang = getByPlaceholderText('select language')
    fireEvent.click(selectLang)
    const frOpt = getByText('French')
    fireEvent.click(frOpt)

    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.srt', {type: 'application/srt'})
    selectFile(fileInput, [file])

    expect(getAllByTestId('CC-CreatorRow-chosen').length).toBe(1)

    // click the + button to add a new row
    const plusBtn = getByText('add new caption')
    fireEvent.click(plusBtn)

    expect(getAllByTestId('CC-CreatorRow-chosen').length).toBe(1)
    expect(getAllByTestId('CC-CreatorRow-choosing').length).toBe(1)
  })

  it('deletes a row when trashcan is clicked', () => {
    const {container, getByText, getByPlaceholderText, getAllByTestId} = render(
      <ClosedCaptionCreator {...makeProps()} />
    )
    expect(getAllByTestId('CC-CreatorRow-choosing').length).toBe(1)

    // create the first row
    let selectLang = getByPlaceholderText('select language')
    fireEvent.click(selectLang)
    let opt = getByText('French')
    fireEvent.click(opt)

    let fileInput = container.querySelector('input[type="file"]')
    let file = new File(['foo'], 'file1.srt', {type: 'application/srt'})
    selectFile(fileInput, [file])

    expect(getAllByTestId('CC-CreatorRow-chosen').length).toBe(1)

    // click the + button to add a new row
    const plusBtn = getByText('add new caption')
    fireEvent.click(plusBtn)

    expect(getAllByTestId('CC-CreatorRow-chosen').length).toBe(1)
    expect(getAllByTestId('CC-CreatorRow-choosing').length).toBe(1)

    // create the 2nd row
    selectLang = getByPlaceholderText('select language')
    fireEvent.click(selectLang)
    opt = getByText('English')
    fireEvent.click(opt)

    fileInput = container.querySelector('input[type="file"]')
    file = new File(['bar'], 'file2.srt', {type: 'application/srt'})
    selectFile(fileInput, [file])

    expect(getAllByTestId('CC-CreatorRow-chosen').length).toBe(2)

    // delete the first row
    const trashcan = getByText('Remove French closed captions').closest('button')
    fireEvent.click(trashcan)

    expect(getAllByTestId('CC-CreatorRow-chosen').length).toBe(1)
    expect(getByText('English')).toBeInTheDocument()
  })
})
