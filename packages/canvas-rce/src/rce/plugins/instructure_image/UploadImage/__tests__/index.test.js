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
import {render, fireEvent} from 'react-testing-library'
import {UploadImage, PANELS, handleSubmit} from '../index'

describe('UploadImage', () => {
  it('calls onDismiss prop when closing', () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<UploadImage onDismiss={handleDismiss} />)

    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('calls handleSubmit on submit', () => {
    const handleSubmit = jest.fn()
    const handleDismiss = () => {}
    const {getByText} = render(<UploadImage onDismiss={handleDismiss} onSubmit={handleSubmit}/>)
    const submitBtn = getByText('Submit').closest('button')
    fireEvent.click(submitBtn)
    expect(handleSubmit).toHaveBeenCalled()
  })

  describe('handleSubmit', () => {

    const fakeNode = {
      addEventListener: jest.fn()
    };
    const fakeEditor = {
      content: '',
      dom: {createHTML: (tag, {src}) => `<img src="${src}" />`},
      insertContent (content) { fakeEditor.content += content },
      selection: { getEnd () {return fakeNode  }}
    }
    it('inserts image with url source when URL panel is selected', () => {
      handleSubmit(fakeEditor, PANELS.URL, {imageUrl: 'http://fake/path'})
      expect(fakeEditor.content).toEqual('<img src="http://fake/path" />')
    })

    it('calls contentProps.startMediaUpload when Computer panel is selected', () => {
      const fakeMediaUpload = jest.fn()
      const fakeFile = {
        name: 'foo.png',
        size: 3000,
        type: 'image/png'
      }
      handleSubmit(fakeEditor, PANELS.COMPUTER, { imageFile: fakeFile}, { startMediaUpload: fakeMediaUpload })
      expect(fakeMediaUpload).toHaveBeenCalledWith("images", {
        parentFolderId: 'media',
        name: 'foo.png',
        size: 3000,
        contentType: 'image/png',
        domObject: fakeFile
      })
    })
  })
})
