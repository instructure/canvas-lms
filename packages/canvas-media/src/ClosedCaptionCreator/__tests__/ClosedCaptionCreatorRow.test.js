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

function makeProps(overrides = {}) {
  return {
    rowId: undefined,
    languages: [
      {id: 'en', label: 'English'},
      {id: 'fr', label: 'French'}
    ],
    liveRegion: () => document.getElementById('flash_screenreader_holder'),
    uploadMediaTranslations: {
      UploadMediaStrings: {
        REMOVE_FILE: 'Remove {lang} closed captions',
        NO_FILE_CHOSEN: 'no file chosen',
        SUPPORTED_FILE_TYPES: 'supported file types',
        CLOSED_CAPTIONS_CHOOSE_FILE: 'choose file',
        CLOSED_CAPTIONS_SELECT_LANGUAGE: 'select language'
      },
      SelectStrings: {
        USE_ARROWS: 'Use arrows',
        LIST_COLLAPSED: 'List collapsed.',
        LIST_EXPANDED: 'List expanded.',
        OPTION_SELECTED: '{option} selected.'
      }
    },
    onDeleteRow: () => {},
    onFileSelected: () => {},
    onLanguageSelected: () => {},
    selectedFile: null,
    selectedLanguage: null,
    ...overrides
  }
}

function makeConfiguredProps(overrides = {}) {
  return makeProps({
    selectedLanguage: {id: 'en', label: 'English'},
    selectedFile: {name: 'thefile.srt'},
    rowId: 'en',
    ...overrides
  })
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

  describe('when showing configured caption data', () => {
    it('renders normally', () => {
      const {getByText} = render(<ClosedCaptionCreatorRow {...makeConfiguredProps()} />)
      expect(getByText('English')).toBeInTheDocument()
      expect(getByText('Remove English closed captions')).toBeInTheDocument()
    })

    it('calls onDeleteRow when trashcan is clicked', () => {
      const onDeleteRow = jest.fn()
      const {getByText} = render(
        <ClosedCaptionCreatorRow {...makeConfiguredProps({onDeleteRow})} />
      )
      const trashcan = getByText('Remove English closed captions').closest('button')
      fireEvent.click(trashcan)
      expect(onDeleteRow).toHaveBeenCalled()
    })
  })

  describe('when editing caption data', () => {
    it('renders normally', () => {
      const {getByText} = render(<ClosedCaptionCreatorRow {...makeProps()} />)
      expect(getByText('select language')).toBeInTheDocument()
      expect(getByText('choose file')).toBeInTheDocument()
      expect(getByText('no file chosen')).toBeInTheDocument()
      expect(getByText('supported file types')).toBeInTheDocument()
    })

    it('renders selected file name if a file is selected', () => {
      const {getByText} = render(
        <ClosedCaptionCreatorRow {...makeProps({selectedFile: {name: 'caps.srt'}})} />
      )
      expect(getByText('caps.srt')).toBeInTheDocument()
    })

    it('renders selected language when a language is selected', () => {
      const {getByDisplayValue} = render(
        <ClosedCaptionCreatorRow {...makeProps({selectedLanguage: {id: 'fr', name: 'French'}})} />
      )
      expect(getByDisplayValue('French')).toBeInTheDocument()
    })

    it('calls onFileSelected when file is selected', () => {
      const onFileSelected = jest.fn()
      const {container} = render(
        <ClosedCaptionCreatorRow
          {...makeProps({
            onFileSelected
          })}
        />
      )
      const fileInput = container.querySelector('input[type="file"]')
      const file = new File(['foo'], 'file1.vtt', {type: 'application/vtt'})
      selectFile(fileInput, [file])
      // We can validate the event object here but the parent is the one grabbing the file
      // from the input
      expect(onFileSelected).toHaveBeenCalledTimes(1)
    })
  })
})
