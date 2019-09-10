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
import {fireEvent, render, waitForElement} from '@testing-library/react'
import React from 'react'

import ClosedCaptionCreator from '../ClosedCaptionCreator'

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
    updateSubtitles: () => {}
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
    const {getByText} = render(<ClosedCaptionCreator {...makeProps()} />)
    expect(getByText('Add Subtitle')).toBeInTheDocument()
  })

  describe('add subtitle button', () => {
    it('starts with a new row', () => {
      const {getByText} = render(<ClosedCaptionCreator {...makeProps()} />)
      expect(getByText('Choose File')).toBeInTheDocument()
      expect(getByText('Add Subtitle').closest('button')).toHaveAttribute('disabled')
    })

    it('disables trashcan on first addition', () => {
      const {getByText, queryByText} = render(<ClosedCaptionCreator {...makeProps()} />)
      expect(getByText('Choose File')).toBeInTheDocument()
      expect(getByText('Add Subtitle').closest('button')).toHaveAttribute('disabled')
      expect(queryByText('Delete Row')).not.toBeInTheDocument()
    })

    it('renders file name when one is selected', async () => {
      const {getByText, container} = render(<ClosedCaptionCreator {...makeProps()} />)
      expect(getByText('Choose File')).toBeInTheDocument()
      const file = new File(['foo'], 'file1.vtt', {type: 'application/vtt'})
      const fileInput = container.querySelector('input[type="file"]')
      selectFile(fileInput, [file])

      expect(await waitForElement(() => getByText('file1.vtt'))).toBeInTheDocument()
    })

    it('creates a new row', async () => {
      const {getByText, getByDisplayValue, queryByText, container} = render(
        <ClosedCaptionCreator {...makeProps()} />
      )
      expect(getByText('Choose File')).toBeInTheDocument()
      const file = new File(['foo'], 'file1.vtt', {type: 'application/vtt'})
      const fileInput = container.querySelector('input[type="file"]')
      selectFile(fileInput, [file])
      fireEvent.click(getByDisplayValue('Select Language'))
      fireEvent.click(getByText('French'))
      expect(await waitForElement(() => getByText('file1.vtt'))).toBeInTheDocument()
      expect(queryByText('Choose File')).not.toBeInTheDocument()
      const addButton = getByText('Add Subtitle').closest('button')
      fireEvent.click(addButton)
      expect(getByText('Choose File')).toBeInTheDocument()
    })

    it('deletes new row when trash is clicked', async () => {
      const {getByText, getByDisplayValue, queryByText, container} = render(
        <ClosedCaptionCreator {...makeProps()} />
      )
      expect(getByText('Choose File')).toBeInTheDocument()
      const file = new File(['foo'], 'file1.vtt', {type: 'application/vtt'})
      const fileInput = container.querySelector('input[type="file"]')
      selectFile(fileInput, [file])
      fireEvent.click(getByDisplayValue('Select Language'))
      fireEvent.click(getByText('French'))
      expect(await waitForElement(() => getByText('file1.vtt'))).toBeInTheDocument()
      expect(queryByText('Choose File')).not.toBeInTheDocument()
      const addButton = getByText('Add Subtitle').closest('button')
      fireEvent.click(addButton)
      expect(getByText('Choose File')).toBeInTheDocument()
      const deleteRowButton = getByText('Delete Row').closest('button')
      fireEvent.click(deleteRowButton)
      expect(queryByText('Choose File')).not.toBeInTheDocument()
    })

    it('deletes subtitle row when trash is clicked', async () => {
      const {getByText, getByDisplayValue, queryByText, container} = render(
        <ClosedCaptionCreator {...makeProps()} />
      )
      expect(getByText('Choose File')).toBeInTheDocument()
      const file1 = new File(['foo'], 'file1.vtt', {type: 'application/vtt'})
      const file2 = new File(['foo'], 'file2.vtt', {type: 'application/vtt'})
      const fileInput1 = container.querySelector('input[type="file"]')

      // Add first subtitle
      selectFile(fileInput1, [file1])
      fireEvent.click(getByDisplayValue('Select Language'))
      fireEvent.click(getByText('French'))
      expect(await waitForElement(() => getByText('file1.vtt'))).toBeInTheDocument()

      const addButton = getByText('Add Subtitle').closest('button')
      fireEvent.click(addButton)

      // Add second subtitle
      const fileInput2 = container.querySelector('input[type="file"]')
      selectFile(fileInput2, [file2])
      fireEvent.click(getByDisplayValue('Select Language'))
      fireEvent.click(getByText('English'))
      expect(await waitForElement(() => getByText('file2.vtt'))).toBeInTheDocument()

      // Delete first subtitle
      const deleteRowButton = getByText('Delete file1.vtt').closest('button')
      fireEvent.click(deleteRowButton)

      expect(queryByText('file1.vtt')).not.toBeInTheDocument()
    })
  })

  /*
  describe('adding a new closed caption', () => {
    it('has the language set to "Select Language" by default', () => {
      expect(true).toEqual(false)
    })

    it('lets you select another language', () => {
      expect(true).toEqual(false)
    })

    it('has the "Submit" button disabled if a file is uploaded with no language selected', () => {
      expect(true).toEqual(false)
    })

    it('has the "Submit" button disabled if no file is uploaded with a language selected', () => {
      expect(true).toEqual(false)
    })

    it('has the "Submit" button enabled if no file is uploaded nor a languaged selected ', () => {
      expect(true).toEqual(false)
    })

    it('has the "Submit" button enabled if a file is uploaded and a languaged is selected ', () => {
      expect(true).toEqual(false)
    })

    it('makes an API call when the submit button is clicked', () => {
      expect(true).toEqual(false)
    })
  })

  describe('removing a closed caption', () => {
    describe('for a not saved row', () => {
      it('can be removed', () => {
        expect(true).toEqual(false)
      })

      it('does not make an API call upon removal', () => {
        expect(true).toEqual(false)
      })
    })

    describe('for a saved row', () => {
      it('can be removed', () => {
        expect(true).toEqual(false)
      })

      it('does make an API call upon removal', () => {
        expect(true).toEqual(false)
      })
    })
  })

  describe('download button', () => {
    it('does not show up for a closed caption that has not been saved', () => {
      expect(true).toEqual(false)
    })

    it('shows up for a saved closed caption', () => {
      expect(true).toEqual(false)
    })

    it('makes an API call when clicked', () => {
      expect(true).toEqual(false)
    })
  })
  */
})
